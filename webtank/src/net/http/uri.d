module webtank.net.http.uri;

import std.string, std.exception, std.uri, std.utf;

import std.range,
		std.string,
		std.ascii,
		std.socket;

import std.stdio;


/// Exception thrown when an URI doesn't parse.
class URIException : Exception
{	this(string msg, string file = __FILE__, size_t line = __LINE__)  pure nothrow{
		super(msg, file, line);
	}
}

/**

	An attempt at implementing URI (RFC 3986).

All constructed URI are valid and normalized.
Bugs:
$(UL
	$(LI Separate segments in parsed form.)
	$(LI Relative URL combining.)
	$(LI . and .. normalization.)
)

Alternative:
	Consider using $(WEB vibed.org,vibe.d) if you need something better.
*/
struct URI
{
	public
	{
		enum HostType
		{
				NONE,
				REG_NAME, /// Host has a registered name.
				IPV4,     /// Host has an IPv4
				IPV6,     /// Host has an IPv6
				IPVFUTURE /// Unknown yet scheme.
		}

		/// Creactes an URI from an input range, throws if invalid.
		/// Input should be an ENCODED url range.
		/// Throws: $(D URIException) if the URI is invalid.
		this(T)(T input) if (isForwardRange!T)
		{
				_scheme = null;
				_hostType = HostType.NONE;
				_hostName = null;
				_port = 0;
				_userInfo = null;
				_path = null;
				_query = null;
				_fragment = null;
				parseURI(input);
		}

		/// Checks URI validity.
		/// Returns: true if input is valid.
		static bool isValid(T)(T input) /* pure */ nothrow
		{
			try
			{
				try
				{
					URI uri = new URI(input);
					return true;
				}
				catch (URIException e)
				{
					return false;
				}
			}
			catch (Exception e)
			{
				assert(false); // came here? Fix the library by writing the missing catch-case.
			}
		}

		// getters and setters for normalized URI components

		/// Returns: URI scheme, guaranteed not null.
		string scheme() @property pure const nothrow
		{	return _scheme;
		}

		void scheme(string value) @property pure nothrow
		{	_scheme = value;
		}

		/// Returns: Host name, or null if not available.
		string hostName() @property pure const nothrow
		{	return _hostName;
		}

		void hostName(string value) @property pure nothrow
		{	_hostName = value;
		}

		/// Returns: Host type (HostType.NONE if not available).
		HostType hostType() @property pure const nothrow
		{
			return _hostType;
		}

		/**
			* Returns: port number.
			* If none is provided by the URI, return the default port for this scheme.
			* If the scheme isn't recognized, return 0.
			*/
		ushort port() @property pure const nothrow
		{
			if (_port != 0)
				return _port;

			foreach (ref e; knownSchemes)
				if (e.scheme == _scheme)
					return e.defaultPort;

			return 0;
		}

		void port(ushort value) @property pure nothrow
		{	_port = value;
		}

		/// Returns: User-info part of the URI, or null if not available.
		string userInfo() @property pure const nothrow
		{	return _userInfo;
		}

		/// Returns: Path part of the URI, never null, can be the empty string.
		string rawPath() @property pure const nothrow
		{	return _path;
		}

		void rawPath(string value) @property pure nothrow
		{	_path = value;
		}

		/// Returns: Path part of the URI, never null, can be the empty string.
		string path() @property pure const nothrow
		{	return _path;
		}

		void path(string value) @property pure nothrow
		{	_path = value;
		}

		string rawQuery() @property pure const nothrow
		{	return _query;
		}

		void rawQuery(string value) @property pure nothrow
		{	_query = value;
		}

		/// Returns: Query part of the URI, or null if not available.
		string query() @property pure const nothrow
		{	
		}

		void query(string value) @property pure nothrow
		{	_query = value;
		}

		/// Returns: Fragment part of the URI, or null if not available.
		string rawFragment() @property pure const nothrow
		{	return _fragment;
		}

		void rawFragment(string value) @property pure nothrow
		{	_fragment = value;
		}

		/// Returns: Fragment part of the URI, or null if not available.
		string fragment() @property pure const nothrow
		{	return _fragment;
		}

		void fragment(string value) @property pure nothrow
		{	_fragment = value;
		}

		/// Returns: Authority part of the URI.
		string authority() @property pure const nothrow
		{
			if ( _hostName.length == 0 )
				return "";

			string res = "";
			if( _userInfo.length > 0 )
				res ~= _userInfo ~ "@";

			res ~= _hostName;

			if (_port != 0)
				res ~= ":" ~ itos(_port);

			return res;
		}

		void authority(string value) @property /+pure+/
		{	//Clearing authority data
			_userInfo = null;
			_hostName = null;
			_port = 0;
			parseAuthority(value);
		}

		/// Resolves URI host name.
		/// Returns: std.socket.Address from the URI.
		Address resolveAddress()
		{
			final switch(_hostType)
			{
				case HostType.REG_NAME:
				case HostType.IPV4:
					return new InternetAddress(_hostName, cast(ushort)port());

				case HostType.IPV6:
					return new Internet6Address(_hostName, cast(ushort)port());

				case HostType.IPVFUTURE:
				case HostType.NONE:
					throw new URIException("Cannot resolve such host");
			}
		}

		/// Returns: Pretty string representation.
		override string toString() const
		{
			string res;

			if( !_scheme.empty )
				res ~= _scheme ~ ":";

			if ( !_hostName.empty )
				res = res ~ "//" ~ authority;

			res ~= _path;

			if( !_query.empty )
				res = res ~ "?" ~ _query;
			if( _fragment.length != 0 )
				res = res ~ "#" ~ _fragment;
			return res;
		}

		/// Semantic comparison of two URIs.
		/// They are equals if they have the same normalized string representation.
		bool opEquals(U)(U other) pure const nothrow if (is(U : FixedPoint))
		{	return value == other.value;
		}
	}

