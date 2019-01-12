module mkk_site.view_service.main;

import webtank.net.server.worker: parseWorkerOptsFromCmd, WorkerOpts, runServer;
import mkk_site.view_service.service;

// Подключение разделов сервиса
import mkk_site.view_service.auth;
import mkk_site.view_service.record_history;

void main(string[] progArgs)
{
	WorkerOpts opts;
	opts.port = 8082;
	parseWorkerOptsFromCmd(progArgs, opts);
	opts.service = Service();
	runServer(opts);
}
