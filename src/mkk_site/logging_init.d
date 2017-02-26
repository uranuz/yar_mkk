module mkk_site.logging_init;

import webtank.common.loger;

import mkk_site.site_data_old;
import mkk_site.logging;

shared static this()
{
	static if( isMKKSiteReleaseTarget )
	{
		enum siteLogLevel = LogLevel.error;
		enum prioriteLogLevel = LogLevel.info;
	}
	else
	{
		enum siteLogLevel = LogLevel.info;
		enum prioriteLogLevel = LogLevel.info;
	}
	
	SiteLoger = new ThreadedLoger( cast(shared) new FileLoger(eventLogFileName, siteLogLevel) );
	PrioriteLoger = new ThreadedLoger( cast(shared) new FileLoger(prioriteLogFileName, prioriteLogLevel) );
} 
