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
}

///"Уровень логирования" (степень детализации журнала)
enum LogLevel 
{	none,
	errors,
	all
}

///Запись в журнал
struct LogEntry 
{	EntryType type;   ///Тип записи в журнал
	SysTyme time;     ///Время записи
	string header;    ///Заголовок записи (краткое описание)
	string text;      ///Текст записи (подробности)
	
	///Детализация информации. Не больше 2. 0 - сжато, 1 - стандартно, 2 - подробно
	ubyte detail = 1;  
	string mod;       ///Имя модуля
	string func;      ///Имя функции или метода
	size_t line;      ///Номер строки
	
}


interface ILogger
{	///Свойства позволяют прочитать или установить уровень логирования
	LogLevel level() @property;
	void level( LogLevel level ) @property;
	
	///Добавление записи в лог
	void log( ref LogEntry logEntry  );
	
}

class FileLogger: ILogger
{	
private:
		import std.stdio;
		
		File _errorFile; ///Лог-файл ошибок
		File _eventFile; ///Лог-файл событий
		
		//Выводимые в файл названия типов событий
		enum prefixes[EntryType] = 
		{	EntryType.traceMsg: "TRACE", EntryType.debugMsg: "DEBUG", EntryType.info: "INFO",
			EntryType.warning: "WARN", EntryType.error: "ERROR", EntryType.critError: "CRIT",
			EntryType.fatalError: "FATAL"
		};
		
public:
	
	this( File errorFile, File eventFile )
	{	_errorFile = errorFile;
		_eventFile = eventFile;
	}
	
	///Добавление записи в лог
	void log( ref LogEntry logEntry  )
	{	File logFile;
		
		
		bool isError =
		(	logEntry.type == EntryType.error || 
			logEntry.type == EntryType.critError || 
			logEntry.type == EntryType.fatalError 
		);
		
		with( LogLevel )
		{
		final switch( logEntry.level )
		{	case errors: //Только ошибки
				if( isError )
				{	logFile.write(prefixes[logEntry.type] ~ ": " ~ header ~ "\r\n" ~ text );
					
					
				}
			break;
			
// 			case verbose:  //Подробно
// 			
// 			break;
			
			case all: //Вся информация
				
			break;
			
			case none:  //Не журналировать
			
			break;
		}
		} //with( LogLevel )
		
	}
	
}