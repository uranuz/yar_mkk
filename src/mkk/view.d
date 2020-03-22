module mkk.view;

import webtank.net.server.worker: parseWorkerOptsFromCmd, WorkerOpts, runServer;
import webtank.ivy.view_service: IvyViewService;

public import mkk.common.service: Service;

shared static this() {
	Service(new IvyViewService("yarMKKView", "/dyn/{remainder}", /*isSecured=*/true));
}

void main(string[] progArgs)
{
	WorkerOpts opts;
	opts.port = 8082;
	parseWorkerOptsFromCmd(progArgs, opts);
	opts.threadCount = 1;
	opts.service = Service();
	runServer(opts);
}
