module webtank.routing_test;

import webtank.net.routing, webtank.net.http.routing, webtank.net.http.context, webtank.net.http.json_rpc_routing, webtank.net.web_server, webtank.net.access_control;

import mkk_site.authentication, mkk_site.site_data;

import std.stdio;

shared static this()
{	
	auto ticketManager = new MKK_SiteAccessTicketManager(authDBConnStr);
	Router
		.join( new HTTPRouterRule(ticketManager) )
		.join( new URIRouterRule )
		.join( new JSON_RPC_RouterRule )
		.join( new JSON_RPC_HandlingRule!(rpcFunc) );
}

string rpcFunc(HTTPContext context, string[string] assocList, int shit)
{	
	writeln("Hello, router!!!");
	return "Your kesha is " ~ assocList.get("kesha", null);
	
}