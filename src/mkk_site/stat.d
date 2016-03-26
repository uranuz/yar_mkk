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
 content ~=  ` <p><a href="/pub/stati_dokument/stat1992_2010.rar"   > Отчёты за 1992-2010 годы (zip) </a></p> `~ "\r\n";

import std.typecons;
	
   ///Начинаем оформлять таблицу с данными
   static immutable statRecFormatVid = RecordFormat!(
		PrimaryKey!(string), "Год", 		 
		string,"gr_1",     string,"un_1",
		string,"gr_2",     string,"un_2",
		string,"gr_3",     string,"un_3",
		string,"gr_4",     string,"un_4",
		string,"gr_5",     string,"un_5",
		string,"gr_6",     string,"un_6",
		string,"gr_7",     string,"un_7",
		string,"gr_8",     string,"un_8",
		string,"gr_9",     string,"un_9",
		string,"gr_10",    string,"un_10",
		string,"gr_всего", string,"un_всего"
		
	)(		null,	tuple()	);
	 
	 static immutable statRecFormatKC = RecordFormat!(
		PrimaryKey!(string), "Вид/КС",
		string,"gr_0",     string,"un_0",
		string,"gr_1",     string,"un_1",
		string,"gr_2",     string,"un_2",
		string,"gr_3",     string,"un_3",
		string,"gr_4",     string,"un_4",
		string,"gr_5",     string,"un_5",
		string,"gr_6",     string,"un_6",
		string,"gr_7",     string,"un_7",		
		string,"gr_всего", string,"un_всего"		
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
  string [] заголовок;
  bool[] bool_заголовок;
  size_t колонок;
  size_t строк;
  string [] вид= ["Вид/к.с.","Пешый","Лыжный","Горный","Водный"," Вело ",	" Авто ", "Спелео","Парус",  "Конный", "Комби",	"ВСЕГО"];
  
   if( prezent_vid=="Весь период.")
   { групп_человек=statRecFormatVid.names.dup;
   заголовок = ["Год","Пешый","Лыжный","Горный","Водный"," Вело ",
                " Авто ", "Спелео","Парус","Конный","Комби","ВСЕГО"];
     bool_заголовок= 
	[true,true,true,true,true,true,      
	true,true,true,true,true,true
	] ;
	колонок=12;
	}
   
	if( prezent_vid=="За год.")  
	{ групп_человек=statRecFormatKC.names.dup;
	  заголовок = ["Вид/к.с.","н.к.","Первая","Вторая","Третья",
	               "Четвёртая","Пятая","Шестая","Путеш.","ВСЕГО"];
		bool_заголовок=
	  [true,true,true,true,true,
	   true,true,true,true,true];
	  колонок=10;
	}
 //writeln(групп_человек);
   if(kod!="")  b_kod= true;
   if(org!="")  b_org= true;
   if(terr!="") b_terr=true;
 
	string запрос_статистика;
	///////---запрос--Весь период---------
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
     
     запрос_статистика ~=` ORDER BY year ),`;

  
 for (int i=1;i<11;i++ )
  {
    запрос_статистика ~=` st`~ i.to!string 
        ~` AS ( SELECT year, count(unit) AS gr_` ~ i.to!string
        ~`,   sum (unit)    AS un_` ~i.to!string
        ~`  FROM stat  WHERE  vid=` ~i.to!string 
        ~` GROUP BY year ORDER BY year  ),`;
  }

запрос_статистика ~=`
 всего AS ( SELECT year, count(unit) AS gr_всего ,  sum (unit)  AS un_всего 
              FROM stat GROUP BY year ORDER BY year )

SELECT
всего.year, 
 gr_1, un_1,
 gr_2, un_2,
 gr_3, un_3,
 gr_4, un_4,
 gr_5, un_5,
 gr_6, un_6,
 gr_7, un_7,
 gr_8, un_8,
 gr_9, un_9,
gr_10,un_10,
gr_всего, un_всего 
              FROM  всего

  LEFT JOIN st1 ON всего.year   = st1.year
  LEFT JOIN st2 ON всего.year   = st2.year
  LEFT JOIN st3 ON всего.year   = st3.year
  LEFT JOIN st4 ON всего.year   = st4.year
  LEFT JOIN st5 ON всего.year   = st5.year
  LEFT JOIN st6 ON всего.year   = st6.year
  LEFT JOIN st7 ON всего.year   = st7.year
  LEFT JOIN st8 ON всего.year   = st8.year
  LEFT JOIN st9 ON всего.year   = st9.year
  LEFT JOIN st10 ON всего.year  = st10.year `;
}
     //-----конец -запроса-- Весь период---
     
     
   //  ----запрос----За год-----------
    
 
   
  if( prezent_vid=="За год.")
{
   запрос_статистика= `
   
   WITH stat_by_year AS (
    SELECT CAST(unit AS integer) AS unit,vid,ks
    FROM pohod 
    WHERE (date_part('YEAR', begin_date)=`~year~` )     
    `;   
    
   if (b_kod) 
             запрос_статистика ~=` AND  kod_mkk ILIKE '%`~ kod ~`%' `;            
           
              
    if (b_org) 
             запрос_статистика ~=`  AND  organization ILIKE '%`~ org ~`%'`;             
              
                 
     if (b_terr ) 
              запрос_статистика ~=`  AND  region_group ILIKE '%`~ terr ~`%'`;         
    
                          
    
 запрос_статистика~= ` ) ,`;
 

запрос_статистика~= `

 ks0 AS ( SELECT vid,count(unit) AS gr_0,  sum (unit)  AS un_0      FROM stat_by_year  WHERE  (ks=0 OR ks=9 )GROUP BY vid ORDER BY vid  ),
 ks1 AS ( SELECT vid,count(unit) AS gr_1,  sum (unit)  AS un_1      FROM stat_by_year  WHERE  ks=1  GROUP BY vid ORDER BY vid  ),
 ks2 AS ( SELECT vid,count(unit) AS gr_2,  sum (unit)  AS un_2      FROM stat_by_year  WHERE  ks=2  GROUP BY vid ORDER BY vid  ),
 ks3 AS ( SELECT vid,count(unit) AS gr_3,  sum (unit)  AS un_3      FROM stat_by_year  WHERE  ks=3  GROUP BY vid ORDER BY vid  ),              
 ks4 AS ( SELECT vid,count(unit) AS gr_4,  sum (unit)  AS un_4      FROM stat_by_year  WHERE  ks=4  GROUP BY vid ORDER BY vid  ),              
 ks5 AS ( SELECT vid,count(unit) AS gr_5,  sum (unit)  AS un_5      FROM stat_by_year  WHERE  ks=5  GROUP BY vid ORDER BY vid  ),
 ks6 AS ( SELECT vid,count(unit) AS gr_6,  sum (unit)  AS un_6      FROM stat_by_year  WHERE  ks=6  GROUP BY vid ORDER BY vid  ),
 put AS ( SELECT vid,count(unit) AS gr_7,  sum (unit)  AS un_7      FROM stat_by_year  WHERE  (ks=7 OR ks is NULL)  GROUP BY vid ORDER BY vid  ),
 всего AS ( SELECT vid,count(unit) AS gr_всего,sum (unit)  AS un_всего  
                                                                    FROM stat_by_year GROUP BY vid ORDER BY vid ),
              
st AS (
SELECT
всего.vid, 
gr_0, un_0,
gr_1, un_1,
gr_2, un_2,
gr_3, un_3,
gr_4, un_4,
gr_5, un_5,
gr_6, un_6,
gr_7, un_7,
gr_всего,un_всего 
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
    sum(gr_0) AS gr_s0,      sum(un_0)   AS  un_s0,
    sum(gr_1) AS gr_s1,      sum(un_1)   AS  un_s1,
    sum(gr_2) AS gr_s2,      sum(un_2)   AS  un_s2,
    sum(gr_3) AS gr_s3,      sum(un_3)   AS  un_s3,
    sum(gr_4) AS gr_s4,      sum(un_4)   AS  un_s4,
    sum(gr_5) AS gr_s5,      sum(un_5)   AS  un_s5,
    sum(gr_6) AS gr_s6,      sum(un_6)   AS  un_s6,
    sum(gr_7) AS gr_put,     sum(un_7)   AS  un_put,
    sum(gr_всего) AS gr_всего,  sum(un_всего) AS  un_всего    
    FROM st ),

 st2 AS ( SELECT*FROM st UNION  SELECT*FROM st1 )

SELECT*FROM st2 ORDER BY vid    
  
  `;
  
  
} 
  

   //-----конец -запроса--За год   
  
     
      IBaseRecordSet rs;
      
   if( prezent_vid=="Весь период.")  rs = dbase.query(запрос_статистика).getRecordSet(statRecFormatVid);
   if( prezent_vid=="За год.")       rs = dbase.query(запрос_статистика).getRecordSet(statRecFormatKC);
   
 

