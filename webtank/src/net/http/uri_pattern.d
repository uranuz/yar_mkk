module webtank.net.http.uri_pattern;

import std.stdio, std.conv;

import std.utf, std.algorithm, std.regex;

struct PlainURIData
{	dstring[dstring] params;
	bool isMatched = false;
}

class PlainURIPattern
{	
	this( dstring URIPatternStr, dstring[dstring] conditions, dstring[dstring] defaults )
	{	_patternStr = toUTF32(URIPatternStr);
		_parseURIPatternStr(URIPatternStr);
		_conditions = conditions;
		_defaults = defaults;
	}
	
	
	PlainURIData getURIData(string URIStr)
	{	import std.utf;
		return getURIData( std.utf.toUTF32(URIStr) );
	}
	
	PlainURIData getURIData(dstring URIStr)
	{	auto parsingResult = _matchURIWithPattern(URIStr);
		if( !parsingResult.isMatched )
			return parsingResult;
		
		auto params = parsingResult.params;
		
		//Задаём значения по-умолчанию для параметров
		foreach( paramName, value; _defaults )
		{	if( params.get(paramName, null).length == 0 )
			{	params[paramName] = value;
			}
		}
		
		size_t matchedConditionsCount = 0;
		//Проверка условий
		foreach( paramName, cond; _conditions )
		{	auto r = regex("^" ~ cond ~ "$", "g");
			if( paramName in params )
			{
				auto matchResult = matchFirst(params[paramName], r);
				if( !matchResult.empty )
				{	//Совпадение с шаблоном
					matchedConditionsCount ++;
				}
				else
				{	//Несовпадение с шаблоном
					return PlainURIData(null, false);
				}
				
			}
			else
			{	//Параметр с заданным именем вовсе не найден
				return PlainURIData(null, false); 
			}
		}
		
		if( matchedConditionsCount == _conditions.length )
			return PlainURIData(params, true);
		else
			return PlainURIData(null, false);
	}
	
protected:
	dstring _patternStr;
	dstring[dstring] _conditions;
	dstring[dstring] _defaults;
	
	dstring[] _literals;
	dstring[] _paramNames;
	bool _isLiteralFirst = true;
	
	void _parseURIPatternStr(dstring URIPatternStr)
	{	size_t i = 0;

		size_t lexemePos = 0;
		bool isNameStarted = false;
		bool isParam = false; //Показывает тип последней обнаруженной лексемы (если есть)
		
		
		for( ; i < URIPatternStr.length; i++ )
		{	
			if( URIPatternStr[i] == '{' )
			{	if( isNameStarted )
					throw new Exception("Bracket balance violation at: " ~ i.to!string );
				
				auto literal = URIPatternStr[lexemePos .. i];
				
				if( literal.length > 0 ) //Добавляем только не пустые литералы
				{	if( _paramNames.length == 0 && _literals.length == 0 )
						_isLiteralFirst = true; //Говорим, что первым идёт литерал
						
					_literals ~= literal;
					isParam = false;
				}
				
				isNameStarted = true;
				lexemePos = i + 1;
			}
			else if( URIPatternStr[i] == '}' )
			{	//По закрытию скобочки добавляем имя параметра
				if( !isNameStarted )
					throw new Exception("Bracket balance violation at: " ~ i.to!string );
				
				if( _paramNames.length > 0 && isParam )
					throw new Exception("Two parameters cannot follow consecutive in URI pattern!!!");
				
				auto paramName = URIPatternStr[lexemePos .. i];
				
				if( paramName.length > 0 )
				{	if( _paramNames.length == 0 && _literals.length == 0 )
						_isLiteralFirst = false; //Говорим, что первым идёт параметр
				
					_paramNames ~= paramName; //Добавляем имя параметра в список
					isParam = true;
				}
				else
					throw new Exception("Name of the parameter in URI pattern cannot be empty!!!");
				
				isNameStarted = false;
				lexemePos = i + 1;
			}
		}
		
		if( isNameStarted ) //Проверка незакрытой скобки в конце шаблона
			throw new Exception("Bracket balance violation at: " ~ i.to!string );
		
		//Добавление литерала в конце шаблона
		if( isParam && lexemePos < URIPatternStr.length )
			_literals ~= URIPatternStr[lexemePos .. $];
	}
	
