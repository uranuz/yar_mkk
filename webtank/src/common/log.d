module webtank.common.log;
///Модуль создан с целью централизации и автоматизации журналирования
///событий, происходящих во время работы. Полученная информация должна
///использоваться для диагностики и отладки системы.

///Тип записи в журнале событий
enum EntryType 
{	traceMsg, /// Сообщение для трассировки
	debugMsg,   /// Отладочное сообщение
	info,  /// Информационное сообщение 
	warning,  /// Предупреждение о возможных неприятных последствиях
	error, /// Нормальная обычная ошибка в ходе работы (например, неверные данные)
	critError,  /// Критическая ошибка (дальнейшая работа существенно затруднена, либо ведёт к неизвестным последствиям)
	fatalError  /// Фатальная ошибка (продолжение работы приложения невозможно)   
};

///"Уровень логирования" (степень детализации журнала)
enum LogLevel 
{	none,
	errors,
	all
};

///Запись в журнал
struct LogEntry 
{	EntryType type;   ///Тип записи в журнал
	//SysTyme time;     ///Время записи
	string title;    ///Заголовок записи о событии (очень краткое описание)
	string text;      ///Текст записи (подробности)
	//string longText;  ///Детальное описание
	//string mod;       ///Имя модуля
	//string func;      ///Имя функции или метода
	//size_t line;      ///Номер строки
	
}


interface ILogger
{	///Свойства позволяют прочитать или установить уровень логирования
// 	LogLevel level() @property;
// 	void level( LogLevel level ) @property;
	
	///Добавление записи в лог
	void log( /*ref*/ LogEntry logEntry  );
	
}

class FileLogger: ILogger
{	
	import std.stdio;
private:
		
		
		File _errorFile; ///Лог-файл ошибок
		File _eventFile; ///Лог-файл событий
		LogLevel _logLevel;
		
		//Выводимые в файл названия типов событий
		enum string[EntryType] prefixes  =
		[	
		
		EntryType.traceMsg: "TRACE", EntryType.debugMsg: "DEBUG", EntryType.info: "INFO",
		
		
		
			EntryType.warning: "WARN", EntryType.error: "ERROR", EntryType.critError: "CRIT",
			EntryType.fatalError: "FATAL"
		];
		
public:
	
	this( File errorFile, File eventFile, LogLevel logLevel )
	{	_errorFile = errorFile;
		_eventFile = eventFile;
		_logLevel = logLevel;
	}
	
	///Добавление записи в лог
	void log( /*ref*/ LogEntry logEntry  )
	{	
		bool isError =
		(	logEntry.type == EntryType.error || 
			logEntry.type == EntryType.critError || 
			logEntry.type == EntryType.fatalError 
		);
		
		with( LogLevel )
		{
		final switch( _logLevel )
		{	case errors: //Только ошибки
				if( isError )
					_errorFile.write(prefixes[logEntry.type] ~ ": " ~ logEntry.title ~ "\r\n" ~ logEntry.text );
			break;
			
// 			case verbose:  //Подробно
// 			
// 			break;
			
			case all: //Вся информация
				if( isError )
					_errorFile.write(prefixes[logEntry.type] ~ ": " ~ logEntry.title ~ "\r\n" ~ logEntry.text );
					_eventFile.write(prefixes[logEntry.type] ~ ": " ~ logEntry.title ~ "\r\n" ~ logEntry.text );
			break;
			
			case none:  //Не журналировать
			
			break;
		}
		} //with( LogLevel )
		
	}
	
}

void main()
{	import std.stdio;
	
	auto logger = new FileLogger(stdout, stdout, LogLevel.errors);
	auto entry = LogEntry(EntryType.error, "Абсолютно неизвестная ошибка");
	logger.log(LogEntry(EntryType.error, "Абсолютно неизвестная ошибка"));
	
	
	
}