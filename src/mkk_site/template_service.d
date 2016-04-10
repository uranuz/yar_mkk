module mkk_site.template_service;

import webtank.templating.plain_templater;

import mkk_site;

shared static this()
{
	JSONRPCRouter.join!(getTemplates);
}

import std.json;

JSONValue getTemplates(string[] templates)
{
	import std.algorithm: startsWith, endsWith;
	
	JSONValue[string] jTemplates;
	
	foreach( templateName; templates )
	{
		string templatePath = buildNormalPath(pageTemplatesDir, templateName);
		if( !templatePath.startsWith(pageTemplatesDir) || !templatePath.endsWith(".html") )
			throw new Exception( "Incorrect template name!" ); //Ограничение безопасности!
		
		PlainTemplate tpl = templateCache.getTemplate(templatePath);
		
		JSONValue jTemplate = serializeTemplate(tpl);
		jTemplate["name"] = templateName;
		jTemplates[templateName] = jTemplate;
	}
	
	return JSONValue(jTemplates);
}

JSONValue serializeTemplate(PlainTemplate tpl)
{
	JSONValue[string] jTemplate;
	
	JSONValue[] jElements;
	foreach( elem; tpl._indexedEls )
	{
		JSONValue[string] jElement;
		jElement["prePos"] = elem.prePos;
		jElement["sufPos"] = elem.sufPos;
		
		if( elem.isVar )
			jElement["matchOpPos"] = elem.matchOpPos;
		else
			jElement["matchOpPos"] = null;
			
		jElements ~= JSONValue(jElement);
	}

	jTemplate["elems"] = JSONValue(jElements);
	
	import std.utf: toUTF8;
	//TODO: Немного костыльно. Возможно стоит исправить
	jTemplate["src"] = toUTF8( tpl._sourceStr );
	
	return JSONValue(jTemplate);
}