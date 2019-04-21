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

class MKKViewService: IvyViewService
{
	import mkk_site.security.common.access_control_client: MKKAccessControlClient;
	import webtank.security.right.controller: AccessRightController;
	import webtank.security.right.remote_source: RightRemoteSource;
	import webtank.ivy.access_rule_factory: IvyAccessRuleFactory;

	import mkk_site.common.utils;

	import ivy.interpreter.data_node: IvyData;
	import ivy.interpreter.data_node_render: renderDataNode, DataRenderType;
	import webtank.net.http.output: HTTPOutput;
	import webtank.net.http.context: HTTPContext;
public:
	this(string serviceName, string pageURIPatternStr)
	{
		super(serviceName, pageURIPatternStr);

		_accessController = new MKKAccessControlClient;
		_rights = new AccessRightController(
			new IvyAccessRuleFactory(this.ivyEngine),
			new RightRemoteSource(this, `yarMKKMain`, `accessRight.list`));
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

			import webtank.security.right.source_method: getAccessRightList;
			import webtank.security.right.controller: AccessRightController;
			import webtank.common.std_json.to: toStdJSON;
			import webtank.ivy.service_mixin: prepareIvyGlobals;
			import ivy.interpreter.data_node: NodeEscapeState;
			import std.json: JSONValue;
			import std.algorithm: splitter, map, filter;
			import std.string: strip;
			import std.array: array;
			AccessRightController rightController = cast(AccessRightController) ctx.service.rightController;
			assert(rightController !is null, `rightController is not of type AccessRightController or null`);
			auto rights = getAccessRightList(rightController.rightSource).toStdJSON();
			string[] accessRoles = ctx.user.data.get("accessRoles", null)
				.splitter(';').map!(strip).filter!((it) => it.length).array;
			IvyData userRightData = JSONValue([
				"user": JSONValue([
					"id": JSONValue(ctx.user.id),
					"name": JSONValue(ctx.user.name),
					"accessRoles": JSONValue(accessRoles),
					"sessionId": (ctx.user.isAuthenticated()? JSONValue("dummy"): JSONValue())
				]),
				"right": (ctx.user.isAuthenticated()? rights: JSONValue()),
				"vpaths": JSONValue(ctx.service.virtualPaths)
			]).toString();
			userRightData.escapeState = NodeEscapeState.Safe;
			IvyData payload = [
				"content":  content,
				"authRedirectURI": IvyData(getAuthRedirectURI(ctx)),
				"pohodFilterFields": favouriteFilters["allFields"],
				"pohodFilterSections": favouriteFilters["sections"],
				"userRightData": userRightData
			];

			ivyEngine.getByModuleName("mkk.GeneralTemplate").run(payload, prepareIvyGlobals(ctx)).then(
				(IvyData fullContent) {
					super.renderResult(fullContent, ctx);
				},
				(Throwable error) {
					import ivy.interpreter.data_node: errorToIvyData;
					super.renderResult(errorToIvyData(error), ctx);
				}
			);
		} else {
			super.renderResult(content, ctx);
		}
	}
}

void stopServer(HTTPContext ctx)
{
	import std.exception: enforce;
	enforce(ctx.user.isInRole(`admin`), `Requested URL is not found!`);
	ctx.service.stop();
	ctx.server.stop();
}

void getCompiledTemplate(HTTPContext ctx)
{
	import webtank.net.http.handler.json_rpc;
	return ctx.response.write(
		ViewService.ivyEngine.getByModuleName(
			ctx.request.form[`moduleName`]).toStdJSON().toString());
}

shared static this() {
	Service(new MKKViewService("yarMKKView", "/dyn/{remainder}"));

	//ViewService.pageRouter.join!stopServer("/dyn/server/stop");

	ViewService.rootRouter.join!getCompiledTemplate("/dyn/server/template");
}