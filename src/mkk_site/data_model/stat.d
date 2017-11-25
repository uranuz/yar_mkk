module mkk_site.data_model.stat;

public import mkk_site.data_model.common;

// Структура фильтра по статистике

struct StatSelect
		{
        import webtank.common.optional: Optional;

			@DBName("conduct")   	size_t conduct;//вид отображения
			@DBName("kodMKK")	      string kodMKK;
			@DBName("organization")	string organization;
			@DBName("territory")   	string territory;
			@DBName("beginYear")	   string beginYear;
			@DBName("endYear")	   string endYear;
		}