module mkk_site.utilities.statistics;

import std.stdio;

//Набор библиотечных модулей по работе с базами данных
import webtank.db, webtank.datctrl; 

//Вспомогательные функции сайта/базы МКК
import mkk_site.utils;

void main()
{
	writeln("Привет Олег!!!");
	auto dbase = getCommonDB(); //Подключение к базе
	auto queryResult = dbase.query(`select * from pohod limit 5;`);
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