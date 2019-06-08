module mkk.main.right.right_edit;

import mkk.main.devkit;

/*
shared static this()
{
	MainService.JSON_RPCRouter.join!(editRight)(`right.rule.list`);

	MainService.pageRouter.joinWebFormAPI!(editRight)("/api/right/rule/list");
}
*/

struct RightRuleData
{
	Optional!size_t num;

@RightObjAttr(`right.object.right`)
@RightObjAttr() {
	@DBField(`object_num`) Undefable!size_t objectNum;
	@DBField(`rule_num`) Undefable!size_t ruleNum;
	@DBField(`access_kind`) Undefable!string accessKind;
	@DBField(`role_num`) Undefable!size_t roleNum;
	@DBField(`inheritance`) Undefable!bool inheritance;
}

}

/*
Tuple!(

)
editRight(HTTPContext ctx, ) {

}
*/