module mkk.main.tourist.model;

import mkk.main.devkit;

// Структура для записи данных о туристе
struct TouristDataToWrite
{
	Optional!size_t num; // номер туриста

@FieldSerializer!maybeDBSerializeMethod
@RightObjAttr(`tourist.item`)
{
	@RightObjAttr() {
		@DBField("family_name") Undefable!string familyName; // фамилия
		@DBField("given_name") Undefable!string givenName; // имя
		@DBField("patronymic") Undefable!string patronymic; // отчество
	}
	@RightObjAttr(`birthDate`) {
		@DBField("birth_year") Undefable!int birthYear; // год рождения
		@DBField("birth_date") Undefable!int birthMonth; // месяц рождения
		/*Специально без DBField*/ Undefable!int birthDay; // день рождения
	}
	@RightObjAttr() {
		@DBField("address") Undefable!string address; // адрес проживания
		@DBField("phone") Undefable!string phone; // телефон
		@DBField("show_phone") Undefable!bool showPhone; // отображать телефон
		@DBField("email") Undefable!string email; // email
		@DBField("show_email") Undefable!bool showEmail; // отображать email
		@DBField("exp") Undefable!string experience; // туристский опыт
		@DBField("comment") Undefable!string comment; // коментарий
		@DBField("razr") Undefable!int sportsCategory; // спортивный разряд
		@DBField("sud") Undefable!int refereeCategory; // судейская категория
	}
}
	bool dbSerializeMode = false; // При переводе в JSON названия полей берем для БД (при true) или из названий переменных
}

import std.meta: AliasSeq;
import std.datetime: Date, DateTime;

alias TouristFullFormatBase = AliasSeq!(
	PrimaryKey!(size_t, "num"),
	string, "family_name",
	string, "given_name",
	string, "patronymic",
	string, "birth_date",
	size_t, "birth_year",
	string, "address",
	string, "phone",
	bool, "show_phone",
	string, "email",
	bool, "show_email",
	string, "exp",
	string, "comment",
	size_t, "razr",
	size_t, "sud",
	DateTime, "reg_timestamp",
	DateTime, "last_edit_timestamp",
	size_t, "last_editor_num",
	size_t, "registrator_num"
);

static immutable touristFullFormat = RecordFormat!(TouristFullFormatBase)();
static immutable touristFullFormatExt = RecordFormat!(
	TouristFullFormatBase,
	DateTime, "last_edit_timestamp_utc" // Служебное поле
)();

private string getTouristFullQuery(T)(ref T format) {
	import std.algorithm: map;
	import std.array: join;

	return "select\n" ~ format.names.map!(
		(name) => (name == "last_edit_timestamp_utc"?
			`last_edit_timestamp at time zone 'UTC'`: `"` ~ name ~ `"`)
	).join(",\n")
	~ `from tourist `;
}

static immutable string touristFullQuery;
static immutable string touristFullQueryExt;
shared static this() {
	touristFullQuery = getTouristFullQuery(touristFullFormat);
	touristFullQueryExt = getTouristFullQuery(touristFullFormatExt);
}