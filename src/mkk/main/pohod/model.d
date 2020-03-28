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
		@DBField("mkk_code") Undefable!string mkkCode;
		/// Номер книги
		@DBField("book_num") Undefable!string bookNum;
		/// Статус заявки
		@DBField("claim_state") Undefable!int claimState;
		/// Коментарий МКК
		@DBField("mkk_comment") Undefable!string mkkComment;
	}

	// Секция "Поход"
	@RightObjAttr(`pohod`) {
		/// Регион, где проходит поход
		@DBField("pohod_region") Undefable!string pohodRegion;
		/// Вид туризма
		@DBField("tourism_kind") Undefable!int tourismKind;
		/// Нитка маршрута
		@DBField("route") Undefable!string route;
		/// Категория сложности маршрута
		@DBField("complexity") Undefable!int complexity;
		/// Элементы категории сложности
		@DBField("complexity_elem") Undefable!int complexityElem;
		/// Дата начала похода
		@DBField("begin_date") Undefable!Date beginDate;
		/// Дата завершения похода
		@DBField("finish_date") Undefable!Date finishDate;
		/// Состояние прохождения маршрута
		@DBField("progress") Undefable!int progress;
		/// Коментарий руководителя группы
		@DBField("chief_comment") Undefable!string chiefComment;
	}

	// Секция "Группа"
	@RightObjAttr(`group`) {
		// Турклуб, организация, наименование коллектива, от имени которого организован поход
		@DBField("organization") Undefable!string organization;
		// Город, посёлок, район, область, где постояннно проживает основная часть участников похода
		@DBField("party_region") Undefable!string partyRegion;
		// Идентификатор руководителя похода в БД МКК
		@DBField("chief_num") Undefable!size_t chiefNum;
		// Идентификатор заместителя  руководителя в БД МКК (при наличии заместителя)
		@DBField("alt_chief_num") Undefable!size_t altChiefNum;
		// Идентификаторы участников группы в БД МКК
		@DBField("unit_neim") Undefable!(size_t[]) partyNums;
		// Общее число участников похода/ размер группы
		@DBField("party_size") Undefable!size_t partySize;
	}

	// Секция "Ссылки на доп. материалы"
	@DBField("links") Undefable!(PohodFileLink[]) extraFileLinks; // Ссылки на файлы/ документы связанные с походом/ маршрутом с их наименованием
} // @FieldSerializer
	bool dbSerializeMode = false; // При переводе в JSON названия полей берем для БД (при true) или из названий переменных

} // struct PohodDataToWrite

import std.meta: AliasSeq;
import std.datetime: Date, DateTime;

alias PohodFullFormatBase = AliasSeq!(
	PrimaryKey!(size_t, "num"),
	string, "mkk_code",
	string, "book_num",
	string, "pohod_region",
	string, "organization",
	string, "party_region",
	string, "route",
	Date, "begin_date",
	Date, "finish_date",
	size_t, "chief_num",
	size_t, "alt_chief_num",
	size_t, "party_size",
	string, "chief_comment",
	string, "mkk_comment",
	size_t, "tourism_kind",
	size_t, "complexity",
	size_t, "complexity_elem",
	size_t, "progress",
	size_t, "claim_state",
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
