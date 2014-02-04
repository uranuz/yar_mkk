module mkk_site.utils.gen_pw_hash;

///Утилита для генерации хэша пароля пользователя для сайта МКК

import std.stdio, std.getopt, std.datetime;

import mkk_site.access_control;

void main(string[] progAgs) {
	//Основной поток - поток управления потоками

	string msg;
	string password;
	string salt;
	bool isHelp;
	
	getopt( progAgs,
		"msg", &msg,
		"pw", &password,
		"salt", &salt,
		"help", &isHelp
	);

	if( isHelp )
	{	writeln("Утилита для генерации хэша пароля пользователя сайта МКК.");
		writeln("Возвращает хэш в виде шестнадцатеричного числа");
		writeln(
			"Опции:\r\n",
			"  --msg=ДАТА_ВРЕМЯ\r\n",
			"  --secret=ПАРОЛЬ\r\n",
			"  --salt=СОЛЬ\r\n",
			"  --help - эта справка"
		);
		return;
	}
	
	if( !msg.length || !password.length || !salt.length )
		writeln("Предупреждение: один или несколько параметров хэша пусты!!!");
	
	auto time = Clock.currTime();
	auto pwHash = makePasswordHash(msg, password, salt);
	writeln( "Время вычисления хэша пароля: ", Clock.currTime() - time, ". Закодированный в Base64URL хэш с параметрами алгоритма:" );
	writeln( encodePasswordHash( pwHash ) );
} 