	private
	{
		// normalized URI components
		string _scheme;     // never null, never empty
		string _userInfo;   // can be null
		HostType _hostType; // what the hostname string is (NONE if no host in URI)
		string _hostName;   // null if no authority in URI
		ushort _port;          // 0 if no port in URI
		string _path;       // never null, bu could be empty
		string _query;      // can be null
		string _fragment;   // can be null

		// URI         = scheme ":" hier-part [ "?" query ] [ "#" fragment ]
		void parseURI(T)(ref T input)
		{	 auto inputOrigin = input[];
			_scheme = toLower(parseScheme(input));
			//consume(input, ':');
			if( _scheme.empty )
				input = inputOrigin;

			parseHierPart(input);

			if (input.empty)
				return;

			char c = popChar(input);

			if (c == '?')
			{
				_query = parseQuery(input);

				if (input.empty)
					return;

				c = popChar(input);
			}

			if (c == '#')
			{
				_fragment = parseFragment(input);
			}

			if (!input.empty)
				throw new URIException("unexpected characters at end of URI");
		}

		string parseScheme(T)(ref T input)
		{
// 			writeln("parseScheme input: ", input);
			string result = "";
			char c = peekChar(input);

			if( !isAlpha(c) )
				return "";
				//throw new URIException("expected alpha character in URI scheme");

			input.popFront();
			result ~= c;

			while(!input.empty)
			{
				c = peekChar(input);

				if (isAlpha(c) || isDigit(c) || "+-.".contains(c))
				{
					result ~= c;
					input.popFront();
				}
				else if( c == ':' )
				{	input.popFront();
					return result;
				}
				else
					return "";
			}

			if( input.empty )
				return "";
			assert(0);
		}

		// hier-part   = "//" authority path-abempty
		//             / path-absolute
		//             / path-rootless
		//             / path-empty
		void parseHierPart(T)(ref T input)
		{
// 			writeln("parseHierPart input: ", input);
			if (input.empty())
				return; // path-empty

			char c = peekChar(input);
			if (c == '/')
			{
				T sinput = input.save;
				input.popFront();

				if (!input.empty() && peekChar(input) == '/')
				{
					consume(input, '/');
					parseAuthority(input);
					_path = parseAbEmpty(input);
				}
				else
				{
					input = sinput.save;
					_path = parsePathAbsolute(input);
				}
			}
			else
			{
				_path = parsePathRootless(input);
			}
		}

		// authority   = [ userinfo "@" ] host [ ":" port ]
		void parseAuthority(T)(ref T input)
		{		/+writeln("parseAuthority input: ", input);+/
			// trying to parse user
			T uinput = input.save;
			try
			{
				_userInfo = parseUserinfo(input);
				consume(input, '@');
			}
			catch(URIException e)
			{
				// no user name in URI
				_userInfo = null;
				input = uinput.save;
			}

			parseHost(input, _hostName, _hostType);

			if (!empty(input) && peekChar(input) == ':')
			{
				consume(input, ':');
				_port = parsePort(input);
			}
		}

		string parsePcharString(T)(ref T input, bool allowColon, bool allowAt, bool allowSlashQuestionMark)
		{
			string res = "";

			while(!input.empty)
			{
				char c = peekChar(input);

				if (isUnreserved(c) || isSubDelim(c))
					res ~= popChar(input);
				else if (c == '%')
					res ~= parsePercentEncodedChar(input);
				else if (c == ':' && allowColon)
					res ~= popChar(input);
				else if (c == '@' && allowAt)
					res ~= popChar(input);
				else if ((c == '?' || c == '/') && allowSlashQuestionMark)
					res ~= popChar(input);
				else
					break;
			}
			return res;
		}


		void parseHost(T)(ref T input, out string res, out HostType hostType)
		{	/+writeln("parseHost input: ", input);+/
			char c = peekChar(input);
			if (c == '[')
				parseIPLiteral(input, res, hostType);
			else
			{
				T iinput = input.save;
				try
				{
					hostType = HostType.IPV4;
					res = parseIPv4Address(input);
				}
				catch (URIException e)
				{
					input = iinput.save;
					hostType = HostType.REG_NAME;
					res = toLower(parseRegName(input));
				}
			}
		}

		void parseIPLiteral(T)(ref T input, out string res, out HostType hostType)
		{
			consume(input, '[');
			if (peekChar(input) == 'v')
			{
				hostType = HostType.IPVFUTURE;
				res = parseIPv6OrFutureAddress(input);
			}
			else
			{
				hostType = HostType.IPV6;
				string ipv6 = parseIPv6OrFutureAddress(input);

				// validate and expand IPv6 (for normalizaton to be effective for comparisons)
				try
				{
					ubyte[16] bytes = Internet6Address.parse(ipv6);
					res = "";
					foreach (i ; 0..16)
					{
							if ((i & 1) == 0 && i != 0)
								res ~= ":";
							res ~= format("%02x", bytes[i]);
					}
				}
				catch(SocketException e)
				{
					// IPv6 address did not parse
					throw new URIException(e.msg);
				}
			}
			consume(input, ']');
		}

		string parseIPv6OrFutureAddress(T)(ref T input)
		{
			string res = "";
			while (peekChar(input) != ']')
				res ~= popChar(input);
			return res;
		}

		string parseIPv4Address(T)(ref T input)
		{
			int a = parseDecOctet(input);
			consume(input, '.');
			int b = parseDecOctet(input);
			consume(input, '.');
			int c = parseDecOctet(input);
			consume(input, '.');
			int d = parseDecOctet(input);
			return format("%s.%s.%s.%s", a, b, c, d);
		}

		// dec-octet     = DIGIT                 ; 0-9
		//               / %x31-39 DIGIT         ; 10-99
		//               / "1" 2DIGIT            ; 100-199
		//               / "2" %x30-34 DIGIT     ; 200-249
		//               / "25" %x30-35          ; 250-255
		int parseDecOctet(T)(ref T input)
		{
			int res = popDigit(input);

			if (!input.empty && isDigit(peekChar(input)))
			{
				res = 10 * res + popDigit(input);

				if (!input.empty && isDigit(peekChar(input)))
					res = 10 * res + popDigit(input);
			}

			if (res > 255)
				throw new URIException("out of range number in IPv4 address");

			return res;
		}

		// query         = *( pchar / "/" / "?" )
		string parseQuery(T)(ref T input)
		{
			return parsePcharString(input, true, true, true);
		}

		// fragment      = *( pchar / "/" / "?" )
		string parseFragment(T)(ref T input)
		{
			return parsePcharString(input, true, true, true);
		}

		// pct-encoded   = "%" HEXDIG HEXDIG
		char parsePercentEncodedChar(T)(ref T input)
		{
			consume(input, '%');

			int char1Val = hexValue(popChar(input));
			int char2Val = hexValue(popChar(input));
			return cast(char)(char1Val * 16 + char2Val);
		}

		// userinfo      = *( unreserved / pct-encoded / sub-delims / ":" )
		string parseUserinfo(T)(ref T input)
		{	/+writeln("parseUserinfo input: ", input);+/
			return parsePcharString(input, true, false, false);
		}

		// reg-name      = *( unreserved / pct-encoded / sub-delims )
		string parseRegName(T)(ref T input)
		{
			return parsePcharString(input, false, false, false);
		}

		// port          = *DIGIT
		ushort parsePort(T)(ref T input)
		{
			ushort res = 0;

			while(!input.empty)
			{
				char c = peekChar(input);
				if (!isDigit(c))
					break;
				res = cast(ushort) ( res * 10u + popDigit(input) );
			}
			return res;
		}

		// segment       = *pchar
		// segment-nz    = 1*pchar
		// segment-nz-nc = 1*( unreserved / pct-encoded / sub-delims / "@" )
		string parseSegment(T)(ref T input, bool allowZero, bool allowColon)
		{
			string res = parsePcharString(input, allowColon, true, false);
			if (!allowZero && res == "")
				throw new URIException("expected a non-zero segment in URI");
			return res;
		}

		// path-abempty  = *( "/" segment )
		string parseAbEmpty(T)(ref T input)
		{	/+writeln("parseAbEmpty input: ", input);+/
			string res = "";
			while (!input.empty)
			{
				if (peekChar(input) != '/')
					break;
				consume(input, '/');
				res = res ~ "/" ~ parseSegment(input, true, true);
			}
			return res;
		}

		// path-absolute = "/" [ segment-nz *( "/" segment ) ]
		string parsePathAbsolute(T)(ref T input)
		{	/+writeln("parsePathAbsolute input: ", input);+/
			consume(input, '/');
			string res = "/";

			try
			{
				res ~= parseSegment(input, false, true);
			}
			catch(URIException e)
			{
				return res;
			}

			res ~= parseAbEmpty(input);
			return res;
		}

		string parsePathNoSlash(T)(ref T input, bool allowColonInFirstSegment)
		{	/+writeln("parsePathNoSlash input: ", input);+/
			string res = parseSegment(input, false, allowColonInFirstSegment);
			res ~= parseAbEmpty(input);
			return res;
		}

		// path-noscheme = segment-nz-nc *( "/" segment )
		string parsePathNoScheme(T)(ref T input)
		{	/+writeln("parsePathNoScheme input: ", input);+/
			return parsePathNoSlash(input, false);
		}

		// path-rootless = segment-nz *( "/" segment )
		string parsePathRootless(T)(ref T input)
		{	/+writeln("parsePathRootless input: ", input);+/
			return parsePathNoSlash(input, true);
		}
	}
}

