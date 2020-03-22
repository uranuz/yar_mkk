module mkk.history;

import webtank.net.server.worker: parseWorkerOptsFromCmd, WorkerOpts, runServer;
import mkk.common.service: Service;

// Подключение разделов сервиса
import mkk.history;

import webtank.history.service.service: HistoryService;

shared static this() {
	Service(new HistoryService("yarMKKHistory"));
}

void main(string[] progArgs)
{
	WorkerOpts opts;
	opts.port = 8084;
	parseWorkerOptsFromCmd(progArgs, opts);
	opts.service = Service();
	runServer(opts);
}
