module mkk_site.main_service.main;

import webtank.net.server.worker: parseWorkerOptsFromCmd, WorkerOpts, runServer;
import mkk_site.common.service: Service;

// Подключение разделов сервиса
import mkk_site.main_service.document.edit;
import mkk_site.main_service.document.list;
import mkk_site.main_service.document.read;

import mkk_site.main_service.pohod.list;
import mkk_site.main_service.pohod.read;
import mkk_site.main_service.pohod.filters;
import mkk_site.main_service.pohod.edit;
import mkk_site.main_service.pohod.stat;

import mkk_site.main_service.right.object_list;

import mkk_site.main_service.tourist.read;
import mkk_site.main_service.tourist.experience;
import mkk_site.main_service.tourist.list;
import mkk_site.main_service.tourist.edit;

import mkk_site.main_service.user.auth;
import mkk_site.main_service.user.moder;
import mkk_site.main_service.user.settings;
import mkk_site.main_service.user.registration;
import mkk_site.main_service.user.list;

import mkk_site.main_service.init_history_data;



void main(string[] progArgs)
{
	WorkerOpts opts;
	opts.port = 8083;
	parseWorkerOptsFromCmd(progArgs, opts);
	opts.service = Service();
	runServer(opts);
}
