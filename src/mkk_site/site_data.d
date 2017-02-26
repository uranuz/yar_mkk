module mkk_site.site_data;

///Перечисление целей сборки сайта
enum BuildTarget { release, test, devel };

///Определение текущей цели сборки сайта
///Разрешена только одна из версий (по умолчанию версия release)
version(devel)
	enum MKKSiteBuildTarget = BuildTarget.devel;
else version(test)
	enum MKKSiteBuildTarget = BuildTarget.test;
else
	enum MKKSiteBuildTarget = BuildTarget.release;


///Константы для определения типа сборки сайта МКК
enum bool isMKKSiteReleaseTarget = MKKSiteBuildTarget == BuildTarget.release;
enum bool isMKKSiteTestTarget = MKKSiteBuildTarget == BuildTarget.test;
enum bool isMKKSiteDevelTarget = MKKSiteBuildTarget == BuildTarget.devel;

// перечислимые значения(типы) в таблице данных (в форме ассоциативных массивов)
import webtank.datctrl.enum_format: enumFormat;
import std.typecons: t = tuple;

static immutable месяцы = enumFormat( 
	[	t(1,"январь"), t(2,"февраль"), t(3,"март"), t(4,"апрель"), t(5,"май"), 
		t(6,"июнь"), t(7,"июль"), t(8,"август"), t(9,"сентябрь"), 
		t(10,"октябрь"), t(11,"ноябрь"), t(12,"декабрь")
	]);
	
	
static immutable месяцы_родительный = enumFormat( 
	[	t(1,"января"), t(2,"февраля"), t(3,"марта"), t(4,"апреля"), t(5,"майя"), 
		t(6,"июня"), t(7,"июля"), t(8,"августа"), t(9,"сентября"), 
		t(10,"октября"), t(11,"ноября"), t(12,"декабря")
	]);	

static immutable видТуризма = enumFormat(
	[	t(1,"пешеходный"), t(2,"лыжный"), t(3,"горный"), t(4,"водный"), 
		t(5,"велосипедный"), t(6,"автомото"), t(7,"спелео"), t(8,"парусный"),
		t(9,"конный"), t(10,"комбинированный") 
	]);
	
static immutable категорияСложности = enumFormat(
	[	t(0,"н.к."), t(1,"первая"), t(2,"вторая"), t(3,"третья"), 
		t(4,"четвёртая"), t(5,"пятая"), t(6,"шестая"),
		t(7,"путешествие"), t(9,"ПВД")
	]);
static immutable элементыКС = enumFormat(
	[	t(1,"с эл. 1"), t(2,"с эл. 2"), t(3,"с эл. 3"), 
		t(4,"с эл. 4"), t(5,"с эл. 5"), t(6,"с эл. 6")
	]);
static immutable готовностьПохода = enumFormat(
	[	t(1,"планируется"), t(2,"набор группы"), t(3,"набор завершён"),
		t(4,"идёт подготовка"), t(5,"на маршруте"), t(6,"пройден"), 
		t(7,"пройден частично"), t(8,"не пройден")
	]);
static immutable статусЗаявки = enumFormat(
	[	t(1,"не заявлен"), t(2,"подана заявка"), t(3,"отказ в заявке"), 
		t(4,"заявлен"), t(5,"засчитан"), t(6,"засчитан частично"), t(7,"не засчитан")
	]);
static immutable спортивныйРазряд = enumFormat(
	[	t(900,"без разряда"),
		t(603,"третий юн."), t(602,"второй юн."), t(601,"первый юн."),
		t(403,"третий"), t(402,"второй"), t(401,"первый"),
		t(400,"КМС"),
		t(205,"МС"), t(204,"ЗМС"), t(203,"МСМК"),
		t(202,"МСМК и ЗМС")
	]);
static immutable судейскаяКатегория = enumFormat(
	[	t(900,"без категории"), t(402,"вторая"), t(401,"первая"), 
		t(202,"всероссийская"), t(201,"всесоюзная"), t(101,"международная")
	]);
