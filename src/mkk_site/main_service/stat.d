module mkk_site.main_service.stat;
import mkk_site.main_service.devkit;
import mkk_site.site_data;

import std.conv, std.string, std.utf;
import std.stdio;


//***********************Обявление метода*******************
shared static this()
{
	Service.JSON_RPCRouter.join!(statData)(`stat.Data`);
	//Service.JSON_RPCRouter.join!(statistSelect)(`stat.Select`);
	
}
//**********************************************************

import std.datetime: Date;
import std.typecons: tuple;
//----------------------------------------
	struct StatSelect
		{
			size_t conduct;//вид отображения
			string kodMKK;
			string organization;
			string territory;
			string beginYear;
			string endYear;
		}

 


//--------------------------------------------------------
import std.json;
 JSONValue statData
	(
		HTTPContext context,	
		StatSelect Select

	)

 {
	 import webtank.common.std_json.to;

		JSONValue StatSet ;	
	
			
			StatSet["conduct"]    = Select;
			
			
			//StatSet["expTabl"]     ;//= expTabl.toStdJSON();

		return StatSet;
 }