module webtank.net.http.routing;

import std.stdio;
import webtank.net.routing, webtank.net.http.context;

private {
	__gshared HTTPRouterRule _rootRule;
	__gshared IRoutingRule[] _routingRules;
}

//Метод добавления правила маршрутизации в систему
///Правила добавлять в shared static this конструкторе модуля!!!
void joinRoutingRule(IRoutingRule newRule)
{	_routingRules ~= newRule;
}
	
void processServerRequest(Object context)
{	if( _rootRule is null )
		buildRoutingTree();
		
	auto status = _rootRule.doRouting(context);
}

//Функция построения дерева маршрутизации
///Запускать один раз после добавления всех правил
void buildRoutingTree()
{	if( _rootRule is null )
	{	_rootRule = new HTTPRouterRule;
	
		import std.algorithm;
		sort!(`count(a.routeName, "` ~ routeNamePartsDelim 
			~ `") < count(b.routeName, "` ~ routeNamePartsDelim ~ `")`)(_routingRules);

		foreach( rule; _routingRules)
			_rootRule.joinRule(rule);
			
		writeln( _rootRule.toString() );
	}
}

shared static this()
{	joinRoutingRule(new URIRouterRule);
	
}

class HTTPForwardRoutingRule(ChildRuleT): ForwardRoutingRule!(ChildRuleT)
{	
public:
	this(string thisRouteName) 
	{	super(thisRouteName); }

	override RoutingStatus doRouting(Object context)
	{	auto ctx = cast(HTTPContext) context;
	
		if( ctx is null )
			return RoutingStatus.continued;
		
		//Проверяем инициализированы ли запрос и ответ,
		//чтобы не было болезненных сегфолтов в процессе работы
		if( ctx.request is null || ctx.response is null )
			return RoutingStatus.continued;
		
		auto status = doHTTPRouting(ctx); //Заменяем вызов общей функции на частную
		
		writeln( "HTTPForwardRoutingRule.doRouting: response.getString(): ", ctx.response.getString() );
		
		return status;
	}
	
	abstract RoutingStatus doHTTPRouting(HTTPContext context);
}

class HTTPEndPointRoutingRule: EndPointRoutingRule
{	
public:
	this(string thisRouteName) 
	{	super(thisRouteName); }

	override RoutingStatus doRouting(Object context)
	{	auto ctx = cast(HTTPContext) context;

		if( ctx is null )
			return RoutingStatus.continued;
		
		//Проверяем инициализированы ли запрос и ответ,
		//чтобы не было болезненных сегфолтов в процессе работы
		if( ctx.request is null || ctx.response is null )
			return RoutingStatus.continued;
		
		auto status = doHTTPRouting(ctx); //Заменяем вызов общей функции на частную
		
		writeln( "HTTPEndPointRoutingRule.doRouting: response.getString(): ", ctx.response.getString() );
		
		return status;
	}
	
	abstract RoutingStatus doHTTPRouting(HTTPContext context);
}

//Маршрутизатор HTTP-запросов к серверу
class HTTPRouterRule: HTTPForwardRoutingRule!(IRoutingRule)
{	
public:
	this()
	{	super(".HTTP");
	}

	override {
		RoutingStatus doHTTPRouting(HTTPContext context)
		{	writeln("Move along ", routeName, " rule");
			
			foreach( childRule; _childRules)
			{	auto status = childRule.doRouting(context);
				if( status != RoutingStatus.continued )
				{	
// 					writeln( "HTTPRouterRule.doRouting: response.getString(): ", context.response.getString() );
					return status;
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
}
	
//Маршрутизатор URI - запросов к приложению
class URIRouterRule: HTTPForwardRoutingRule!(URIHandlingRule)
{	this()
	{	super(".HTTP.URI");
	}
		
	override {
		RoutingStatus doHTTPRouting(HTTPContext context)
		{	writeln("Move along ", routeName, " rule");
			
			auto URIHandler = _childRules
				.get( _normalizePagePath(context.request.path), null );
			
			if( URIHandler )
				return URIHandler.doRouting(context);
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
		{	writeln("Move along ", routeName, " rule");
				
			_handler(context); //Вызов пользовательского обработчика
			writeln("Handler for URI: \"" ~ URI ~ "\" executed!!!");
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