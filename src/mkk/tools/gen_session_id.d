module mkk.tools.gen_session_id;
///Утилита для генерации идентификатора сессии пользователя для сайта МКК

import std.stdio: writeln;
import std.getopt: getopt;
import std.base64: Base64URL;

import webtank.security.auth.core.crypto: generateSessionId;

void main(string[] progAgs)
{
	string login;
	string group;
	string timestamp;
	bool isHelp;
	
	//Получаем порт из параметров командной строки
	getopt(progAgs,
		"login", &login,
		"group", &group,
		"timestamp", &timestamp,
		"help|h", &isHelp
	);

	if( !login.length || !group.length || !timestamp.length )
	{
		writeln("Предупреждение: один или несколько из параметров хэша пусты!!!\r\n");
		isHelp = true;
	}

	if( isHelp )
	{
		writeln(
			"Утилита для генерации идентификатора сессии сайта МКК.\r\n",
			"Возвращает ИД сессии в виде числа в кодировке Base64\r\n",
			"Опции:\r\n",
			"  --login=ЛОГИН\r\n",
			"  --group=ГРУППА_ПОЛЬЗ\r\n",
			"  --timestamp=ДАТА_НАЧ_СЕССИИ\r\n",
			"  --help - эта справка"
		);
		return;
	}

	writeln("Идентификатор сессии в кодировке Base64URL:");
	writeln( Base64URL.encode( generateSessionId(login, group, timestamp) ) );
} 
