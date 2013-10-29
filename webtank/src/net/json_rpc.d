module webtank.net.json_rpc;

import std.stdio, std.string, std.conv, std.traits, std.typecons, std.json;

//Класс исключения для удалённого вызова процедур
class JSON_RPC_Exception : Exception {
	this(string msg, string file = __FILE__, size_t line = __LINE__) {
		super(msg, file, line);
	}
}

