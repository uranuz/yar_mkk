module mkk_site.view_service.registration;

import mkk_site.view_service.service;
import mkk_site.view_service.utils;

shared static this() {
	ViewService.pageRouter.join!(findTourist)("/dyn/user/reg/find_tourist");
	ViewService.pageRouter.join!(userReg)("/dyn/user/reg");
}

import ivy;
import mkk_site.data_model.tourist_edit;

@IvyModuleAttr(`mkk.UserReg.FindTourist`)
IvyData findTourist(HTTPContext ctx)
{
	auto req = ctx.request;

	return IvyData();
}

@IvyModuleAttr(`mkk.UserReg`)
IvyData userReg(HTTPContext ctx)
{
	import std.conv: ConvException, to;
	import std.json: JSONValue;
	import webtank.common.optional: Optional;
	import webtank.common.std_json.to: toStdJSON;
	import webtank.net.deserialize_web_form: formDataToStruct;
	auto req = ctx.request;
	Optional!size_t touristNum;

	try {
		touristNum = req.form.get("num", null).to!size_t;
	} catch(ConvException) {}

	if( req.form.get("action", null) == "write" ) {
		TouristDataToWrite touristData;
		UserRegData userData;
		formDataToStruct(req.form, touristData);
		formDataToStruct(req.form, userData);

		ctx.mainServiceCall(`user.register`, [
			`touristData`: touristData.toStdJSON(),
			`userData`: userData.toStdJSON()
		]);
	} else {
		return IvyData([
			"tourist": ctx.mainServiceCall(`tourist.read`, [
				`touristNum`: (touristNum.isSet? JSONValue(touristNum): JSONValue())
			])
		]);
	}
	return IvyData();
}