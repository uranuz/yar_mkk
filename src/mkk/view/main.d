module mkk.view.main;

import webtank.net.server.worker: parseWorkerOptsFromCmd, WorkerOpts, runServer;
import mkk.view.service;

// Подключение разделов сервиса
import mkk.view.auth;

void main(string[] progArgs)
{
	WorkerOpts opts;
	opts.port = 8082;
	parseWorkerOptsFromCmd(progArgs, opts);
	opts.service = Service();
	runServer(opts);
}
