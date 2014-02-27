module webtank.common.logger;
///Модуль создан с целью централизации и автоматизации журналирования
///событий, происходящих во время работы. Полученная информация должна
///использоваться для диагностики и отладки системы.

///Тип события
enum LogEventType
{	fatal,
	crit,  /// Критическая ошибка (дальнейшая работа существенно затруднена, либо ведёт к неизвестным последствиям)
	error, /// Нормальная обычная ошибка в ходе работы (например, неверные данные)
	warn,  /// Предупреждение о возможных неприятных последствиях
	info,  /// Информационное сообщение 
	dbg,   /// Отладочное сообщение
	trace /// Сообщение для трассировки  
};

// //Степень подробности описания события
// enum Verbosity
// {	none,  ///Не записываем в журнал
// 	low,   ///Сжато
// 	norm,  ///Стандартно
// 	high   ///Подробно
// };

///"Уровень логирования" (общая степень детализации журнала)
enum LogLevel 
{	none,
	fatal,
	crit,
	error,
	warn,
	info,
	dbg,
	trace,
	full
};


///Событие журнала
struct LogEvent 
{	import std.datetime: SysTime;
	LogEventType type;   ///Тип записи в журнал
	string mod;       ///Имя модуля
	string file;       ///Имя файла
	size_t line;      ///Номер строки
	string text;      ///Текст записи
	string title;
// 	Tid threadId;
 	string funcName;      ///Имя функции или метода
 	string prettyFuncName;
	SysTime timestamp;     ///Время записи
}


abstract class Logger
{	
	
	
public:
	void writeEvent(LogEvent event);
	
	void write(	LogEventType eventType, string text, string title = null,
		string file = __FILE__, int line = __LINE__, 
		string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
		string mod = __MODULE__)
	{	
		import std.datetime;
		LogEvent event;
		event.type = eventType;
		event.text = text;
		event.title = title;
		event.mod = mod;
		event.file = file;
		event.line = line;
		event.funcName = funcName;
		event.prettyFuncName = prettyFuncName;
		event.timestamp = std.datetime.Clock.currTime();
//  		event.threadId = thisTid;

		writeEvent( event );

	}
	
	void fatal( string text, string title = null,
		string file = __FILE__, int line = __LINE__, 
		string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
		string mod = __MODULE__ )
	{	write( LogEventType.fatal, text, title, file, line, funcName, prettyFuncName, mod ); }
	
	void crit( string text, string title = null,
		string file = __FILE__, int line = __LINE__, 
		string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
		string mod = __MODULE__ )
	{	write( LogEventType.crit, text, title, file, line, funcName, prettyFuncName, mod ); }
	
	void error( string text, string title = null,
		string file = __FILE__, int line = __LINE__, 
		string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
		string mod = __MODULE__ )
	{	write( LogEventType.error, text, title, file, line, funcName, prettyFuncName, mod ); }
	
	void warn( string text, string title = null,
		string file = __FILE__, int line = __LINE__, 
		string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
		string mod = __MODULE__ )
	{	write( LogEventType.warn, text, title, file, line, funcName, prettyFuncName, mod ); }
	
	void info( string text, string title = null,
		string file = __FILE__, int line = __LINE__, 
		string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
		string mod = __MODULE__ )
	{	write( LogEventType.info, text, title, file, line, funcName, prettyFuncName, mod ); }
	
	void dbg( string text, string title = null,
		string file = __FILE__, int line = __LINE__, 
		string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
		string mod = __MODULE__ )
	{	write( LogEventType.dbg, text, title, file, line, funcName, prettyFuncName, mod ); }
	
	void trace( string text, string title = null,
		string file = __FILE__, int line = __LINE__, 
		string funcName = __FUNCTION__, string prettyFuncName = __PRETTY_FUNCTION__,
		string mod = __MODULE__ )
	{	write( LogEventType.trace, text, title, file, line, funcName, prettyFuncName, mod ); }

protected:
	
}

class FileLogger: Logger
{	
	import std.stdio, std.concurrency, std.file;
protected:
	LogLevel _logLevel;
	string _logFileName;
public:
	
	this( string logFileName, LogLevel logLevel )
	{	/+_logFile = File( logFileName, "a" );+/
		_logFileName = logFileName;
		_logLevel = logLevel;
	}

	this( string logFileName, LogLevel logLevel ) shared
	{	/+_logFile = File( logFileName, "a" );+/
		_logFileName = logFileName;
		_logLevel = logLevel;
	}
	
	///Добавление записи в лог
	override void writeEvent(LogEvent event)
	{	import std.conv, std.datetime;
		if( ( cast(int) event.type ) < ( cast(int) _logLevel ) )
		{	/+assert( _logFile.isOpen(), "Error while writing to log file!!!" );+/
			string message = 
				"//---------------------------------------\r\n"
				~ event.timestamp.toISOExtString() 
				~ " [" ~ std.conv.to!string( event.type ) ~ "] " ~ event.file ~ "(" 
				~ std.conv.to!string( event.line ) ~ ") " ~ event.prettyFuncName ~ ": " ~ event.title ~ "\r\n"
				~ event.text ~ "\r\n";
			std.file.append(_logFileName, message);
		}
	}

protected:
}

class ThreadedLogger: Logger
{	import std.concurrency;
public:
	

	this(shared(Logger) baseLogger)
	{	_loggerTid = spawn(&_run, thisTid, baseLogger);
	}
	
	override void writeEvent(LogEvent event)
	{	send(_loggerTid, event);
	}
	
	void stop()
	{	send(_loggerTid, LogStopMsg());
	}

protected:
	Tid _loggerTid;
	
	struct LogStopMsg {}
	
	static void _run( Tid ownerTid, shared(Logger) baseLogger )
	{	
		bool cont = true;
		auto logger = cast(Logger) baseLogger;
		while(cont)
		{	receive(
				(LogEvent ev) {
					logger.writeEvent(ev);
				},
				(LogStopMsg msg) {
					cont = false;
				},
				(OwnerTerminated e) {
					logger.write(LogEventType.fatal, "Нить, породившая процесс логера, завершилась!!!");
					throw e;
				}
			);
		}
	}
}

//TODO: Реализовать продвинутую фильтрацию логов
// class LogFilter: Logger
// {	
// 	override void writeEvent(LogEvent event)
// 	{	
// 		
// 	}
// 	
// }


// private {
// 	__gshared shared(Logger)[] _loggers;
// }
// 
// __gshared Logger log;
// 
// import core.thread, std.datetime;
// 
// void func()
// {	for(size_t i = 0; i < 10; i++)
// 	{	Thread.sleep( dur!("seconds")( 1 ) );
// 		log.write( LogEventType.warn, "Сообщение" );
// 	}
// 
// }
// 
// 
// 
// void main()
// {
// 	log = new ThreadedLogger( new FileLogger("test.log", LogLevel.warn) );
// 	pragma(msg, typeof(log));
// 
// 	auto th = new Thread(&func);
// 	th.start();
// 
// 	log.crit( "Произошла страшно непонятная ошибка!!!", "Абсолютно неизвестная ошибка" );
// 
// }