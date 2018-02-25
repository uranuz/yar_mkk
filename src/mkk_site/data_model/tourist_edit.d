module mkk_site.data_model.tourist_edit;

public import mkk_site.data_model.common;

// Структура для записи данных о туристе
struct TouristDataToWrite
{
	import webtank.common.optional: Undefable, Optional;
	Optional!size_t num; // номер туриста

@FieldSerializer!maybeDBSerializeMethod {
	@DBName("family_name") Undefable!string familyName; // фамилия
	@DBName("given_name") Undefable!string givenName; // имя
	@DBName("patronymic") Undefable!string patronymic; // отчество
	@DBName("birth_year") Undefable!int birthYear; // год рождения
	@DBName("birth_date") Undefable!int birthMonth; // месяц рождения
	/*Специально без DBName*/ Undefable!int birthDay; // день рождения
	@DBName("address") Undefable!string address; // адрес проживания
	@DBName("phone") Undefable!string phone; // телефон
	@DBName("show_phone") Undefable!bool showPhone; // отображать телефон
	@DBName("email") Undefable!string email; // email
	@DBName("show_email") Undefable!bool showEmail; // отображать email
	@DBName("exp") Undefable!string experience; // туристский опыт
	@DBName("comment") Undefable!string comment; // коментарий
	@DBName("razr") Undefable!int sportsCategory; // спортивный разряд
	@DBName("sud") Undefable!int refereeCategory; // судейская категория
}

	bool dbSerializeMode = false; // При переводе в JSON названия полей берем для БД (при true) или из названий переменных

}