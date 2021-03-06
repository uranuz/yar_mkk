module mkk.main.pohod.stat;

import mkk.main.devkit;

import mkk.main.enums;

import std.conv, std.string, std.utf;
import std.typecons;
import std.datetime;
import std.json;

shared static this()
{
	MainService.JSON_RPCRouter.join!(statData)(`stat.Data`);
	MainService.JSON_RPCRouter.join!(statCsv)(`stat.Csv`);

	MainService.pageRouter.joinWebFormAPI!(renderStat)("/api/stat");
	MainService.pageRouter.joinWebFormAPI!(renderStatCsv)("/api/stat.csv");
}

// Структура фильтра по статистике
struct StatSelect
{
	import webtank.common.optional: Optional;

	@DBField("conduct")   	size_t conduct; //вид отображения
	@DBField("kodMKK")	      string kodMKK;
	@DBField("organization")	string organization;
	@DBField("territory")   	string territory;
	@DBField("beginYear")	   string beginYear;
	@DBField("endYear")	   string endYear;
}

auto first_reading(HTTPContext context,StatSelect select)
{
	import std.meta; //staticMap
	import std.range; //iota
	static immutable string[] prezent = [ "Год","Вид/КС" ];
	static immutable size_t[] number_lines = [12,10];
	

	template FieldPairFormat(size_t index) {
		alias FieldPairFormat = AliasSeq!(
			size_t, "gr_" ~ index.to!string,
			size_t, "un_" ~ index.to!string
		);
	}
	alias GeneralFormat(size_t count, string keyField) = RecordFormat!(
		PrimaryKey!(string, keyField),
		staticMap!(FieldPairFormat, aliasSeqOf!(iota(count)))
	);
	//-- формальные шаблоны данных
	static immutable statRecFormatVid = GeneralFormat!(11, "Год")();
	static immutable statRecFormatKC = GeneralFormat!(9, "Вид/КС")();
	//#############################################

	if( !select.beginYear.length )
		select.beginYear = "1960";
	if( !select.endYear.length )
		select.endYear = Clock.currTime().year.text;
	
	 	//***********************************
	string[] заголовок;//заголовок таблицы
	

	if( select.conduct == 0 )
	{
		заголовок = [
			"Год", "","Пеший", "","Лыжный","", "Горный","", "Водный", "","Вело",
			"","Авто", "","Спелео", "","Парус", "","Конный","", "Комби","", "ВСЕГО"
		];
	}

	if( select.conduct == 1 )
	{
		заголовок = [
			"Вид/ к.с.", "","н.к.", "","Первая","", "Вторая", "","Третья",
			"","Четвёртая","", "Пятая", "","Шестая", "","Путеш.", "","ВСЕГО"
		];
	}

	

	bool b_kod = false, b_org = false, b_terr = false;
	if(select.kodMKK.length)
		b_kod = true;
	if(select.organization.length)
		b_org = true;
	if(select.territory.length)
		b_terr = true;


	string запрос_статистика;
		//---запрос--по годам-----VID----
	if( select.conduct == 0 )
	{
		запрос_статистика =
			` WITH claim_state AS (select  CAST ((date_part('YEAR', begin_date)) AS integer) AS year,tourism_kind,complexity,CAST (party_size AS integer)  AS party_size  FROM pohod 
			WHERE begin_date is not null and tourism_kind is not null and complexity is not null and party_size is not null `;
		if( b_kod || b_org ||  b_terr )
			запрос_статистика ~= ` AND `;
		if( b_kod )
		{
			запрос_статистика ~= ` mkk_code ILIKE '%` ~ PGEscapeStr(select.kodMKK) ~ `%'`;
			if( b_org || b_terr )
				запрос_статистика ~= ` AND `;
		}

		if( b_org )
		{
			запрос_статистика ~= ` organization ILIKE '%` ~ PGEscapeStr(select.organization) ~ `%'`;
			if( b_terr )
				запрос_статистика ~= ` AND `;
		}

		if( b_terr )
			запрос_статистика ~= ` party_region ILIKE '%` ~ PGEscapeStr(select.territory) ~ `%'`;

		запрос_статистика ~= ` ORDER BY year ),`;

		for( int i = 1; i < 11; i++ )
		{
			запрос_статистика ~= `
			 st` ~ i.to!string
				~ ` AS ( SELECT year, count(party_size) AS gr_` ~ i.to!string
				~ `,   sum (party_size)    AS un_` ~i.to!string
				~ `  FROM claim_state  WHERE  tourism_kind=` ~i.to!string
				~ ` GROUP BY year ORDER BY year  ),`;
		}

				запрос_статистика ~= `
				всего AS ( SELECT year, count(party_size) AS gr_всего ,  sum (party_size)  AS un_всего
								FROM claim_state GROUP BY year ORDER BY year ),

				st AS (SELECT
				всего.year,`; 

		foreach( size_t n; 1..11 )
			запрос_статистика ~= ` 
				gr_` ~n.to!string~`, un_`~n.to!string~`,`;

			запрос_статистика ~= `				
				gr_всего,un_всего 
 				FROM  всего	`;

		foreach( size_t n; 1.. 11 )
			запрос_статистика ~= `		
	LEFT JOIN st`~n.to!string~` ON всего.year   = st`~n.to!string~`.year `;

	запрос_статистика ~= ` 
),

st100 AS ( 
	SELECT null::integer AS tourism_kind, `;

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
		SELECT CAST(party_size AS integer) AS party_size,tourism_kind,complexity
		FROM pohod
		WHERE
		   party_size is not null AND 
         tourism_kind is not null AND
			(date_part('YEAR', begin_date)>=` ~ PGEscapeStr(select.beginYear)
		~` AND
			date_part('YEAR', begin_date)<=` ~ PGEscapeStr(select.endYear) ~`)`;
		if( b_kod )
			запрос_статистика ~= `
			 AND  mkk_code ILIKE '%` ~ PGEscapeStr(select.kodMKK) ~ `%' `;

		if( b_org )
			запрос_статистика ~= `
			  AND  organization ILIKE '%` ~ PGEscapeStr(select.organization) ~ `%'`;

		if( b_terr )
			запрос_статистика ~= `
			  AND  party_region ILIKE '%` ~ PGEscapeStr(select.territory) ~ `%'`;

		запрос_статистика ~= ` ) ,`;

		запрос_статистика ~= `
			  ks0 AS ( SELECT tourism_kind,count(party_size) AS gr_0,  sum (party_size)  
			      AS un_0   FROM stat_by_year  WHERE  (complexity=0 OR complexity=9 )GROUP BY tourism_kind ORDER BY tourism_kind  ),`;
			foreach(size_t n; 1.. 7) 
				запрос_статистика ~= `
					complexity`~n.to!string~` AS ( SELECT tourism_kind,count(party_size) AS gr_`
										~ n.to!string~`,  sum (party_size)  AS un_`
										~ n.to!string~`  FROM stat_by_year  WHERE  complexity=`
										~ n.to!string~`  GROUP BY tourism_kind ORDER BY tourism_kind  ),`;
			запрос_статистика ~= `
			put AS ( SELECT tourism_kind,count(party_size) AS gr_7,  sum (party_size)  AS un_7
			      FROM stat_by_year  WHERE  (complexity=7 OR complexity is NULL)  GROUP BY tourism_kind ORDER BY tourism_kind  ),
			всего AS ( SELECT tourism_kind,count(party_size) AS gr_всего,sum (party_size)  AS un_всего
			FROM stat_by_year  WHERE tourism_kind is not null GROUP BY tourism_kind ORDER BY tourism_kind ),
			st AS (
			SELECT
			всего.tourism_kind,`; 
			foreach(size_t n; 0.. 8)
				запрос_статистика ~= `	
				gr_`~n.to!string~`, un_`~ n.to!string~`,`;
			
			запрос_статистика ~= `
			gr_всего,un_всего 
						FROM  всего `;

			foreach(size_t n; 0.. 7)
				запрос_статистика ~= `	 
				LEFT JOIN complexity`~n.to!string~` ON всего.tourism_kind   = complexity`~ n.to!string~`.tourism_kind `;

				запрос_статистика ~= `
			LEFT JOIN put ON всего.tourism_kind   = put.tourism_kind
			),
			st1 AS ( 
				SELECT 11 AS tourism_kind,`;
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
			SELECT*FROM st2 ORDER BY tourism_kind
			`;
	}
	//-----конец -запроса--"по КС"

	auto dbase = getCommonDB(); //Подключение к базе
	auto rs = dbase.query(запрос_статистика);

	                  //************************
	bool parity;
	// --формируем исходные матрицы------//
	string[][] for_all; //обобщённый массив данных 
	//----------------------
	for_all.length = rs.recordCount+1; //строк втаблице

	// --первая строка
	string[] pref_data_array;
	size_t qtyGraf;//возможное число графиков
	pref_data_array.length = qtyGraf;
	pref_data_array = заголовок;
	for_all[][0]=pref_data_array;
	import mkk.main.enums;

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
									tourismKind.getName(rs.get(column_num, recIndex).to!int);
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

	return for_all;
}
//*******************************************************
auto compressed_data (string[][]for_all)//удаляем пустые столбцы
{
	string[][]compressed_data;
	string[] last_line = for_all[for_all.length-1];

	foreach(i, str; for_all)
	{
		string[] data_array;
		data_array ~=for_all[i][0];

		for( int g=1; g < str.length; ++g )
			if( last_line[g].length != 0 )
				data_array ~= for_all[i][g];
			
		compressed_data ~= data_array;
	} 
	return compressed_data;
}
 

