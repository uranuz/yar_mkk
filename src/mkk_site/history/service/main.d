module mkk_site.history.service.main;

import webtank.net.server.worker: parseWorkerOptsFromCmd, WorkerOpts, runServer;
import mkk_site.common.service: Service;

// Подключение разделов сервиса
import mkk_site.history.service.writer;

void main(string[] progArgs)
{
	WorkerOpts opts;
	opts.port = 8084;
	parseWorkerOptsFromCmd(progArgs, opts);
	opts.handler = Service.rootRouter;
	opts.loger = Service.loger;
	runServer(opts);
}
