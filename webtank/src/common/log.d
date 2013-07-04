module webtank.common.log;
///Модуль создан с целью централизации и автоматизации журналирования
///событий, происходящих во время работы. Полученная информация должна
///использоваться для диагностики и отладки системы.

///Тип события
enum EventType
{	crit,  /// Критическая ошибка (дальнейшая работа существенно затруднена, либо ведёт к неизвестным последствиям)
	error, /// Нормальная обычная ошибка в ходе работы (например, неверные данные)
	warn,  /// Предупреждение о возможных неприятных последствиях
	info,  /// Информационное сообщение 
	dbg,   /// Отладочное сообщение
	trace /// Сообщение для трассировки  
};

//Степень подробности описания события
enum Verbosity
{	none,  ///Не записываем в журнал
	low,   ///Сжато
	norm,  ///Стандартно
	high   ///Подробно
};

///"Уровень логирования" (общая степень детализации журнала)
enum LogLevel 
{	none,
	crit,
	error,
	warn,
	info,
	dbg,
	tracing,
	all
};



immutable Verbosity[EventType] verbosityMappingDefault;

static this()
{	
	alias Verbosity v;
	alias EventType e;
	
	verbosityMappingDefault =
	[	e.crit: v.high,
		e.error: v.norm,
		e.warn: v.norm,
		e.info: v.low,
		e.dbg: v.none,
		e.trace: v.none
	];
	
}


///Запись в журнал
struct LogEvent 
{	import std.datetime: SysTime;
	EventType type;   ///Тип записи в журнал
	string title;    ///Заголовок записи о событии (очень краткое описание)
	string text;      ///Текст записи (подробности)
	string longText;  ///Детальное описание
	string file;       ///Имя файла
	size_t line;      ///Номер строки
// 	string func;      ///Имя функции или метода
	SysTime time;     ///Время записи
}


interface ILogger
{	///Свойства позволяют прочитать или установить уровень логирования
// 	LogLevel level() @property;
// 	void level( LogLevel level ) @property;
	
	///Добавление записи в лог
// 	void log( /*ref*/ LogEvent event  );
	
}

class FileLogger: ILogger
{	
	import std.stdio;
private:
		
		
		File _errorFile; ///Лог-файл ошибок
		File _eventFile; ///Лог-файл событий
		Verbosity[EventType] _vbMap;  //Карта степени подробности
		
		//Выводимые в файл названия типов событий
		enum string[EventType] prefixes  =
		[	EventType.trace: "TRACE", EventType.dbg: "DEBUG", EventType.info: "INFO",
			EventType.warn: "WARN", EventType.error: "ERROR", EventType.crit: "CRIT"
		];
		
public:
	
	this( File errorFile, File eventFile, LogLevel logLevel )
	{	_errorFile = errorFile;
		_eventFile = eventFile;
		
		foreach( key, val;  verbosityMappingDefault)
			_vbMap[key] = val;
	}
	
	///Добавление записи в лог
	private void _log( /*ref*/ LogEvent event  )
	{	
		Verbosity verb = _vbMap[event.type];
		
		if( verb == Verbosity.none ) //Не выводим
			return;
			
		bool isError =
		(	event.type == EventType.error || 
			event.type == EventType.crit
		);
		import std.datetime;
		auto timeString = event.time.toSimpleString();
		import std.conv;
		string output = timeString ~ ": " ~ event.file ~ "(" ~ std.conv.to!(string)(event.line) ~ "): " ~ prefixes[event.type] ~ ": " ~ event.title ~ "\n";

		final switch( verb )
		{	case Verbosity.none:
				
			break;
			
			case Verbosity.low:
				
			break;
			
			case Verbosity.norm:
				output ~= event.text ~ "\n";
			break;
			
			case Verbosity.high:
				output ~= event.longText ~ "\n";
			break;
		}
		
		if( isError )
			_errorFile.write(output);
			_eventFile.write(output);
		
	}
	
	void log( string file = __FILE__, int line = __LINE__/*, string func = __FUNCTION__*/ )
		( EventType eventType, string title, string text = null, string longText = null )
	{	LogEvent event;
		event.type = eventType;
		event.title = title;
		event.text = text;
		event.longText = longText;
		event.file = file;
		event.line = line;
// 		event.func = func;
		import std.datetime;
		event.time = std.datetime.Clock.currTime();
		_log( event );
	}
	
	void crit( string file = __FILE__, int line = __LINE__/*, string func = __FUNCTION__*/ )
		(string title, string text = null, string longText = null)
	{	log!(file, line)(EventType.crit, title, text, longText); }
	void error( string file = __FILE__, int line = __LINE__/*, string func = __FUNCTION__*/ )
		(string title, string text = null, string longText = null)
	{	log!(file, line)(EventType.error, title, text, longText); }
	void warn( string file = __FILE__, int line = __LINE__/*, string func = __FUNCTION__*/ )
		(string title, string text = null, string longText = null)
	{	log!(file, line)(EventType.warn, title, text, longText); }
	void info( string file = __FILE__, int line = __LINE__/*, string func = __FUNCTION__*/ )
		(string title, string text = null, string longText = null)
	{	log!(file, line)(EventType.info, title, text, longText); }
	void dbg( string file = __FILE__, int line = __LINE__/*, string func = __FUNCTION__*/ )
		(string title, string text = null, string longText = null)
	{	log!(file, line)(EventType.dbg, title, text, longText); }
	void trace( string file = __FILE__, int line = __LINE__/*, string func = __FUNCTION__*/ )
		(string title, string text = null, string longText = null)
	{	log!(file, line)(EventType.trace, title, text, longText); }
	
}

void main()
{	import std.stdio;
	
	auto logger = new FileLogger(stdout, stdout, LogLevel.error);
	logger.warn("Абсолютно неизвестная ошибка", "Произошла страшно непонятная ошибка!!!");
	
}