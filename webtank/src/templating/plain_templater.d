module webtank.templating.plain_templater;

/**
	Пример шаблона:
*/
dstring testTemplateStr = `
	<html>
	<head>
	<title>{{browserTitle}}</title>
	<meta charset="{{encoding}}"
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

struct Config
{	dstring markPre = "{{";
	dstring markSuf = "}}";
	dstring varPre = "{{?";
	dstring varSuf = "}}";
	dstring matchOp = ":=";
}

class PlainTemplater
{	
//protected:
	
	Element[][dstring] _namedEls;
	Element[] _indexedEls;
	dstring _sourceStr;
	Config _config;
public:
	this( dstring templateStr, Config config = Config.init )
	{	_config = config;
		parseTemplateStr(templateStr);
	}
	
	void setSubst(dstring value, dstring name, size_t index = size_t.max)
	{	if( index == size_t.max )
		{	foreach(el; _namedEls[name])
			{	el.subst = value;
			}
			
			
		}
				
	}
	
	
	
	void parseTemplateStr( dstring templateStr )
	{	
		size_t prefixPos;
		size_t matchOpPos = size_t.max;
		dstring elemName;
		bool markPreFound = false;
		bool varPreFound = false;
		_sourceStr = templateStr;
		auto markPre = _config.markPre;
		auto markSuf = _config.markSuf;
		auto varPre = _config.varPre;
		auto varSuf = _config.varSuf;
		auto matchOp = _config.matchOp;
		size_t minPreLen = 
			( markPre.length < varPre.length ) ? markPre.length : varPre.length;
		
		for( size_t i = 0; i < templateStr.length; ++i )
		{	
			bool isLexeme(dstring lex)
			{	if( lex.length > 0 )
					if( (i + lex.length) < templateStr.length )
						return ( templateStr[i .. (i + lex.length) ] == lex );
				return false;
			}
			
			if( isLexeme(markPre) )
			{	prefixPos = i;
				if( varPreFound )
				{	
				}
				markPreFound = true;
			}
			if( isLexeme(markSuf) && (matchOpPos == size_t.max) )
			{	import std.string;
				elemName = std.string.strip(
					templateStr[ (prefixPos + markPre.length) .. i ]
				);
				auto elem = new Element(prefixPos, i);
				_namedEls[elemName] ~= elem;
				_indexedEls ~= elem;
			}
			if( isLexeme(varPre) )
			{	prefixPos = i; }
			if( isLexeme(matchOp) )
			{	matchOpPos = i; }
			if( isLexeme(varSuf) && (matchOpPos != size_t.max) )
			{	import std.string;
				elemName = std.string.strip(
					templateStr[ (prefixPos + varPre.length) .. matchOpPos ]
				);
				auto elem = new Element(prefixPos, i, matchOpPos);
				_namedEls[elemName] ~= elem;
				_indexedEls ~= elem;
				matchOpPos = size_t.max;
			}
		}
	}
}



void main()
{	import std.stdio;
	auto tempter = new PlainTemplater(testTemplateStr);
	foreach(el; tempter._indexedEls)
	{	
		writeln(tempter._sourceStr[
			(  ( ( el.matchOpPos == size_t.max ) ? tempter._config.markPre.length : tempter._config.varPre.length ) + el.prePos  ) .. ( ( el.matchOpPos == size_t.max ) ? el.sufPos : el.matchOpPos )
		]);
		writeln(el.prePos);
		writeln(el.sufPos);
		writeln(el.matchOpPos);
	}
	
	
}