private pure
{
	bool contains(string s, char c) nothrow
	{
		foreach(char sc; s)
			if (c == sc)
				return true;
		return false;
	}

	bool isAlpha(char c) nothrow
	{
		return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
	}

	bool isDigit(char c) nothrow
	{
		return c >= '0' && c <= '9';
	}

	bool isHexDigit(char c) nothrow
	{
		return hexValue(c) != ushort.max;
	}

	bool isUnreserved(char c) nothrow
	{
		return isAlpha(c) || isDigit(c) || "-._~".contains(c);
	}

	bool isReserved(char c) nothrow
	{
		return isGenDelim(c) || isSubDelim(c);
	}

	bool isGenDelim(char c) nothrow
	{
		return ":/?#[]@".contains(c);
	}

	bool isSubDelim(char c) nothrow
	{
		return "!$&'()*+,;=".contains(c);
	}

	ushort hexValue(char c) nothrow
	{
		if( isDigit(c) )
				return c - '0';
		else if (c >= 'a' && c <= 'f')
				return c - 'a';
		else if (c >= 'A' && c <= 'F')
				return c - 'A';
		else
				return ushort.max;
	}

	// peek char from input range, or throw
	char peekChar(T)(ref T input)
	{
		if (input.empty())
				throw new URIException("expected character");

		dchar c = input.front;

		if (cast(int)c >= 127)
				throw new URIException("US-ASCII character expected");

		return cast(char)c;
	}

	// pop char from input range, or throw
	char popChar(T)(ref T input)
	{
		char result = peekChar(input);
		input.popFront();
		return result;
	}

	ushort popDigit(T)(ref T input)
	{
		char c = popChar(input);
		if (!isDigit(c))
				throw new URIException("expected digit character");
		return hexValue(c);
	}

	void consume(T)(ref T input, char expected)
	{
		char c = popChar(input);
		if (c != expected)
				throw new URIException("expected '" ~ c ~ "' character");
	}

	string itos(int i) pure nothrow
	{
		string res = "";
		do
		{
				res = ('0' + (i % 10)) ~ res;
				i = i / 10;
		} while (i != 0);
		return res;
	}

	struct KnownScheme
	{	string scheme;
		ushort defaultPort;
	}

	enum knownSchemes =
	[
		KnownScheme("ftp", 21),
		KnownScheme("sftp", 22),
		KnownScheme("telnet", 23),
		KnownScheme("smtp", 25),
		KnownScheme("gopher", 70),
		KnownScheme("http", 80),
		KnownScheme("nntp", 119),
		KnownScheme("https", 443)
	];

}

