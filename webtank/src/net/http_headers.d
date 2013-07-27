module webtank.net.http_headers;

//enum HTTPHeadersType {request, response, empty, illegal}

class HTTPHeaders
{	
	this(string data, uint count = uint.max)
	{	appendData(data);
		process(count);
	}
	
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
					_currLineStart = _pos + 2;
					if( _pos+4 < _data.length ) //Обнаруживаем конец заголовков
					{	if( _data[_pos.._pos+4] == "\r\n\r\n" )
						{	_headerLength = _pos;
							break;
						}
					}
				}
			}
		}
		if( _dataLines.length == 1 )
		{	//Разбираем первую строку
			import std.array;
			auto firstLineAttr = split(_dataLines[0], " ");
			if( firstLineAttr.length >= 3 )
			{	_headers["HTTP_METHOD"] = firstLineAttr[0];
				_headers["HTTP_PATH"] = firstLineAttr[1];
				_headers["HTTP_VERSION"] = firstLineAttr[2];
			}
			else //Плохой запрос
			{	//TODO: Добавить ошибку о плохом запросе
			}
		}
		else if( _dataLines.length > 1 )
		{	//Разбор заголовков
			foreach( var; _dataLines[1..$] )
			{	for( size_t j = 0; j < var.length; j++ )
				{	if( j+2 < var.length )
					{	if( var[j..j+2] == ": " )
						{	_headers[ var[0..j] ] = var[j+2..$];
							break;
						}
					}
				}
			}
		}
	}
	
	void reprocess(uint count = uint.max) @property
	{	_partialClear();
		process(count);
	}
	
	bool isFirstLineAccepted() @property
	{	return _dataLines.length >= 1;
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
	size_t _headerLength;
	public string[string] _headers;
	size_t _currLineStart;
	
	void _partialClear()
	{	_dataLines = null;
		_pos = 0;
		_headersFinished = false;
		string[string] _headers = null;
		_headerLength = 0;
		_currLineStart = 0;
	}

}