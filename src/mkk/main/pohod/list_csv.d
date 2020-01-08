module mkk.main.pohod.list_csv;

import mkk.main.devkit;

import mkk.main.pohod.list_filter: PohodFilter;
import mkk.main.pohod.list: PohodEnumFields, PohodList;

shared static this()
{
	MainService.JSON_RPCRouter.join!(pohodCsv)(`pohod.Csv`);

	MainService.pageRouter.joinWebFormAPI!(renderPohodCsv)("/api/pohod.csv");
}

auto pohodCsv(HTTPContext context, PohodFilter filter)
{
	import std.string: translate;
	import std.datetime.date;
	import std.conv; 
	import mkk.main.enums;
	import mkk.main.utils: dateRusFormatLetter;

	string[dchar] transTable1 = [',':" /",'\r':" ",'\n':" " ];

	string pohod_csv = ",Походы\r\n";
//--------------
	import std.algorithm: map;
	import std.string: join;
		
	string[] enumFields;
	static foreach( enum enumSpec; PohodEnumFields )
	{
		enumFields ~= `, ` ~ enumSpec[2] ~ `:, ` ~
			__traits(getMember, filter, enumSpec[0]).map!((it) {
				mixin(`return ` ~ enumSpec[0] ~ `.getName(it);`);
			}).join(",");
	}

	pohod_csv ~= "Фильтры походов\r\n" ~ enumFields.join("\r\n");
	pohod_csv ~= ",,,\r\n";

	if( filter.pohodRegion.length )
		pohod_csv ~= ",Район, похода,"~filter.pohodRegion~",\r\n";

	if( !filter.dates["beginRangeHead"].isNull )
		pohod_csv ~= ",с,"  ~ dateRusFormatLetter ( filter.dates["beginRangeHead"])~",\r\n";

	if( !filter.dates["endRangeTail"].isNull )
		pohod_csv ~= ",по," ~ dateRusFormatLetter ( filter.dates["endRangeTail"]) ~ ",\r\n" ;

	if( filter.withFiles )
		pohod_csv ~= ",Походы с ,дополнительными, материалами,"~",\r\n";

//--------------------------
	pohod_csv ~= "№ в базе,код МКК,№ книги,Начало похода,Конец похода,Вид,Категория,с эл.,Район,Руков Ф,Руков И,Руков О,Руков ГР,Число участников,Организация,Город,Маршрут, Готовность похода,Статус заявки,\r\n";

	Navigation nav;
	nav.offset.getOrSet(0); nav.pageSize.getOrSet(10000);

	IDBQueryResult rs = PohodList(filter, nav);

	string[][] for_all; //обобщённый массив данных 
	for_all.length = rs.recordCount+1; //строк втаблице

	foreach( recIndex; 0..rs.recordCount )
	{
		string[] data_array;
		data_array.length = rs.fieldCount;

		foreach( column_num; 0..rs.fieldCount ) {
			data_array[column_num] = rs.get(column_num, recIndex);
		}

		for_all[][recIndex] = data_array;
	}

	foreach( str; for_all )
	{
		size_t columnNumberInQuery = 0;
		size_t p = 0;

		foreach( el; str )
		{
			switch(p)
			{
				case 3, 4:
					if( el.length != 0 )
					{
						auto dt = Date.fromISOExtString(el);
						pohod_csv ~= dt.day.to!string ~ `.` ~ (cast(int) dt.month).to!string ~ `.` ~ dt.year.to!string ~ ',';
					}
					else
						pohod_csv ~= ',';
					//преобразование формата даты
				break;

				case 6:
					if( el.length != 0 )
					{
						pohod_csv ~= complexity[el.to!int]~  ',';
					}
					else
						pohod_csv ~= ',';
				break;

				case 5:
					if( el.length != 0 )
					{
						pohod_csv ~= tourismKind[el.to!int] ~ ',';
					}
					else
						pohod_csv ~= ',';
				break;

				case 19:
					if( el.length != 0 )
					{
						pohod_csv ~= progress[el.to!int]~  ',';
					}
					else
						pohod_csv ~= ',';
				break;

				case 20:
					if(el.length!=0)
					{
						pohod_csv ~= claimState[el.to!int]~  ',';
					}
					else
						pohod_csv ~= ',';
				break;

				case 9, 18:
				break;

				default:
					pohod_csv ~= translate(el , transTable1) ~ ',';
				break;
			}

			p = p+1;
		}
		pohod_csv ~= "\r\n";
	}

	return pohod_csv;
}

void renderPohodCsv(HTTPContext ctx, PohodFilter filter)
{
	import std.conv: to;

	ctx.response.headers[HTTPHeader.ContentType] = `text/csv; charset="utf-8`;
	ctx.response.write(pohodCsv(ctx, filter).to!string);
}