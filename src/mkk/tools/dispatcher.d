module mkk.tools.dispatcher;

import webtank.net.server.dispatcher: startDispatchProcess;

void main(string[] progArgs)
{
	import std.getopt: getopt;
	string workerPath;
	ushort port = 0; // Invalid port
	string workerSockAddr;
	getopt(progArgs,
		"port", &port,
		"workerPath", &workerPath,
		"workerSockAddr", &workerSockAddr);
	startDispatchProcess(port, workerPath, workerSockAddr);
}