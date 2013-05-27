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

enum LexemeType 
{	markPre, markSuf, varPre, matchOp, varSuf };

dstring[LexemeType] defaultLexems;

static this()
{	with( LexemeType )
	{
	defaultLexems = [
		markPre: "{{", markSuf: "}}", 
		varPre: "{{?", matchOp: ":=", varSuf: "}}" 
	];
	} //with( LexemeType )
}

class PlainTemplater
{	
protected:
	Element[][dstring] _namedEls;
	Element[] _indexedEls;
	dstring _sourceStr;
	dstring[LexemeType] _lexValues;
	
public:
	this( dstring templateStr, dstring[LexemeType] lexems = defaultLexems )
	{	_lexValues = lexems;
		_sourceStr = templateStr;
		_parseTemplateStr();
	}
	
	void substitude(dstring value, dstring name)
	{	foreach(el; _namedEls[name])
		{	el.subst = value;
		}
	}
	
	dstring getValue(dstring name)
	{	if( (name in _namedEls) && (_namedEls[name].length > 0) )
		{	auto el = _namedEls[name][0];
			return 
				_sourceStr[ (el.matchOpPos + _lexValues[LexemeType.matchOp].length) .. el.sufPos ];
		}
		else 
			return null;
	}
	
	dstring getStr()
	{	dstring result;
		size_t textStart = 0;
		foreach(el; _indexedEls)
		{	if( el.isVar )
			{	result ~= _sourceStr[textStart .. el.prePos];
				textStart = el.sufPos + _lexValues[LexemeType.varSuf].length;
			}
			else
			{	result ~= _sourceStr[textStart .. el.prePos] ~ el.subst;
				textStart = el.sufPos + _lexValues[LexemeType.markSuf].length;
			}
		}
		result ~= _sourceStr[textStart .. $];
		return result;
	}
	
	void _parseTemplateStr()
	{	
		size_t prefixPos;
		size_t matchOpPos;
		bool markPreFound = false;
		bool varMatchOpFound = false;
		bool varPreFound = false;
		
		for( size_t i = 0; i < _sourceStr.length; ++i )
		{	dstring[LexemeType] selLexemes;
			foreach( lexType, curLexValue; _lexValues )
			{	if( (i + curLexValue.length) < _sourceStr.length )
				{	if( _sourceStr[i .. (i + curLexValue.length) ] == curLexValue )
					{	//Если нашли, то добавляем в сортированный список новый элемент
						bool checked = true;
						with( LexemeType )
						{
						switch( lexType )
						{	
							case matchOp: {
								checked = varPreFound;
								break;
							}
							case varSuf: {
								checked = varPreFound && varMatchOpFound;
								break;
							}
							case markSuf: {
								checked = markPreFound;
								break;
							}
							default:
							
							break;
						}
						} //with( LexemeType )
						if( checked )
							selLexemes[lexType] ~= curLexValue;
					}
				}
			}
			
			//Если ни одной лексемы не найдено, то идём дальше
			if( selLexemes.length <= 0 )
				continue;
			//Из всех найденных лексем будем брать самую длинную
			size_t largestLexLen;
			LexemeType selLexType;
			foreach( lexType, curLexValue; selLexemes )
			{	if( curLexValue.length > largestLexLen )
				{	largestLexLen = curLexValue.length;
					selLexType = lexType;
				}
			}
			
			with( LexemeType )
			{
			switch( selLexType )
			{
				case matchOp: {
					varMatchOpFound = true;
					matchOpPos = i;
					break;
				}
				case varPre: {
					varPreFound = true;
					prefixPos = i;
					break;
				}
				case varSuf: {
					import std.string;
					auto elemName = std.string.strip(
						_sourceStr[ (prefixPos + _lexValues[varPre].length) .. matchOpPos ]
					);
					auto elem = new Element(prefixPos, i, matchOpPos);
					_namedEls[elemName] ~= elem;
					_indexedEls ~= elem;
					varMatchOpFound = false;
					varPreFound = false;
					break;
				}
				case markPre: {
					markPreFound = true;
					prefixPos = i;
					break;
				}
				case markSuf: {
					import std.string;
					auto elemName = std.string.strip(
						_sourceStr[ (prefixPos + _lexValues[markPre].length) .. i ]
					);
					auto elem = new Element(prefixPos, i);
					_namedEls[elemName] ~= elem;
					_indexedEls ~= elem;
					markPreFound = false;
					break;
				}
				default:
				
				break;
			}
			} //with( LexemeType )
		}
	}
}

void main()
{	import std.stdio;
	auto tempter = new PlainTemplater(testTemplateStr);
	tempter.substitude("Вася", "content");
	writeln( tempter.getStr() );
	writeln(tempter.getValue("page_title"));
	
}
