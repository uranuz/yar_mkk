module mkk_site.stat;

import std.conv, std.string, std.file, std.array, std.stdio;

import mkk_site.page_devkit;

static immutable(string) thisPagePath;

shared static this()
{	
	thisPagePath = dynamicPath ~ "stat";
	PageRouter.join!(netMain)(thisPagePath);
}

string netMain(HTTPContext context)
{	
	auto rq = context.request; //запрос
	auto rp = context.response; //ответ
	bool isForPrint = rq.bodyForm.get("for_print", null) == "on"; //если on то true
 
	string table_header;
	string table;

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
	)( null, tuple() );

	static immutable statRecFormatKC = RecordFormat!(
		PrimaryKey!(string), "Вид/КС",
		string, "gr_0",     string, "un_0",
		string, "gr_1",     string, "un_1",
		string, "gr_2",     string, "un_2",
		string, "gr_3",     string, "un_3",
		string, "gr_4",     string, "un_4",
		string, "gr_5",     string, "un_5",
		string, "gr_6",     string, "un_6",
		string, "gr_7",     string, "un_7",
		string, "gr_всего", string, "un_всего"
	)( null, tuple() );
	//------------шаблон страницы
	auto tpl = getPageTemplate( pageTemplatesDir ~ "show_stat.html" );
	//создаёт  страницу из шаблона

	string[] групп_человек;
	auto dbase = getCommonDB(); //Подключение к базе
	bool b_kod = false, b_org = false, b_terr = false;

	string kod = PGEscapeStr( rq.bodyForm.get("kod_MKK",     "") );
	string org = PGEscapeStr( rq.bodyForm.get("organization", "") );
	string terr = PGEscapeStr( rq.bodyForm.get("territory",   "") );
	string year_B = PGEscapeStr( rq.bodyForm.get("year_B",   "1992") );
	string year_E = PGEscapeStr( rq.bodyForm.get("year_E",   "2016") );
	string prezent_vid = PGEscapeStr( rq.bodyForm.get("prezent_vid","по годам"));

	string[] prezent = [ "по годам","по КС" ];
	string[] заголовок;
	bool[] bool_заголовок;
	size_t колонок;
	size_t строк;
	string[] вид = [
		"Вид/ к.с.", "Пеший", "Лыжный", "Горный", "Водный", "Вело",
		"Авто", "Спелео", "Парус", "Конный", "Комби", "ВСЕГО"
	];

	if( prezent_vid == "по годам" )
	{
		групп_человек = statRecFormatVid.names.dup;
		заголовок = [
			"Год", "Пеший", "Лыжный", "Горный", "Водный", "Вело",
			"Авто", "Спелео", "Парус", "Конный", "Комби", "ВСЕГО"
		];
		tpl.set( "skript_Neim", "stat_all.js");
		bool_заголовок = [ true,true,true,true,true,true,true,true,true,true,true,true ];
		колонок = 12;
	}

	if( prezent_vid == "по КС" )
	{
		групп_человек = statRecFormatKC.names.dup;
		заголовок = [
			"Вид/ к.с.", "н.к.", "Первая", "Вторая", "Третья",
			"Четвёртая", "Пятая", "Шестая", "Путеш.", "ВСЕГО"
		];
		tpl.set( "skript_Neim", "stat_year.js" );
		bool_заголовок = [true,true,true,true,true,true,true,true,true,true];
		колонок = 10;
	}

	if( kod != "" )
		b_kod = true;
	if( org != "" )
		b_org = true;
	if( terr != "" )
		b_terr = true;

	string запрос_статистика;
	///////---запрос--по годам---------
	if( prezent_vid == "по годам" )
	{
		запрос_статистика =
			` WITH stat AS (select  CAST ((date_part('YEAR', begin_date)) AS integer) AS year,vid,ks,CAST (unit AS integer)  AS unit  FROM pohod `;
		if( b_kod || b_org ||  b_terr )
			запрос_статистика ~= ` WHERE `;
		if( b_kod )
		{
			запрос_статистика ~= ` kod_mkk ILIKE '%` ~ kod ~ `%'`;
			if( b_org || b_terr )
				запрос_статистика ~= ` AND `;
		}

		if( b_org )
		{
			запрос_статистика ~= ` organization ILIKE '%` ~ org ~ `%'`;
			if( b_terr )
				запрос_статистика ~= ` AND `;
		}

		if( b_terr )
			запрос_статистика ~= ` region_group ILIKE '%` ~ terr ~ `%'`;

		запрос_статистика ~= ` ORDER BY year ),`;

		for( int i = 1; i < 11; i++ )
		{
			запрос_статистика ~= ` st` ~ i.to!string
				~ ` AS ( SELECT year, count(unit) AS gr_` ~ i.to!string
				~ `,   sum (unit)    AS un_` ~i.to!string
				~ `  FROM stat  WHERE  vid=` ~i.to!string
				~ ` GROUP BY year ORDER BY year  ),`;
		}

		запрос_статистика ~= `
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
	//-----конец -запроса-- по годам---

	//  ----запрос----"по КС"-----------
	if( prezent_vid == "по КС" )
	{
		запрос_статистика = `
		WITH stat_by_year AS (
		SELECT CAST(unit AS integer) AS unit,vid,ks
		FROM pohod
		WHERE
			(date_part('YEAR', begin_date)>=` ~ year_B
		~` AND
			date_part('YEAR', begin_date)<=` ~ year_E ~`)`;
		if( b_kod )
			запрос_статистика ~= ` AND  kod_mkk ILIKE '%` ~ kod ~ `%' `;

		if( b_org )
			запрос_статистика ~= `  AND  organization ILIKE '%` ~ org ~ `%'`;

		if( b_terr )
			запрос_статистика ~= `  AND  region_group ILIKE '%` ~ terr ~ `%'`;

		запрос_статистика ~= ` ) ,`;

		запрос_статистика ~= `

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

	//-----конец -запроса--"по КС"
	IBaseRecordSet rs;

	if( prezent_vid == "по годам" )
		rs = dbase.query(запрос_статистика).getRecordSet(statRecFormatVid);
	if( prezent_vid == "по КС" )
		rs = dbase.query(запрос_статистика).getRecordSet(statRecFormatKC);

	// --формируем исходные матрицы------///////////
	bool parity;
	строк = rs.length;
	string[][] for_tabl;   // массив данных для таблицы
	string[][] for_graf;   // массив данных для графика
	for( size_t i = 0; i < строк; i++ )//формирование ячеек таблицы
	{
		auto rec = rs[i];
		string[] line_tabl;
		string[] line_graf;
		line_tabl.length = колонок;
		line_graf.length = колонок;
		parity = false;
		string resurs_tabl;
		string resurs_graf;

		foreach( v, td; групп_человек)
		{
			if( v == 0 && prezent_vid == "по годам" )
			{
				line_tabl[v] = rec.getStr(td, "");
				line_graf[v] = rec.getStr(td, "");
			}

			if( v == 0 && prezent_vid == "по КС" )
			{
				line_tabl[v] = вид[ rec.getStr(td, "").to!int ];
				line_graf[v] = вид[ rec.getStr(td, "").to!int ];
			}

			if( v != 0)
			{
				if( parity )
					resurs_tabl = rec.getStr(td, "").to!string;

				if( !parity && rec.getStr(td, "") != "" )
				{
					line_tabl[(v)/2] ~= resurs_tabl ~ `(` ~ rec.getStr(td, "") ~ `)`;
					line_graf[(v)/2] = rec.getStr(td, "");
				}
			}
			parity =! parity;
		}
		for_tabl ~= line_tabl;
		for_graf ~= line_graf;
	}

	//---------------------строки для передачи данных в скрипт----------
	bool[12] bool_list = false;
	//--------проверка пустых столбцов------------------------ position
	for( size_t j = 0; j < bool_заголовок.length; j++  )
	{
		string kl;
		for( size_t i = 0; i < строк; i++  )
		{
			kl ~= for_tabl[i][j];
		}

		if( kl == "" )
			bool_заголовок[j] = false;
	}

	string skript_Surs = "";
	//---------------------------
	if( prezent_vid == "по годам" )
	{
		skript_Surs ~= "prez=1," ~ "\r\n";
		for( size_t j = 0; j < bool_заголовок.length; j++ )
		{
			string kl, kk = "", pref;
			if( j == 0 )
				pref = "";
			else
				pref = ",";

			for( size_t i = 0; i < строк; i++ )
			{
				string pr;

				if( i == 0 )
					pr = "";
				else
					pr = ",";

				kl ~= for_graf[i][j];
				if( for_graf[i][j] == "" )
					kk ~= pr ~ "0";
				else
					kk ~= pr ~ for_graf[i][j];
			}

			if( kl == "" )
				bool_list[j] = false;
			else
				bool_list[j] = true;

			skript_Surs ~= "Surs" ~ j.to!string ~ "=[" ~ kk ~ "]," ~ "\r\n";
			tpl.set( заголовок[j], kk );
		}
	}

	//////////////////////"по КС"////////////////////////////////////
	int[string] vid = [
		"Пеший": 1, "Лыжный": 2, "Горный": 3,"Водный": 4, "Вело": 5,
		"Авто": 6, "Спелео": 7, "Парус": 8, "Конный": 9, "Комби": 10, "ВСЕГО": 11
	];

	if( prezent_vid == "по КС" )
	{
		skript_Surs = "prez=2," ~ "\r\n";
		// формируем bool_list
		bool_list[0] = true;

		foreach( v, td; for_graf )
		{
			bool_list[  vid[ td[0] ] ] = true;
		}

		//------------------
		skript_Surs ~= "Surs0=[0,1,2,3,4,5,6,7]," ~ "\r\n";
		int qqq = 0;
		for( int v = 1; v < 12; v++ )
		{
			string kk = "";
			if( !bool_list[v] )
			{
				skript_Surs ~= "Surs" ~ v.to!string ~ "=[0,0,0,0,0,0,0,0]," ~ "\r\n";
			}
			else
			{
				foreach( t, tt; for_graf[qqq] )
				{
					if( t > 0 )
					{
						string pref;
						if( t == 1 )
							pref = "";
						else
							pref=",";

						if( tt.to!string == "" )
							kk ~= pref ~ "0";
						else
							kk ~= pref ~ tt.to!string;
					}
				}
				qqq = qqq + 1;
				skript_Surs ~= "Surs" ~ v.to!string ~ "=[" ~ kk ~ "]," ~ "\r\n" ;
			}
		}
	}

	string bl = "bool_list = [";
	foreach( m, tr; bool_list )
	{
		if( m == 0 )
			bl ~= tr.to!string;
		else
			bl ~= "," ~ tr.to!string;
	}

	bl ~= "],";
	skript_Surs ~= bl ~ "\r\n";
	skript_Surs ~= "y=" ~ строк.to!string ~ "\r\n" ;
	tpl.set( "skript_Surs", skript_Surs);

	//---------заголовок таблицы --------------------------------------

	foreach( v, td; заголовок)
	{
		if( bool_заголовок[v] )
			table_header ~= `<th>` ~ td ~ `</th>` ~ "\r\n";
	}

	tpl.set( "stat_table_header", table_header );

	//-----------------------------------------------
	for( size_t i = 0; i < строк; i++ ) //формирование ячеек таблицы
	{
		table ~= `<tr class="e-row t-mkk_table">`;

		for( size_t v = 0; v < колонок; ++v )
		{
			if( v == 0 )
				table ~= `<td>` ~ for_tabl[i][v] ~ `</td>` ~ "\r\n";

			if( bool_заголовок[v] && v != 0 )
				table ~= `<td>` ~ for_tabl[i][v] ~ `</td>` ~ "\r\n";

		}
		table ~= `</tr>`~ "\r\n";
	}
	//---------------------------------------------------

	//--блок переключения вида
	if( isForPrint )
	{
		if( prezent_vid == "по годам" )
		{
			tpl.set( "period", "по годам" );
		}
		if( prezent_vid == "по КС" )
		{
			tpl.set( "period", `За ` ~ year_B ~ ` - ` ~ year_E ~ ` годы`);
		}

		tpl.set( "no_print", `class="no_print"` );
	}
	else
	{
		tpl.set( "no_print", `` );
	}

	if( prezent_vid == "по годам" )
	{
		tpl.set( "on_years", "checked" );
		tpl.set( "on_KC", " " );
	}

	if( prezent_vid == "по КС" )
	{
		tpl.set( "on_KC", "checked");
		tpl.set( "on_years", " " );
	};

	// блок фильтров
	if( isForPrint )
	{
		string ffl="";

		if( kod != `` )
			ffl ~= `Код МКК ` ~ kod ~ `<br/>`;

		if( org != `` )
			ffl ~= `Организация ` ~ org ~ `<br/>`;

		if( terr != `` )
			ffl ~= `Территория ` ~ terr;

		tpl.set( "filtrum",  ffl);
	}

	tpl.set( "kod_MKK", HTMLEscapeValue( rq.bodyForm.get("kod_MKK", "176-00") ) );
	tpl.set( "organization", HTMLEscapeValue( rq.bodyForm.get("organization", "") ) );
	tpl.set( "territory", HTMLEscapeValue( rq.bodyForm.get("territory", "") ) );

	if( prezent_vid == "по КС" )
	{
		tpl.set( "year_S",
			`
			<div class="form-inline">
				<label>
					<span class="form-control-label">С</span>
					<input type="text" name="year_B" class="form-control" style="width: 8em;" value="`
						~ HTMLEscapeValue( rq.bodyForm.get("year_B", "1992") )
					~ `">
				</label>
				<label>
					<span class="form-control-label">по</span>
					<input type="text" name="year_E" class="form-control" style="width: 8em;" value="`
						~ HTMLEscapeValue( rq.bodyForm.get("year_E", "2016") )
					~ `">
				</label>
				<span class="form-control-label">годы</span>
			</div>
			`
		);
	}

	if( isForPrint )
	{
		tpl.set( "ckript_or_button",
			`<a href='javascript:window.print(); void 0;' class="noprint">
			<img height="60" width="60" class="noprint" src="/pub/img/icons/printer.png"/>
			</a> <!-- печать страницы -->`
		);
	}
	else
	{
		tpl.set( "ckript_or_button",`<button name="filtr" type="submit" class="noprint btn btn-primary">Обновить</button>`);
	}

	if (isForPrint) //для печати
	{
		tpl.set( "for_print", `class="noprint"`);
		tpl.set( "MESSAGE", "Назад");
	}
	else
	{
		tpl.set( "for_print", `value="on"`);
		tpl.set( "MESSAGE", "Для печати");
	}

	tpl.set( "stat_table", table );

	return tpl.getString();
}
