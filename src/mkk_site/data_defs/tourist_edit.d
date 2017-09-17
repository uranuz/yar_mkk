module mkk_site.data_defs.tourist_edit;

public import mkk_site.data_defs.common;

// Структура для записи данных о туристе
struct TouristDataToWrite
{
	import webtank.common.optional: Undefable, Optional;
	Optional!size_t num; // номер туриста

	@DBName("family_name") Undefable!string familyName; // фамилия
	@DBName("given_name") Undefable!string givenName; // имя
	@DBName("patronymic") Undefable!string patronymic; // отчество
	@DBName("brith_year") Undefable!int birthYear; // год рождения
	@DBName("adress") Undefable!string address; // адрес проживания
	@DBName("phone") Undefable!string phone; // телефон
	@DBName("show_phon") Undefable!bool showPhone; // отображать телефон
	@DBName("email") Undefable!string email; // email
	@DBName("show_email") Undefable!bool showEmail; // отображать email
	@DBName("exp") Undefable!string experience; // туристский опыт
	@DBName("comment") Undefable!string comment; // коментарий
	@DBName("razr") Undefable!int sporsCategory; // спортивный разряд
	@DBName("sud") Undefable!int refereeСategory; // судейская категория
}