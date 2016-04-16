module mkk_site.logging_init;

import webtank.common.logger;

import mkk_site.site_data;
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
	
	SiteLogger = new ThreadedLogger( cast(shared) new FileLogger(eventLogFileName, siteLogLevel) );
	PrioriteLogger = new ThreadedLogger( cast(shared) new FileLogger(prioriteLogFileName, prioriteLogLevel) );
} 
