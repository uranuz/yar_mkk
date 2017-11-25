module mkk_site.data_model.pohod_list;

import webtank.common.optional_date: OptionalDate;

public import mkk_site.data_model.common;

/// Структура фильтра по походам
struct PohodFilter
{
	int[] tourismKind; /// Виды туризма
	int[] complexity; /// Категории сложности
	int[] progress; /// Фазы прохождения похода
	int[] claimState; /// Состояния заявок
	OptionalDate[string] dates; /// Фильтр по датам
	string pohodRegion; /// Регион проведения похода
	bool withFiles; /// Записи с доп. материалами
	bool withDataCheck; /// Режим проверки данных

	/// Проверка, что есть какая-либо фильтрация
	bool withFilter() @property
	{
		import std.algorithm: canFind;

		if( tourismKind.length > 0 || complexity.length > 0 ||
			progress.length > 0 || claimState.length > 0 ||
			pohodRegion.length > 0 || withFiles || withDataCheck
		) return true;

		foreach( fieldName, date; this.dates )
		{
			// Второе условие на проверку того, что переданное поле даты есть в наборе
			if( !date.isNull && соотвПолейСроков.canFind!( (x, y)=> x.имяВФорме == y )(fieldName) )
				return true;
		}
		return false;
	}

	void init() pure nothrow
	{
		// Подпорка для инициализации фильтра дат чем-нибудь. Нужно для шаблонизатора
		foreach( item; соотвПолейСроков ) {
			dates[item.имяВФорме] = OptionalDate();
		}
	}
}

struct СоотвПолейСроков {
	string имяВФорме;
	string имяВБазе;
	string опСравн;
};

//Вспомогательный массив структур для составления запроса
//Устанавливает соответствие между полями в форме и в базе
//и операциями сравнения, которые будут в запросе
static immutable СоотвПолейСроков[] соотвПолейСроков = [
	{ "beginDateRangeHead", "begin_date", "<=" },
	{ "beginDateRangeTail", "begin_date", ">=" },
	{ "endDateRangeHead", "finish_date", "<=" },
	{ "endDateRangeTail", "finish_date", ">=" }
];