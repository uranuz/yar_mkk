module webtank.test.xhr_test;

import std.conv, std.string, std.file, std.stdio;

import webtank.net.http.router, webtank.net.http.request, webtank.net.http.response;

immutable asyncHandlersPath = "/dyn/handlers/";
immutable thisPagePath = asyncHandlersPath ~ "xhr_test";

static this()
{	Router.registerRequestHandler(thisPagePath, &netMain);
	Router.registerRPCMethod("Тестирование.Выполнить", &testMethod);
}

void netMain(ServerRequest rq, ServerResponse rp)  //Определение главной функции приложения
{	auto pVars = rq.postVars;
	auto qVars = rq.queryVars;
	writeln("Трололо!");
	rp ~= "Доброго времени суток вам, г-н " ~ pVars.get("name", "");
}

static void testMethod(string arg)
{	writeln("ЗАРАБОТАЛО!!!" ~ arg);
	
}