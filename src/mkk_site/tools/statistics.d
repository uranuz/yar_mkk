module mkk_site.tools.statistics;

import std.stdio;

//Набор библиотечных модулей по работе с базами данных
import webtank.db, webtank.datctrl; 

//Вспомогательные функции сайта/базы МКК
import mkk_site.common.utils, mkk_site.db_utils;

void main()
{
	writeln("Привет Олег!!!");
	auto dbase = getCommonDB(); //Подключение к базе
	auto queryResult = dbase.query(` WITH 
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
      всего.year
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
      LEFT JOIN комби ON всего.year   = комби.year limit 10;`);
	for( int i = 0; i < queryResult.recordCount; i++ )
	{
		for( int j = 0; j < queryResult.fieldCount; j++ )
		{
			write( queryResult.get(j, i), " | " );
		}
		writeln();
	}
	
	int[9][2] container;
	foreach(ref elem; container) {elem=0;}
	
}