unittest
{

	{
		string s = "HTTP://machin@fr.wikipedia.org:80/wiki/Uniform_Resource_Locator?Query%20Part=4#fragment%20part";
		assert(URI.isValid(s));
		auto uri = new URI(s);
		assert(uri.scheme == "http");
		assert(uri.userInfo == "machin");
		assert(uri.hostName == "fr.wikipedia.org");
		assert(uri.port == 80);
		assert(uri.authority == "machin@fr.wikipedia.org:80");
		assert(uri.path == "/wiki/Uniform_Resource_Locator");
		assert(uri.query == "Query Part=4");
		assert(uri.fragment == "fragment part");
	}

	// host tests
	{
		assert((new URI("http://truc.org")).hostType == URI.HostType.REG_NAME);
		assert((new URI("http://127.0.0.1")).hostType == URI.HostType.IPV4);
		assert((new URI("http://[2001:db8::7]")).hostType == URI.HostType.IPV6);
		assert((new URI("http://[v9CrazySchemeFromOver9000year]")).hostType == URI.HostType.IPVFUTURE);
	}

	auto wellFormedURIs =
	[
		"ftp://ftp.rfc-editor.org/in-notes/rfc2396.txt",
		"mailto:Quidam.no-spam@example.com",
		"news:fr.comp.infosystemes.www.auteurs",
		"gopher://gopher.quux.org/",
		"http://Jojo:lApIn@www.example.com:8888/chemin/d/acc%C3%A8s.php?q=req&q2=req2#signet",
		"ldap://[2001:db8::7]/c=GB?objectClass?one",
		"mailto:John.Doe@example.com",
		"tel:+1-816-555-1212",
		"telnet://192.0.2.16:80/",
		"urn:oasis:names:specification:docbook:dtd:xml:4.1.2",
		"about:",
	];

	foreach (wuri; wellFormedURIs)
	{	bool valid = URI.isValid(wuri);
		assert(valid);
	}
}

