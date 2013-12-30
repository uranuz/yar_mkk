module webtank.net.http.handler;

import std.stdio, std.conv;

import webtank.net.http.context, webtank.common.utils;

///Интерфейс обработчика HTTP-запросов приложения
interface IHTTPHandler
{	///Метод обработки запроса. Возвращает true, если запрос обработан.
	///Возвращает false, если запрос не соответствует обработчику
	///В случае ошибки кидает исключение
	bool processRequest(HTTPContext context);
}

///Типы обработчиков, используемых при обработке HTTP-запросов

///Тип обработчика: ошибка при обработке HTTP-запроса
alias bool delegate(HTTPContext, Throwable) ErrorHandler;

///Тип обработчика: начало опроса обработчика HTTP-запроса
alias void delegate(HTTPContext)  PrePollHandler;

///Тип обработчика: начало обработки HTTP-запроса
alias void delegate(HTTPContext) PreProcessHandler;

///Тип обработчика: завершение обработки HTTP-запроса
alias void delegate(HTTPContext) PostProcessHandler;

///Базовый класс набора обработчиков HTTP-запросов
class EventBasedHTTPHandler: IHTTPHandler
{	this()
	{	_errorEvent = new Event!(ErrorHandler);
		_prePollEvent = new Event!(PrePollHandler);
		_preProcessEvent = new Event!(PreProcessHandler);
		_postProcessEvent = new Event!(PostProcessHandler);
	}
	
	///События, возникающие при обработке запроса
	@property {
		///Событие: ошибка при обработке HTTP-запроса
		Event!(ErrorHandler) onError()
		{	return _errorEvent; }
		
		///Событие: начало опроса обработчика HTTP-запроса
		Event!(PrePollHandler) onPrePoll()
		{	return _prePollEvent; }
		
		///Событие: начало обработки HTTP-запроса
		Event!(PreProcessHandler) onPreProcess()
		{	return _preProcessEvent; }
		
		///Событие: завершение обработки HTTP-запроса
		Event!(PostProcessHandler) onPostProcess()
		{	return _postProcessEvent; }
	}
	
	///Реализация обработчика HTTP-запроса по-умолчанию.
	///Без отсутствия явной необходимости не переопределять,
	///а использовать переопределение customProcessRequest
	bool processRequest( HTTPContext context )
	{	//Перебор различных обработчиков для запроса
		try {
			onPrePoll.fire(context);
			if( customProcessRequest(context) )
			{	onPostProcess.fire(context);
				return true; //Запрос обработан
			}
		}
		catch( Throwable error )
		{	if( onError.fire(context, error) )
				return true; //Ошибка обработана -> запрос обработан
			else
				throw error; //Ни один обработчик не смог обработать ошибку
		}
		
		return false; //Запрос не обработан
	}
	
	///Переопределяемый пользователем метод для обработки запроса
	abstract bool customProcessRequest( HTTPContext context );
	
protected:
	Event!(ErrorHandler) _errorEvent;
	Event!(PrePollHandler) _prePollEvent;
	Event!(PreProcessHandler) _preProcessEvent;
	Event!(PostProcessHandler) _postProcessEvent;
}

class HTTPRouter: EventBasedHTTPHandler
{	
	override bool customProcessRequest( HTTPContext context )
	{	writeln("HTTPRouter test 10");
		onPrePoll.fire(context);
		//TODO: Проверить, что имеем достаточно корректный HTTP-запрос
		onPreProcess.fire(context);
		
		foreach( hdl; _handlers )
		{	writeln("HTTPRouter test 20");
			if( hdl.processRequest(context) )
				return true;
		}
		
		onPostProcess.fire(context);
		
		return false;
	}
	
	///Метод присоединения обработчика HTTP-запроса
	HTTPRouter join(IHTTPHandler handler)
	{	_handlers ~= handler;
		return this;
	}
	
	///Метод присоединения массива обработчиков HTTP-запросов к набору
	HTTPRouter join(IHTTPHandler[] handlers)
	{	_handlers ~= handlers;
		return this;
	}
	
protected:
	IHTTPHandler[] _handlers;
}


import webtank.net.http.uri_pattern;

///Маршрутизатор запросов к страницам сайта по URI
class URIPageRouter: EventBasedHTTPHandler
{	
	this( string URIPatternStr, string[string] regExprs, string[string] defaults )
	{	_uriPattern = new URIPattern(URIPatternStr, regExprs, defaults);
	}
	
	this( string URIPatternStr, string[string] defaults = null )
	{	this(URIPatternStr, null, defaults);
	}
	
	alias void delegate(HTTPContext) PageHandler;
	
	override bool customProcessRequest( HTTPContext context )
	{	auto uriData = _uriPattern.match(context.request.path);
		
		writeln("JSON_RPC_Router uriData: ", uriData);
		
		if( !uriData.isMatched )
			return false;

		onPreProcess.fire(context);
		
		//Перебор маршрутов к страницам
		foreach( ref route; _pageRoutes )
		{	auto pageURIData = route.pattern.match(context.request.path);
			
			if( pageURIData.isMatched )
			{	route.handler(context);
				return true; //Запрос обработан
			}
		}
		
		//Перебор различных обработчиков для запроса
		foreach( handler; _handlers )
		{	if( handler.processRequest(context) )
				return true; //Запрос обработан
		}
		
		return false; //Запрос не обработан этим узлом
	}
	
	URIPageRouter join(IHTTPHandler handler)
	{	_handlers ~= handler;
		return this;
	}
	
	struct PageRoute
	{	URIPattern pattern;
		PageHandler handler;
	}
	
	template join(alias Method)
	{	
		import std.functional;
		URIPageRouter join(string URIPatternStr, string[string] regExprs, string[string] defaults)
		{	auto uriPattern = new URIPattern(URIPatternStr, regExprs, defaults);
			_pageRoutes ~= PageRoute( uriPattern, toDelegate( &Method ) );
			return this;
		}
		
		URIPageRouter join(string URIPatternStr, string[string] defaults = null)
		{	return this.join!(Method)( URIPatternStr, null, defaults );
		}
	}
	
protected:
	PageRoute[] _pageRoutes;
	
	IHTTPHandler[] _handlers;
	
	URIPattern _uriPattern;
}


// class PlainPageHandler(alias Method): IHTTPHandler
// {	this(string URIPatternStr, string[string] regExprs, string[string] defaults)
// 	{	_uriPattern = new URIPattern(URIPatternStr, regExprs, defaults);
// 	}
// 	
// 	override bool processRequest( HTTPContext context )
// 	{	auto uriData = _uriPattern.match(context.request.path);
// 		
// 		if( uriData.isMatched )
// 		{	Method(context);
// 			return true;
// 		}
// 		else
// 			return false;
// 	}
// protected:
// 	URIPattern _uriPattern;
// }