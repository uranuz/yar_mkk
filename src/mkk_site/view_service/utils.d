module mkk_site.view_service.utils;

import webtank.net.http.context: HTTPContext;
import ivy.interpreter.data_node: IvyData;
import std.json: JSONValue;
import webtank.net.uri_pattern: URIPattern;
import webtank.net.http.handler.uri_page_route: URIPageRoute;
import webtank.net.http.handler.iface: ICompositeHTTPHandler;
import webtank.net.std_json_rpc_client: endpoint, RemoteCallInfo, remoteCall;
import webtank.ivy.rpc_client: remoteCall;


// Перегрузка mainServiceCall для удобства, которая позволяет передать HTTP контекст для извлечения заголовков
Result mainServiceCall(Result = IvyData, T...)(HTTPContext ctx, string rpcMethod, auto ref T paramsObj)
	if( (is(Result == IvyData) || is(Result == JSONValue)) && T.length <= 1 )
{
	import std.exception: enforce;
	enforce(ctx !is null, `HTTP context is null`);
	return ctx.endpoint(`yarMKKMain`).remoteCall!(Result)(rpcMethod, paramsObj);
}

// Аттрибут, который говорит, что данные возвращаемые методом нужно передать в шаблон
struct IvyModuleAttr {
	string moduleName;
	string dirName;
}

import std.traits: ReturnType, Parameters;
template join(alias Method)
	if(
		(is(ReturnType!(Method) == string) || is(ReturnType!(Method) == IvyData))
		&& Parameters!(Method).length == 1 && is(Parameters!(Method)[0] : HTTPContext)
	)
{
	void _processRequest(HTTPContext context) {
		import std.traits: getUDAs;
		import ivy.programme: ExecutableProgramme;
		import mkk_site.view_service.service: ViewService;
		enum modAttr = getUDAs!(Method, IvyModuleAttr);
		auto methodRes = Method(context);

		static if( modAttr.length == 0 ) {
			ViewService.renderResult(methodRes, context);
		} else static if( modAttr.length == 1 ) {
			import webtank.ivy.service_mixin: prepareIvyGlobals;
			// Если есть аттрибут шаблона на методе, то используем этот шаблон для отображения
			// результата выполнения метода
			ExecutableProgramme ivyProg = ViewService.ivyEngine.getByModuleName(modAttr[0].moduleName);
			if( modAttr[0].dirName.length == 0 ) {
				ivyProg.run(methodRes, prepareIvyGlobals(context)).then(
					(IvyData ivyRes) {
						ViewService.renderResult(ivyRes, context);
					},
					(Throwable error) {
						throw error;
					}
				);
			} else {
				ivyProg.runMethod(modAttr[0].dirName, methodRes, prepareIvyGlobals(context)).then(
					(IvyData ivyRes) {
						ViewService.renderResult(ivyRes, context);
					},
					(Throwable error) {
						throw error;
					}
				);
			}
		} else {
			static assert(false, `Expected only one template name`);
		}
	}

	import std.functional: toDelegate;
	ICompositeHTTPHandler join(ICompositeHTTPHandler parentHdl, string uriPatternStr)
	{
		parentHdl.addHandler(new URIPageRoute(toDelegate(&_processRequest), uriPatternStr));
		return parentHdl;
	}

	ICompositeHTTPHandler join(ICompositeHTTPHandler parentHdl, URIPattern uriPattern)
	{
		parentHdl.addHandler(new URIPageRoute(toDelegate(&_processRequest), uriPattern));
		return parentHdl;
	}
}