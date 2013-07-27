module webtank.net.http_headers;

//TODO: Подумать, нужно ли делать URI декодировку заголовков

//Все ключи в заголовках храним в нижнем регистре
class HTTPHeaders
{	
	this(string data, uint count = uint.max)
	{	appendData(data);
		process(count);
	}
	
	this() {}
	
	//Добавление данных для обработки
	void appendData(string data)
	{	_data ~= data;
	}
	
	void process(uint count = uint.max)
	{	if(_headersFinished) return; //Если заголовки уже закончились, то ничего не делаем
		for( ; _pos < _data.length && count > 0; _pos++, count-- )
		{	if( _pos+2 < _data.length )
			{	if( _data[_pos.._pos+2] == "\r\n" )  //Разбираем строки по переносу
				{	_dataLines ~= _data[_currLineStart.._pos];
					_currLineStart = _pos + 2; //Начало текущей строки
					if( _pos+4 < _data.length ) //Обнаруживаем конец заголовков
					{	if( _data[_pos.._pos+4] == "\r\n\r\n" )
						{	_headersLength = _pos + 4;
							break;
						}
					}
				}
			}
		}
		
		//Разбор заголовков
		foreach( n, var; _dataLines[_parsedLinesCount..$] )
		{	import std.string;
			if( n == 1 )
			{	//Разбираем первую строку
				import std.array;
				auto firstLineAttr = split(_dataLines[0], " ");
				if( firstLineAttr.length >= 3 )
				{	
					//TODO: Добавить проверку начальной строки
					//Проверить методы по списку
					//Проверить URI (не знаю как)
					//Проверить версию HTTP. Поддерживаем 1.0, 1.1 (0.9 фтопку)
					_headers["method"] = firstLineAttr[0];
					_headers["request-uri"] = firstLineAttr[1];
					_headers["http-version"] = firstLineAttr[2];
				}
				else //Плохой запрос
				{	//TODO: Добавить ошибку о плохом запросе
				}
			}
			else if( n > 1 )
			{	for( size_t j = 0; j < var.length; j++ )
				{	if( j+2 < var.length )
					{	if( var[j..j+2] == ": " )
						{	//Названия заголовков храним без лишних пробелов в нижнем регистре,
							//а значения в том, в котором пришли
							_headers[ toLower( strip( var[0..j] ) ) ] = var[j+2..$];
							break;
						}
					}
				}
			}
		}
		_parsedLinesCount = _dataLines.length;
	}
	
	void reprocess(uint count = uint.max) @property
	{	_partialClear();
		process(count);
	}
	
	bool isStartLineAccepted() @property
	{	return _dataLines.length >= 1;
	}
	
	string opIndex(string name)
	{	import std.string;
		return _headers.get( toLower( strip( name ) ), null ); 
	}
	
	string extraData() @property
	{	if( _headersFinished ) 
			return null;
		else
			return _data[_headersLength..$];
	}
	
	size_t strLength() @property
	{	return _headersLength;
	}
	
// 	bool isRequest() @property
// 	{	
// 		
// 	}
// 	
// 	bool isResponse() @property
// 	{	
// 		
// 	}
	
	bool isFinished() @property
	{	return _headersFinished;
	}
	
	void clear()
	{	_data = null;
		_partialClear();
	}

protected:
	string _data;
	string[] _dataLines;
	size_t _pos = 0;
	bool _headersFinished = false;
	size_t _headersLength;
	public string[string] _headers;
	size_t _currLineStart;
	size_t _parsedLinesCount = 0;
	
	void _partialClear()
	{	_dataLines = null;
		_pos = 0;
		_headersFinished = false;
		_headers = null;
		_headersLength = 0;
		_currLineStart = 0;
		_parsedLinesCount = 0;
	}

}

// void main()
// {	auto headers = new HTTPHeaders;
// 	string headerStr = "GET / HTTP/1.1\r\nHost: translate.google.ru\r\nConnection: keep-alive\r\nCache-Control: max-age=0\r\nAccept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\nUser-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1500.71 Safari/537.36\r\nX-Chrome-Variations: COu1yQEIh7bJAQiptskBCJqEygEIqYXKAQi3hcoB\r\nAccept-Encoding: gzip,deflate,sdch\r\nAccept-Language: ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4\r\n\r\n";
// 	headers.appendData(headerStr);
// 	headers.process();
// 	import std.stdio;
// 	writeln(headers._headers);
// }