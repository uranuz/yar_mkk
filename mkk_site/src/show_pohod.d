module mkk_site.full_test;

import std.stdio;

//import webtank.db.database;
import webtank.datctrl.field_type;
import webtank.db.postgresql;
import webtank.db.datctrl_joint;

import webtank.datctrl.record;
//import webtank.datctrl.record_set;

import webtank.view_logic.record_set_view;

immutable(string) projectPath = `/webtank`;

int main()
{	string output = "Content-type: text/html; charset=\"utf-8\" \r\n\r\n"; //"Выхлоп" программы
	try {
	RecordFormat touristRecFormat; //объявляем формат записи таблицы book
	with(FieldType) {
	touristRecFormat = RecordFormat(
	[IntKey, Str, Str, Str, Str, Str, Str, Str, Str],
	["Ключ", "Номер", "Сроки <br> похода", "Вид, кс","Район","Руководитель","Участники","Город,<br>организация", "Комментарий","Статус<br> похода"],
	//[null, null, null, null, null, null,null, null, null],
	[true, true, true, true, true, true, true, true,true, true] //Разрешение нулевого значения
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
  family_name||' '||given_name||' '||patronymic||', '||birth_year::text, '<br>') as gr
from tourist_info
group by num
) `

	  `select pohod.num, (coalesce(kod_mkk,'')||'<br>'||coalesce(nomer_knigi,'')) as nomer_knigi, `  
     `(coalesce(begin_date::text,'')||'<br>'||coalesce(finish_date::text,'')) as date , ` 
     `( coalesce( vid::text, '' )||'<br>'|| coalesce( ks::text, '' )||coalesce( element::text, '' ) ) as vid,`

     `region_pohod ,`
     `(tourist.family_name||'<br>'||coalesce(tourist.given_name,'')||'<br>'||coalesce(tourist.patronymic,'')||'<br>'||coalesce(tourist.birth_year::text,'')), `
     `(' title="'||coalesce(gr,'')||'"'||pohod.unit), `
     
     `(coalesce(organization,'')||'<br>'||coalesce(region_group,'')), `
     `(coalesce(marchrut,'')||'<br>'||coalesce(chef_coment,'')),`
     `(coalesce(prepare::text,'')||'<br>'||coalesce(status::text,''))  `
             `from pohod  `
               
        ` JOIN tourist   `
      `on pohod.chef_grupp = tourist.num `
      `join U `
      `on U.num = pohod.num `        

;
		
	auto response = dbase.query(queryStr); //запрос к БД
	auto rs = response.getRecordSet(touristRecFormat);  //трансформирует ответ БД в RecordSet (набор записей)
	
	auto rsView = new RecordSetView(rs);
	with( FieldOutputMode )
		rsView._outputModes = [visible, visible, visible, visible,visible, visible, visible, visible, visible, visible];
	rsView._viewManners = [FieldViewManner.plainText, FieldViewManner.plainText/*, FieldViewManner.simpleControls*/];
	rsView._HTMLClasses = [`cod`, `book-name`, `author`];
	string html = `<html><body><head><link rel="stylesheet" type="text/css" href="` ~ projectPath ~ `/css/full_test.css">` 
		~ rsView.getHTMLStr() ~ `</head></body></html>`; //превращаем RecordSet в строку html-кода
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

