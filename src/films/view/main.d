module films.view.main;

import webtank.net.server.worker: parseWorkerOptsFromCmd, WorkerOpts, runServer;
import films.view.service;

void main(string[] progArgs)
{
	WorkerOpts opts;
	opts.port = 8086;
	parseWorkerOptsFromCmd(progArgs, opts);
	opts.service = Service();
	runServer(opts);
}
