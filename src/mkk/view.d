module mkk.view;

public import mkk.common.service: Service;

shared static this() {
	import webtank.ivy.service.view: IvyViewService;

	Service(new IvyViewService("yarMKKView", "/dyn/{remainder}", /*isSecured=*/true));
}

void main(string[] progArgs)
{
	import webtank.net.server.worker: parseWorkerOptsFromCmd, WorkerOpts, runServer;

	WorkerOpts opts;
	opts.port = 8082;
	parseWorkerOptsFromCmd(progArgs, opts);
	opts.threadCount = 1;
	opts.service = Service();
	runServer(opts);
}
