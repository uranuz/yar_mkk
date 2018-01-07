module mkk_site.data_model.document;

public import mkk_site.data_model.common;

import webtank.common.optional: Optional, Undefable;
// Структура фильтра по списку туристов
struct DocumentListFilter
{
	@DBName("name") string name; // Фильтр по названию документа
	Optional!(size_t[]) nums; // Фильтр по списку идентификаторов документов
}

struct DocumentDataToWrite
{
	Optional!size_t num; // Номер походе в базе

	@DBName("name") Undefable!string name;
	@DBName("link") Undefable!string link;
}