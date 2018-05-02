module mkk_site.security.common.access_rules;

import webtank.security.access_control: IUserIdentity;
import webtank.security.right.plain_rule: PlainAccessRule;
import webtank.security.right.core_storage: CoreAccessRuleStorage;


bool regionalModerRule(IUserIdentity identity, string[string] data)
{
	return true;
}

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
	return rs;
}