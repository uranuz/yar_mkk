module mkk.tools.add_user;

///Утилита для добавления пользователя сайта МКК
import std.stdio;
import std.getopt;
import std.datetime;
import std.conv;
import std.algorithm: endsWith;
import std.uuid: randomUUID;

import mkk.security.core.access_control: minLoginLength, minPasswordLength;
import mkk.tools.auth_db: getAuthDB;
import webtank.common.conv: fromPGTimestamp;
import mkk.security.core.register_user: registerUser;

void showHelp()
{
	writeln("Утилита для добавления пользователя сайта МКК.");
	writeln(
		"Опции:\r\n",
		"  --login=ЛОГИН         Минимум " ~ minLoginLength.to!string ~ " символов\r\n",
		"  --name=ИМЯ_ПОЛЬЗ\r\n",
		"  --group=ГРУППА_ПОЛЬЗ\r\n",
		"  --email=EMAIL\r\n",
		"  --help - эта справка"
	);
}

void main(string[] progAgs) {
	//Основной поток - поток управления потоками

	string login;
	string name;
	string group;
	string email;
	bool scr;
	bool isHelp;
	
	//Получаем порт из параметров командной строки
	getopt( progAgs,
		"login", &login,
		"name", &name,
		"email", &email,
		"scr", &scr,
		"help", &isHelp
	);

	if( isHelp ) {
		showHelp();
	}

	writeln("Введите пароль нового пользователя сайта. Выбирайте сложный пароль (минимум ", minPasswordLength, " символов)");
	write("password=");
	
	string password = readln();

	//Обрезаем символы переноса строки в конце пароля
	password = password.endsWith("\r\n") ? password[0..$-2] : password[0..$-1];

	size_t userId;
	try {
		userId = registerUser(login, name, email);
	} catch(Exception ex) {
		writeln(ex.msg);
		showHelp();
	}

	writeln(`Пользователь с логином "`, login, `" успешно зарегистрирован с идентификатором: `, userId);
} 
