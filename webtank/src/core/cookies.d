module webtank.core.cookies;

class Cookies
{	
protected:
	string[string] _values;
	string[string] _domains;
	string[string] _paths;
	string[string] _expires;
	bool[string] _HTTPOnlyFlags;
	bool[string] _secureFlags;
	
	
public:
	this( string cookieStr )
	{	_values = parseResponseCookieStr(cookieStr);
	}
	
	this() {}
	
	string opIndex(string name)
	{	return _values.get(name, null); }
	
	void opIndexAssign(string value, string name)
	{	if( value !is null)
			_values[name] = value;
	}
	void setDomain(string value, string name)
	{	if( (value !is null) && (name in _values) )
			_domains[name] = value;
	}
	void setPath(string value, string name)
	{	if( (value !is null) && (name in _values) )
			_paths[name] = value;
	}
	void setExpiresStr(string value, string name)
	{	if( (value !is null) && (name in _values) )
			_expires[name] = value;
	}
	void setSecure(bool value, string name)
	{	if( name in _values )
			_secureFlags[name] = value;
	}
	void setHTTPOnly(bool value, string name)
	{	if( name in _values )
			_HTTPOnlyFlags[name] = value;
	}
	
	bool hasName(string name)
	{	return ( name in _values ) ? true : false; }
	
	string getResponseStr()
	{	string result;
		size_t count = 0;
		foreach( name, value; _values )
		{	result ~= `Set-Cookie: ` ~ name ~ `=` ~ value;
			if( (name in _domains) && (_domains[name] !is null) )
				result ~= `; Domain=` ~ _domains[name];
			if( (name in _paths) && (_paths[name] !is null) )
				result ~= `; Path=` ~ _paths[name];
			if( (name in _expires) && (_expires[name].length > 0) )
				result ~= `; Expires=` ~ _expires[name];
			if( (name in _HTTPOnlyFlags) && (_HTTPOnlyFlags[name]) )
				result ~= `; HttpOnly`;
			if( (name in _secureFlags) && (_secureFlags[name]) )
				result ~= `; Secure`;
			result ~= "\r\n";
		}
		return result;
	}
}


string[string] parseResponseCookieStr(string cookieStr)
{	string[string] result;
	import std.array;
	string[] rawVars = split(cookieStr, `; `);
	foreach(var; rawVars)
	{	auto varParts = split(var, `=`);
		result[ varParts[0] ] = varParts[1];
	}
	return result;
}

Cookies getCookies()
{	import std.process;
	return new Cookies( getenv(`HTTP_COOKIE`) ); //Актуально для Apache
	
}