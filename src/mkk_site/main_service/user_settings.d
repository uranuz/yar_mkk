module mkk_site.main_service.user_settings;

import mkk_site.main_service.devkit;
import mkk_site.security.access_control;

shared static this()
{
	Service.JSON_RPCRouter.join!(changePassword)(`user.changePassword`);
}

void changePassword(
	HTTPContext ctx,
	string oldPassword,
	string newPassword,
	string repeatPassword
) {
	import std.exception: enforce;

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
		changeUserPassword!(true)( toDelegate(&getAuthDB), ctx.user.id, oldPassword, newPassword ),
		`Произошла ошибка при попытке смены пароля! Возможно, введен неверный старый пароль`
	);
}