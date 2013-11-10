module webtank.routing_test;

import webtank.net.http.routing, webtank.net.http.context, webtank.net.http.json_rpc_routing, webtank.net.web_server;

import std.stdio;

shared static this()
{	joinRoutingRule(new JSON_RPC_HandlingRule!(rpcFunc)("rpcFunc"));
}

string rpcFunc(string[string] assocList)
{	
	writeln("Hello, router!!!");
	return "Your kesha is " ~ assocList.get("kesha", null);
	
}

// void main()
// {	
// 	buildRoutingTree();
// 	
// 	auto ctx = new HTTPContext;
// 	processServerRequest(ctx);
// }
