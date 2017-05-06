module mkk_site.view_service.pohod;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	Service.pageRouter.join!(renderPohodList)("/dyn/pohod/list");
}

import ivy.interpreter_data, ivy.json, ivy.interpreter;

import webtank.net.http.handler;
import webtank.net.http.context;

/+
string отрисоватьБлокНавигацииДляПечати(VM)( ref VM vm )
{
	import std.array: join;

	auto формаФильтрации = getPageTemplate( pageTemplatesDir ~ "pohod_navigation_for_print.html" );

	foreach( fieldDescr; PohodEnumFields )
	{
		string[] selectedNames;
		mixin( `auto FilterField = &vm.filter.` ~ fieldDescr[2] ~ `;` );

		if( FilterField.length)
		{
			foreach( el; *FilterField )
			{
				if( fieldDescr[1].hasValue(el) ) //Проверяет наличие значения в перечислимом типе
					selectedNames ~= fieldDescr[1].getName(el);
			}
		}
		else
		{
			selectedNames ~= "Показаны все";
		}

		формаФильтрации.set( fieldDescr[0], selectedNames.join(",<br/>\r\n") );
	}

	формаФильтрации.set("print_switch_btn_text","Назад");
	foreach( имяПоля, дата; vm.filter.сроки )
	{
		auto полеДаты = bsPlainDatePicker(дата);
		полеДаты.dataFieldName = имяПоля;
		полеДаты.controlName = имяПоля;
		полеДаты.nullDayText = "день";
		полеДаты.nullMonthText = "месяц";
		полеДаты.nullYearText = "год";
		
		формаФильтрации.set( имяПоля, полеДаты.print() );
	}
	
	with( формаФильтрации )
	{
		set( "region_pohod", HTMLEscapeValue(vm.filter.районПохода) );
		if( vm.filter.сМатериалами )
			set( "with_files", ` checked="checked"` );
			
		if( vm.filter.контрольДанных )
			set( "data_check", ` checked="checked"` );
			
			if( !vm.isAuthorized )
			set( "none", ` style="display:none" ` );
	}

	return формаФильтрации.getString();
}
+/


string renderPohodList(HTTPContext ctx)
{
	import std.json: JSONValue, JSON_TYPE;
	import std.conv: to, ConvException;
	import std.exception: ifThrown;

	auto req = ctx.request;
	bool isForPrint = req.bodyForm.get("for_print", null) == "on";
	bool isAuthorized = ctx.user.isAuthenticated && ( ctx.user.isInRole("admin") || ctx.user.isInRole("moder") );
	size_t pohodsPerPage = ( isForPrint? 10000: 10 );
	size_t curPageNum = req.bodyForm.get("cur_page_num", "1").to!(size_t).ifThrown!ConvException(1);

	//size_t pageCount = pohodCount / pohodsPerPage + 1; //Количество страниц
	//if( curPageNum > pageCount ) curPageNum = pageCount;

	JSONValue filter;
	foreach( name; ["tourismKinds", "complexities", "progresss", "claimStates"] ) {
		if( name in req.bodyForm ) {
			int[] data = req.bodyForm.array(name).to!(int[]).ifThrown!ConvException(null);
			if( data.length > 0 ) {
				filter[name] = data;
			}
		}
	}

	filter["pohodRegion"] = req.bodyForm.get("pohodRegion", null);
	foreach( name; ["withFiles", "withDataCheck"] ) {
		if( name in req.bodyForm ) {
			filter[name] = req.bodyForm[name] == "on";
		}
	}

	JSONValue datesFilter;
	foreach( name; [
		"beginDateRangeHead",
		"beginDateRangeTail",
		"endDateRangeHead",
		"endDateRangeTail"
	]) {
		if( name in req.bodyForm ) {
			datesFilter[name] = req.bodyForm[name];
		}
	}
	if( datesFilter.type != JSON_TYPE.NULL ) {
		filter["dates"] = datesFilter;
	}

	TDataNode dataDict;
	dataDict["pohodSet"] = mainServiceCall("pohod.list", ctx, JSONValue([
		"filter": filter,
		"offset": JSONValue( (curPageNum - 1) * pohodsPerPage ),
		"limit": JSONValue(pohodsPerPage)
	]));

	// Возвращаем поля фильтрации назад пользователю
	dataDict["pohodEnums"] = mainServiceCall("pohod.enumTypes", ctx);
	dataDict["filter"] = filter.toIvyJSON();

	dataDict["vpaths"] = Service.virtualPaths;
	dataDict["isAuthenticated"] = isAuthorized;
	dataDict["isForPrint"] = isForPrint;

	return Service.templateCache.getByModuleName("mkk.PohodList").run(dataDict).str;
}
