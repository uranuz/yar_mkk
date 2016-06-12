module mkk_site.templating;

import std.conv, std.json;

import
	webtank.net.http.context,
	webtank.net.utils,
	webtank.templating.plain_templater,
	webtank.ui.templating;

import 
	mkk_site.site_data,
	mkk_site.routing;

import mkk_site.templating_init;

enum withTemplateCache = !isMKKSiteDevelTarget;

__gshared PlainTemplateCache!(withTemplateCache) templateCache;

// Функция отрисовки списка фильтров походов в боковом меню сайта
// на основе данных из pohodFiltersJSON.
string renderPohodFilterMenuSections()
{
	if( pohodFiltersJSON.type != JSON_TYPE.ARRAY )
		return null;

	string sectionsHTML;

	auto sectionTpl = getPageTemplate( pageTemplatesDir ~ "pohod_filter_menu_section.html" );
	auto itemTpl = getPageTemplate( pageTemplatesDir ~ "pohod_filter_menu_item.html" );

	// Проход по секциям фильтров походов
	foreach( size_t i, ref section; pohodFiltersJSON.array )
	{
		if( section.type != JSON_TYPE.OBJECT )
			return null;

		string itemsHTML;

		// Добавляем текст заголовка секции
		string sectionTitle;
		if( auto s = "title" in section )
			sectionTitle = s.type == JSON_TYPE.STRING ? s.str : null;
		sectionTpl.setHTMLText( "section_title", sectionTitle );

		// Проход по элементам меню
		foreach( size_t j, ref item; section["items"].array )
		{
			if( item.type != JSON_TYPE.OBJECT )
				return null;

			// Добавляем текст пункта меню
			string itemText;
			if( auto s = "text" in item )
				itemText = s.type == JSON_TYPE.STRING ? s.str : null;
			itemTpl.setHTMLText( "item_text", itemText );

			import std.conv: text;
			// Сохраняем позицию фильтра в самом теге
			itemTpl.setHTMLValue( "item_pos", i.text ~ "/" ~ j.text );

			itemsHTML ~= itemTpl.getString();
		}

		sectionTpl.set( "filter_items", itemsHTML );

		sectionsHTML ~= sectionTpl.getString();
	}

	return sectionsHTML;
}

// Функция вывода элементов скрытой формы для отправки фильтров
string renderPohodFilterMenuInputs()
{
	if( pohodFilterFields.length == 0 )
		return null;

	string formInputsHTML;
	auto inputTpl = getPageTemplate( pageTemplatesDir ~ "pohod_filter_menu_input.html" );

	foreach( fieldName; pohodFilterFields )
	{
		inputTpl.setHTMLValue( "filter_field_name", fieldName );
		formInputsHTML ~= inputTpl.getString();
	}

	return formInputsHTML;
}


PlainTemplater getGeneralTemplate(HTTPContext context)
{	
	import std.algorithm: endsWith;

	auto tpl = getPageTemplate(generalTemplateFileName);
	tpl.set("this page path", context.request.uri.path);

	if( context.request.uri.path.endsWith("/dyn/auth")  ) //Записываем исходный транспорт
		tpl.set( "transport_proto", context.request.headers.get("x-forwarded-proto", "http") );

	tpl.set( "authentication uri", getAuthRedirectURI(context) );
	
	if( context.user.isAuthenticated )
	{	
		tpl.set( "auth_state_cls", "m-with_auth" );
		tpl.set( "auth_popdown_btn_text", HTMLEscapeText( context.user.name ) );
		tpl.set( "auth_popdown_btn_title", "Открыть список опций для учетной записи" );
	}
	else
	{	
		tpl.set( "auth_state_cls", "m-without_auth" );
		tpl.set( "auth_popdown_btn_text", "Вход не выполнен" );
		tpl.set( "auth_popdown_btn_title", "Вход на сайт не выполнен" );
	}

	tpl.set( "pohod_filter_menu_sections", renderPohodFilterMenuSections() );
	tpl.set( "pohod_filter_menu_inputs", renderPohodFilterMenuInputs() );
	tpl.set( "pohod_filter_menu_data", toJSON( &pohodFiltersJSON ) );
	
	return tpl;
}

PlainTemplater getPageTemplate(string tplFileName, bool shouldInit = true)
{	
	PlainTemplater tpl = templateCache.get(tplFileName);
	
	if( shouldInit )
	{	//Задаём местоположения всяких файлов

		tpl.set("public folder", publicPath);
		tpl.set("img folder", imgPath);
		tpl.set("css folder", cssPath);
		tpl.set("js folder", jsPath);
		
		tpl.set("webtank public folder", webtankPublicPath);
		tpl.set("webtank img folder", webtankImgPath);
		tpl.set("webtank css folder", webtankCssPath);
		tpl.set("webtank js folder", webtankJsPath);
		
		tpl.set( "bootstrap public", siteVirtualPaths.get("bootstrapPublic", "") );
		tpl.set( "bootstrap img folder", siteVirtualPaths.get("bootstrapImg", "") );
		tpl.set( "bootstrap css folder", siteVirtualPaths.get("bootstrapCSS", "") );
		tpl.set( "bootstrap js folder", siteVirtualPaths.get("bootstrapJS", "") );
		
		tpl.set("dynamic path", dynamicPath);
	}
	
	return tpl;
}

string renderPaginationTemplate(VM)( ref VM vm )
{
	import std.conv: text;
	auto paginTpl = getPageTemplate( pageTemplatesDir ~ "pagination.html" );
	
	if( vm.curPageNum <= 1 )
	{
		paginTpl.set( "prev_btn_cls", ".is-inactive_link" );
		paginTpl.set( "prev_btn_attr", `disabled="disabled"` );
	}
		
	paginTpl.set( "prev_page_num", (vm.curPageNum - 1).text );
	paginTpl.set( "cur_page_num", vm.curPageNum.text );
	paginTpl.set( "page_count", vm.pageCount.text );
	paginTpl.set( "next_page_num", (vm.curPageNum + 1).text );
	
	if( vm.curPageNum >= vm.pageCount )
	{
		paginTpl.set( "next_btn_cls", ".is-inactive_link" );
		paginTpl.set( "next_btn_attr", `disabled="disabled"` );
	}
	
	return paginTpl.getString();
}