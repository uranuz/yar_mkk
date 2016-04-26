module mkk_site.user_settings;

import mkk_site.page_devkit;

import mkk_site.access_control;

static immutable(string) thisPagePath;

shared static this()
{
	thisPagePath = dynamicPath ~ "user_settings";
	PageRouter.join!(netMain)(thisPagePath);
}

string netMain(HTTPContext context)
{
	auto req = context.request;
	auto user = context.user;

	if( !user.isAuthenticated )
		return `<h3>Просмотр и изменение персональных настроек требует аутентификации на сайте!</h3>`;

	string oldPassword = req.bodyForm.get( "old_password", null );
	string newPassword = req.bodyForm.get( "new_password", null );
	string repeatPassword = req.bodyForm.get( "repeat_password", null );

	string msg;

	if( oldPassword.length > 0 && newPassword.length > 0 && repeatPassword.length > 0 )
	{
		if( newPassword == repeatPassword )
		{
			if( changeUserPassword!(true)( user.id, oldPassword, newPassword ) )
			{
				msg = `Смена пароля успешно завершена!`;
			}
			else
			{
				msg = `Произошла ошибка при попытке смены пароля! Возможно, введен неверный старый пароль`;
			}
		}
		else
		{
			msg = `Смена пароля не произведена. Новый пароль и подтверждение пароля не совпадают!`;
		}
	}

	static struct ViewModel
	{
		string userFullName;
		string userLogin;
		string message;
	}

	ViewModel vm = ViewModel(
		user.name,
		user.id,
		msg
	);

	return renderUserSettingsPage(vm);
}

string renderUserSettingsPage(VM)( ref VM vm )
{
	auto tpl = getPageTemplate( pageTemplatesDir ~ "user_settings.html" );
	tpl.setHTMLValue( "user_full_name", vm.userFullName );
	tpl.setHTMLValue( "user_login", vm.userLogin );
	tpl.setHTMLText( "pw_change_msg", vm.message );

	return tpl.getString();
}




