module webtank.net.http.json_rpc_routing;

import std.stdio, std.json;

import webtank.net.routing, webtank.net.http.routing, webtank.net.http.context, webtank.net.http.request, webtank.net.http.response, webtank.net.json_rpc;

shared static this()
{	joinRoutingRule(new JSON_RPC_RouterRule);
	
}

class JSON_RPC_RouterRule: HTTPForwardRoutingRule!(JSON_RPC_HandlingRuleBase)
{	
public:
	this()
	{	super(".HTTP.JSON_RPC");
	}

	override {
		RoutingStatus doHTTPRouting(HTTPContext context)
		{	writeln("Move along ", routeName, " rule");

			import std.string;
			string HTTPMethod = toLower( context.request.headers.get("method", null) );
			
			if( HTTPMethod != "post" )
				return RoutingStatus.continued;
			
			auto jMessageBody = context.request.JSON_Body;
			
			writeln( "Received JSON_Body: ", toJSON( &jMessageBody ), " of type ", jMessageBody.type );
			
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
				{
					return hdlRule.doRouting(context);
					writeln( "JSON_RPC_RouterRule.doRouting: response.getString(): ", context.response.getString() );
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
	this(string methodName)
	{	super(".HTTP.JSON_RPC.");
		_methodName = methodName;
	}

	string methodName() @property
	{	return _methodName; }

protected:
	string _methodName;
}

class JSON_RPC_HandlingRule(alias JSON_RPC_Method): JSON_RPC_HandlingRuleBase
{	
public:
	this(string methodName)
	{	super(methodName);
	}

	override RoutingStatus doHTTPRouting(HTTPContext context)
	{	writeln("Move along ", routeName, " rule");
		
		auto jMessageBody = context.request.JSON_Body;
		string reqMethodName = jMessageBody.object["method"].str;
		
		if( this.methodName != reqMethodName ) //Доп. проверка не повредит
			return RoutingStatus.continued;
		
		auto jParams = jMessageBody.object["params"];
		
// 		writeln("Received jParams: ", toJSON(&jParams));
		
		auto jResult = callJSON_RPC_Method!(JSON_RPC_Method)(jParams);
// 		writeln("JSON-RPC method calling finished!!!");
// 		writeln("Returned jResult: ", toJSON(&jResult));
		context.response ~= toJSON(&jResult).idup;
//  		writeln("response.getString() returned: ", context.response.getString());
		
		return RoutingStatus.succeed;
	}
	
}