module mkk_site.main_service.auth;

import mkk_site.main_service.service;

shared static this()
{
	//Service.JSON_RPCRouter.join!(getUserInfoBySessionId)(`auth.userInfoBySID`);
	Service.JSON_RPCRouter.join!(getUserInfoBySessionId)(`auth.authenticateByPassword`);
}

getUserInfoBySID()
{

}

string authenticateByPassword(string login, string password)
{


}