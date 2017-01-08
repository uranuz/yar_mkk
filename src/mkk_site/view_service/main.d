module mkk_site.view_service.main;

import webtank.net.web_server: WebServer2;
import webtank.net.http.handler;
import webtank.net.http.context;
import webtank.common.logger;

import mkk_site.view_service.uri_page_router;

import ivy, ivy.compiler, ivy.interpreter, ivy.common, ivy.lexer, ivy.parser;

enum bool useTemplatesCache = false;
static immutable relTemplatesPath = "res/ivy_templates/";

__gshared HTTPRouter Router;
__gshared MKK_ViewService_URIPageRouter PageRouter;
__gshared Logger ServiceLogger;
__gshared ProgrammeCache!(useTemplatesCache) TemplateCache;

shared static this()
{
	import std.path: getcwd, buildNormalizedPath;
	string logFileName = "/home/uranuz/sites/mkk_site/logs/view_service.log";
	string[] templatesPaths = [ buildNormalizedPath(getcwd(), relTemplatesPath) ];

	Router = new HTTPRouter;
	PageRouter = new MKK_ViewService_URIPageRouter( "/dyn/{remainder}" );
	ServiceLogger = new ThreadedLogger( cast(shared) new FileLogger(logFileName, LogLevel.info) );

	PageRouter.join!(renderFunction)("/dyn/index");

	Router.join(PageRouter);

	TemplateCache = new ProgrammeCache!(useTemplatesCache)(templatesPaths);
}

import webtank.net.http.client;

string makeMethodQuery()
{
	import std.conv: to;
	import std.socket;
	string domain = "localhost";
	ushort port = 8082;

	Socket sock = new TcpSocket(new InternetAddress(domain, port));
	scope(exit) sock.close();
	string requestPayload = `{"jsonrpc": "2.0", "method": "mkk_site.show_pohod.participantsList", "params": {"pohodNum": 20}, "id": 1}`;
	string requestHeaders = "POST /dyn/jsonrpc/ HTTP/1.0\r\nContent-Length: " ~ requestPayload.length.to!string ~ "\r\n\r\n";
	string requestData = requestHeaders ~ requestPayload;
	sock.send(requestData);

	ClientResponse response = receiveHTTPResponse(sock);

	return response.messageBody;
}


string renderFunction(HTTPContext ctx)
{
	import std.path: getcwd, buildNormalizedPath;
	auto prog = TemplateCache.getProgramme( buildNormalizedPath(getcwd(), relTemplatesPath, "main_template.html") );
	TDataNode[string] dataDict;
	dataDict["site_title"] = "Маршрутно-квалификационная комиссия Ярославской области";
	dataDict["hello_sentence"] = "Привет, пользователь!";

	string queryResult = makeMethodQuery();

	dataDict["query_result"] = queryResult;

	auto renderResult = prog.run( TDataNode(dataDict) );
	return renderResult.str;
}

void main(string[] progAgs)
{
	import std.getopt: getopt;

	//Основной поток - поток управления потоками
	ushort port = 8083;
	//Получаем порт из параметров командной строки
	getopt( progAgs, "port", &port );

	auto server = new WebServer2(port, Router, ServiceLogger, 5);
	server.start();
}
