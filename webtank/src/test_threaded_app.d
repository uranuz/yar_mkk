module test_threaded_app;

import std.stdio;

import webtank.net.application, webtank.net.connection_handler;

static this()
{	HTTPConnectionHandler.setHandler(&netMain, "/dynamic/vasya");
	
}

Application netApp;

void netMain(Application netApp)
{	test_threaded_app.netApp = netApp;
	writeln(netApp.request.headers["user-agent"]);
	netApp.response ~= "Вася!";
	writeln("Привети4ек!");
}
