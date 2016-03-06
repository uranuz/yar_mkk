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
	
 bool isForPrint = rq.bodyForm.get("for_print", null) == "on";//если on то true
 string content;
 string table;
 content = `<p>Относительно полная информация с 1992 года, ранее фрагментарный характер информации.</p>`~ "\r\n";
 content ~=  ` <p><a href="/pub/stati_dokument/stat1992_2010.rar"   > Отчёты за 1992-2010 годы.(zip) </a></p> `~ "\r\n";

import std.typecons;
	
   ///Начинаем оформлять таблицу с данными
   static immutable statRecFormatVid = RecordFormat!(
		PrimaryKey!(string), "Год", 		 
		string,"Пешый", string,"Лыжный", 	string,"Горный",	string,"Водный", 	string," Вело ",
		string," Авто ", 	string,"Спелео",	string, "Парус", 	string,"Конный",	string, "Комби", 
		string, "ВСЕГО"		
	)(		null,	tuple()	);
	
	 static immutable statRecFormatKC = RecordFormat!(
		PrimaryKey!(string), "Вид/КС", 		 
		string,"н.к.", string,"первая", 	string,"вторая",	string,"третья", 	string,"четвёртая",
		string,"пятая", 	string,"шестая",	string, "пут.", 
		string, "ВСЕГО"		
	)(		null,	tuple()	);
	
	
	//int[string]ks=["н.к.","первая","вторая","третья","четвёртая","пятая","шестая","пут.","всего"];
	string[] групп_человек;
	
 auto dbase = getCommonDB(); //Подключение к базе
 
 bool b_kod=false, b_org=false, b_terr=false;
 
 string kod= PGEscapeStr( rq.bodyForm.get("kod_MKK",     "") );
 string org= PGEscapeStr( rq.bodyForm.get("organization", "") );
 string terr= PGEscapeStr( rq.bodyForm.get("territory",   "") );
 string year= PGEscapeStr( rq.bodyForm.get("year",   "2014") );
 string prezent_vid= PGEscapeStr( rq.bodyForm.get("prezent_vid","Весь период."));
 
 string [] prezent=["Весь период.","За год."]; 
  bool[string] заголовок;
  string [] вид= ["Вид/КС","Пешый","Лыжный","Горный","Водный"," Вело ",	" Авто ", "Спелео","Парус",  "Конный", "Комби",	"ИТОГО"] ;
  
   if( prezent_vid=="Весь период.")
   { групп_человек=statRecFormatVid.names;
     заголовок= 
	["Год":true, 	 "Пешый":true,  "Лыжный":true,  "Горный":true,  "Водный":true, 	" Вело ":true,      
	" Авто ":true,  "Спелео":true, "Парус":true,  	"Конный":true,  "Комби":true,   	"ВСЕГО":true
	] ;
	}
   
	if( prezent_vid=="За год.")  
	{групп_человек=statRecFormatKC.names;
		заголовок=
	  ["Вид/КС":true,"н.к.":true,"первая":true,"вторая":true,"третья":true,
	  "четвёртая":true, "пятая":true,"шестая":true,"пут.":true,"ВСЕГО":true];
	  
	}
  //writeln(групп_человек);
   if(kod!="")  b_kod= true;
   if(org!="")  b_org= true;
   if(terr!="") b_terr=true;
 
	string запрос_статистика;
	///////-----Весь период---------
	if( prezent_vid=="Весь период.")
{
	запрос_статистика= ` WITH 
      stat AS (select  CAST ((date_part('YEAR', begin_date)) AS integer) AS year,vid,ks,CAST (unit AS integer)  AS unit  FROM pohod`;
      if (b_kod || b_org ||  b_terr )   запрос_статистика ~=` WHERE `;
      if (b_kod) 
            { запрос_статистика ~=` kod_mkk ILIKE '%`~ kod ~`%'`;      
                if (b_org ||  b_terr ) запрос_статистика ~=` AND `;
            }
              
       if (b_org) 
             {запрос_статистика ~=` organization ILIKE '%`~ org ~`%'`;
                 if (b_terr ) запрос_статистика ~=` AND `;
              }
                 
       if (b_terr ) запрос_статистика ~=` region_group ILIKE '%`~ terr ~`%'`;           
     
     запрос_статистика ~=` ORDER BY year ),

      st1 AS ( SELECT year, 
                                COALESCE(  CAST(count(unit) AS VARCHAR)  ||  '('|| 
                                CAST(sum (unit)  AS VARCHAR)  ||  ')'
                             ) AS un_1   FROM stat  WHERE  vid=1  GROUP BY year ORDER BY year  ),

st2 AS ( SELECT year,
   COALESCE(  CAST(count(unit) AS VARCHAR)  ||  '('|| 
                                CAST(sum (unit)  AS VARCHAR)  ||  ')'
 )    AS un_2   FROM stat  WHERE  vid=2  GROUP BY year ORDER BY year ),
 st3 AS ( SELECT year,
   COALESCE(  CAST(count(unit) AS VARCHAR)  ||  '('|| 
                                CAST(sum (unit)  AS VARCHAR)  ||  ')'
 )    AS un_3   FROM stat  WHERE  vid=3  GROUP BY year ORDER BY year  ),
 st4 AS ( SELECT year,
  COALESCE(  CAST(count(unit) AS VARCHAR)  ||  '('|| 
                                CAST(sum (unit)  AS VARCHAR)  ||  ')'
 )    AS un_4   FROM stat  WHERE  vid=4  GROUP BY year ORDER BY year  ),
st5 AS ( SELECT year,
   COALESCE(  CAST(count(unit) AS VARCHAR)  ||  '('|| 
                                CAST(sum (unit)  AS VARCHAR)  ||  ')'
 )    AS un_5   FROM stat  WHERE  vid=5  GROUP BY year ORDER BY year  ),
 st6 AS ( SELECT year,
   COALESCE(  CAST(count(unit) AS VARCHAR)  ||  '('|| 
                                CAST(sum (unit)  AS VARCHAR)  ||  ')'
  )   AS un_6   FROM stat  WHERE  vid=6  GROUP BY year ORDER BY year  ),


st7 AS ( SELECT year,
  COALESCE(  CAST(count(unit) AS VARCHAR)  ||  '('|| 
                                CAST(sum (unit)  AS VARCHAR)  ||  ')'
 )    AS un_7   FROM stat  WHERE  vid=7  GROUP BY year ORDER BY year  ),

st8 AS ( SELECT year,
  COALESCE(  CAST(count(unit) AS VARCHAR)  ||  '('|| 
                                CAST(sum (unit)  AS VARCHAR)  ||  ')'
 )    AS un_8  FROM stat  WHERE  vid=8 GROUP BY year ORDER BY year  ),

 st9 AS ( SELECT year,
  COALESCE(  CAST(count(unit) AS VARCHAR)  ||  '('|| 
                                CAST(sum (unit)  AS VARCHAR)  ||  ')'
 )    AS un_9   FROM stat  WHERE  vid=9  GROUP BY year ORDER BY year  ),

st10 AS ( SELECT year,
  COALESCE(  CAST(count(unit) AS VARCHAR)  ||  '('|| 
                                CAST(sum (unit)  AS VARCHAR)  ||  ')'
 )    AS un_10   FROM stat  WHERE  vid=10  GROUP BY year ORDER BY year  ),



 всего AS ( SELECT year,
  COALESCE(  CAST(count(unit) AS VARCHAR)  ||  '('|| 
                                CAST(sum (unit)  AS VARCHAR)  ||  ')'
 )    AS un_всего   FROM stat GROUP BY year ORDER BY year )

SELECT
всего.year,
 
 
 un_1,
 un_2,
 un_3,
 un_4,
 un_5,
 un_6,
 un_7,
 un_8,
 un_9,
 un_10,

un_всего 


 FROM  всего

  LEFT JOIN st1 ON всего.year   = st1.year
  LEFT JOIN st2 ON всего.year   = st2.year
  LEFT JOIN st3 ON всего.year   = st3.year
  LEFT JOIN st4 ON всего.year   = st4.year
  LEFT JOIN st5 ON всего.year  = st5.year
  LEFT JOIN st6 ON всего.year  = st6.year
  LEFT JOIN st7 ON всего.year  = st7.year
  LEFT JOIN st8 ON всего.year  = st8.year
  LEFT JOIN st9 ON всего.year  = st9.year
  LEFT JOIN st10 ON всего.year  = st10.year `;
}
     //-----конец -- Весь период---
     
     
   //  --------За год-----------
   
  
   
  if( prezent_vid=="За год.")
{
   запрос_статистика= `
   
   WITH stat_by_year AS (
    SELECT CAST(unit AS integer) AS unit,vid,ks
    FROM pohod 
    WHERE (date_part('YEAR', begin_date)=`~year~` )     
    `;   
    
  if (b_kod) 
            { запрос_статистика ~=` AND  kod_mkk ILIKE '%`~ kod ~`%' `;      
               // if (b_org ||  b_terr ) запрос_статистика ~=` AND `;
            }
              
       if (b_org) 
             {запрос_статистика ~=`  AND  organization ILIKE '%`~ org ~`%'`;
               //  if (b_terr ) запрос_статистика ~=` AND `;
              }
                 
       if (b_terr ) 
              запрос_статистика ~=`  AND  region_group ILIKE '%`~ terr ~`%'`;         
    
             // запрос_статистика ~= ` AND  (date_part('YEAR', begin_date)=2000` ;
              
    
 запрос_статистика~= ` ) ,`;
 
 
запрос_статистика~= `



ks0 AS ( SELECT vid,count(unit) AS gr_ks0,sum (unit)    AS un_ks0   FROM stat_by_year  WHERE  (ks=0 OR ks=9 )GROUP BY vid ORDER BY vid  ),
 ks1 AS ( SELECT vid,count(unit) AS gr_ks1,sum (unit)    AS un_ks1   FROM stat_by_year  WHERE  ks=1  GROUP BY vid ORDER BY vid  ),
 ks2 AS ( SELECT vid,count(unit) AS gr_ks2,sum (unit)    AS un_ks2   FROM stat_by_year  WHERE  ks=2  GROUP BY vid ORDER BY vid  ),
 ks3 AS ( SELECT vid,count(unit) AS gr_ks3,sum (unit)    AS un_ks3   FROM stat_by_year  WHERE  ks=3  GROUP BY vid ORDER BY vid  ),
 ks4 AS ( SELECT vid,count(unit) AS gr_ks4,sum (unit)    AS un_ks4   FROM stat_by_year  WHERE  ks=4  GROUP BY vid ORDER BY vid  ),
 ks5 AS ( SELECT vid,count(unit) AS gr_ks5,sum (unit)    AS un_ks5   FROM stat_by_year  WHERE  ks=5  GROUP BY vid ORDER BY vid  ),
 ks6 AS ( SELECT vid,count(unit) AS gr_ks6,sum (unit)    AS un_ks6   FROM stat_by_year  WHERE  ks=6  GROUP BY vid ORDER BY vid  ),
 put AS ( SELECT vid,count(unit) AS gr_put,sum (unit)    AS un_put   FROM stat_by_year  WHERE  ks=7  GROUP BY vid ORDER BY vid  ),
 всего  AS ( 
    SELECT vid,count(unit) AS gr_всего,sum (unit)    AS un_всего   FROM stat_by_year GROUP BY vid ORDER BY vid ),


st AS (
SELECT
всего.vid,
gr_ks0, un_ks0,
gr_ks1, un_ks1,
gr_ks2, un_ks2,
gr_ks3, un_ks3,
gr_ks4, un_ks4,
gr_ks5, un_ks5,
gr_ks6, un_ks6,
gr_put, un_put,
gr_всего, un_всего 

 FROM  всего
  LEFT JOIN ks0 ON всего.vid   = ks0.vid
  LEFT JOIN ks1 ON всего.vid   = ks1.vid
  LEFT JOIN ks2 ON всего.vid   = ks2.vid
  LEFT JOIN ks3 ON всего.vid   = ks3.vid
  LEFT JOIN ks4 ON всего.vid   = ks4.vid
  LEFT JOIN ks5 ON всего.vid   = ks5.vid
  LEFT JOIN ks6 ON всего.vid   = ks6.vid
  LEFT JOIN put ON всего.vid   = put.vid
),

st1 AS ( 
    SELECT 11 AS vid,
    sum(gr_ks0) AS gr_ks0,      sum(un_ks0)   AS  un_ks0,
    sum(gr_ks1) AS gr_ks1,      sum(un_ks1)   AS  un_ks1,
    sum(gr_ks2) AS gr_ks2,      sum(un_ks2)   AS  un_ks2,
    sum(gr_ks3) AS gr_ks3,      sum(un_ks3)   AS  un_ks3,
    sum(gr_ks4) AS gr_ks4,      sum(un_ks4)   AS  un_ks4,
    sum(gr_ks5) AS gr_ks5,      sum(un_ks5)   AS  un_ks5,
    sum(gr_ks6) AS gr_ks6,      sum(un_ks6)   AS  un_ks6,
    sum(gr_put) AS gr_put,      sum(un_put)   AS  un_put,
    sum(gr_всего) AS gr_всего,  sum(un_всего) AS  un_всего    
    FROM st ),

st2 AS (
  (SELECT vid,
      COALESCE( CAST(gr_ks0 AS VARCHAR)  ||'('  || CAST(un_ks0 AS VARCHAR )  ||  ')') AS ks0,
      COALESCE( CAST(gr_ks1 AS VARCHAR)  ||'('  || CAST(un_ks1 AS VARCHAR )  ||  ')') AS ks1,
      COALESCE( CAST(gr_ks2 AS VARCHAR)  ||'('  || CAST(un_ks2 AS VARCHAR )  ||  ')') AS ks2,
      COALESCE( CAST(gr_ks3 AS VARCHAR)  ||'('  || CAST(un_ks3  AS VARCHAR)  ||  ')') AS ks3,
      COALESCE( CAST(gr_ks4 AS VARCHAR)  ||'('  || CAST(un_ks4 AS VARCHAR )  ||  ')') AS ks4,
      COALESCE( CAST(gr_ks5 AS VARCHAR)  ||'('  || CAST(un_ks5 AS VARCHAR )  ||  ')') AS ks5,
      COALESCE( CAST(gr_ks6 AS VARCHAR)  ||'('  || CAST(un_ks6 AS VARCHAR )  ||  ')') AS ks6,
      COALESCE( CAST(gr_put AS VARCHAR)  ||'('  || CAST(un_put  AS VARCHAR)  ||  ')') AS put,
      COALESCE( CAST(gr_всего AS VARCHAR)||'('  || CAST(un_всего AS VARCHAR) ||  ')') AS всего
               FROM  st  )

  UNION 

  (SELECT vid,
      COALESCE( CAST(gr_ks0 AS VARCHAR)  ||'('  || CAST(un_ks0 AS VARCHAR )  ||  ')') AS ks0,
      COALESCE( CAST(gr_ks1 AS VARCHAR)  ||'('  || CAST(un_ks1 AS VARCHAR )  ||  ')') AS ks1,
      COALESCE( CAST(gr_ks2 AS VARCHAR)  ||'('  || CAST(un_ks2 AS VARCHAR )  ||  ')') AS ks2,
      COALESCE( CAST(gr_ks3 AS VARCHAR)  ||'('  || CAST(un_ks3  AS VARCHAR)  ||  ')') AS ks3,
      COALESCE( CAST(gr_ks4 AS VARCHAR)  ||'('  || CAST(un_ks4 AS VARCHAR )  ||  ')') AS ks4,
      COALESCE( CAST(gr_ks5 AS VARCHAR)  ||'('  || CAST(un_ks5 AS VARCHAR )  ||  ')') AS ks5,
      COALESCE( CAST(gr_ks6 AS VARCHAR)  ||'('  || CAST(un_ks6 AS VARCHAR )  ||  ')') AS ks6,
      COALESCE( CAST(gr_put AS VARCHAR)  ||'('  || CAST(un_put  AS VARCHAR)  ||  ')') AS put,
      COALESCE( CAST(gr_всего AS VARCHAR)||'('  || CAST(un_всего AS VARCHAR) ||  ')') AS всего

              FROM  st1 )

              )

SELECT*FROM st2 ORDER BY vid 
  
  
  `;
  
  
} 
  

   //-----конец --За год
     
     
     
      IBaseRecordSet rs;
      
   if( prezent_vid=="Весь период.")  rs = dbase.query(запрос_статистика).getRecordSet(statRecFormatVid);
   if( prezent_vid=="За год.")       rs = dbase.query(запрос_статистика).getRecordSet(statRecFormatKC);
   
  /* auto q_res = dbase.query(запрос_статистика);
   for( size_t i = 0; i < q_res.recordCount; ++i )
   {
		for( size_t j = 0; j < q_res.fieldCount; ++j )
		{
			std.stdio.write( q_res.get(j, i), "; " );
		}
		std.stdio.writeln();
   }*/
   
   
