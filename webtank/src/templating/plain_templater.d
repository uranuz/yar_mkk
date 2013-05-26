module webtank.templating.plain_templater;

/**
	Пример шаблона:
*/
dstring testTemplateStr = `
	<html>
	<head>
	<title>{{browserTitle}}</title>
	<meta charset="{{encoding}}">
	<link rel="stylesheet" type="text/css" href="{{stylesheet}}"/>
	</head>
	{{?page_title:=hello}}
	{{?user_name:=vasya}}
		
	<body>
	<div id="header">{{header}}</div>
	<div id="sidebar">{{sidebar}}</div>
	<div id="content">{{content}}</div>
	<div id="footer">{{footer}}</div>
	</body>
	</html>`d;

class Element
{	immutable(size_t) prePos;
	immutable(size_t) sufPos;
	immutable(size_t) matchOpPos;
	dstring subst;
	this( size_t prefixPos, size_t suffixPos, size_t matchOperatorPos = size_t.max )
	{	prePos = prefixPos; sufPos = suffixPos; matchOpPos = matchOperatorPos; }
	bool isVar() @property
	{	return matchOpPos != size_t.max;
	}
}

enum dstring[dstring] defaultConfig = 
[	"markPre": "{{", "markSuf": "}}", "varPre": "{{?",
	"varSuf": "}}", "matchOp": ":="
];

// struct Config
// {	dstring markPre = "{{";
// 	dstring markSuf = "}}";
// 	dstring varPre = "{{?";
// 	dstring varSuf = "}}";
// 	dstring matchOp = ":=";
// }

struct Lexeme
{	dstring name;
	dstring value;
	alias bool delegate(size_t i) CheckFuncT;
	alias void delegate(size_t i) FixFuncT;
	CheckFuncT check;
	FixFuncT fix;
}

class PlainTemplater
{	
//protected:
	
	Element[][dstring] _namedEls;
	Element[] _indexedEls;
	dstring _sourceStr;
// 	Config _config;
	dstring[dstring] _config;
public:
	this( dstring templateStr, dstring[dstring] config = defaultConfig )
	{	_config = config;
		parseTemplateStr(templateStr);
	}
	
	void substitude(dstring value, dstring name)
	{	foreach(el; _namedEls[name])
		{	el.subst = value;
		}
	}
	
	Lexeme[] _prepareLexems(
		Lexeme.CheckFuncT[dstring] checkFuncs,
		Lexeme.FixFuncT[dstring] fixFuncs
	)
	{	Lexeme[] result;
		foreach( name, value; _config )
		{	result ~= Lexeme(
				name, value, 
				checkFuncs.get(name, null),
				fixFuncs.get(name, null)
			);
		}
// 		import std.algorithm;
// 		std.algorithm.sort!("a.value.length > b.value.length")(result);
		return result;
	}
	
	dstring getStr()
	{	dstring result;
		size_t textStart = 0;
		foreach(el; _indexedEls)
		{	if( el.isVar )
			{	result ~= _sourceStr[textStart .. el.prePos];
				textStart = el.sufPos + _config["varSuf"].length;
			}
			else
			{	result ~= _sourceStr[textStart .. el.prePos] ~ el.subst;
				textStart = el.sufPos + _config["markSuf"].length;
			}
		}
		result ~= _sourceStr[textStart .. $];
		return result;
	}
	
	void parseTemplateStr( dstring templateStr )
	{	
		size_t prefixPos;
		size_t matchOpPos;
		bool markPreFound = false;
		bool varMatchOpFound = false;
		bool varPreFound = false;
		
		_sourceStr = templateStr;
		
		Lexeme.CheckFuncT[dstring] checkFuncs = 
		[	"matchOp": (size_t i){
				return varPreFound;
			},
			"varSuf": (size_t i){
				return varPreFound && varMatchOpFound;
			},
			"markSuf": (size_t i){
				return markPreFound;
			}
		];
		
		Lexeme.FixFuncT[dstring] fixFuncs = 
		[	"matchOp": (size_t i){
				varMatchOpFound = true;
				matchOpPos = i;
			},
			"varPre": (size_t i){
				varPreFound = true;
				prefixPos = i;
			},
			"varSuf": (size_t i){
				varMatchOpFound = false;
				varPreFound = false;
			},
			"markPre": (size_t i){
				markPreFound = true;
				prefixPos = i;
			},
			"markSuf": (size_t i){
				markPreFound = false;
			}
		];
		
		
		auto lexems = _prepareLexems(checkFuncs, fixFuncs);
// 		import std.stdio;
// 		writeln(lexems);
// 		writeln("\r\n------------------------------\r\n");
		dstring elemName;
		
		for( size_t i = 0; i < templateStr.length; ++i )
		{	Lexeme[] selLexemes;
			foreach( curLex; lexems )
			{	if( (i + curLex.value.length) < templateStr.length )
				{	if( templateStr[i .. (i + curLex.value.length) ] == curLex.value )
					{	//Если нашли, то добавляем в сортированный список новый элемент
						if( ( curLex.check is null ) ? true : curLex.check(i) )
						{	selLexemes ~= curLex;
						}
					}
				}
			}
			
			if( selLexemes.length > 0 )
			{
				size_t largestLexLen;
				size_t selIndex = 0;
				foreach( k, curLex; selLexemes )
				{	if( curLex.value.length > largestLexLen )
					{	largestLexLen = curLex.value.length;
						selIndex = k;
					}
				}
				selLexemes[selIndex].fix(i);

//  				import std.stdio;
//  				writeln(selLexemes);
//  				writeln("\r\n------------------------------\r\n");
				
				if( selLexemes[selIndex].name == "markSuf"  )
				{	import std.string;
					elemName = std.string.strip(
						templateStr[ (prefixPos + _config["markPre"].length) .. i ]
					);
					auto elem = new Element(prefixPos, i);
					_namedEls[elemName] ~= elem;
					_indexedEls ~= elem;
				}
			
				if( selLexemes[selIndex].name == "varSuf" )
				{	import std.string;
				
// 					import std.stdio;
// 					writeln(matchOpPos);
// 					writeln("\r\n------------------------------\r\n");
				
					elemName = std.string.strip(
						templateStr[ (prefixPos + _config["varPre"].length) .. matchOpPos ]
					);
					auto elem = new Element(prefixPos, i, matchOpPos);
					_namedEls[elemName] ~= elem;
					_indexedEls ~= elem;
				}
			}
			//else if( selLexemes.length > 1 )
				//assert(0, "Обнаружена неоднозначность при разборе", selLexemes.length);
		}
	}
}



void main()
{	import std.stdio;
	auto tempter = new PlainTemplater(testTemplateStr);
// 	foreach(el; tempter._indexedEls)
// 	{	
// 		//writeln(el);
// 		writeln(tempter._sourceStr[
// 			(  ( ( el.matchOpPos == size_t.max ) ? tempter._config.markPre.length : tempter._config.varPre.length ) + el.prePos  ) .. ( ( el.matchOpPos == size_t.max ) ? el.sufPos : el.matchOpPos )
// 		]);
// 		//writeln(el.prePos);
// 		//writeln(el.sufPos);
// 		//writeln(el.matchOpPos);
// 	}
	tempter.substitude("Вася", "content");
	writeln( tempter.getStr() );
	
}
