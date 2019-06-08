module mkk.history.service.main;

import webtank.net.server.worker: parseWorkerOptsFromCmd, WorkerOpts, runServer;
import mkk.common.service: Service;

// Подключение разделов сервиса
import mkk.history.service.writer;

void main(string[] progArgs)
{
	WorkerOpts opts;
	opts.port = 8084;
	parseWorkerOptsFromCmd(progArgs, opts);
	opts.service = Service();
	runServer(opts);
}
