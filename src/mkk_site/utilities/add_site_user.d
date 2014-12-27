module mkk_site.utilities.add_site_user;

///Утилита для добавления пользователя сайта МКК

import std.stdio, std.getopt, std.digest.digest, std.base64, std.datetime, std.utf, std.conv, std.algorithm : endsWith;

import std.uuid : randomUUID;

import webtank.db.postgresql;

import mkk_site.access_control, mkk_site.site_data;

void main(string[] progAgs) {
	//Основной поток - поток управления потоками

	string login;
	string name;
	string group;
	string email;
	bool isHelp;
	
	//Получаем порт из параметров командной строки
	getopt( progAgs,
		"login", &login,
		"name", &name,
		"group", &group,
		"email", &email,
		"help", &isHelp
	);

	if( isHelp )
	{	writeln("Утилита для добавления пользователя сайта МКК.");
		writeln("Возвращает ИД сессии в виде числа в кодировке Base64");
		writeln(
			"Опции:\r\n",
			"  --login=ЛОГИН         Минимум " ~ minLoginLength.to!string ~ " символов\r\n",
			"  --name=ИМЯ_ПОЛЬЗ\r\n",
			"  --group=ГРУППА_ПОЛЬЗ\r\n",
			"  --email=EMAIL\r\n",
			"  --help - эта справка"
		);
		return;
	}
	
	if( !login.length || !name.length || !group.length || !email.length )
	{	writeln("Ошибка: один или несколько обязательных параметров профиля пользователя пусты!!!");
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

	if(
		dbase.query(
			`select 1 from site_user where login='` ~ login ~ `';`
		).recordCount != 0
	)
	{	writeln("Ошибка: пользователь с заданным логином уже зарегистрирован!!!");
		return;
	}

	writeln("Введите пароль нового пользователя сайта. Выбирайте сложный пароль (минимум ", minPasswordLength, " символов)");
	write("password=");
	
	string password = readln();

	//Обрезаем символы переноса строки в конце пароля
	password = password.endsWith("\r\n") ? password[0..$-2] : password[0..$-1];

	if( password.count < minPasswordLength )
	{	writeln("Ошибка: длина пароля меньше минимально допустимой (", minPasswordLength, " символов)!!!");
		return;
	}
	
	string pwSaltStr = randomUUID().toString();
	DateTime regDateTime = cast(DateTime) Clock.currTime();
	string regTimestampStr = regDateTime.toISOExtString();
	
	ubyte[] pwHash = makePasswordHash( password, pwSaltStr, regTimestampStr );
	string pwHashStr = encodePasswordHash( pwHash );
	
	dbase.query(
		`insert into site_user ( login, name, user_group, email, pw_hash, pw_salt, reg_timestamp ) `
		~ ` values( '` ~ login ~ `', '` ~ name ~ `', '` ~ group ~ `', '` 
		~ email ~ `', '` ~ pwHashStr ~ `', '` ~ pwSaltStr ~ `', '` ~ regTimestampStr ~ `' ) `
	);
} 
