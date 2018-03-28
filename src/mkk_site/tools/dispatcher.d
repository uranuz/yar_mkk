module mkk_site.tools.dispatcher;

import webtank.net.server.dispatcher: startDispatchProcess;

void main(string[] progArgs)
{
	import std.getopt: getopt;
	string workerPath;
	ushort port = 8082;
	string workerSockAddr;
	getopt(progArgs,
		"port", &port,
		"workerPath", &workerPath,
		"workerSockAddr", &workerSockAddr);
	startDispatchProcess(port, workerPath, workerSockAddr);
}