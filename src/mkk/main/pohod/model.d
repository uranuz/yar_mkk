module mkk.main.pohod.model;

import mkk.main.devkit;

alias PohodFileLink = Tuple!(
	string, `link`,
	string, `name`,
	Optional!size_t, `num`
);

struct PohodDataToWrite
{
	import std.datetime: Date;
	Optional!size_t num; // Номер похода в базе

@FieldSerializer!maybeDBSerializeMethod
@RightObjAttr(`pohod.item`) // Пространство имён для прав
@RightObjAttr() // Признак, что нужно добавлять название самого поля в качестве последнего элемента
{
	// Секция "Маршрутная книжка"
	@RightObjAttr(`book`) {
		/// Код МКК
		@DBField("kod_mkk") Undefable!string mkkCode;
		/// Номер книги
		@DBField("nomer_knigi") Undefable!string bookNum;
		/// Статус заявки
		@DBField("stat") Undefable!int claimState;
		/// Коментарий МКК
		@DBField("MKK_coment") Undefable!string mkkComment;
	}

	// Секция "Поход"
	@RightObjAttr(`pohod`) {
		/// Регион, где проходит поход
		@DBField("region_pohod") Undefable!string pohodRegion;
		/// Вид туризма
		@DBField("vid") Undefable!int tourismKind;
		/// Нитка маршрута
		@DBField("marchrut") Undefable!string route;
		/// Категория сложности маршрута
		@DBField("ks") Undefable!int complexity;
		/// Элементы категории сложности
		@DBField("elem") Undefable!int complexityElems;
		/// Дата начала похода
		@DBField("begin_date") Undefable!Date beginDate;
		/// Дата завершения похода
		@DBField("finish_date") Undefable!Date finishDate;
		/// Состояние прохождения маршрута
		@DBField("prepar") Undefable!int progress;
		/// Коментарий руководителя группы
		@DBField("chef_coment") Undefable!string chiefComment;
	}

	// Секция "Группа"
	@RightObjAttr(`group`) {
		// Турклуб, организация, наименование коллектива, от имени которого организован поход
		@DBField("organization") Undefable!string organization;
		// Город, посёлок, район, область, где постояннно проживает основная часть участников похода
		@DBField("region_group") Undefable!string partyRegion;
		// Идентификатор руководителя похода в БД МКК
		@DBField("chef_grupp") Undefable!size_t chiefNum;
		// Идентификатор заместителя  руководителя в БД МКК (при наличии заместителя)
		@DBField("alt_chef") Undefable!size_t altChiefNum;
		// Идентификаторы участников группы в БД МКК
		@DBField("unit_neim") Undefable!(size_t[]) partyNums;
		// Общее число участников похода/ размер группы
		@DBField("unit") Undefable!size_t partySize;
	}

	// Секция "Ссылки на доп. материалы"
	@DBField("links") Undefable!(PohodFileLink[]) extraFileLinks; // Ссылки на файлы/ документы связанные с походом/ маршрутом с их наименованием
} // @FieldSerializer
	bool dbSerializeMode = false; // При переводе в JSON названия полей берем для БД (при true) или из названий переменных

} // struct PohodDataToWrite

import std.meta: AliasSeq;
import std.datetime: Date, DateTime;

alias PohodFullFormatBase = AliasSeq!(
	PrimaryKey!(size_t), "num",
	string, "kod_mkk",
	string, "nomer_knigi",
	string, "region_pohod",
	string, "organization",
	string, "region_group",
	string, "marchrut",
	Date, "begin_date",
	Date, "finish_date",
	size_t, "chef_grupp",
	size_t, "alt_chef",
	size_t, "unit",
	string, "chef_coment",
	string, "MKK_coment",
	size_t[], "unit_neim",
	size_t, "vid",
	size_t, "ks",
	size_t, "elem",
	size_t, "prepar",
	size_t, "stat",
	DateTime, "reg_timestamp",
	DateTime, "last_edit_timestamp",
	size_t, "last_editor_num",
	size_t, "registrator_num",
	string[], "links"
);

static immutable pohodFullFormat = RecordFormat!(PohodFullFormatBase)();
static immutable pohodFullFormatExt = RecordFormat!(
	PohodFullFormatBase,
	DateTime, "last_edit_timestamp_utc" // Служебное поле
)();

private string getPohodFullQuery(T)(ref T format) {
	import std.algorithm: map;
	import std.array: join;

	return "select\n" ~ format.names.map!( (name) {
		if( name == "last_edit_timestamp_utc" )
			return `last_edit_timestamp at time zone 'UTC'`;
		else if( name == "links" )
// Костыль для "правильного" форматирования массива строк
// т.к. формат возврата массивов из Postgres не очень стабилен
			return `to_json(links) "links"`;
		else
			return `"` ~ name ~ `"`;
	}).join(",\n")
	~ `from pohod `;
}

static immutable string pohodFullQuery;
static immutable string pohodFullQueryExt;

shared static this() {
	pohodFullQuery = getPohodFullQuery(pohodFullFormat);
	pohodFullQueryExt = getPohodFullQuery(pohodFullFormatExt);
}