	//Проверка корректности набора лексем
	bool _isValidLexemeSet() nothrow
	{	return ( _literals.length == _paramNames.length || 
			_literals.length == ( _paramNames.length + 1 ) ||
			( _literals.length + 1 ) ==  _paramNames.length
		);
	}
	
	//Функция пытается разобрать адрес по шаблону, представленному массивом lexemes
	//Возвращает структуру с результатами разбора
	PlainURIData _matchURIWithPattern( dstring URIStr ) nothrow
	{	//Проверка, что имеем корректный набор лексем
		if( !_isValidLexemeSet )
			return PlainURIData(null, false);

		dstring[dstring] params;
		
		size_t literalIndex = 0;
		size_t paramIndex = 0;
		
		size_t paramValuePos = 0; //Позиция значения текущего параметра
		
		size_t i = 0; //Позиция окна анализа в строке
		
		//Проверка, если в начале должен идти литерал
		if( _isLiteralFirst && _literals.length > 0 ) 
		{	if( URIStr.startsWith(_literals[0]) )
			{	i = _literals[0].length;
				paramValuePos = _literals[0].length;
				literalIndex++;
			}
			else
			{	//Несоответствие шаблону - в начале должен идти литерал
				return PlainURIData(null, false);
			}
		}
		
		//Метод добавления значения параметра в результат
		bool appendParam(size_t i) nothrow
		{	auto paramName = _paramNames[paramIndex];
			auto paramValue = URIStr[paramValuePos..i];
			
			if( paramName in params )
			{	if( paramValue != params[paramName] )
					return false;
			}
			else
			{	params[ paramName ] = paramValue;
				paramIndex++;
			}
			
			return true;
		}
		
		//Цикл просмотра строки и поиска литералов
		for( ; i < URIStr.length; i++ )
		{	if( literalIndex < _literals.length && paramIndex < _paramNames.length )
			{	if( URIStr[i..$].startsWith(_literals[literalIndex]) )
				{	//Нашли литерал 
				
					if( !appendParam(i) ) //Добавляем параметр, идущий до него
						return PlainURIData(null, false);
					
					//Выставляем позицию после текущего параметра
					paramValuePos = i + _literals[literalIndex].length; 
					
					//Далее идут костыли
					literalIndex++;
					
					if( literalIndex != _literals.length )
					{	i = i + _literals[literalIndex-1].length - 1; //Ставим курсор после литерала
						//literalIndex-1, ибо уже увеличили literalIndex
					}
					else
						break; //Чтобы не увеличивалось i при обнаружении последнего литерала
				}
			}
			else
				break; //Все литералы найдены - завершаем цикл
		}
		
		if( _literals.length == _paramNames.length && _isLiteralFirst ||
			( _literals.length + 1 ) == _paramNames.length )
		{	//Добавление последнего параметра
			if( !appendParam(URIStr.length) )
				return PlainURIData(null, false); //Если не получилось добавить, то всё плохо
		}
		else if( _literals.length == _paramNames.length && !_isLiteralFirst ||
			_literals.length == ( _paramNames.length + 1 ) )
		{	//Проверка последнего литерала (что им оканчивается строка)
			if( URIStr[i..$] != _literals[$-1] )
				return PlainURIData(null, false);
		}
		

		//Прверяем количества найденных литералов и параметров
		if( literalIndex == _literals.length && paramIndex == _paramNames.length )
			return PlainURIData(params,true); //Всё отлично!!!
		else
			return PlainURIData(null, false);
	}
	
}




// void main()
// {	
// 	
// 	dstring URIPatternStr = `/dyn/pohod/by_date/(  {start_year}( |/{start_month} )(|/to/{end_year}(|/{end_month})))`;
// 	
// 	
// 	dstring plainURIPatternStr1 = `{fig}/dyn/pohod/by_date/{start_year}/{start_month}/to/{end_year}/{end_month}`;
// 	dstring URIExampleStr1 = `/dyn/pohod/by_date/2013r/08/to/2014/06`;
// 	
// 	dstring plainURIPatternStr2 = `/dyn/pohod/by_date/{goblin}/ololo_{name}`;
// 	dstring URIExampleStr2 = `/dyn/pohod/by_date/{goblin}/ololo_{name}/`;
// 	
// 	auto pattern = new PlainURIPattern(plainURIPatternStr1, ["start_year": `\d*`], ["fig": "ooo"]);
// 	
// 	writeln( pattern.getURIData(URIExampleStr1) );
// 
// }