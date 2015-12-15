module mkk_site.stat;

import std.conv, std.string, std.file, std.array;
import std.stdio;

import webtank.datctrl, webtank.db, webtank.net.http, webtank.templating.plain_templater, webtank.net.utils, webtank.common.conv;

// import webtank.net.javascript;
import webtank.datctrl.data_field, webtank.datctrl.record_format, webtank.db.postgresql, webtank.db.datctrl_joint,webtank.datctrl.record, webtank.net.http.context;


import mkk_site.site_data, mkk_site.access_control, mkk_site.utils, mkk_site;




immutable(string) thisPagePath;

shared static this()
{	
	thisPagePath = dynamicPath ~ "stat";
	PageRouter.join!(netMain)(thisPagePath);
}

string netMain(HTTPContext context)
{	
	auto rq = context.request;//запрос
	auto rp = context.response;//ответ
	
	auto pVars = rq.queryForm;
	auto qVars = rq.bodyForm;

 string content;
 string table;
 content = `Вася`;
 
 table~=`
 
 <table class="tab1" >
 <tr>
    <td rowspan="2">Год</td>
    <th colspan="2">Все</th>
    <th colspan="2">Пеший</th>
    <th colspan="2">Лыжный</th>
    <th colspan="2">Горный</th>
    <th colspan="2">Водный</th>
    <th colspan="2">Вело</th>
    <th colspan="2">Авто</th>
    <th colspan="2">Спелео</th>
    <th colspan="2">Парус</th>
    <th colspan="2">Конный</th>
    <th colspan="2">Комбинир</th>
    
   </tr>
   <tr>
    <th>гр.</th><th>чел.</th>
    <th>гр.</th><th>чел.</th>
    <th>гр.</th><th>чел.</th>
    <th>гр.</th><th>чел.</th>
    <th>гр.</th><th>чел.</th>
    <th>гр.</th><th>чел.</th>
    <th>гр.</th><th>чел.</th>
    <th>гр.</th><th>чел.</th>
    <th>гр.</th><th>чел.</th>
    <th>гр.</th><th>чел.</th>
    <th>гр.</th><th>чел.</th>
    
   </tr>

 `;


import std.typecons;
	
   ///Начинаем оформлять таблицу с данными
   static immutable statRecFormat = RecordFormat!(
		PrimaryKey!(string), "Год", 
		string, "гр_всего", 
		string,  "уч_всего", 
		string, "гр_пешый",
		string,  "уч_пешый",
		string, "гр_лыжный", 
		string,  "уч_лыжный", 
		string, "гр_горный",
		string,  "уч_горный",
		string, "гр_водный", 
		string,  "уч_водный", 
		string, "гр_вело",
		string,  "уч_вело",
		string, "гр_авто", 
		string,  "уч_авто", 
		string, "гр_спелео",
		string,  "уч_спелео",
		string, "гр_парус", 
		string,  "уч_парус", 
		string, "гр_конный",
		string,  "уч_конный",
		string, "гр_комби", 
		string,  "уч_комби" 
		
	)(
		null,
		tuple()
	);
 auto dbase = getCommonDB(); //Подключение к базе
 
	string тело_статистика = ` WITH 
      st AS (select kod_mkk,  CAST ((date_part('YEAR', begin_date)) AS integer) AS year,vid,ks,CAST (unit AS integer) FROM pohod WHERE kod_mkk='176-00'  ORDER BY year ),

      всего  AS ( SELECT year,count(unit) AS gr_всего,sum (unit)     AS un_всего   FROM st               GROUP BY year ORDER BY year ),
      пешый  AS ( SELECT year,count(unit) AS gr_пешый,sum (unit)     AS un_пешый   FROM st  WHERE vid=1  GROUP BY year ORDER BY year ),
      лыжный AS ( SELECT year,count(unit) AS gr_лыжный,sum (unit)    AS un_лыжный  FROM st  WHERE vid=2  GROUP BY year ORDER BY year ),
      горный AS ( SELECT year,count(unit) AS gr_горный,sum (unit)    AS un_горный  FROM st  WHERE vid=3  GROUP BY year ORDER BY year ),
      водный AS ( SELECT year,count(unit) AS gr_водный, sum (unit)   AS un_водный  FROM st  WHERE vid=4  GROUP BY year ORDER BY year ),
      вело   AS ( SELECT year,count(unit) AS gr_вело, sum (unit)     AS un_вело    FROM st  WHERE vid=5  GROUP BY year ORDER BY year ),
      авто   AS ( SELECT year,count(unit) AS gr_авто, sum (unit)     AS un_авто    FROM st  WHERE vid=6  GROUP BY year ORDER BY year ),
      спелео AS ( SELECT year,count(unit) AS gr_спелео ,sum (unit)   AS un_спелео  FROM st  WHERE vid=7  GROUP BY year ORDER BY year ),
      парус  AS ( SELECT year,count(unit) AS gr_парус, sum (unit)    AS un_парус   FROM st  WHERE vid=8  GROUP BY year ORDER BY year ),
      конный AS ( SELECT year,count(unit) AS gr_конный, sum (unit)   AS un_конный  FROM st  WHERE vid=9  GROUP BY year ORDER BY year ),
      комби  AS ( SELECT year,count(unit) AS gr_комби, sum (unit)    AS un_комби   FROM st  WHERE vid=10 GROUP BY year ORDER BY year )
      
      SELECT
      всего.year,
      gr_всего,un_всего,
      gr_пешый,un_пешый,
      gr_лыжный,un_лыжный,
      gr_горный,un_горный,
      gr_водный,un_водный,
      gr_вело,un_вело,
      gr_авто,un_авто,
      gr_спелео,un_спелео,
      gr_парус,un_парус,
      gr_конный,un_конный,
      gr_комби,un_комби



           FROM всего 
      LEFT JOIN пешый ON всего.year   = пешый.year
      LEFT JOIN лыжный ON всего.year  = лыжный.year
      LEFT JOIN горный ON всего.year  = горный.year
      LEFT JOIN водный ON всего.year  = водный.year
      LEFT JOIN вело ON всего.year    = вело.year
      LEFT JOIN авто ON всего.year    = авто.year
      LEFT JOIN спелео  ON всего.year = спелео .year
      LEFT JOIN парус ON всего.year   = парус.year
      LEFT JOIN конный ON всего.year  = конный.year
      LEFT JOIN комби ON всего.year   = комби.year `;
      
      auto rs = dbase.query(тело_статистика).getRecordSet(statRecFormat);
 
  foreach(rec; rs)
  {
  table ~= `<tr>`;
  table ~= `<td>` ~ rec.get!"Год"("нет")  ~ `</td>`~ "\r\n";
  table ~= `<td>` ~ rec.get!"гр_всего"("-")  ~ `</td>`~ "\r\n";
  table ~= `<td>` ~ rec.get!"уч_всего"("-")  ~ `</td>`~ "\r\n";
  table ~= `<td>` ~ rec.get!"гр_пешый"("-")  ~ `</td>`~ "\r\n";
  table ~= `<td>` ~ rec.get!"уч_пешый"("-")  ~ `</td>`~ "\r\n";
  table ~= `<td>` ~ rec.get!"гр_лыжный"("-")  ~ `</td>`~ "\r\n";
  table ~= `<td>` ~ rec.get!"уч_лыжный"("-")  ~ `</td>`~ "\r\n";
  table ~= `<td>` ~ rec.get!"гр_горный"("-")  ~ `</td>`~ "\r\n";
  table ~= `<td>` ~ rec.get!"уч_горный"("-")  ~ `</td>`~ "\r\n";
  table ~= `<td>` ~ rec.get!"гр_водный"("-")  ~ `</td>`~ "\r\n";
  table ~= `<td>` ~ rec.get!"уч_водный"("-")  ~ `</td>`~ "\r\n";
  table ~= `<td>` ~ rec.get!"гр_вело"("-")  ~ `</td>`~ "\r\n";
  table ~= `<td>` ~ rec.get!"уч_вело"("-")  ~ `</td>`~ "\r\n";
  table ~= `<td>` ~ rec.get!"гр_авто"("-")  ~ `</td>`~ "\r\n";
  table ~= `<td>` ~ rec.get!"уч_авто"("-")  ~ `</td>`~ "\r\n";
  table ~= `<td>` ~ rec.get!"гр_спелео"("-")  ~ `</td>`~ "\r\n";
  table ~= `<td>` ~ rec.get!"уч_спелео"("-")  ~ `</td>`~ "\r\n";
  table ~= `<td>` ~ rec.get!"гр_парус"("-")  ~ `</td>`~ "\r\n";
  table ~= `<td>` ~ rec.get!"уч_парус"("-")  ~ `</td>`~ "\r\n";
  table ~= `<td>` ~ rec.get!"гр_конный"("-")  ~ `</td>`~ "\r\n";
  table ~= `<td>` ~ rec.get!"уч_конный"("-")  ~ `</td>`~ "\r\n";
  table ~= `<td>` ~ rec.get!"гр_комби"("-")  ~ `</td>`~ "\r\n";
  table ~= `<td>` ~ rec.get!"уч_комби"("-")  ~ `</td>`~ "\r\n";
  
  
  
  table ~= `</tr>`~ "\r\n";
  }
 
 
 content~= table~` </table>`;
 content~=`<canvas width="300" height="225"></canvas>`~ "\r\n";
 
	return content;
}
