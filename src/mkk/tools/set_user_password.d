module mkk.tools.set_user_password;

///Утилита для добавления пользователя сайта МКК

import std.stdio: writeln, write, readln;
import std.getopt: getopt;
import std.conv: to;
import std.algorithm: endsWith;

import mkk.security.core.access_control;
import mkk.tools.auth_db: getAuthDB;

void main(string[] progAgs)
{
	string login;
	bool isHelp;

	getopt(progAgs,
		"login", &login,
		"help", &isHelp
	);

	if( !login.length )
	{
		writeln("Ошибка: не задан логин пользователя!!!\r\n");
		isHelp = true;
	}

	if( login.length < minLoginLength )
	{
		writeln("Ошибка: длина логина меньше минимально допустимой (", minLoginLength, " символов)!!!\r\n");
		isHelp = true;
	}

	if( isHelp )
	{
		writeln(
			"Утилита для изменения пароля пользователя сайта МКК.\r\n",
			"Опции:\r\n",
			"  --login=ЛОГИН         Минимум " ~ minLoginLength.to!string ~ " символов\r\n",
			"  --help - эта справка"
		);
		return;
	}

	auto userExistsRes = getAuthDB().query(
		`select 1 from site_user where login = '` ~ login ~ `';`
	);

	if( userExistsRes.recordCount != 1 )
	{
		writeln("Ошибка: пользователь с заданным логином отсутствует!!!");
		return;
	}

	writeln("Введите новый пароль пользователя сайта. Выбирайте сложный пароль (минимум ", minPasswordLength, " символов)");
	write("password=");

	string password = readln();

	//Обрезаем символы переноса строки в конце пароля
	password = password.endsWith("\r\n")? password[0..$-2] : password[0..$-1];

	if( password.length < minPasswordLength )
	{	
		writeln("Ошибка: длина пароля меньше минимально допустимой (", minPasswordLength, " символов)!!!");
		return;
	}

	import std.functional: toDelegate;
	if( changeUserPassword!(false)(toDelegate(&getAuthDB), login, null, password) ) {
		writeln(`Установлен новый пароль для пользователя с логином "`, login, `"!`);
	} else {
		writeln(`При запросе на установку пароля пользователя произошла ошибка!`);
	}
}
