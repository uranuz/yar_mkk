module mkk_site.security.crypto;

import std.base64: Base64URL;
import std.conv: to;

import deimos.openssl.sha;
import webtank.crypto.scrypt;
import mkk_site.common.session_id;

enum uint pwHashByteLength = 72; //Количество байт в хэше пароля
enum uint pwHashStrLength = pwHashByteLength * 8 / 6; //Длина в символах в виде base64 - строки
//alias ubyte[pwHashByteLength] PasswordHash;

enum scryptN = 1024;
enum scryptR = 8;
enum scryptP = 1;

//Служебная функция для генерации Ид сессии
SessionId generateSessionId(const(char)[] login, const(char)[] group, const(char)[] dateString)
{
    auto idSource = login ~ "::" ~ dateString ~ "::" ~ group; //Создаём исходную строку
	SessionId sessionId;
	SHA384( cast(const(ubyte)*) idSource.ptr, idSource.length, sessionId.ptr );
	return sessionId; //Возвращаем идентификатор сессии
}

import std.datetime, std.random, core.thread;

///Генерирует хэш для пароля с "солью" и "перцем"
ubyte[] makePasswordHash(
	const(char)[] password,
    const(char)[] salt,
    const(char)[] pepper,
	size_t hashByteLength = pwHashByteLength,
	ulong N = scryptN,
    uint r = scryptR,
    uint p = scryptP
) {	
    ubyte[] pwHash = new ubyte[hashByteLength];

	auto secret = password ~ pepper;
	auto spice = pepper ~ salt;

	int result = crypto_scrypt(
		cast(const(ubyte)*) secret.ptr, secret.length,
		cast(const(ubyte)*) spice.ptr, spice.length,
		N, r, p, pwHash.ptr, hashByteLength
	);

	if( result != 0 )
		throw new Exception("Cannot make password hash!!!");

	return pwHash;
}

///Кодирует хэш пароля для хранения в виде строки
string encodePasswordHash( const(ubyte[]) pwHash, ulong N = scryptN, uint r = scryptR, uint p = scryptP )
{
    return ( "scr$" ~ Base64URL.encode(pwHash) ~ "$" ~ pwHash.length.to!string
		~ "$" ~ N.to!string ~ "$" ~ r.to!string ~ "$" ~ p.to!string ).idup;
}

import std.array;

///Проверяет пароль на соответствие закодированному хэшу с заданной солью и перцем
bool checkPassword(const(char)[] encodedPwHash, const(char)[] password, const(char)[] salt, const(char)[] pepper)
{
    auto params = encodedPwHash.split("$");

	if( params.length != 6 || params[0] != "scr" )
		return false;

	ubyte[] pwHash = Base64URL.decode(params[1]);
	if( pwHash.length != params[2].to!size_t )
		return false;

	return pwHash == makePasswordHash(
        password,
        salt,
        pepper,
        params[2].to!size_t,
        params[3].to!ulong,
        params[4].to!uint,
        params[5].to!uint
    );
}