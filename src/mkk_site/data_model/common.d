module mkk_site.data_model.common;

// Используется в качестве аттрибута для указания названия поля в базе данных
struct DBName
{
	string dbName;
}

// Структура для навигации по выборке данных
struct Navigation
{
	size_t offset = 0; // Сдвиг по числу записей
	size_t pageSize = 10; // Число записей на странице
}