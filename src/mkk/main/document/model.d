module mkk.main.document.model;

import webtank.db.write_utils: DBField;
import webtank.security.right.common: RightObjAttr;
import webtank.common.optional: Optional, Undefable;

// Структура фильтра по списку туристов
struct DocumentListFilter
{
	@DBField("name") string name; // Фильтр по названию документа
	Optional!(size_t[]) nums; // Фильтр по списку идентификаторов документов
}

struct DocumentDataToWrite
{
	Optional!size_t num; // Номер похода в базе

@RightObjAttr(`document.item`):

	@DBField("name") Undefable!string name;
	@DBField("link") Undefable!string link;
}