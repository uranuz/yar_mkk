module webtank.core.auth;

import std.process;

import webtank.core.http.cookies;
import webtank.db.postgresql;

class AuthException : Exception {
	this(string msg, string file = __FILE__, size_t line = __LINE__) {
		super(msg, file, line);
	}
}

class UserInfo
{	
	
}

//UserInfo getUserInfo

void strictAuth()
{	string cookieStr = getenv(`HTTP_COOKIE`);
	auto cookies = new Cookies(cookieStr);
	if( !cookies.hasName(`sid`) )
		throw new AuthException(`Session ID (SID) is not found in client's cookies`);
	
	string connStr = "dbname=postgres host=localhost user=postgres password=postgres";
	auto dbase = new DBPostgreSQL(connStr);
	if ( !dbase.isConnected )
		throw new AuthException(`Could not connect to session storage`);
	
	auto response = dbase.query(`select U.name, U.user_group from session join "user" as U on U.id = user_id;`);
	if( response.recordCount <= 0 )
		throw new AuthException(`Could not find user connected with session`);
	string userGroup = response.getValue(1);
	
	if( userGroup.length <= 0  )
		throw new AuthException(`Could not find out user group`);
		
	
	
}

