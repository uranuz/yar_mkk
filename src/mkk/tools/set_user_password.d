module mkk.tools.set_user_password;

///Утилита для добавления пользователя сайта МКК

import std.stdio: writeln, write, readln;
import std.getopt: getopt;
import std.conv: to;
import std.algorithm: endsWith;

import webtank.security.auth.core.consts: minLoginLength, minPasswordLength;
import webtank.security.auth.core.change_password: changeUserPassword;
import mkk.backend.database: DBFactory, getAuthDB;

void main(string[] progAgs)
{
	string login;
	bool useScr;
	bool isHelp;

	getopt(progAgs,
		"login", &login,
		"scr", &useScr,
		"help|h", &isHelp
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
			"  --scr   Использовать старый формат хэша пароля\r\n",
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
	// Поскольку это у нас админский инструмент, то старый пароль здесь не проверяем
	if( changeUserPassword!(/*doPwCheck=*/false)(DBFactory, login, null, password, useScr) ) {
		writeln(`Установлен новый пароль для пользователя с логином "`, login, `"!`);
	} else {
		writeln(`При запросе на установку пароля пользователя произошла ошибка!`);
	}
}
