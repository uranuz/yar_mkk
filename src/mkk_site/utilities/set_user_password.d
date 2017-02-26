module mkk_site.utilities.set_user_password;

///Утилита для добавления пользователя сайта МКК

import std.stdio, std.getopt, std.digest.digest, std.base64, std.datetime, std.utf, std.conv, std.algorithm : endsWith;

import std.uuid : randomUUID;

import webtank.db.postgresql;

import mkk_site.access_control, mkk_site.site_data_old;

void main(string[] progAgs) {
	string login;
	bool isHelp;
	
	getopt( progAgs,
		"login", &login,
		"help", &isHelp
	);

	if( isHelp )
	{	writeln("Утилита для изменения пароля пользователя сайта МКК.");
		writeln(
			"Опции:\r\n",
			"  --login=ЛОГИН         Минимум " ~ minLoginLength.to!string ~ " символов\r\n",
			"  --help - эта справка"
		);
		return;
	}
	
	if( !login.length )
	{	writeln("Ошибка: не задан логин пользователя!!!");
		return;
	}

	if( login.count < minLoginLength )
	{	writeln("Ошибка: длина логина меньше минимально допустимой (", minLoginLength, " символов)!!!");
		return;
	}
	
	auto dbase = new DBPostgreSQL(authDBConnStr);
	
	if( dbase is null || !dbase.isConnected )
	{	writeln("Не удалось подключиться к базе данных МКК");
		return;
	}

	auto regTimestampResult = dbase.query(
		`select reg_timestamp from site_user where login = '` ~ login ~ `';`
	);
	
	if( regTimestampResult.recordCount != 1 )
	{	writeln("Ошибка: пользователь с заданным логином отсутствует!!!");
		return;
	}
	
	if( regTimestampResult.get(0, 0, null).length == 0 )
	{	writeln("Ошибка: не удалось получить дату регистрации пользователя!!!");
		return;
	}

	writeln("Введите новый пароль пользователя сайта. Выбирайте сложный пароль (минимум ", minPasswordLength, " символов)");
	write("password=");
	
	string password = readln();

	//Обрезаем символы переноса строки в конце пароля
	password = password.endsWith("\r\n") ? password[0..$-2] : password[0..$-1];

	if( password.count < minPasswordLength )
	{	writeln("Ошибка: длина пароля меньше минимально допустимой (", minPasswordLength, " символов)!!!");
		return;
	}
	
	import webtank.common.conv: DateTimeFromPGTimestamp;
	
	string pwSaltStr = randomUUID().toString();
	DateTime regDateTime = DateTimeFromPGTimestamp( regTimestampResult.get(0, 0, null) );
	string regTimestampStr = regDateTime.toISOExtString();
	
	ubyte[] pwHash = makePasswordHash( password, pwSaltStr, regTimestampStr );
	string pwHashStr = encodePasswordHash( pwHash );
	
	auto addUserResult = dbase.query(
		`update site_user set `
		~ ` pw_hash = '` ~ pwHashStr ~ `', pw_salt = '` ~ pwSaltStr ~ `' `
		~ ` where login = '` ~ login ~ `' `
		~ ` returning 'passwd set'`
	);
	
	if( addUserResult.recordCount != 1 || addUserResult.get(0, 0, null) != `passwd set` )
	{
		writeln( `При запросе на установку пароля пользователя произошла ошибка!` );
	}
	else
	{
		writeln( `Установлен новый пароль для пользователя с логином "`, login, `"!` );
	}
} 
