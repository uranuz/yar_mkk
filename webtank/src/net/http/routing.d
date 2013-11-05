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
		
	auto routeSeg = _rootRule.getRouteSegment(context, null);
	if( routeSeg )
		routeSeg.moveAlongRoute();
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
	}
}

//Участок маршрута HTTP-роутера
class HTTPRouterSegment: BaseRouteSegmentTpl!(HTTPRouterRule, HTTPContext, IRouteSegment)
{	
public:
	this(HTTPRouterRule routeRule, HTTPContext context, IRouteSegment prevSegment)
	{	super(routeRule, context, prevSegment);
	}
	
	override void moveAlongRoute()
	{	writeln("Move along ", _routingRule.routeName, " rule");
		foreach( rule; _routingRule )
		{	auto currentSegment = rule.getRouteSegment(_context, _parentSegment);
			if( currentSegment )
			{	currentSegment.moveAlongRoute();
				break;
			}
		}
	}
}

//Маршрутизатор HTTP-запросов к серверу
class HTTPRouterRule: ForwardRoutingRuleTpl!(IRoutingRule)
{	
public:
	this()
	{	super(".HTTP");
	}

	override {
		IRouteSegment getRouteSegment(Object context, IRouteSegment prevSegment)
		{	auto ctx = cast(HTTPContext) context;
			if( ctx is null )
				return null;
			else
			{	return new HTTPRouterSegment(this, ctx, prevSegment);
			}
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


class URIRouterSegment: BaseRouteSegmentTpl!(URIRouterRule, HTTPContext, HTTPRouterSegment)
{	
	this(URIRouterRule routeRule, HTTPContext context, HTTPRouterSegment prevSegment)
	{	super(routeRule, context, prevSegment);
	}
	
	override void moveAlongRoute()
	{	writeln("Move along ", _routingRule.routeName, " rule");
		foreach( rule; _routingRule )
		{	auto currentSegment = rule.getRouteSegment(_context, _parentSegment);
			if( currentSegment )
			{	currentSegment.moveAlongRoute();
				break;
			}
		}
	}
}
	
//Маршрутизатор URI - запросов к приложению
class URIRouterRule: ForwardRoutingRuleTpl!(URIHandlingRule)
{	this()
	{	super(".HTTP.URI");
	}
	
	override {
		IRouteSegment getRouteSegment(Object context, IRouteSegment prevSegment)
		{	auto ctx = cast(HTTPContext) context;
			auto parentSeg = cast(HTTPRouterSegment) prevSegment;
			if( ctx is null )
				return null;
			else
			{	return new URIRouterSegment(this, ctx, parentSeg);
			}
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

class URIHandlingSegment: BaseRouteSegmentTpl!(URIHandlingRule, HTTPContext, URIRouterSegment)
{	this(URIHandlingRule routeRule, HTTPContext context, URIRouterSegment prevSegment)
	{	super(routeRule, context, prevSegment);
	}
	
	override void moveAlongRoute()
	{	writeln("Move along ", _routingRule.routeName, " rule");
		
	}
	
}

alias void function(HTTPContext) URIHandlerFuncType;

class URIHandlingRule: EndPointRoutingRule
{	
	this()
	{	super(".HTTP.URI.");
	}
	
	override {
		IRouteSegment getRouteSegment(Object context, IRouteSegment prevSegment)
		{	auto ctx = cast(HTTPContext) context;
			auto parentSeg = cast(URIRouterSegment) prevSegment;
			
			if( ctx is null )
				return null;
			
			
			return new URIHandlingSegment(this, ctx, parentSeg);
		}
	} //override
	
	string URI() @property
	{	return "vasya";
		
	}
	
	
	
protected:
	
}
