module webtank.net.http.routing;

public import webtank.net.routing;

import std.stdio;

import webtank.net.http.context, webtank.net.connection, webtank.net.access_control;

class HTTPForwardRoutingRule(ChildRuleT): ForwardRoutingRule!(ChildRuleT)
{	
public:
	this(string thisRouteName) 
	{	super(thisRouteName); }

	override RoutingStatus doRouting(IConnectionContext context)
	{	auto ctx = cast(HTTPContext) context;
		
		if( ctx is null )
			return RoutingStatus.continued;
		
		//Проверяем инициализированы ли запрос и ответ,
		//чтобы не было болезненных сегфолтов в процессе работы
		if( ctx.request is null || ctx.response is null )
			return RoutingStatus.continued;
		
		auto status = doHTTPRouting(ctx); //Заменяем вызов общей функции на частную
		
		return status;
	}
	
	abstract RoutingStatus doHTTPRouting(HTTPContext context);
}

class HTTPEndPointRoutingRule: EndPointRoutingRule
{	
public:
	this(string thisRouteName) 
	{	super(thisRouteName); }

	override RoutingStatus doRouting(IConnectionContext context)
	{	auto ctx = cast(HTTPContext) context;
		
		if( ctx is null )
			return RoutingStatus.continued;
		
		//Проверяем инициализированы ли запрос и ответ,
		//чтобы не было болезненных сегфолтов в процессе работы
		if( ctx.request is null || ctx.response is null )
			return RoutingStatus.continued;
		
		auto status = doHTTPRouting(ctx); //Заменяем вызов общей функции на частную

		return status;
	}
	
	abstract RoutingStatus doHTTPRouting(HTTPContext context);
}

//Маршрутизатор HTTP-запросов к серверу
class HTTPRouterRule: HTTPForwardRoutingRule!(IRoutingRule)
{	
public:
	this(IAccessTicketManager ticketManager)
	{	super(".HTTP");
		_ticketManager = ticketManager;
	}

	override {
		RoutingStatus doHTTPRouting(HTTPContext context)
		{	
			context._setAccessTicket( _ticketManager.getTicket(context) );
			
			foreach( childRule; _childRules)
			{	auto status = childRule.doRouting(context);
				if( status != RoutingStatus.continued )
				{	return status;
				}
			}
			
			return RoutingStatus.continued;
		}
	
		void joinToThis(IRoutingRule newRule)
		{	_childRules ~= newRule;
		}
		
		int opApply(int delegate(IRoutingRule) dg)
		{	int result = 0;
		
			for (int i = 0; i < _childRules.length; i++)
			{	result = dg(_childRules[i]);
				if (result)
				break;
			}
			return result;
		}

	
	} //override
	
protected:
	IRoutingRule[] _childRules;
	IAccessTicketManager _ticketManager;
}
	
//Маршрутизатор URI - запросов к приложению
class URIRouterRule: HTTPForwardRoutingRule!(URIHandlingRule)
{	this()
	{	super(".HTTP.URI");
	}
		
	override {
		RoutingStatus doHTTPRouting(HTTPContext context)
		{
			auto URIHandler = _childRules
				.get( _normalizePagePath(context.request.path), null );
			
			if( URIHandler )
			{	try {
					return URIHandler.doRouting(context);
				}
				catch( Exception exc )
				{	
					
				}
				
			}
			else
				return RoutingStatus.continued;
		}
		
		void joinToThis(URIHandlingRule newRule)
		{	_childRules[newRule.URI] = newRule;
		}
		
		int opApply(int delegate(IRoutingRule) dg)
		{	int result = 0;
		
			foreach ( rule; _childRules)
			{	result = dg(rule);
				if (result)
					break;
			}
			return result;
		}
		
	} //override
	
protected:
	URIHandlingRule[string] _childRules;
}

alias void function(HTTPContext) URIHandlerFuncType;

class URIHandlingRule: HTTPEndPointRoutingRule
{	
	this(string URI, URIHandlerFuncType handler)
	{	super(".HTTP.URI.");
		_URI = _normalizePagePath(URI);
		_handler = handler;
	}
	
	override {
		RoutingStatus doHTTPRouting(HTTPContext context)
		{	
			_handler(context); //Вызов пользовательского обработчика
			return RoutingStatus.succeed;
		}
	} //override
	
	string URI() @property
	{	return _URI; }
	
protected:
	string _URI;
	URIHandlerFuncType _handler;
}

class URIErrorHandlingRule: HTTPEndPointRoutingRule
{	
	this(string URI, URIHandlerFuncType handler)
	{	super(".HTTP.URI.");
		_URI = _normalizePagePath(URI);
		_handler = handler;
	}
	
	override {
		RoutingStatus doHTTPRouting(HTTPContext context)
		{	
			_handler(context); //Вызов пользовательского обработчика
			return RoutingStatus.succeed;
		}
	} //override
	
	string URI() @property
	{	return _URI; }
	
protected:
	string _URI;
	URIHandlerFuncType _handler;
}


static string _normalizePagePath(string path, bool ignoreEndSlash = true)
{	import std.string;
	import std.path;
	string clearPath = buildNormalizedPath( strip( path ) );
	version(Windows) {
		if ( ignoreEndSlash && clearPath[$-1] == '\\' ) 
			return clearPath[0..$-1];
	}
	version(Posix) {
		if ( ignoreEndSlash && clearPath[$-1] == '/')
			return clearPath[0..$-1];
	}
	return clearPath;
}