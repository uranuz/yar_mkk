module mkk_site.security.common.access_rules;

import webtank.security.access_control: IUserIdentity;
import webtank.security.right.plain_rule: PlainAccessRule;
import webtank.security.right.core_storage: CoreAccessRuleStorage;
import webtank.ivy.service_mixin: IIvyServiceMixin;

import ivy;
import ivy.json;
import ivy.interpreter.data_node;
import ivy.interpreter.interpreter: Interpreter;

import mkk_site.common.service: Service;


auto runFromTemplateCache(string moduleName, string funcName, IvyData[string] args)
{
	import std.exception: enforce;
	IIvyServiceMixin ivyMixin = cast(IIvyServiceMixin) Service();
	enforce(ivyMixin !is null, `Expected IIvyServiceMixin`);
	Interpreter interp = ivyMixin.runIvySaveState(moduleName);
	return interp.runModuleDirective(funcName, args);
}


bool regionalModerRule(IUserIdentity identity, string[string] data)
{
	return true;
}

import std.stdio;

CoreAccessRuleStorage makeCoreAccessRules()
{
	CoreAccessRuleStorage rs = new CoreAccessRuleStorage;
	import std.functional: toDelegate;
	rs.join(new PlainAccessRule(
		// Rule to allow access
		"allow", (IUserIdentity identity, string[string] data) {
			return true;
		}
	));
	rs.join(new PlainAccessRule(
		// Rule to allow access
		"check_new_user", (IUserIdentity identity, string[string] data) {
			IvyData[string] ivyData;
			bool result = runFromTemplateCache(`mkk.AccessRules`, `CheckSomething`, ivyData).boolean;
			writeln(`TRACE check_new_user result: `, result);
			return result;
		}
	));
	return rs;
}