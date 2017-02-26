module mkk_site.logging;

import webtank.common.loger;

import mkk_site.site_data_old;
import mkk_site.logging_init;

///Основной объект для ведения журнала сайта
__gshared Loger SiteLoger;

///Объект для приоритетных записей журнала сайта
__gshared Loger PrioriteLoger;