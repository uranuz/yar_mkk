module mkk_site.view_service.service;

public import webtank.net.http.handler;
public import mkk_site.view_service.utils;
public import mkk_site.common.service: Service;

MKKViewService ViewService() @property
{
	MKKViewService srv = cast(MKKViewService) Service();
	assert( srv, `View service is null` );
	return srv;
}

import webtank.ivy.view_service: IvyViewService;
import mkk_site.security.common.access_control_client: MKKAccessControlClient;
import mkk_site.security.common.access_rules: makeCoreAccessRules;
import webtank.security.right.controller: AccessRightController;
import webtank.security.right.remote_source: RightRemoteSource;
class MKKViewService: IvyViewService
{
	import mkk_site.common.utils;

	import ivy;
	import ivy.interpreter.data_node_render: renderDataNode, DataRenderType;
	import webtank.net.http.output: HTTPOutput;
public:
	this(string serviceName, string pageURIPatternStr)
	{
		super(serviceName,
			new MKKAccessControlClient,
			pageURIPatternStr,
			new AccessRightController(
				makeCoreAccessRules(),
				new RightRemoteSource(this, `yarMKKMain`, `accessRight.list`)
			)
		);
	}

	override MKKAccessControlClient accessController() @property
	{
		auto controller = cast(MKKAccessControlClient) _accessController;
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

			content = runIvyModule("mkk.GeneralTemplate", payload);
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

shared static this() {
	Service(new MKKViewService("yarMKKView", "/dyn/{remainder}"));
}