string separateQuery(const string URIString)
{	for( size_t i = 0; i < URIString.length; i++ )
		if( URIString[i] == '?' )
			return URIString[i+1..$].idup;
	return null;
}

string separatePath(const string URIString)
{	for( size_t i = 0; i < URIString.length; i++ )
		if( URIString[i] == '?' )
			return URIString[0..i].idup;
	return URIString;
}


//Эта функция принимает строку похожую на URI-запрос и анализирует. Результат
//возращается в ассоциативный массив типа  значение[ключ]. Осторожно, функция
//кидается исключениями, если что-то не так. Если запрос пуст, то возвращается
//массив с одной парой с пустым ключом и значением (чтобы при переборе оператором
//foreach не вылетало с исключением)
string[string] parseURIQuery(string queryStr)
{
	string[string] Res;
	if (queryStr=="") { Res[""]=""; return Res; }

	string ProcStr=queryStr;
	string Key=""; int i=0; bool KeyStarted=true; bool ValueStarted=false;

	while (true)
	{
		if ( i>=ProcStr.length )
		{	if (  ( (queryStr[$-1]=='=')
				|| Res.length==0) && (Key=="")  )
				throw new Exception("Не найден ключ в конце строки");
			else if (queryStr[$-1]=='&') throw new Exception("'&' не разрешён в конце строки");
			else Res[Key]=ProcStr[0..$];
			break;
		}
		if ( (ProcStr[i]=='=') || (ProcStr[i]=='&') )
		{	string Lex=ProcStr[0..i];
			if (ProcStr[i]=='=')
			{	if (ValueStarted==true) throw new Exception("Не найден разделитель переменных в выражении '"~Lex~"'");
				else
				{	Key=Lex;
					KeyStarted=true; ValueStarted=true;
				}
			}
			else if (ProcStr[i]=='&')
			{	if (KeyStarted==true && (Key!="") )
				{	Res[Key]=Lex; KeyStarted=false; Key=""; ValueStarted=false;
				}
				else throw new Exception("Не найден ключ в выражении '"~Lex~"'");
			}
			ProcStr=ProcStr[i+1..$]; i=0;
			continue;
		}
		++i;
	}
	return Res;
}

