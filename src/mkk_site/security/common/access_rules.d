module mkk_site.security.common.access_rules;

import webtank.security.right.access_rule;

bool regionalModerRule(IUserIdentity identity, string[string] data)
{
	return true;
}

CoreAccessRuleStorage makeCoreAccessRules()
{
	CoreAccessRuleStorage rs = new CoreAccessRuleStorage;
	import std.functional: toDelegate;
	rs.join(new PlainAccessRule(
		"regional_moder",
		toDelegate(&regionalModerRule)
	));
	rs.join(new PlainAccessRule(
		"vid_moder",
		toDelegate(&regionalModerRule)
	));
	return rs;
}