module mkk_site.main_service.user_list;
import mkk_site.main_service.devkit;

shared static this()
{
	MainService.JSON_RPCRouter.join!(userList)(`user.list`);
}

/// Формат записи для списка пользователей сайта
static immutable userListRecFormat = RecordFormat!(
	PrimaryKey!(size_t), "num",
	string, "name",
	string, "login",
	bool, "is_email_confirmed",
	bool, "is_blocked"
)();

import std.json: JSONValue;

auto userList(HTTPContext ctx)
{
	auto user_rs = getAuthDB().query(`
	select num, name, login, is_email_confirmed, is_blocked
	from site_user su
	`).getRecordSet(userListRecFormat);
	return user_rs;
}

shared static this() {
	MainService.pageRouter.joinWebFormAPI!(renderUserList)("/api/user/list");
}

auto renderUserList(HTTPContext ctx)
{
	return JSONValue([
		"userList": userList(ctx).toStdJSON()
	]);
}