dstring[dstring] parseURIQuery2(dstring queryStr)
{	dstring[dstring] result;
	//dstring[][dstring] result;
	size_t LexStart = 0;
	dstring curKey;
	dstring curValue;
	for( size_t i = 0; i < queryStr.length; ++i )
	{	if( queryStr[i] == '=' )
		{	curKey = queryStr[LexStart..i].idup;
			curValue = null;
			LexStart = i+1;
		}
		if( (queryStr[i] == '&') || (i+1 == queryStr.length) )
		{	curValue = queryStr[ LexStart .. (i+1 == queryStr.length) ? ++i : i ].idup;
			if( curKey.length > 0)
			{	result[curKey] = curValue;
				//result[curKey] ~= curValue;
			}
			curKey = null;
			LexStart = i+1;
		}
	}
	return result;
}

string[string] parseURIQuery2(string queryStr)
{	string[string] result;
	import std.utf;
	foreach( key, value; parseURIQuery2( toUTF32(queryStr) ) )
		result[ toUTF8(key) ] = toUTF8(value);
	return result;
}


dstring[][dstring] parseURIQuery2Array(dstring queryStr)
{	dstring[][dstring] result;
	size_t LexStart = 0;
	dstring curKey;
	dstring curValue;
	for( size_t i = 0; i < queryStr.length; ++i )
	{	if( queryStr[i] == '=' )
		{	curKey = queryStr[LexStart..i].idup;
			curValue = null;
			LexStart = i+1;
		}
		if( (queryStr[i] == '&') || (i+1 == queryStr.length) )
		{	curValue = queryStr[ LexStart .. (i+1 == queryStr.length) ? ++i : i ].idup;
			if( curKey.length > 0)
			{	result[curKey] ~= curValue;
			}
			curKey = null;
			LexStart = i+1;
		}
	}
	return result;
}

