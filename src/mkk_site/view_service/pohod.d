module mkk_site.view_service.pohod;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	Service.pageRouter.join!(renderPohodList)("/dyn/pohod/list");
	Service.pageRouter.join!(renderPartyInfo)("/dyn/pohod/partyInfo");
	Service.pageRouter.join!(renderExtraFileLinks)("/dyn/pohod/extraFileLinks");
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
	size_t recordCount = mainServiceCall("pohod.listSize", ctx, JSONValue(["filter": filter])).integer;
	size_t pageSize = isForPrint? 10000: 10;
	size_t offset = req.bodyForm.get("offset", "0").to!(size_t).ifThrown!ConvException(0);

	JSONValue nav = [
		"pageSize": JSONValue(pageSize),
		"offset": JSONValue(offset)
	];

	dataDict["pohodSet"] = mainServiceCall("pohod.list", ctx, JSONValue([
		"filter": filter,
		"nav": nav
	]));
	nav["recordCount"] = recordCount;
	dataDict["pohodNav"] = nav.toIvyJSON();
	dataDict["filter"] = filter.toIvyJSON(); // Возвращаем поля фильтрации назад пользователю
	dataDict["pohodEnums"] = mainServiceCall("pohod.enumTypes", ctx);
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
	TDataNode dataDict = mainServiceCall("pohod.partyInfo", ctx, JSONValue(["num": pohodNum]));

	ctx.response.write(
		Service.templateCache.getByModuleName("mkk.PohodList.PartyInfo").run(dataDict).str
	);
}

void renderExtraFileLinks(HTTPContext ctx)
{
	import std.json: JSONValue, JSON_TYPE, parseJSON;
	import std.conv: to;
	import std.base64: Base64;
	debug import std.stdio;
	TDataNode dataDict;
	if( "key" in ctx.request.queryForm ) {
		debug writeln(`Getting link list from MKK service`);
		// Если есть ключ похода, то берем ссылки из похода
		size_t pohodNum = ctx.request.queryForm.get("key", "0").to!size_t;
		dataDict["linkList"] = mainServiceCall("pohod.extraFileLinks", ctx, JSONValue(["num": pohodNum]));
	} else {
		debug writeln(`Rendering passed link list`);
		// Иначе отрисуем список ссылок, который нам передали
		string rawExtraFileLinks = ctx.request.queryForm.get("extraFileLinks", null);
		string decodedExtraFileLinks = cast(string) Base64.decode(rawExtraFileLinks);
		JSONValue extraFileLinks = parseJSON(decodedExtraFileLinks);
		if( extraFileLinks.type != JSON_TYPE.ARRAY && extraFileLinks.type != JSON_TYPE.NULL  ) {
			throw new Exception(`Некорректный формат списка ссылок на доп. материалы`);
		}

		TDataNode[] linkList;
		if( extraFileLinks.type == JSON_TYPE.ARRAY ) {
			linkList.length = extraFileLinks.array.length;
			foreach( size_t i, ref JSONValue entry; extraFileLinks ) {
				if( entry.type != JSON_TYPE.ARRAY || entry.array.length < 2) {
					throw new Exception(`Некорректный формат элемента списка ссылок на доп. материалы`);
				}
				if( entry[0].type != JSON_TYPE.STRING && entry[0].type != JSON_TYPE.NULL ) {
					throw new Exception(`Некорректный формат описания ссылки на доп. материалы`);
				}
				if( entry[1].type != JSON_TYPE.STRING && entry[1].type != JSON_TYPE.NULL ) {
					throw new Exception(`Некорректный формат ссылки на доп. материалы`);
				}
				linkList[i] = [
					(entry[0].type == JSON_TYPE.STRING? entry[0].str : null),
					(entry[1].type == JSON_TYPE.STRING? entry[1].str : null)
				];
			}
		}
		dataDict["linkList"] = linkList;
	}
	dataDict["instanceName"] = ctx.request.queryForm.get("instanceName", null);
	debug writeln(dataDict);

	ctx.response.write(
		Service.templateCache.getByModuleName("mkk.PohodEdit.ExtraFileLinksEdit.LinkItems").run(dataDict).str
	);
}