//writeln(rs.getStr);
      
  //--------проверка пустых столбцов------------------------ 

   foreach(k;заголовок.byKey())
	  {
	   string kl;
	   for( size_t i = 0; i < rs.length; ++i  )
	   {  
			kl ~= rs[i].getStr(k, "");
		}
   	//foreach(rec; rs) kl~=rec.getStr(k, "");;
   	if(kl=="") заголовок[k]=false;
	
	  }
  
   
   
  //---------заголовок таблицы -------------------------------------- 
   
   
   table~=`<table class="tab1" >`;
   table~=`<tr>`;
  
    
    foreach(td; групп_человек)
     {
      if(заголовок[td]) table     ~=`<td>`~td~`</td>`~ "\r\n";
      
     }   
 
    
  table ~=` </tr>

 `;
   //-----------------------------------------------
  for( size_t i = 0; i < rs.length; ++i  )//формирование ячеек таблицы
  {
  table ~= `<tr>`;
      foreach(v,td; групп_человек)
      {
      if(v==0  &&  prezent_vid=="Весь период." )
              table ~= `<td>` ~rs[i].getStr(td, "-") ~ `</td>`~ "\r\n" ;
   
      if(v==0  &&  prezent_vid=="За год.")
              table ~= `<td>`
               ~  вид [ rs[i].getStr(td, "").to!int ]~ `</td>`~ "\r\n" ;
              
      if(заголовок[td] && v!=0) table ~= `<td>` ~rs[i].getStr(td, "-") ~ `</td>`~ "\r\n";
      }
  table ~= `</tr>`~ "\r\n";
  }
  
  table ~=` </table>`; 
  //---------------------------------------------------
