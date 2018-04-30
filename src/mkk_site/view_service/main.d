module mkk_site.view_service.main;

import webtank.net.server.worker: parseWorkerOptsFromCmd, WorkerOpts, runServer;
import mkk_site.view_service.service;

// Подключение разделов сервиса
import mkk_site.view_service.index;
import mkk_site.view_service.moder;
import mkk_site.view_service.auth;
import mkk_site.view_service.pohod_list;
import mkk_site.view_service.pohod_read;
import mkk_site.view_service.pohod_edit;
import mkk_site.view_service.document_list;
import mkk_site.view_service.document_edit;
import mkk_site.view_service.tourist_list;
import mkk_site.view_service.tourist_edit;
import mkk_site.view_service.experience;
import mkk_site.view_service.user_settings;
import mkk_site.view_service.stat;
import mkk_site.view_service.record_history;
import mkk_site.view_service.csv;

void main(string[] progArgs)
{
	WorkerOpts opts;
	opts.port = 8082;
	parseWorkerOptsFromCmd(progArgs, opts);
	opts.service = Service;
	runServer(opts);
}
