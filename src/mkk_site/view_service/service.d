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
import webtank.security.right.controller: AccessRightController;
import webtank.security.right.remote_source: RightRemoteSource;
import webtank.ivy.access_rule_factory: IvyAccessRuleFactory;
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
				new IvyAccessRuleFactory(this),
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

	override void renderResult(IvyData content, HTTPContext ctx)
	{
		import std.string: toLower;
		ctx.response.tryClearBody();

		static struct OutRange
		{
			private HTTPOutput _resp;
			void put(T)(T data) {
				import std.conv: text;
				_resp.write(data.text);
			}
		}

		if( ctx.request.queryForm.get("generalTemplate", null).toLower() != "no" )
		{
			auto favouriteFilters = ctx.mainServiceCall(`pohod.favoriteFilters`);
			assert("sections" in favouriteFilters, `There is no "sections" property in pohod.favoriteFilters response`);
			assert("allFields" in favouriteFilters, `There is no "allFields" property in pohod.favoriteFilters response`);

			IvyData payload = [
				"content":  content,
				"authRedirectURI": IvyData(getAuthRedirectURI(ctx)),
				"pohodFilterFields": favouriteFilters["allFields"],
				"pohodFilterSections": favouriteFilters["sections"]
			];

			runIvyModule("mkk.GeneralTemplate", ctx, payload).then(
				(IvyData fullContent) {
					super.renderResult(fullContent, ctx);
				}
			);
		} else {
			super.renderResult(content, ctx);
		}
	}
}

shared static this() {
	Service(new MKKViewService("yarMKKView", "/dyn/{remainder}"));
}

// TODO: Experimental functions
debug {
	void stopServer(HTTPContext ctx)
	{
		import std.exception: enforce;
		enforce(ctx.user.isInRole(`admin`), `Requested URL is not found!`);
		ctx.service.stop();
		ctx.server.stop();
	}

	import std.json: JSONValue;
	void getCompiledTemplate(HTTPContext ctx) {
		return ctx.response.write(ViewService.getIvyModule(ctx.request.form[`moduleName`]).toStdJSON().toString());
	}

	@IvyModuleAttr("mkk.JSRender")
	IvyData templatePlayground(HTTPContext ctx) {
		return IvyData();
	}

	import ivy;
	import webtank.net.http.json_rpc_handler;
	shared static this() {
		ViewService.pageRouter.join!stopServer("/dyn/server/stop");
		ViewService.rootRouter.join!getCompiledTemplate("/dyn/server/template");
		ViewService.pageRouter.join!templatePlayground("/dyn/server/jsrender");
	}
}