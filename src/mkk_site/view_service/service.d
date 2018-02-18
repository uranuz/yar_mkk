module mkk_site.view_service.service;

public import mkk_site.view_service.uri_page_router;
public import webtank.net.http.handler;

MKKViewService Service() @property {
	return _mkk_view_service;
}

import webtank.ivy.view_service: IvyViewService;

class MKKViewService: IvyViewService
{
	import mkk_site.view_service.access_control;
	import mkk_site.view_service.utils;
	import mkk_site.common.utils;
	import ivy;
	import ivy.interpreter.data_node_render: renderDataNode, DataRenderType;
	import webtank.net.http.output: HTTPOutput;
public:
	this(string serviceName, string pageURIPatternStr)
	{
		super(serviceName,
			new MKKViewAccessController,
			pageURIPatternStr
		);
	}

	override MKKViewAccessController accessController() @property
	{
		auto controller = cast(MKKViewAccessController) _accessController;
		assert(controller, `MKK access controller is null`);
		return controller;
	}

	override void renderResult(TDataNode content, HTTPContext context)
	{
		import std.string: toLower;
		context.response.tryClearBody();

		if( context.request.queryForm.get("generalTemplate", null).toLower() != "no" )
		{
			auto favouriteFilters = mainServiceCall(`pohod.favoriteFilters`, context);
			assert("sections" in favouriteFilters, `There is no "sections" property in pohod.favoriteFilters response`);
			assert("allFields" in favouriteFilters, `There is no "allFields" property in pohod.favoriteFilters response`);

			TDataNode payload = [
				"vpaths": TDataNode(Service.virtualPaths),
				"content":  TDataNode(content),
				"isAuthenticated": TDataNode(context.user.isAuthenticated),
				"userName": TDataNode(context.user.name),
				"authRedirectURI": TDataNode(getAuthRedirectURI(context)),
				"pohodFilterFields": TDataNode(favouriteFilters["allFields"]),
				"pohodFilterSections": TDataNode(favouriteFilters["sections"])
			];

			content = templateCache.getByModuleName("mkk.GeneralTemplate").run(payload);
		}

		static struct OutRange
		{
			private HTTPOutput _resp;
			void put(T)(T data) {
				import std.conv: text;
				_resp.write(data.text);
			}
		}

		renderDataNode!(DataRenderType.HTML)(content, OutRange(context.response));
	}
}

private __gshared MKKViewService _mkk_view_service;

shared static this() {
	_mkk_view_service = new MKKViewService("yarMKKView", "/dyn/{remainder}");
}