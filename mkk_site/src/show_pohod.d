module mkk_site.full_test;

import std.stdio;
import std.conv;

//import webtank.db.database;
import webtank.datctrl.field_type;
import webtank.db.postgresql;
import webtank.db.datctrl_joint;

import webtank.datctrl.record;
//import webtank.datctrl.record_set;


immutable(string) projectPath = `/webtank`;

int main()
{	string output = "Content-type: text/html; charset=\"utf-8\" \r\n\r\n"; //"Выхлоп" программы
	try {
	RecordFormat touristRecFormat; //объявляем формат записи таблицы book
	with(FieldType) {
	touristRecFormat = RecordFormat(
	[IntKey, Str, Str, Str, Str, Str, Str, Str, Str, Str, Str],
	["Ключ", "Номер", "Сроки <br> похода", "Вид, кс","Район","Руководитель","Участники","Уч","Город,<br>организация", "Нитка маршрута","Статус<br> похода"],
	//[null, null, null, null, null, null,null, null, null],
	[true, true, true, true, true, true, true, true,true, true, true] //Разрешение нулевого значения
	);
	}
	
	string connStr = "dbname=baza_MKK host=localhost user=postgres password=postgres";
	auto dbase = new DBPostgreSQL(connStr);
	if (dbase.isConnected) output ~= "Соединение с БД установлено";
	else  output ~= "Ошибка соединения с БД";
	
	//SELECT num, femelu, neim, otchectv0, brith_date, god, adrec, telefon, tel_viz FROM turistbl;
	string queryStr = 
	`with 
tourist_nums as (
  select num, unnest(unit_neim) as tourist_num from pohod
),  `

   `  tourist_info as (
select tourist_nums.num, tourist_num, family_name, given_name, patronymic, birth_year from tourist_nums
  join tourist 
   on tourist_num = tourist.num
), `

`U as (

select num, string_agg(
  family_name||' '||coalesce(given_name,'')||' '||coalesce(patronymic,'')||' '||coalesce(birth_year::text,''), chr(13) 
  ) as gr
from tourist_info
group by num
) `

	  `select pohod.num, (coalesce(kod_mkk,'')||'<br>'||coalesce(nomer_knigi,'')) as nomer_knigi, `  
     `(coalesce(begin_date::text,'')||'<br>'||coalesce(finish_date::text,'')) as date , ` 
     `( coalesce( vid::text, '' )||'<br>'|| coalesce( ks::text, '' )||coalesce( element::text, ' ' ) ) as vid,`

     `region_pohod , `
     `(tourist.family_name||'<br>'||coalesce(tourist.given_name,'')||'<br>'||coalesce(tourist.patronymic,'')||'<br>'||coalesce(tourist.birth_year::text,'')), `
     `(coalesce(pohod.unit,'')),(coalesce(gr,'')), `
     
     `(coalesce(organization,'')||'<br>'||coalesce(region_group,'')), `
     `(coalesce(marchrut::text,'')||'<br>'||coalesce(chef_coment::text,'')), `
     `(coalesce(prepare::text,'')||'<br>'||coalesce(status::text,''))  `
             `from pohod  `
               
        ` JOIN tourist   `
      `on pohod.chef_grupp = tourist.num `
      ` LEFT OUTER JOIN  U `
      `on U.num = pohod.num order by pohod.num `        

;
		
	auto response = dbase.query(queryStr); //запрос к БД
	auto rs = response.getRecordSet(touristRecFormat);  //трансформирует ответ БД в RecordSet (набор записей)
	
	//uint aaa = cast(uint) rs.recordCount;
	//output ~= aaa.to!string;
		string table = `<table>`;
		
		table ~= `<td>"Ключ"</td><td> "Номер"</td><td> "Сроки <br> похода"</td><td> "Вид, кс"</td><td>"Район"</td><td>"Руководитель"</td><td>"Участники"</td><td>"Город,<br>организация"</td><td> "Нитка маршрута"</td><td>"Статус<br> похода"</td>`;
	foreach(rec; rs)
	{	table ~= `<tr>`;
	  
		table ~= `<td>` ~ ( ( rec["Ключ"].isNull() ) ? "Не задано" : rec["Ключ"].getStr() ) ~ `</td>`;
		table ~= `<td>` ~ ( ( rec["Номер"].isNull() ) ? "Не задано" : rec["Номер"].getStr() ) ~ `</td>`;
		table ~= `<td>` ~ ( ( rec["Сроки <br> похода"].isNull() ) ? "Не задано" : rec["Сроки <br> похода"].getStr() ) ~ `</td>`;
		table ~= `<td>` ~ ( ( rec["Вид, кс"].isNull() ) ? "Не задано" : rec["Вид, кс"].getStr() ) ~ `</td>`;
		table ~= `<td>` ~ ( ( rec["Район"].isNull() ) ? "Не задано" : rec["Район"].getStr() ) ~ `</td>`;
		table ~= `<td>` ~ ( ( rec["Руководитель"].isNull() ) ? "Не задано" : rec["Руководитель"].getStr() ) ~ `</td>`;
		
		table ~= `<td  title="`~ ( ( rec["Уч"].isNull() ) ? "Не задано" : rec["Уч"].getStr() )~`">` ~`<font color="red">`~  ( ( rec["Участники"].isNull() ) ? "Не задано" : rec["Участники"].getStr() ) ~ `</font ></td>`;
		
		
		table ~= `<td>` ~ ( ( rec["Город,<br>организация"].isNull() ) ? "Не задано" : rec["Город,<br>организация"].getStr() ) ~ `</td>`;
		
		
	
		table ~= `<td>` ~ ( ( rec["Нитка маршрута"].isNull() ) ? "Не задано" : rec["Нитка маршрута"].getStr() ) ~ `</td>`;
		table ~= `<td>` ~ ( ( rec["Статус<br> похода"].isNull() ) ? "Не задано" : rec["Статус<br> похода"].getStr() ) ~ `</td>`;
		table ~= `</tr>`;
	}
	table ~= `</table>`;
	
	string html = `<html><body><head><link rel="stylesheet" type="text/css" href="` ~  `/css/full_test.css">` 
		~ table 
		~ `</head></body></html>`; //превращаем RecordSet в строку html-кода
	output ~= html;
	}
	//catch(Exception e) {
		//output ~= "\r\nНепредвиденная ошибка в работе сервера";
	//}
	finally {
		writeln(output);
	}
	return 0;
}

