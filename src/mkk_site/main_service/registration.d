module mkk_site.main_service.registration;

import mkk_site.main_service.devkit;
import mkk_site.data_model.pohod_edit: PohodDataToWrite, DBName, PohodFileLink;
import webtank.security.right.common: GetSymbolAccessObject;
import mkk_site.history.client;
import mkk_site.history.common;
import mkk_site.data_model.tourist_edit;
import mkk_site.security.core.register_user: registerUser, addUserRoles;

import mkk_site.main_service.tourist_edit: editTourist;


shared static this()
{
	MainService.JSON_RPCRouter.join!(regUser)(`user.register`);
}

import std.json: JSONValue;
JSONValue regUser(HTTPContext ctx, TouristDataToWrite touristData, UserRegData userData)
{
	import webtank.db.transaction: makeTransaction;
	auto trans = getAuthDB().makeTransaction();
	scope(failure) trans.rollback();
	scope(success) trans.commit();

	import std.array: join;
	string[] nameParts; // Склеиваем имя пользователя
	if( touristData.familyName.isSet ) {
		nameParts ~= touristData.familyName.value;
	}
	if( touristData.givenName.isSet ) {
		nameParts ~= touristData.givenName.value;
	}
	if( touristData.patronymic.isSet ) {
		nameParts ~= touristData.patronymic.value;
	}
	
	size_t userNum = registerUser!(getAuthDB)(
		userData.login,
		userData.password,
		nameParts.join(` `),
		touristData.email
	);

	addUserRoles!(getAuthDB)(userNum, [`new_user`]);

	ctx.user = MainService.accessController.authenticateByPassword(
		userData.login,
		userData.password,
		ctx.request.headers[`x-real-ip`],
		ctx.request.headers[`user-agent`]
	);

	return JSONValue([
		"touristNum":  editTourist(ctx, touristData),
		"userNum": userNum
	]);
}