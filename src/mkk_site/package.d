module mkk_site;

public import mkk_site.site_main, mkk_site.site_data, mkk_site.utils;

//Главное меню
import mkk_site.index; //Главная страница сайта
import mkk_site.show_tourist; //Список туристов
import mkk_site.show_pohod; //Список походов
import mkk_site.show_moder; //Список модераторов
import mkk_site.stati; //Статьи и документы

static if( isMKKSiteDevelTarget )
	import mkk_site.stat; //Статистика сайта

// //Остальные разделы
import mkk_site.auth; //Аутентификация пользователей
import mkk_site.edit_tourist; //Редактирование туристов
import mkk_site.edit_pohod; //Редактирование походов
import mkk_site.show_pohod_for_tourist; //Список походов, в которых участвовал турист
import mkk_site.pohod; //Карточка похода
import mkk_site.inform; //Цели и задачи сайта
import mkk_site.template_service; //Сервис получения HTML шаблонов