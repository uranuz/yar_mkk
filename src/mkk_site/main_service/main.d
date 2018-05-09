module mkk_site.main_service.main;

import webtank.net.server.worker: parseWorkerOptsFromCmd, WorkerOpts, runServer;
import mkk_site.common.service: Service;

// Подключение разделов сервиса
import mkk_site.main_service.auth;
import mkk_site.main_service.moder;
import mkk_site.main_service.pohod_list;
import mkk_site.main_service.pohod_read;
import mkk_site.main_service.pohod_filters;
import mkk_site.main_service.pohod_edit;
import mkk_site.main_service.document_list;
import mkk_site.main_service.document_edit;
import mkk_site.main_service.tourist_list;
import mkk_site.main_service.tourist_edit;
import mkk_site.main_service.experience;
import mkk_site.main_service.user_settings;
import mkk_site.main_service.stat;
import mkk_site.main_service.init_history_data;
import mkk_site.main_service.right_object_list;

void main(string[] progArgs)
{
	WorkerOpts opts;
	opts.port = 8083;
	parseWorkerOptsFromCmd(progArgs, opts);
	opts.service = Service();
	runServer(opts);
}
