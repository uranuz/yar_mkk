module mkk_site.data_model.tourist_list;

public import mkk_site.data_model.common;

// Структура фильтра по списку туристов
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
	@DBName("num") Optional!(size_t[]) nums;
}