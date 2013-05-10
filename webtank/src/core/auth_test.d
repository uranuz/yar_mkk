module webtank.auth_test;

import std.stdio;
import std.process;

import webtank.auth;
import webtank.core.http.cookies;

//void AuthenticateUser()
//{
	
	
//}


int main()
{	
	/*writeln(
		"Content-type: text/html\r\n"
		"Set-Cookie: username=aaa13; path=/\r\n"
		"Set-Cookie: password=pass\r\n"
		"Set-Cookie: surname=Vasukov\r\n"
	);
	auto cookies = parseResponseCookieStr( getenv(`HTTP_COOKIE`) );
	foreach(key, val; cookies)
	{	writeln(key ~ `: "` ~ val ~ `"` );
	}
	writeln(cookies[`username`]);*/
	//writeln(getenv(`HTTP_COOKIE`));
	//char[] buf; while (stdin.readln(buf)) write(buf);
	auto cook = new Cookies;
	cook[`vasya`] = `aaa`;
	cook.setDomain(`.localhost`, `vasya`);
	cook.setPath(`/cgi-bin/webtank`, `vasya`);
	cook.setHTTPOnly(true, `vasya`);
	write(cook.getStr());
	write("Content-type: text/html; charset=UTF-8\r\n\r\n");
	
	writeln(`<hr>`);
	writeln(getenv(`HTTP_COOKIE`));
	return 0;
}