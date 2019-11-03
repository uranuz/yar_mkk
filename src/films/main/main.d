module films.main.main;

import webtank.net.server.worker: parseWorkerOptsFromCmd, WorkerOpts, runServer;
import mkk.common.service: Service;

void main(string[] progArgs)
{
	WorkerOpts opts;
	opts.port = 8085;
	parseWorkerOptsFromCmd(progArgs, opts);
	opts.service = Service();
	runServer(opts);
}
