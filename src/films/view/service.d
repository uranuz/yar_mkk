module films.view.service;

public import webtank.net.http.handler;
public import mkk.common.service: Service;

FilmsViewService ViewService() @property
{
	FilmsViewService srv = cast(FilmsViewService) Service();
	assert( srv, `View service is null` );
	return srv;
}

import webtank.ivy.view_service: IvyViewService;

class FilmsViewService: IvyViewService
{
	import webtank.security.right.controller: AccessRightController;
	import webtank.security.right.remote_source: RightRemoteSource;
	import webtank.ivy.access_rule_factory: IvyAccessRuleFactory;
	import webtank.security.access_control: IAccessController;

	import ivy.interpreter.data_node: IvyData;
	import ivy.interpreter.data_node_render: renderDataNode, DataRenderType;
	import webtank.net.http.output: HTTPOutput;
	import webtank.net.http.context: HTTPContext;
public:
	this(string serviceName, string pageURIPatternStr)
	{
		super(serviceName, pageURIPatternStr);
	}

	override IAccessController accessController() @property
	{
		assert(false, `Access controller is null`);
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
			import webtank.ivy.service_mixin: prepareIvyGlobals;

			IvyData payload = [
				"content": content,
				"vpaths": IvyData(ctx.service.virtualPaths)
			];

			ivyEngine.getByModuleName("films.GeneralTemplate").run(payload, prepareIvyGlobals(ctx)).then(
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

import webtank.net.http.context: HTTPContext;

void getCompiledTemplate(HTTPContext ctx)
{
	import webtank.net.http.handler.json_rpc;
	return ctx.response.write(
		ViewService.ivyEngine.getByModuleName(
			ctx.request.form[`moduleName`]).toStdJSON().toString());
}

shared static this() {
	Service(new FilmsViewService("filmsView", "/dyn/{remainder}"));

	ViewService.rootRouter.join!getCompiledTemplate("/dyn/server/template");
}