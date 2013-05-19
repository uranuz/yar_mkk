module webtank.net.response;

import webtank.net.cookies;
import webtank.net.uri;

class Response  //Ответ приложения
{
protected:
	string _respBody = "";
	string[] _headers;
	Cookies _cookies; //Куки в ответ
public:
	this()
	{	_cookies = new Cookies; 
	}
	
	void write(string str)
	{	_respBody ~= str; }
	
	void opOpAssign(string op: "~")(string str)
	{	_respBody ~= str; }
	
	void redirect(string location)
	{	addHeader("Status: 302 Found");
		addHeader("Location: " ~ location);
	}
	
	void addHeader(string header)
	{	_headers ~= header; }
	
	void _submit()
	{	import std.stdio;
		string responseStr = _getHeaderStr() ~ _respBody;
		std.stdio.write( responseStr );
	}
	
	Cookies cookies() @property
	{ return _cookies; }

protected:
	string _getCustomHeaderStr()
	{	string result;
		foreach(header; _headers)
			result ~= header ~ "\r\n";
		return result;
	}
	
	string _getHeaderStr()
	{	return 
			_getCustomHeaderStr()
			~ _cookies.getResponseStr() 
			~ "Content-type: text/html; charset=\"utf-8\" \r\n\r\n"; 
	}
}