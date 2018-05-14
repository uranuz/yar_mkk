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
	import webtank.net.http.context: HTTPContext;
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

	override void renderResult(TDataNode content, HTTPContext ctx)
	{
		import std.string: toLower;
		ctx.response.tryClearBody();

		if( ctx.request.queryForm.get("generalTemplate", null).toLower() != "no" )
		{
			auto favouriteFilters = ctx.mainServiceCall(`pohod.favoriteFilters`);
			assert("sections" in favouriteFilters, `There is no "sections" property in pohod.favoriteFilters response`);
			assert("allFields" in favouriteFilters, `There is no "allFields" property in pohod.favoriteFilters response`);

			TDataNode payload = [
				"content":  content,
				"authRedirectURI": TDataNode(getAuthRedirectURI(ctx)),
				"pohodFilterFields": favouriteFilters["allFields"],
				"pohodFilterSections": favouriteFilters["sections"]
			];

			content = runIvyModule("mkk.GeneralTemplate", ctx, payload);
		}

		static struct OutRange
		{
			private HTTPOutput _resp;
			void put(T)(T data) {
				import std.conv: text;
				_resp.write(data.text);
			}
		}

		renderDataNode!(DataRenderType.HTML)(content, OutRange(ctx.response));
	}
}

shared static this() {
	Service(new MKKViewService("yarMKKView", "/dyn/{remainder}"));
}