module mkk_site.data_defs.pohod_edit;

struct DBName { string dbName; }

struct PohodDataToWrite
{
	import webtank.common.optional: Optional, Undefable;
	import std.datetime: Date;
	Optional!size_t num; // Номер походе в базе

	// Секция "Маршрутная книжка"
	@DBName("kod_mkk") Undefable!string mkkCode; // Код МКК
	@DBName("nomer_knigi") Undefable!string bookNum; // Номер книги
	@DBName("stat") Undefable!int claimState; // Статус заявки
	@DBName("MKK_coment") Undefable!string mkkComment; // Коментарий МКК

	// Секция "Поход"
	@DBName("region_pohod") Undefable!string pohodRegion; // Регион, где проходит поход
	@DBName("vid") Undefable!int tourismKind; // Вид туризма
	@DBName("marchrut") Undefable!string route; // Нитка маршрута
	@DBName("ks") Undefable!int complexity; // Категория сложности маршрута
	@DBName("elem") Undefable!int complexityElems; // Элементы категори сложности
	@DBName("begin_date") Undefable!Date beginDate; // Дата начала похода
	@DBName("finish_date") Undefable!Date finishDate; // Дата завершения похода
	@DBName("prepar") Undefable!int progress; // Состояние прохождения маршрута
	@DBName("chef_coment") Undefable!string chiefComment; // Коментарий руководителя группы

	// Секция "Группа"
	@DBName("organization") Undefable!string organization; // Турклуб, организация, наименование коллектива, от имени которого организован поход
	@DBName("region_group") Undefable!string partyRegion; // Город, посёлок, район, область, где постояннно проживает основная часть участников похода
	@DBName("chef_grupp") Undefable!size_t chiefNum; // Идентификатор руководителя похода в БД МКК
	@DBName("alt_chef") Undefable!size_t altChiefNum; // Идентификатор заместителя  руководителя в БД МКК (при наличии заместителя)
	@DBName("unit_neim") Undefable!(size_t[]) partyNums;  // Идентификаторы участников группы в БД МКК
	@DBName("unit") Undefable!size_t partySize; // Общее число участников похода/ размер группы

	// Секция "Ссылки на доп. материалы"
	@DBName("links") Undefable!(string[][]) extraFileLinks; // Ссылки на файлы/ документы связанные с походом/ маршрутом с их наименованием
}

struct TouristListFilter
{
	import webtank.common.optional: Optional;

	@DBName("family_name") string familyName;
	@DBName("given_name") string givenName;
	@DBName("patronymic") string patronymic;
	@DBName("birth_year") Optional!int birthYear;
	@DBName("address") string region;
	@DBName("address") string city;
	@DBName("address") string street;
	@DBName("num") size_t[] nums;
}

struct Navigation
{
	size_t offset = 0;
	size_t pageSize = 10;
}