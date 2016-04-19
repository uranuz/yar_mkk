module mkk_site.templating_init;

import
	webtank.templating.plain_templater,
	webtank.ui.templating;

import mkk_site.site_data;
import mkk_site.templating;

shared static this()
{
	templateCache = new PlainTemplateCache!(useTemplateCache)();
	webtank.ui.templating.setTemplatesDir( webtankResDir ~ "templates" );
} 
