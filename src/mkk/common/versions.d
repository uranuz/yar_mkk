module mkk.common.versions;

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