//*******************************************************
auto tabl_data (string[][] for_all)//матрица таблицы
{
	//удаляем пустые столбцы
	string[][]compressed_data = compressed_data (for_all);

	//--------матрица таблицы-------------

	bool t = false;
	string[][] tabl_data;
	size_t  p;

	foreach( data_str; compressed_data )
	{
		p = 0;
		string  coll;
		string [] str;
		foreach( col; data_str ) 
		{
			switch(p)
			{
				case 0:
					p = 1;
					str ~= col;
					break;
				case 1:
					p = 2;
					coll=col;
					break;
				case 2:
					p=1;
					if( coll.length )
						coll ~= "/";
					coll ~= col;
					str ~= coll;
					break;
				default:
					break;
			}
		}
		tabl_data ~= str;
		t = true;
		
	}
	//конец--------матрица таблицы------------
	return tabl_data;
}
//*******************************************************

auto statData //начало основной функции////////////////
 (HTTPContext context,StatSelect select)
  
 {   
	import std.meta;//staticMap
	import std.range;//iota

	size_t qtyGraf;//возможное число графиков
	bool[] boolGraf;//разрешонные графики	
	qtyGraf = 12;
	boolGraf.length = qtyGraf;
	boolGraf[] = false;

	string[][] for_all=first_reading ( context,select);
	// первичное чтение и очистка

// -----удаляем пустые столбцы----
	string[][]compressed_data;
	string[] last_line = for_all[for_all.length-1];

	foreach(i, str; for_all)
	{
		string[] data_array;
		data_array ~=for_all[i][0];

		for( int g=1; g < str.length; ++g )
			if( last_line[g].length != 0 )
				data_array ~= for_all[i][g];
			
		compressed_data ~= data_array;
	} 
	
	string[][] tabl_data = tabl_data (for_all);//матрица таблицы



	//--------матрица графика-------------
	size_t  p;
	string[][] graf_data;
	foreach( data_str; for_all )
	{
		p= 0;
		string [] str;
		foreach( col; data_str )
		{
			switch(p) 
			{
				case 0:
					p=1;
					str ~= col;
					break;
				case 1:
					p=0;
					break;
				default:
					break;
			}
		}
		graf_data ~= str;
	}
	
	//конец----матрица графика-------------
	import std.algorithm.searching: count;
	import std.algorithm.comparison: equal;
	import std.range.interfaces;
	import std.array: array;
	import std.algorithm: map;

	string[][] trans_graf_data;
	string[][] var;
	
	if(select.conduct == 0)
	{
		trans_graf_data = transposed(graf_data[1..compressed_data.length-1]).map!( (a) => a.array ).array;
		// отбросить первую строку и ТРАНСПОНИРОВАТЬ МАТРИЦУ
		if(!trans_graf_data.length) trans_graf_data ~=[["1992"], ["0"], ["0"], ["0"], ["0"],
		 ["0"], ["0"], ["0"], ["0"], ["0"], ["0"], ["0"]];

	}

	if(select.conduct == 1)
	{
		trans_graf_data ~= ["0","1","2","3","4","5","6","7" ];

		for( int v = 1; v < 11; v++ )
		{
			p = 1;
			foreach( col; graf_data )
			{
				
				if( count(col, tourismKind.getName(v)) )
				{
					trans_graf_data ~= col[1..col.length-1];
					p= 0;
				}
			}
			if(p) trans_graf_data~=["0","0","0","0","0","0","0","0" ];
		}
		trans_graf_data ~= graf_data[graf_data.length-1]
		[1..graf_data[graf_data.length-1].length-1];
		
	}


	//--заполним пустые позиции нулями
	foreach(i,data_str;trans_graf_data)
	{
		foreach(j,str;data_str)
		{
			if(!str.length) trans_graf_data[i][j]="0";
			else if(str != "0") boolGraf[i]=true;
		}
	}
	//--конец------матрица графика--нули-----------

	//---------------------graf_data
	JSONValue result;	
	result[`tabl`]=tabl_data;
	result[`graf`]=trans_graf_data;
	result[`grafLength`]=trans_graf_data[0].length;
	result[`boolGraf`]=boolGraf;
	
			
	return result;
 }
