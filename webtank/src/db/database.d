module webtank.db.database;
///Какие-то там базовые интерфейсы по работе с базой данных
//Большой пользы пока не приносят, но как бы украшают...

///Тип СУБД, или по-буржуйски Database Management System (DBMS)
enum DBMSType {postgreSQL, mySQL}; //Вроде как на будущее

interface IDatabase ///Интерфейс БД
{	bool connect(string connStr);  //Подключение к БД, используя строку подключения
	bool isConnected() @property;  //Вернёт true, если мы подключены к БД
	IDBQueryResult query(string queryStr);  //Подача запроса к БД, возвращает результат
	//DBStatus getStatus() @property; //Подробнее узнать как дела у базы
	string lastErrorMessage() @property; //Прочитать последнюю ошибку
	//string getVersionInfo();
	DBMSType type() @property; //Тип системы управления БД
	
	void disconnect(); //Отключение от БД
}

interface IDBQueryResult ///Интерфейс результата запроса к БД
{	/+DBMSType type() @property; //Снова тип СУБД+/
	size_t recordCount() @property; //Число записей
	size_t fieldCount() @property;  //Число полей данных
	void clear(); //Очистить объект
	
	string getFieldName(size_t index);
	size_t getFieldIndex(string name);
	bool isNull(size_t fieldIndex, size_t recordIndex);
	string get(size_t fieldIndex, size_t recordIndex);
	string get(size_t fieldIndex, size_t recordIndex, string defaultValue);
}

///Класс исключений при работе с БД
class DBException : Exception {
	this(string msg, string file = __FILE__, size_t line = __LINE__) {
		super(msg, file, line);
	}
}

