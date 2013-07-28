module test_threaded_app;

import std.stdio;

import webtank.net.application;

static this()
{	Application.setHandler(&netMain, "/dynamic/vasya");
	
}

Application netApp;

void netMain(Application netApp)
{	test_threaded_app.netApp = netApp;
	writeln(netApp.request.headers["user-agent"]);
	writeln(netApp.request.messageBody);
	netApp.response ~= "Вася!";
	writeln("Привети4ек!");
}