string[][string] parseURIQuery2Array(string queryStr)
{	string[][string] result;
	import std.utf;
	foreach( key, values; parseURIQuery2Array( toUTF32(queryStr) ) )
	{	string decodedKey = toUTF8(key);
		foreach( val; values )
			result[ decodedKey ] ~= toUTF8(val);
	}
	return result;
}


unittest
{	string Query="ff=adfggg&text_inp1=kirpich&text_inp2=another_text&opinion=kupi_konya";
	string[string] Res=parseURIQuery(Query);
	assert(Res.length==4);
	assert (  Res["ff"]=="adfggg" && Res["text_inp1"]=="kirpich" &&
	          Res["text_inp2"]=="another_text" && Res["opinion"]=="kupi_konya"  );

}

string[string] extractURIData(string queryStr)
{	string[string] result;
	foreach( key, value; parseURIQuery2( queryStr ) )
		result[ decodeURI(key) ] = decodeURI(value);
	return result;
}

string[][string] extractURIDataArray(string queryStr)
{	string[][string] result;
	foreach( key, values; parseURIQuery2Array( queryStr ) )
	{	string decodedKey = decodeURI(key);
		foreach( val; values )
			result[ decodedKey ] ~= decodeURI(val);
	}
	return result;
}

//Декодировать URI. Прослойка на случай, если захотим написать свою версию, отличную
//от стандартной. TODO: Может переписать через alias? (однако неудобно смотреть аргументы)
string decodeURI(string src)
{	char[] result = src.dup;
	for ( int i = 0; i < src.length; ++i )
	{	if ( src[i] == '+' ) result[i] = ' '; //Заменяем плюсики на пробелы
	}
	return std.uri.decodeComponent(result.idup);
}

//Декодировать URI. Прослойка на случай, если захотим написать свою версию, отличную
//от стандартной. TODO: Может переписать через alias? (однако неудобно смотреть аргументы)
string encodeURI(string src)
{	char[] result = src.dup;
	for ( int i = 0; i < src.length; ++i )
	{	if ( src[i] == '+' ) result[i] = ' '; //Заменяем плюсики на пробелы
	}
	return std.uri.encodeComponent(result.idup);
}


string decodeComponent(string str)
{	

}


// import std.stdio;

// void main()
// {
// // 	string uri_string = "http://vasya@www.yandex.ru:8080/products/cars/mercedes?hello#goodbye";
// 	//string uri_string = "products/cars/mercedes?hello#goodbye";
// 	string uri_string = "http:products/cars/mercedes";
// 	URI uri = new URI(uri_string);
// 
// 	writeln("uri.scheme: ", uri.scheme);
// 	writeln("uri.authority: ", uri.authority);
// 	writeln("uri.userInfo: ", uri.userInfo);
// 	writeln("uri.host: ", uri.hostName);
// 	writeln("uri.port: ", uri.port);
// 	writeln("uri.path: ", uri.path);
// 	writeln("uri.query: ", uri.query);
// 	writeln("uri.fragment: ", uri.fragment);
// 	writeln("uri: ", uri);
// 
// }