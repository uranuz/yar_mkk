module mkk_site.utilities.gen_pw_hash;

///Утилита для генерации хэша пароля пользователя для сайта МКК

import std.stdio, std.getopt, std.digest.digest, std.base64;

import mkk_site.access_control;

void main(string[] progAgs) {
	//Основной поток - поток управления потоками

	string login;
	string group;
	string date;
	bool isHelp;
	
	//Получаем порт из параметров командной строки
	getopt( progAgs,
		"login", &login,
		"group", &group,
		"date", &date,
		"help", &isHelp
	);

	if( isHelp )
	{	writeln("Утилита для генерации идентификатора сессии сайта МКК.");
		writeln("Возвращает ИД сессии в виде числа в кодировке Base64");
		writeln(
			"Опции:\r\n",
			"  --login=ЛОГИН\r\n",
			"  --группа=ГРУППА_ПОЛЬЗ\r\n",
			"  --date=ДАТА_НАЧ_СЕССИИ\r\n",
			"  --help - эта справка"
		);
		return;
	}
	
	if( !login.length || !group.length || !date.length )
		writeln("Предупреждение: один или несколько из параметров хэша пусты!!!");
	
	writeln("Идентификатор сессии в кодировке Base64URL:");
	writeln( Base64URL.encode( generateSessionId(login, group, date) ) );
} 
