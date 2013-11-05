module webtank.routing_test;

import webtank.net.http.routing, webtank.net.http.context;

shared static this()
{	joinRoutingRule(new URIRouterRule);
	joinRoutingRule(new URIHandlingRule);
}

void func(HTTPContext)
{	
	
}

void main()
{	
	auto ctx = new HTTPContext;
	processServerRequest(ctx);
}
