module mkk.main.utils;

import webtank.common.optional_date: OptionalDate;

import mkk.main.enums: months;

string dateRusFormatLetter(OptionalDate date)
{
	import std.conv: text;
	import std.meta: AliasSeq;
	
	string  dateRu;
	auto tmpDate = date;
	foreach( fieldName; AliasSeq!(`day`, `month`, `year`) )
	{
		auto dtPart = __traits(getMember, tmpDate, fieldName);
		if( fieldName != `month` )
			dateRu ~= (dtPart.isNull? `__`: dtPart.value.text) ~ " ";
		else
			dateRu ~= (dtPart.isNull? `__`: months[dtPart.value]) ~ " ";
	}

	return dateRu;
	// вывод  в формате 23 февраля 2013
}

string dateRusFormatNumber(OptionalDate date)
{
	import std.conv: text;
	import std.meta: AliasSeq;

	string  dateRu;
	auto tmpDate = date;
	foreach( fieldName; AliasSeq!(`day`, `month`, `year`) )
	{
		auto dtPart = __traits(getMember, tmpDate, fieldName);
		if( fieldName != `year` )
			dateRu ~= (dtPart.isNull? `__`: dtPart.value.text) ~ ".";
		else
			dateRu ~= (dtPart.isNull? `__`:months[dtPart.value]);
	}

	return dateRu;
	// вывод  в формате 23.02.2013
}