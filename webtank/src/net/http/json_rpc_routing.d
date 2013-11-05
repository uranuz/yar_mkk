module webtank.net.http.json_rpc_routing;

import webtank.net.routing, webtank.net.http.routing, webtank.net.http.context, webtank.net.http.request, webtank.net.http.response;

class JSON_RPC_RouterRule: ForwardRoutingRuleTpl!(JSON_RPC_HandlingRule)
{	
public:
	this()
	{	super(".HTTP");
	}

	override {
		IRouteSegment getRouteSegment(Object context, IRouteSegment prevSegment)
		{	auto ctx = cast(HTTPContext) context;
			if( ctx is null ) //Проверяем, что правильный контекст
				return null;
			
			import std.string;
			string HTTPMethod = toLower( ctx.request.headers.get("method", null) );
			
			if( HTTPMethod != "post" )
				return null;
			
			auto jMessageBody = ctx.request.JSON_Body;
			
			if( jMessageBody.type == JSON_TYPE.OBJECT )
			{	if( jMessageBody !is null )
				{	string jsonrpc;
					if( "jsonrpc" in jMessageBody.object )
					{	if( jMessageBody.object["jsonrpc"].type == JSON_TYPE.STRING )
							jsonrpc = jMessageBody.object["jsonrpc"].str;
					}
					
					if( jsonrpc != "2.0" )
						return null;
						
					string methodName;
					if( "method" in jMessageBody.object )
					{	if( jMessageBody.object["method"].type == JSON_TYPE.STRING )
							methodName = jMessageBody.object["method"].str;
					}
					
					if( methodName.length == 0 )
						return null;
						
					return new JSON_RPC_RouterSegment
				}
				else
					return null;
			}
			else
				return null
		}
	
		void joinToThis(JSON_RPC_HandlingRule newRule)
		{	childRules[newRule.methodName] ~= newRule;
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
	JSON_RPC_HandlingRule[string] _childRules;

}


class JSON_RPC_RouterSegment: BaseRouteSegmentTpl!(JSON_RPC_RouterRule, HTTPContext, HTTPRouterSegment)
{	
	this(JSON_RPC_RouterRule routeRule, HTTPContext context, HTTPRouterSegment prevSegment)
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

class JSON_RPC_HandlingRule: EndPointRoutingRule
{	
public:
	this()
	{	super(".HTTP");
	}

	override {
		IRouteSegment getRouteSegment(Object context, IRouteSegment prevSegment)
		{	auto ctx = cast(HTTPContext) context;
			if( ctx is null ) //Проверяем, что правильный контекст
				return null;
			
			auto jMessageBody = ctx.request.JSON_Body;
			string reqMethodName = jMessageBody.object["method"].str;
			
			if( methodName == reqMethodName )
			{	jMessageBody.
				return new JSON_RPC_HandlingSegment()
				
			}
			else
				return null;
		}	
	} //override
	
	string methodName() @property
	{	
		
	}
protected:
	IRoutingRule[] _childRules;

}

class JSON_RPC_HandlingSegment: BaseRouteSegmentTpl!(JSON_RPC_HandlingRule, HTTPContext, JSON_RPC_RouterSegment)
{	
	this(JSON_RPC_RouterRule routeRule, HTTPContext context, HTTPRouterSegment prevSegment)
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