module mkk_site.logging;

import webtank.common.logger;

import mkk_site.site_data;
import mkk_site.logging_init;

///Основной объект для ведения журнала сайта
__gshared Logger SiteLogger;

///Объект для приоритетных записей журнала сайта
__gshared Logger PrioriteLogger;