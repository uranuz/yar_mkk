module mkk.main.user.list;
import mkk.main.devkit;

shared static this()
{
	MainService.JSON_RPCRouter.join!(userList)(`user.list`);

	MainService.pageRouter.joinWebFormAPI!(userList)("/api/user/list");
}

/// Формат записи для списка пользователей сайта
static immutable userListRecFormat = RecordFormat!(
	PrimaryKey!(size_t), "num",
	string, "name",
	string, "login",
	bool, "is_email_confirmed",
	bool, "is_blocked"
)();

Tuple!(IBaseRecordSet, `userList`) userList(HTTPContext ctx)
{
	return typeof(return)(getAuthDB().query(`
		select num, name, login, is_email_confirmed, is_blocked
		from site_user su
		`).getRecordSet(userListRecFormat));
}

