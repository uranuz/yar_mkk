module webtank.net.http.json_rpc_routing;

import std.json, std.traits, std.string;

import webtank.net.routing, webtank.net.http.routing, webtank.net.http.context, webtank.net.http.request, webtank.net.http.response, webtank.net.json_rpc;

class JSON_RPC_RouterRule: HTTPForwardRoutingRule!(JSON_RPC_HandlingRuleBase)
{	
public:
	this()
	{	super(".HTTP.JSON_RPC");
	}

	override {
		RoutingStatus doHTTPRouting(HTTPContext context)
		{	string HTTPMethod = toLower( context.request.headers.get("method", null) );
			
			if( HTTPMethod != "post" )
				return RoutingStatus.continued;
			
			auto jMessageBody = context.request.JSON_Body;
			
			if( jMessageBody.type == JSON_TYPE.OBJECT )
			{	string jsonrpc;
				if( "jsonrpc" in jMessageBody.object )
				{	if( jMessageBody.object["jsonrpc"].type == JSON_TYPE.STRING )
						jsonrpc = jMessageBody.object["jsonrpc"].str;
				}
				
				if( jsonrpc != "2.0" )
					return RoutingStatus.continued;
					
				string methodName;
				if( "method" in jMessageBody.object )
				{	if( jMessageBody.object["method"].type == JSON_TYPE.STRING )
						methodName = jMessageBody.object["method"].str;
				}
				
				if( methodName.length == 0 )
					return RoutingStatus.continued;
				
				//Запрос должен иметь элемент params, даже если параметров
				//не передаётся. В последнем случае должно передаваться
				//либо null в качестве параметра, либо пустой объект {}
				if( "params" in jMessageBody.object )
				{	auto paramsType = jMessageBody.object["params"].type;
				
					//В текущей реализации принимаем либо объект (список поименованных параметров)
					//либо null, символизирующий их отсутствие
					if( paramsType != JSON_TYPE.OBJECT && paramsType != JSON_TYPE.NULL )
						return RoutingStatus.continued;
				}
				else
					return RoutingStatus.continued;
					
				auto hdlRule = _childRules.get(methodName, null);
				if( hdlRule )
				{	return hdlRule.doRouting(context);
				}
				else
					return RoutingStatus.continued;
			}
			else
				return RoutingStatus.continued;
			assert(0);
		}
	
		void joinToThis(JSON_RPC_HandlingRuleBase newRule)
		{	_childRules[newRule.methodName] = newRule;
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
	JSON_RPC_HandlingRuleBase[string] _childRules;

}

class JSON_RPC_HandlingRuleBase: HTTPEndPointRoutingRule
{	
public:
	this()
	{	super(".HTTP.JSON_RPC."); }

	abstract string methodName() @property;
}

class JSON_RPC_HandlingRule(alias JSON_RPC_Method): JSON_RPC_HandlingRuleBase
{	
public:

	override RoutingStatus doHTTPRouting(HTTPContext context)
	{	
		auto jMessageBody = context.request.JSON_Body;
		string reqMethodName = jMessageBody.object["method"].str;
		
		if( this.methodName != reqMethodName ) //Доп. проверка не повредит
			return RoutingStatus.continued;
		
		auto jParams = jMessageBody.object["params"];
		auto jResult = callJSON_RPC_Method!(JSON_RPC_Method)(jParams, context);
		context.response ~= toJSON(&jResult).idup;
		
		return RoutingStatus.succeed;
	}
	
	override string methodName() @property
	{	return fullyQualifiedName!(JSON_RPC_Method);
	}
	
}