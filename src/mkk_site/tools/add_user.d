module mkk_site.tools.add_user;

///Утилита для добавления пользователя сайта МКК
import std.stdio;
import std.getopt;
import std.datetime;
import std.conv;
import std.algorithm: endsWith;
import std.uuid: randomUUID;

import mkk_site.security.core.access_control: minLoginLength, minPasswordLength;
import mkk_site.security.core.crypto: makePasswordHash, encodePasswordHash;
import mkk_site.tools.auth_db: getAuthDB;
import webtank.common.conv: fromPGTimestamp;

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
	
	if( !login.length || !name.length || !group.length || !email.length )
	{
		writeln("Ошибка: один или несколько обязательных параметров профиля пользователя пусты!!!");
		isHelp = true;
	}

	import std.utf: count;

	if( login.count < minLoginLength )
	{
		writeln("Ошибка: длина логина меньше минимально допустимой (", minLoginLength, " символов)!!!");
		isHelp = true;
	}

	if( isHelp )
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
		return;
	}

	if(
		getAuthDB().query(
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

	// Сначала устанавливаем общую информацию о пользователе,
	// и заставляем БД саму установить дату регистрации, чтобы не иметь проблем с временными зонами
	auto addUserResult = getAuthDB().query(
		`insert into site_user ( login, name, user_group, email, reg_timestamp ) `
		~ ` values( '` ~ login ~ `', '` ~ name ~ `', '` ~ group ~ `', '` ~ email ~ `', current_timestamp ) `
		~ ` returning 'user added', num, reg_timestamp`
	);

	if( addUserResult.recordCount != 1 || addUserResult.get(0, 0, null) != `user added` ) {
		writeln( `При запросе на регистрацию пользователя произошла ошибка!` );
	}

	// Генерируем случайную соль для пароля, и используем дату регистрации из базы для сотворения хэша пароля
	string pwSaltStr = randomUUID().toString();
	DateTime regDateTime = fromPGTimestamp!DateTime(addUserResult.get(2, 0, null));

	ubyte[] pwHash = makePasswordHash( password, pwSaltStr, regDateTime.toISOExtString() );
	string pwHashStr = encodePasswordHash( pwHash );

	// Прописываем хэш пароля в БД
	getAuthDB().query(
		`update site_user set pw_hash = '` ~ pwHashStr ~ `', pw_salt = '` ~ pwSaltStr ~ `' `
		~ `where num = ` ~ addUserResult.get(1, 0, null)
	);

	writeln( `Пользователь с логином "`, login, `" успешно зарегистрирован!` );
} 
