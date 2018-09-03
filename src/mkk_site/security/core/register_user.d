module mkk_site.security.core.register_user;

import std.datetime: DateTime;
import std.algorithm: endsWith;
import std.uuid: randomUUID;

import mkk_site.security.core.access_control: minLoginLength, minPasswordLength;
import mkk_site.security.core.crypto: makePasswordHash, encodePasswordHash;
import webtank.common.conv: fromPGTimestamp;
import webtank.net.utils: PGEscapeStr;
import webtank.db.datctrl_joint: getRecordSet;
import webtank.datctrl.record_format: RecordFormat, PrimaryKey;

size_t registerUser(alias getAuthDB)(string login, string password, string name, string email)
{
	import std.utf: count;
	import std.conv: text;

	if( !login.length || !name.length || !password.length ) {
		throw new Exception("Один или несколько обязательных параметров профиля пользователя пусты");
	}

	if( login.count < minLoginLength ) {
		throw new Exception("Длина логина меньше минимально допустимой (" ~ minLoginLength.text ~ " символов)");
	}

	if(
		getAuthDB().query(
			`select 1 from site_user where login='` ~ PGEscapeStr(login) ~ `';`
		).recordCount != 0
	) {
		throw new Exception("Пользователь с заданным логином уже зарегистрирован");
	}

	if( password.count < minPasswordLength ) {
		throw new Exception("Длина пароля меньше минимально допустимой (" ~ minPasswordLength.text ~ " символов)");
	}

	static immutable addUserResultFmt = RecordFormat!(
		PrimaryKey!(size_t), "num",
		string, "status",
		DateTime, "regTimestamp"
	)();

	// Сначала устанавливаем общую информацию о пользователе,
	// и заставляем БД саму установить дату регистрации, чтобы не иметь проблем с временными зонами
	auto addUserResult = getAuthDB().query(
		`insert into site_user (login, name, email, reg_timestamp) `
		~ ` values('` ~ PGEscapeStr(login) ~ `', '` ~ PGEscapeStr(name) ~ `', '` ~ PGEscapeStr(email) ~ `', current_timestamp) `
		~ ` returning num, 'user added' "status", reg_timestamp`
	).getRecordSet(addUserResultFmt);

	if( addUserResult.length != 1 || addUserResult.front.get!"status"() != `user added` ) {
		throw new Exception(`При сохранении информации о пользователе произошла ошибка`);
	}

	// Генерируем случайную соль для пароля, и используем дату регистрации из базы для сотворения хэша пароля
	string pwSaltStr = randomUUID().toString();
	ubyte[] pwHash = makePasswordHash(password, pwSaltStr, addUserResult.front.get!"regTimestamp"().toISOExtString());
	string pwHashStr = encodePasswordHash(pwHash);

	// Прописываем хэш пароля в БД
	auto setPasswordResult = getAuthDB().query(
		`update site_user set pw_hash = '` ~ PGEscapeStr(pwHashStr) ~ `', pw_salt = '` ~ PGEscapeStr(pwSaltStr) ~ `' `
		~ `where num = ` ~ addUserResult.front.getStr!"num"() ~ ` returning num, 'user upd' "status", reg_timestamp`
	).getRecordSet(addUserResultFmt);

	if( setPasswordResult.length != 1 || setPasswordResult.front.get!"status"() != `user upd` ) {
		throw new Exception(`Произошла ошибка при завершении сохранения информации о пользователе`);
	}

	// Возвращаем идентификатор нового пользователя народу
	return setPasswordResult.front.get!"num"();
}

void addUserRoles(alias getAuthDB)(size_t userId, string[] roles, bool overwrite = false)
{
	import std.algorithm: map;
	import std.array: join;
	import std.conv: text;
	// При установке флага на перезапись ролей пользователя (overwrite)
	// будет добавлен подзапрос на удаление связей пользователя с ролями не из переданного списка.
	// Если флаг не установлен то будут назначены роли, к которым пользователь не был привязан.
	// Роль в любом случае должна уже существовать, она не будет добавлена автоматически (добавляются только связи)
	immutable string deleteDataQuery = `,
	for_delete as(
		select ua_role.num
		from user_access_role ua_role
		left join access_role a_role
			on a_role.num = ua_role.role_num
		left join rolz rlz
			on rlz.rol = a_role.name
		where ua_role.num = ` ~ userId.text ~ ` and(a_role.num is null or rlz.rol is null)
	)`;
	static immutable string deleteQuery = `union all
	delete from user_access_role as new_ua_role
	where new_ua_role.num in (select num from for_delete)
	returning new_ua_role.num, 'delete' status`;

	getAuthDB().query(`
	with rolz(rol) as(
		select unnest(ARRAY[` ~ roles.map!( (it) => "'" ~ PGEscapeStr(it) ~ "'" ).join(", ") ~ `]::text[])
	),
	for_insert as(
		select ` ~ userId.text ~ ` user_num, a_role.num role_num
		from rolz
		join access_role a_role
			on rolz.rol = a_role.name
		left join user_access_role ua_role
			on ua_role.user_num = ` ~ userId.text ~ ` and ua_role.role_num = a_role.num
		where ua_role.num is null
	)`~ (overwrite? deleteDataQuery: null) ~`
	insert into user_access_role as new_ua_role (user_num, role_num)
	select * from for_insert
	returning new_ua_role.num, 'insert' status
	` ~ (overwrite? deleteQuery: null));
}
