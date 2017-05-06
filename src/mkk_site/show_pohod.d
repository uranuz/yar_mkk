module mkk_site.show_pohod;

import std.conv, std.string, std.array, std.stdio;
import std.exception : ifThrown;

import mkk_site.page_devkit;
//import std.stdio;

static immutable(string) thisPagePath;

shared static this()
{	thisPagePath = dynamicPath ~ "show_pohod";
	PageRouter.join!(netMain)(thisPagePath);
	JSONRPCRouter.join!(participantsList);
	JSONRPCRouter.join!(partyInfo);
}

//-------------------------------------------------------------
// ??? Не используется?
// -------Формирует информационную строку о временном диапазоне поиска походов
string поисковыйДиапазонПоходов(const ref ФильтрПоходов фильтрПоходов)
{
	import std.datetime: Date;
	
	OptionalDate фильтрДатыНачало = фильтрПоходов.сроки[ "begin_date_range_head" ];
	OptionalDate фильтрДатыКонец = фильтрПоходов.сроки[ "end_date_range_tail" ];

	string[] _месяцы = ["января","февраля","марта","апреля","мая","июня","июля","августа","сентября","октября","ноября","декабря"];
	string район;
	string beginDateStr;
	string endDateStr;
	
	if( фильтрПоходов.районПохода.length > 0 )
		район ~= "<br/>Район похода содержит [ " ~ фильтрПоходов.районПохода ~ " ].<br/>";
	if( фильтрПоходов.сМатериалами )
		район ~= " По данным походам имеются отчёты или дополнительные материалы.<br/><br/>";
	
	if( фильтрДатыНачало.isNull )
	{
		beginDateStr ~= " не определено";
	}
	else
	{
		if( !фильтрДатыНачало.day.isNull || !фильтрДатыНачало.month.isNull )
		{
			beginDateStr ~= фильтрДатыНачало.day.isNull ? "" : фильтрДатыНачало.day.to!string ~ ` `;
			if( фильтрДатыНачало.day.isNull )
				beginDateStr ~= фильтрДатыНачало.month.isNull ? "число любого месяца" : месяцы.getName(фильтрДатыНачало.month);
			else
				beginDateStr ~= фильтрДатыНачало.month.isNull ? "число любого месяца" : месяцы_родительный.getName(фильтрДатыНачало.month);
		}
		beginDateStr ~= ` ` ~ (фильтрДатыНачало.year.isNull ? "" : фильтрДатыНачало.year.to!string);
	}
	
	if( фильтрДатыКонец.isNull )
	{
		endDateStr ~= " не определён ";
	}
	else
	{ 
		if( !фильтрДатыКонец.day.isNull || !фильтрДатыКонец.month.isNull )
		{
			endDateStr ~= фильтрДатыКонец.day.isNull ? "" : фильтрДатыНачало.day.to!string ~ ` `;
			if( фильтрДатыКонец.day.isNull )
				endDateStr ~= фильтрДатыКонец.month.isNull ? " число любого месяца" : месяцы.getName(фильтрДатыКонец.month);
			else
				endDateStr ~= фильтрДатыКонец.month.isNull ? " число любого месяца" : месяцы_родительный.getName(фильтрДатыКонец.month);
		}
		endDateStr ~= ` ` ~ ( фильтрДатыКонец.year.isNull ? " " : фильтрДатыКонец.year.to!string );
	}
		
	return (район~`<fieldset><legend>Сроки похода</legend> Начало похода ` ~ beginDateStr ~ `<br/> Конец похода  ` ~ endDateStr ~ `</fieldset>`);
}

//-----------------------------------------------------------------------------
