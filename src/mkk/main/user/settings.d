module mkk.main.user.settings;

import mkk.main.devkit;
import mkk.security.core.access_control: changeUserPassword;
import mkk.security.common.exception: SecurityException;

shared static this()
{
	MainService.JSON_RPCRouter.join!(changePassword)(`user.changePassword`);

	MainService.pageRouter.joinWebFormAPI!(renderUserSettings)("/api/user/settings");
}

void changePassword(
	HTTPContext ctx,
	string oldPassword,
	string newPassword,
	string repeatPassword
) {
	enforce!SecurityException(
		ctx.user.isAuthenticated,
		`Изменение пароля пользователя требует аутентификации на сайте!`
	);
	enforce!SecurityException(
		oldPassword.length > 0 && newPassword.length > 0 && repeatPassword.length > 0,
		`Некоторые параметры не заданы!`
	);
	enforce!SecurityException(
		newPassword == repeatPassword,
		`Смена пароля не произведена. Новый пароль и подтверждение пароля не совпадают!`
	);
	import std.functional: toDelegate;
	enforce!SecurityException(
		// Здесь, естественно, необходимо проверять старый пароль перед тем как его сменить, иначе будет пичально...
		changeUserPassword!(/*doPwCheck=*/true)(toDelegate(&getAuthDB), ctx.user.id, oldPassword, newPassword),
		`Произошла ошибка при попытке смены пароля! Возможно, введен неверный старый пароль`
	);
}

Tuple!(
	string, `userFullName`,
	string, `userLogin`,
	string, `pwChangeMessage`
)
renderUserSettings(
	HTTPContext ctx,
	string oldPassword,
	string newPassword,
	string repeatPassword
) {
	typeof(return) res;
	res.userFullName = ctx.user.name;
	res.userLogin = ctx.user.id;

	try {
		changePassword(ctx, oldPassword, newPassword, repeatPassword);
	} catch(Exception ex) {
		res.pwChangeMessage = ex.msg;
	}

	return res;
}