content ~=`<form id="main_form" method="post">`
//--блок переключения вида
~`<fieldset>`;  

 if (isForPrint)
  {
     if(prezent_vid=="Весь период.") content ~=`Весь период.`;
     if(prezent_vid=="За год.") content ~=`За `~year~` год.`;
      content ~=`<div  class="no_print">`; 
   } 
  else content~=`<div >`;
  
    foreach(d; prezent)
    {
        content ~=`<input  type="radio"    
        name="prezent_vid" value="`~ d ~`"`;
        if(d==prezent_vid) content ~=`  checked `;
        content ~= `>`~d;
    } 
 content ~=`</div> </fieldset> `;
   
 // блок фильтров   
 
 
  content ~=`<fieldset>`;
   if(!isForPrint || kod~org~terr!=``)  content ~=`<legend>Фильтры</legend>`;
  
   if (isForPrint)
   {
       if (kod!=`` ) content ~=`Код МКК `~ kod~`<br/>`; 
       if (org!=`` )content ~=`Организация `~ org~`<br/>`;
       if (terr!=``)content ~=`Территория `~terr;
   
    content ~=`<div  class="no_print">`; 
   }
   else content~=`<div >`;
   
  content ~=`<input type="text" name="kod_MKK"  size="6"  value="`
  ~  HTMLEscapeValue( rq.bodyForm.get("kod_MKK", "176-00") ) 
  ~ `" > 
                                 код МКК (176-00, 000-00, и т.п.)<br/>`
  ~`<input type="text" name="organization" size="12" value="`
  ~HTMLEscapeValue( rq.bodyForm.get("organization", "") )
  ~ `"  >
                                  организация<br/>`
  ~`<input type="text" name="territory"  size="12"value="`
  ~HTMLEscapeValue( rq.bodyForm.get("territory", "") )
  ~`"  > 
                                  территория ( Ярославль, Тутаев, Москва, и т.п.) <br/>`;
                                  
   if(prezent_vid=="За год.")                              
  content ~=`<input type="text" name="year"  size="4" value="`                               
  ~HTMLEscapeValue( rq.bodyForm.get("year", "2000") )
  ~`"  > 
                                 год <br/>`;                                 
                                
content ~=`</div></fieldset><br/>`;

   if (isForPrint)
	{
	 content ~=` <a href='javascript:window.print(); void 0;' class="noprint" > <img  height="60" width="60"  class="noprint"   src="/pub/img/icons/printer.png" /></a> <!-- печать страницы -->`
	 ~ "\r\n" ;}
	 else content ~=`<button  name="filtr" type="submit" class="noprint" > Обновить </button>`;
content ~= `&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`;

   if (isForPrint)//для печати
	      {content ~=` <button name="for_print" type="submit"  class="noprint" > Назад </button>`;}
	 else	     
	    { content ~=` <button name="for_print" type="submit"  value="on"  > Для печати </button>`;}
 content ~= `</form>` ~ "\r\n";
 content~= table;
 content~=`<canvas width="300" height="225"></canvas>`~ "\r\n";
 
	return content;
}
