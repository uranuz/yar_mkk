module mkk.main.user.settings;

import mkk.main.devkit;
import webtank.security.auth.core.change_password: changeUserPassword;
import webtank.ivy.main_service: MainServiceContext;


shared static this()
{
	MainService.JSON_RPCRouter.join!(changePassword)(`user.changePassword`);

	MainService.pageRouter.joinWebFormAPI!(renderUserSettings)("/api/user/settings");
}


void changePassword(
	MainServiceContext ctx,
	string oldPassword,
	string newPassword,
	string repeatPassword
) {
	import webtank.security.auth.common.exception: AuthException;
	
	enforce!AuthException(
		ctx.user.isAuthenticated,
		`Изменение пароля пользователя требует аутентификации на сайте!`
	);
	enforce!AuthException(
		oldPassword.length > 0 && newPassword.length > 0 && repeatPassword.length > 0,
		`Некоторые параметры не заданы!`
	);
	enforce!AuthException(
		newPassword == repeatPassword,
		`Смена пароля не произведена. Новый пароль и подтверждение пароля не совпадают!`
	);
	import std.functional: toDelegate;
	enforce!AuthException(
		// Здесь, естественно, необходимо проверять старый пароль перед тем как его сменить, иначе будет пичально...
		changeUserPassword!(/*doPwCheck=*/true)(ctx.service, ctx.user.id, oldPassword, newPassword),
		`Произошла ошибка при попытке смены пароля! Возможно, введен неверный старый пароль`
	);
}

Tuple!(
	string, `userFullName`,
	string, `userLogin`,
	string, `pwChangeMessage`
)
renderUserSettings(
	MainServiceContext ctx,
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