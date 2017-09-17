///Комплект модулей для разработки страниц сайта.
///Импортирует основные модули, которые могут быть полезны для созданиия страниц сайта
module mkk_site.main_service.devkit;

//Импортируем модули библиотеки
public import
	webtank.common.conv,
	webtank.common.optional,
	webtank.common.optional_date,
	webtank.datctrl.iface.data_field,
	webtank.datctrl.enum_format,
	webtank.datctrl.record_format,
	webtank.datctrl.iface.record,
	webtank.datctrl.iface.record_set,
	webtank.datctrl.cursor_record,
	webtank.datctrl.record_set,
	webtank.datctrl.typed_record,
	webtank.datctrl.typed_record_set,
	webtank.db.database,
	webtank.db.datctrl_joint,
	webtank.net.http.context,
	webtank.net.http.json_rpc_handler,
	webtank.net.http.handler,
	webtank.net.utils,
	webtank.net.uri;

//Импорт модулей сайта
public import
	mkk_site.main_service.service,
	mkk_site.utils;