// --формируем исходные матрицы------///////////

bool parity;
строк = rs.length;

 // writeln(rs.length);
string [][] for_tabl;   // массив данных для таблицы
	for( size_t i = 0; i < строк; i++  )//формирование ячеек таблицы
	{
			auto rec = rs[i];
			string[] line;
			line.length = колонок;
			 parity=false;
			 string resurs;

			foreach(v,td; групп_человек)
			{
			 			  
					if(v==0  &&  prezent_vid=="Весь период.")
							line[v]= rec.getStr(td, "");

					if(v==0  &&  prezent_vid=="За год.")
							line[v]=  вид [ rec.getStr(td, "").to!int ];

					if(v!=0)
					{   
							if(parity  ) 
							  resurs= rec.getStr(td, "").to!string;
							  
							if(!parity && rec.getStr(td, "") != "" ) 
							  line[(v)/2]~=resurs~ `(`~rec.getStr(td, "")~`)`;

							
					}
             parity=!parity;
			} 


			for_tabl~=line;
  }
  writeln(for_tabl);

      
  //--------проверка пустых столбцов------------------------ position 

  
  for( size_t j = 0; j< bool_заголовок.length; j++  )
	  {
	 
	   string kl;
	   for( size_t i = 0; i < строк; i++  )
			{  		
				kl ~= for_tabl[i][j];			
			}
   	
   	if(kl=="") bool_заголовок[j]=false;	
	  }
	
  //string []заг;   foreach(td;  bool_заголовок){ if(td)заг~="true"; else заг~="false";}   writeln( заг);
  
  

  //---------заголовок таблицы -------------------------------------- 
   
   
   table~=`<table class="tab1" >`;
   table~=`<tr>`;
  
    
    foreach(v,td; заголовок)
     {
      if(bool_заголовок[v]) table     ~=`<td>`~td~`</td>`~ "\r\n";
      
     }   
 
    
  table ~=` </tr> `;
   //-----------------------------------------------
  
  for( size_t i = 0; i < строк; i++ )//формирование ячеек таблицы
  {
  table ~= `<tr>`;
     
      for( size_t v = 0; v < колонок; ++v )
      {
      if(v==0  )
     
              table ~= `<td>` ~ for_tabl[i][v] ~ `</td>`~ "\r\n" ; 
             
      if(bool_заголовок[v] && v!=0) table ~= `<td>` ~for_tabl[i][v] ~ `</td>`~ "\r\n";
   
      }
  table ~= `</tr>`~ "\r\n";  }  
    
  table ~=` </table>`; // writeln(table);
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
  ~ `" >  код МКК (176-00, 000-00, и т.п.)<br/>`
  
  ~`<input type="text" name="organization" size="12" value="`
  ~HTMLEscapeValue( rq.bodyForm.get("organization", "") )
  ~ `"  >   организация<br/>`
  
  ~`<input type="text" name="territory"  size="12"value="`
  ~HTMLEscapeValue( rq.bodyForm.get("territory", "") )
  ~`"  >  территория ( Ярославль, Тутаев, Москва, и т.п.) <br/>`;
                                  
   if(prezent_vid=="За год.")                              
  content ~=`<input type="text" name="year"  size="4" value="`                               
  ~HTMLEscapeValue( rq.bodyForm.get("year", "2016") )
  ~`"  >  год <br/>`;                                 
                                
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
 
 
	return content;
}
