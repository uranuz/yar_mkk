module mkk_site.templating;

import std.conv;

import
	webtank.net.http.context,
	webtank.net.utils,
	webtank.templating.plain_templater,
	webtank.ui.templating;

import 
	mkk_site.site_data,
	mkk_site.routing;

import mkk_site.templating_init;

enum useTemplateCache = !isMKKSiteDevelTarget;

__gshared PlainTemplateCache!(useTemplateCache) templateCache;

PlainTemplater getGeneralTemplate(HTTPContext context)
{	
	import std.algorithm: endsWith;

	auto tpl = getPageTemplate(generalTemplateFileName);
	tpl.set("this page path", context.request.uri.path);

	if( context.request.uri.path.endsWith("/dyn/auth")  ) //Записываем исходный транспорт
		tpl.set( "transport_proto", context.request.headers.get("x-forwarded-proto", "http") );

	tpl.set( "authentication uri", getAuthRedirectURI(context) );
	
	string authMenuCaption;
	
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