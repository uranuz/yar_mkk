module mkk_site.main_service.stat;
import mkk_site.main_service.devkit;
import mkk_site.site_data;
import mkk_site.data_defs.stat;

import std.conv, std.string, std.utf;
import std.stdio;
import std.typecons;
import std.datetime;
import std.typecons: tuple;
import std.json;



//***********************Обявление метода*******************
shared static this()
{
	Service.JSON_RPCRouter.join!(statData)(`stat.Data`);
}
//**********************************************************



auto statData //начало основной функции////////////////
 (HTTPContext context,StatSelect select)
  
 {   
	 
						//AliasSeq aliasSeqOf ###################
				import std.meta;//staticMap
				import std.range;//iota
				static immutable string[] prezent = [ "Год","Вид/КС" ];
				static immutable size_t[] number_lines = [12,10];

				template FieldPairFormat(size_t index) {
					alias FieldPairFormat = AliasSeq!(
						size_t, "gr_" ~ index.to!string,
						size_t, "un_" ~ index.to!string
					);
				}
				alias GeneralFormat(size_t count, string keyField) = RecordFormat!(
					PrimaryKey!(string), keyField,
					staticMap!(FieldPairFormat, aliasSeqOf!(iota(count)))
				);
				//-- формальные шаблоны данных
				static immutable statRecFormatVid = GeneralFormat!(11, "Год")( null, tuple() );
				static immutable statRecFormatKC = GeneralFormat!(9, "Вид/КС")( null, tuple() );
				//#############################################

		if(!select.beginYear.length) select.beginYear="1992";
		if(!select.endYear.length)  select.endYear=  Clock.currTime().year.text; 
	
	 	//***********************************
	string[] групп_человек;	 
	string[] заголовок;
	bool[] bool_заголовок;
	size_t колонок;
	size_t строк;
	


	if( select.conduct == 0 )
	{
		заголовок = [
			"Год", "","Пеший", "","Лыжный","", "Горный","", "Водный", "","Вело",
			"","Авто", "","Спелео", "","Парус", "","Конный","", "Комби","", "ВСЕГО"
		];
		колонок = 23;
	}

	if( select.conduct == 1 )
	{
		заголовок = [
			"Вид/ к.с.", "","н.к.", "","Первая","", "Вторая", "","Третья",
			"","Четвёртая","", "Пятая", "","Шестая", "","Путеш.", "","ВСЕГО"
		];
		колонок = 19;
	}

		bool_заголовок.length = колонок;
		bool_заголовок[]= true;


		bool b_kod = false, b_org = false, b_terr = false;
			if(select.kodMKK.length) b_kod = true;
			if(select.organization.length) b_org = true;
			if(select.territory.length) b_terr = true;

		//tpl.set( "skript_Neim", "stat_all.js");


	string запрос_статистика;
		//---запрос--по годам-----VID----
	if( select.conduct == 0 )
	{
		запрос_статистика =
			` WITH stat AS (select  CAST ((date_part('YEAR', begin_date)) AS integer) AS year,vid,ks,CAST (unit AS integer)  AS unit  FROM pohod `;
		if( b_kod || b_org ||  b_terr )
			запрос_статистика ~= ` WHERE `;
		if( b_kod )
		{
			запрос_статистика ~= ` kod_mkk ILIKE '%` ~ select.kodMKK ~ `%'`;
			if( b_org || b_terr )
				запрос_статистика ~= ` AND `;
		}

		if( b_org )
		{
			запрос_статистика ~= ` organization ILIKE '%` ~ select.organization~ `%'`;
			if( b_terr )
				запрос_статистика ~= ` AND `;
		}

		if( b_terr )
			запрос_статистика ~= ` region_group ILIKE '%` ~ select.territory ~ `%'`;

		запрос_статистика ~= ` ORDER BY year ),`;

		for( int i = 1; i < 11; i++ )
		{
			запрос_статистика ~= `
			 st` ~ i.to!string
				~ ` AS ( SELECT year, count(unit) AS gr_` ~ i.to!string
				~ `,   sum (unit)    AS un_` ~i.to!string
				~ `  FROM stat  WHERE  vid=` ~i.to!string
				~ ` GROUP BY year ORDER BY year  ),`;
		}

				запрос_статистика ~= `
				всего AS ( SELECT year, count(unit) AS gr_всего ,  sum (unit)  AS un_всего
								FROM stat GROUP BY year ORDER BY year ),

				st AS (SELECT
				всего.year,`; 

	       foreach(size_t n; 1.. 11)
			 запрос_статистика ~= ` 
				gr_` ~n.to!string~`, un_`~n.to!string~`,`;

			запрос_статистика ~= `				
				gr_всего,un_всего 
 				FROM  всего	`;

				  foreach(size_t n; 1.. 11)
			запрос_статистика ~= `		
    LEFT JOIN st`~n.to!string~` ON всего.year   = st`~n.to!string~`.year `;
 
 запрос_статистика ~= ` 
),

st100 AS ( 
    SELECT null::integer AS vid, `;

	 foreach(size_t n; 1.. 11)
	 запрос_статистика ~= `	    
    sum(gr_`~n.to!string~`) AS gr_s`
				~n.to!string~`,      sum(un_`
				~n.to!string~`)   AS  un_s`
				~n.to!string~`,`;

     запрос_статистика ~= `	 
    sum(gr_всего) AS gr_всего,  sum(un_всего) AS  un_всего    
    FROM st ),

 st200 AS ( SELECT*FROM st UNION  SELECT*FROM st100 )
SELECT*FROM st200 ORDER BY year nulls last			`;



			

			


	}
	//-----конец -запроса-- по годам--VID-

	//  ----запрос----"по КС"-----------
	if( select.conduct == 1 )
	{
		запрос_статистика = `
		WITH stat_by_year AS (
		SELECT CAST(unit AS integer) AS unit,vid,ks
		FROM pohod
		WHERE
			(date_part('YEAR', begin_date)>=` ~ select.beginYear
		~` AND
			date_part('YEAR', begin_date)<=` ~ select.endYear ~`)`;
		if( b_kod )
			запрос_статистика ~= `
			 AND  kod_mkk ILIKE '%` ~ select.kodMKK ~ `%' `;

		if( b_org )
			запрос_статистика ~= `
			  AND  organization ILIKE '%` ~ select.organization ~ `%'`;

		if( b_terr )
			запрос_статистика ~= `
			  AND  region_group ILIKE '%` ~ select.territory ~ `%'`;

		запрос_статистика ~= ` ) ,`;
		

        запрос_статистика ~= `
			  ks0 AS ( SELECT vid,count(unit) AS gr_0,  sum (unit)  AS un_0   FROM stat_by_year  WHERE  (ks=0 OR ks=9 )GROUP BY vid ORDER BY vid  ),`;
			foreach(size_t n; 1.. 7) 
				запрос_статистика ~= `
					ks`~n.to!string~` AS ( SELECT vid,count(unit) AS gr_`
										~ n.to!string~`,  sum (unit)  AS un_`
										~ n.to!string~`  FROM stat_by_year  WHERE  ks=`
										~ n.to!string~`  GROUP BY vid ORDER BY vid  ),`;
			запрос_статистика ~= `
			put AS ( SELECT vid,count(unit) AS gr_7,  sum (unit)  AS un_7
			      FROM stat_by_year  WHERE  (ks=7 OR ks is NULL)  GROUP BY vid ORDER BY vid  ),
			всего AS ( SELECT vid,count(unit) AS gr_всего,sum (unit)  AS un_всего
			FROM stat_by_year GROUP BY vid ORDER BY vid ),
			st AS (
			SELECT
			всего.vid,`; 
			foreach(size_t n; 0.. 8)
				запрос_статистика ~= `	
				gr_`~n.to!string~`, un_`~ n.to!string~`,`;
			
			запрос_статистика ~= `
			gr_всего,un_всего 
						FROM  всего `;

			foreach(size_t n; 0.. 7)
				запрос_статистика ~= `	 
				LEFT JOIN ks`~n.to!string~` ON всего.vid   = ks`~ n.to!string~`.vid `;

				запрос_статистика ~= `
			LEFT JOIN put ON всего.vid   = put.vid
			),
			st1 AS ( 
				SELECT 11 AS vid,`;
				запрос_статистика ~= `
				`;

				foreach(size_t n; 0.. 7)
				запрос_статистика ~= `		
				sum(gr_`~n.to!string~`) AS gr_s`
														~n.to!string~`,  sum(un_`
														~n.to!string~`)   AS  un_s`
														~n.to!string~`,`;

				запрос_статистика ~= `
				sum(gr_7) AS gr_put,     sum(un_7)   AS  un_put,
				sum(gr_всего) AS gr_всего,  sum(un_всего) AS  un_всего    
				FROM st ),

			st2 AS ( SELECT*FROM st UNION  SELECT*FROM st1 )
			SELECT*FROM st2 ORDER BY vid
			`;
}

	//-----конец -запроса--"по КС"



	auto dbase = getCommonDB(); //Подключение к базе

	IDBQueryResult rs;

	if( select.conduct == 0 )
		rs = dbase.query(запрос_статистика);//.getRecordSet(statRecFormatVid);
	if( select.conduct == 1  )
		rs = dbase.query(запрос_статистика);//.getRecordSet(statRecFormatKC);
	//*******************************************

	
		// --формируем исходные матрицы------///////////
		string[string] вид = [
		"0":"Вид/ к.с.", "1":"Пеший","2": "Лыжный", "3":"Горный","4": "Водный", "5":"Вело",
		"6":"Авто", "7":"Спелео","8": "Парус", "9":"Конный","19": "Комби", "11":"ВСЕГО"
	];


	bool parity;
	//строк = rs.length;
	
	string[][] for_all;   //обобщённый массив данных 
//----------------------

for_all.length = rs.recordCount+1;//строк втаблице 

// --первая строка
string[] pref_data_array;
//pref_data_array.length = rs.fieldCount;
pref_data_array.length = колонок;
pref_data_array = заголовок;
for_all[][0]=pref_data_array;
import mkk_site.site_data;

foreach( recIndex; 0..rs.recordCount ) 
{
	string[] data_array;
	data_array.length = rs.fieldCount;
		
	foreach( column_num; 0..rs.fieldCount )
		{
		switch (select.conduct)
			{
				case 0:
					{
							if(recIndex==rs.recordCount-1 && column_num==0)
							   data_array[column_num]= "ИТОГО";
							else 
							  data_array[column_num]=rs.get(column_num, recIndex);
					}
					break;	
				case 1:
					{
						if(recIndex==rs.recordCount-1 && column_num==0)
							   data_array[column_num]= "ИТОГО";
						else 
							 {
								 if(recIndex!=rs.recordCount-1 && column_num==0 )
									data_array[column_num]=
									видТуризма.getName(rs.get(column_num, recIndex).to!int);
								 else
								  data_array[column_num]=rs.get(column_num, recIndex);
							 }
					}
				   break;
				default:
					break;
			}
		}

		

	for_all[][recIndex+1]=data_array;
}
// -----удаляем пустые столбцы----
 string[][]compressed_data;
 string[] last_line = for_all[for_all.length-1];

foreach(i, str; for_all)
{
	string[] data_array;
	data_array ~=for_all[i][0];

	for(int g=1; g < str.length; ++g)
		if(last_line[g].length!=0) data_array ~=for_all[i][g];	
		
	compressed_data ~= data_array;
} 
	//writeln(запрос_статистика);
//---------------------
	
//**************************************



	
			
		return compressed_data;
 }