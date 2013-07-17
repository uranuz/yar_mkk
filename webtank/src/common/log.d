module webtank.common.log;
///Модуль создан с целью централизации и автоматизации журналирования
///событий, происходящих во время работы. Полученная информация должна
///использоваться для диагностики и отладки системы.

///Тип события
enum EventType
{	crit,  /// Критическая ошибка (дальнейшая работа существенно затруднена, либо ведёт к неизвестным последствиям)
	error, /// Нормальная обычная ошибка в ходе работы (например, неверные данные)
	warn,  /// Предупреждающее сообщение (возможны проблемы в системе)
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
{	none, crit, error, warn, info, dbg, trace, full };

///Распределение количества выводимой информации по уровням логирования
immutable Verbosity[EventType][LogLevel] verbosityMapDefault;

static this()
{	alias Verbosity v;
	alias EventType e;
	alias LogLevel l;
	
	///Заполняем распределение 
	verbosityMapDefault =
	[	l.crit: [ e.crit: v.high ], ///Только критические ошибки
		l.error: [ e.crit: v.high, e.error: v.norm ], ///Все ошибки
		l.warn: ///Ошибки и предупреждения
		[	e.crit: v.high, e.error: v.norm, e.warn: v.norm],
		l.info: ///Ошибки, предупреждения и информационные сообщения
		[ e.crit: v.high, e.error: v.norm, e.warn: v.norm, e.info: v.low ],
		l.dbg: ///+ Отладочная информация (без инфо-сообщений)
		[	e.crit: v.high, e.error: v.norm, e.warn: v.norm, 
			e.info: v.none, e.dbg: v.norm
		],
		l.trace: ///+ Трассировочные сообщения
		[	e.crit: v.high, e.error: v.norm, e.warn: v.norm, 
			e.info: v.none, e.dbg: v.norm, e.trace: v.norm
		],
		l.full: ///Вся возможная информация
		[	e.crit: v.high, e.error: v.high, e.warn: v.high, 
			e.info: v.high, e.dbg: v.high, e.trace: v.high
		],
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
public:
	///Добавление записи в лог
	void crit( string title, string text = null, string longText = null, 
		string file = __FILE__, int line = __LINE__/*, string func = __FUNCTION__*/ );
	
	void error( string title, string text = null, string longText = null, 
		string file = __FILE__, int line = __LINE__/*, string func = __FUNCTION__*/ );
	
	void warn( string title, string text = null, string longText = null, 
		string file = __FILE__, int line = __LINE__/*, string func = __FUNCTION__*/ );
	
	void info( string title, string text = null, string longText = null, 
		string file = __FILE__, int line = __LINE__/*, string func = __FUNCTION__*/ );
	
	void dbg( string title, string text = null, string longText = null, 
		string file = __FILE__, int line = __LINE__/*, string func = __FUNCTION__*/ );
	
	void trace( string title, string text = null, string longText = null, 
		string file = __FILE__, int line = __LINE__/*, string func = __FUNCTION__*/ );
	
}

class FileLogger: ILogger
{	
	import std.stdio;
private:
		
		
		File _errorFile; ///Лог-файл ошибок
		File _eventFile; ///Лог-файл событий
		Verbosity[EventType] _vbMap;  //Карта степеней подробности для событий
		
		//Выводимые в файл названия типов событий
		enum string[EventType] prefixes  =
		[	EventType.trace: "TRACE", EventType.dbg: "DEBUG", EventType.info: "INFO",
			EventType.warn: "WARN", EventType.error: "ERROR", EventType.crit: "CRIT"
		];
		
public:
	
	this( File errorFile, File eventFile, LogLevel logLevel )
	{	_errorFile = errorFile;
		_eventFile = eventFile;
		if( logLevel in verbosityMapDefault )
		{	foreach( key, val;  verbosityMapDefault[logLevel])
				_vbMap[key] = val;
		}
	}
	
	///Добавление записи в лог
	private void _log( /*ref*/ LogEvent event  )
	{	Verbosity currVerbosity = _vbMap.get(event.type, Verbosity.none);
		
		if( currVerbosity == Verbosity.none ) //Не выводим
			return;
			
		bool isError = event.type == EventType.error || event.type == EventType.crit;
		import std.datetime;
		auto timeString = event.time.toSimpleString();
		import std.conv;
		
		string output = timeString ~ ": " ~ event.file ~ "(" 
			~ std.conv.to!(string)(event.line) ~ "): " 
			~ prefixes[event.type] ~ ": " ~ event.title ~ "\n";
		

		final switch( currVerbosity )
		{	case Verbosity.none:
				
			break;
			
			case Verbosity.low:
				
			break;
			
			case Verbosity.norm:
				output ~= event.text ~ "\n";
			break;
			
			case Verbosity.high:
			{	string outText = ( event.longText.length > 0 ) ? event.longText : text;
				output ~= ( outText.length > 0 ) ? ( outText ~ "\n" ) : "";
				break;
			}
		}
		
		if( isError )
			_errorFile.write(output);
			_eventFile.write(output);
		
	}

public:
	void log( EventType eventType, string title, string text = null, string longText = null, 
		string file = __FILE__, int line = __LINE__/*, string func = __FUNCTION__*/ )
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
	
	
	override {
		///Функции для журналирования событий
		void crit( string title, string text = null, string longText = null, 
			string file = __FILE__, int line = __LINE__/*, string func = __FUNCTION__*/ )
		{	log(EventType.crit, title, text, longText, file, line); }
		
		void error( string title, string text = null, string longText = null, 
			string file = __FILE__, int line = __LINE__/*, string func = __FUNCTION__*/ )
		{	log(EventType.error, title, text, longText); }
		
		void warn( string title, string text = null, string longText = null, 
			string file = __FILE__, int line = __LINE__/*, string func = __FUNCTION__*/ )
		{	log(EventType.warn, title, text, longText, file, line); }
		
		void info( string title, string text = null, string longText = null, 
			string file = __FILE__, int line = __LINE__/*, string func = __FUNCTION__*/ )
		{	log(EventType.info, title, text, longText, file, line); }
		
		void dbg( string title, string text = null, string longText = null, 
			string file = __FILE__, int line = __LINE__/*, string func = __FUNCTION__*/ )
		{	log(EventType.dbg, title, text, longText, file, line); }
		
		void trace( string title, string text = null, string longText = null, 
			string file = __FILE__, int line = __LINE__/*, string func = __FUNCTION__*/ )
		{	log(EventType.trace, title, text, longText, file, line); }
	}
	
}
static shared int vasya = 500;

void main()
{	import std.stdio;
	shared int vasya1 = 501;
	
	auto logger = cast(ILogger) new FileLogger(stdout, stdout, LogLevel.warn);
	logger.error("Абсолютно неизвестная ошибка", "Произошла страшно непонятная ошибка!!!");
	
}