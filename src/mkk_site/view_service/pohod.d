module mkk_site.view_service.pohod;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	Service.pageRouter.join!(renderPohodList)("/dyn/pohod/list");
	Service.pageRouter.join!(renderPartyInfo)("/dyn/pohod/partyInfo");
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
	bool isForPrint = req.bodyForm.get("isForPrint", null) == "on";
	bool isAuthorized = ctx.user.isAuthenticated && ( ctx.user.isInRole("admin") || ctx.user.isInRole("moder") );
	JSONValue filter; // JSON с фильтрами по походам

	// Далее идёт вытаскивание данных фильтрации из формы и создание JSON со структурой фильтра

	// Выборка фильтров по перечислимым полям
	foreach( name; ["tourismKinds", "complexities", "progresss", "claimStates"] ) {
		if( name in req.bodyForm ) {
			int[] data = req.bodyForm.array(name).to!(int[]).ifThrown!ConvException(null);
			if( data.length > 0 ) {
				filter[name] = data;
			}
		}
	}

	filter["pohodRegion"] = req.bodyForm.get("pohodRegion", null); // Район похода

	// Флаги "с доп. материамлами", "режим контроля данных"
	foreach( name; ["withFiles", "withDataCheck"] ) {
		if( name in req.bodyForm ) {
			filter[name] = req.bodyForm[name] == "on";
		}
	}

	// Вытаскиваем данные для поля dates с фильтром по датам
	JSONValue datesFilter;
	foreach( name; [
		"beginDateRangeHead",
		"beginDateRangeTail",
		"endDateRangeHead",
		"endDateRangeTail"
	]) {
		int[string] currDate;
		foreach( partName; ["day", "month", "year"])
		{
			string formField = name ~ "__" ~ partName;
			if( formField in req.bodyForm && req.bodyForm[formField].length > 0 ) {
				try {
					currDate[partName] = req.bodyForm[formField].to!int;
				} catch(ConvException) {} // Игнорируем неверные значения
			}
		}
		datesFilter[name] = JSONValue(currDate);
	}
	filter["dates"] = datesFilter;

	TDataNode dataDict;
	size_t pohodCount = mainServiceCall("pohod.listSize", ctx, JSONValue(["filter": filter])).integer;
	size_t pohodsPerPage = isForPrint? 10000: 10;
	size_t currentPage = req.bodyForm.get("currentPage", "1").to!(size_t).ifThrown!ConvException(1);
	size_t pageCount = pohodCount / pohodsPerPage + 1;
	if( currentPage > pageCount ) {
		currentPage = pageCount;
	}

	dataDict["pohodSet"] = mainServiceCall("pohod.list", ctx, JSONValue([
		"filter": filter,
		"offset": JSONValue( (currentPage - 1) * pohodsPerPage ),
		"limit": JSONValue(pohodsPerPage)
	]));

	dataDict["pohodCount"] = pohodCount;
	dataDict["currentPage"] = currentPage;
	dataDict["pageCount"] = pageCount;
	dataDict["pohodEnums"] = mainServiceCall("pohod.enumTypes", ctx);
	dataDict["filter"] = filter.toIvyJSON(); // Возвращаем поля фильтрации назад пользователю

	dataDict["vpaths"] = Service.virtualPaths;
	dataDict["isAuthenticated"] = isAuthorized;
	dataDict["isForPrint"] = isForPrint;

	return Service.templateCache.getByModuleName("mkk.PohodList").run(dataDict).str;
}

void renderPartyInfo(HTTPContext ctx)
{
	import std.json: JSONValue;
	import std.conv: to;
	size_t pohodNum = ctx.request.queryForm.get("key", "0").to!size_t;
	TDataNode dataDict = mainServiceCall("pohod.partyInfo", ctx, JSONValue(["pohodNum": pohodNum]));

	ctx.response.write(
		Service.templateCache.getByModuleName("mkk.PohodList.PartyInfo").run(dataDict).str
	);
}