//********"csv"******************************
 auto statCsv (HTTPContext context, StatSelect select)
 {
	string[][] for_all= first_reading(context, select);
	string[][]tabl_data=tabl_data (for_all);//удаляем пустые столбцы

	//  ----"csv"-----------
    string csv_stat;
   csv_stat ~= ",Данные ,по числу ,походов/, участников \r\n";

	if(select.kodMKK.length)        csv_stat ~=",Код МКК,"~ select.kodMKK ~" \r\n";
	if(select.organization.length)  csv_stat ~=",Организация,"~ select.organization ~" \r\n";
	if(select.territory.length)     csv_stat ~=",Территория,"~ select.territory ~" \r\n";

	if( select.conduct == 0 )  csv_stat ~=",по годам \r\n";
	if( select.conduct == 1 )
	{  
		csv_stat ~=",по КС  ";
		if(select.beginYear.length) csv_stat ~= ",С " ~ select.beginYear ;
		if(select.endYear.length) csv_stat ~= ",по "  ~  select.endYear ;
		csv_stat ~=",\r\n";
	}


	foreach( str; tabl_data )
			 {
				 foreach( el; str )  csv_stat ~= el.to!string~',';
				 csv_stat ~= "\r\n";
			 }
			 
		 return csv_stat;
}

JSONValue renderStat(HTTPContext ctx, StatSelect select)
{
	import webtank.common.std_json.to: toStdJSON;
	return JSONValue([
		"select": select.toStdJSON(),
		"data": statData(ctx, select)
	]);
}

void renderStatCsv(HTTPContext ctx, StatSelect select)
{
	import std.conv: to;

	ctx.response.headers[HTTPHeader.ContentType] = `text/csv; charset="utf-8`;
	ctx.response.put(statCsv(ctx, select).to!string);
}