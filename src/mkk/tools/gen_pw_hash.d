module mkk.tools.gen_pw_hash;

/// Утилита для генерации хэша пароля пользователя для сайта МКК

import std.stdio: writeln;
import std.getopt: getopt;
import std.datetime: Clock;

import mkk.security.core.crypto: makePasswordHashCompat;

void main(string[] progAgs)
{
	string timestamp;
	string password;
	string salt;
	bool useScr;
	bool isHelp;
	
	getopt(progAgs,
		"timestamp", &timestamp,
		"pw", &password,
		"salt", &salt,
		"scr", &useScr,
		"help", &isHelp,
	);

	if( !timestamp.length || !password.length || !salt.length )
	{
		writeln("Предупреждение: один или несколько из обязательных параметров пусты!!!\r\n");
		isHelp = true;
	}

	if( isHelp )
	{
		writeln(
			"Утилита для генерации хэша пароля пользователя сайта МКК.\r\n",
			"Возвращает хэш в виде шестнадцатеричного числа\r\n",
			"Опции:\r\n",
			"  --timestamp=ДАТА_ВРЕМЯ\r\n",
			"  --pw=ПАРОЛЬ\r\n",
			"  --salt=СОЛЬ_ХЭША\r\n",
			"  --scr   Использовать старый формат хэша пароля\r\n",
			"  --help - эта справка"
		);
		return;
	}

	auto time = Clock.currTime();
	auto hashRes = makePasswordHashCompat(timestamp, password, salt, useScr);
	writeln( "Время вычисления хэша пароля: ", Clock.currTime() - time, ". Закодированный в Base64URL хэш с параметрами алгоритма:" );
	writeln( hashRes.pwHashStr );
} 
