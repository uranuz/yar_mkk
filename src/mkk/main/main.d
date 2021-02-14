module mkk.main.main;

import mkk.common.service: Service;

// Подключение разделов сервиса
import mkk.main.document.edit;
import mkk.main.document.list;
import mkk.main.document.read;

import mkk.main.pohod.list;
import mkk.main.pohod.read;
import mkk.main.pohod.filters;
import mkk.main.pohod.edit;
import mkk.main.pohod.stat;

import mkk.main.right.object.list;

import mkk.main.tourist.read;
import mkk.main.tourist.experience;
import mkk.main.tourist.list;
import mkk.main.tourist.edit;

import mkk.main.user.auth;
import mkk.main.user.moder;
import mkk.main.user.settings;
import mkk.main.user.registration;
import mkk.main.user.list;

import mkk.main.init_history_data;

void main(string[] progArgs)
{
	import webtank.net.server.worker: parseWorkerOptsFromCmd, WorkerOpts, runServer;

	WorkerOpts opts;
	opts.port = 8083;
	parseWorkerOptsFromCmd(progArgs, opts);
	opts.service = Service();
	runServer(opts);
}
