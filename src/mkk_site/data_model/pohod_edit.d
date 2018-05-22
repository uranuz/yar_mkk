module mkk_site.data_model.pohod_edit;

public import mkk_site.data_model.common;
import webtank.security.right.common: RightObjAttr;

import std.typecons: Tuple;
import webtank.common.optional: Optional;
alias PohodFileLink = Tuple!(
	string, `link`,
	string, `name`,
	Optional!size_t, `num`
);

struct PohodDataToWrite
{
	import webtank.common.optional: Optional, Undefable;
	import std.datetime: Date;
	Optional!size_t num; // Номер похода в базе

@RightObjAttr(`pohod.item`): // Пространство имён для прав
@RightObjAttr(): // Признак, что нужно добавлять название самого поля в качестве последнего элемента

@FieldSerializer!maybeDBSerializeMethod {
	// Секция "Маршрутная книжка"
	@RightObjAttr(`book`) {
		/// Код МКК
		@DBName("kod_mkk") Undefable!string mkkCode;
		/// Номер книги
		@DBName("nomer_knigi") Undefable!string bookNum;
		/// Статус заявки
		@DBName("stat") Undefable!int claimState;
		/// Коментарий МКК
		@DBName("MKK_coment") Undefable!string mkkComment;
	}

	// Секция "Поход"
	@RightObjAttr(`pohod`) {
		/// Регион, где проходит поход
		@DBName("region_pohod") Undefable!string pohodRegion;
		/// Вид туризма
		@DBName("vid") Undefable!int tourismKind;
		/// Нитка маршрута
		@DBName("marchrut") Undefable!string route;
		/// Категория сложности маршрута
		@DBName("ks") Undefable!int complexity;
		/// Элементы категории сложности
		@DBName("elem") Undefable!int complexityElems;
		/// Дата начала похода
		@DBName("begin_date") Undefable!Date beginDate;
		/// Дата завершения похода
		@DBName("finish_date") Undefable!Date finishDate;
		/// Состояние прохождения маршрута
		@DBName("prepar") Undefable!int progress;
		/// Коментарий руководителя группы
		@DBName("chef_coment") Undefable!string chiefComment;
	}

	// Секция "Группа"
	@RightObjAttr(`group`) {
		// Турклуб, организация, наименование коллектива, от имени которого организован поход
		@DBName("organization") Undefable!string organization;
		// Город, посёлок, район, область, где постояннно проживает основная часть участников похода
		@DBName("region_group") Undefable!string partyRegion;
		// Идентификатор руководителя похода в БД МКК
		@DBName("chef_grupp") Undefable!size_t chiefNum;
		// Идентификатор заместителя  руководителя в БД МКК (при наличии заместителя)
		@DBName("alt_chef") Undefable!size_t altChiefNum;
		// Идентификаторы участников группы в БД МКК
		@DBName("unit_neim") Undefable!(size_t[]) partyNums;
		// Общее число участников похода/ размер группы
		@DBName("unit") Undefable!size_t partySize;
	}

	// Секция "Ссылки на доп. материалы"
	@DBName("links") Undefable!(PohodFileLink[]) extraFileLinks; // Ссылки на файлы/ документы связанные с походом/ маршрутом с их наименованием

	bool dbSerializeMode = false; // При переводе в JSON названия полей берем для БД (при true) или из названий переменных
} // @FieldSerializer

} // struct PohodDataToWrite
