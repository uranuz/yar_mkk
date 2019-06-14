module mkk.main.right.read;

import mkk.main.devkit;

import mkk.main.right.object.list: readObject;
import mkk.main.right.list: objRightRecFormat, rightQueryBase;
import mkk.main.right.role.list: readRole;
import mkk.main.right.rule.list: readRightRule;

shared static this()
{
	MainService.JSON_RPCRouter.join!(readBaseRight)(`right.readBase`);
	MainService.JSON_RPCRouter.join!(readRight)(`right.read`);

	MainService.pageRouter.joinWebFormAPI!(readBaseRight)("/api/right/readBase");
	MainService.pageRouter.joinWebFormAPI!(readRight)("/api/right/read");
}

Tuple!(IBaseRecord, `right`)
readBaseRight(HTTPContext ctx, Optional!size_t num = Optional!size_t())
{
	import std.format: format;

	enforce(ctx.user.isInRole(`admin`), `Недостаточно прав для вызова метода`);
	if( num.isNull ) {
		return typeof(return)(makeMemoryRecord(objRightRecFormat));
	}

	return typeof(return)(
		getAuthDB().queryParams(
			rightQueryBase.format(`where rgh.num = $1`), num
	).getRecord(objRightRecFormat));
}

Tuple!(
	IBaseRecord, `right`,
	IBaseRecord, `object`,
	IBaseRecord, `role`,
	IBaseRecord, `rule`
)
readRight(
	HTTPContext ctx,
	Optional!size_t num = Optional!size_t(),
	Optional!size_t objectNum = Optional!size_t()
) {
	enforce(
		!num.isSet || !objectNum.isSet,
		`Одновременно можно указать либо идентификатор права, либо объекта прав`);

	typeof(return) res;
	res.right = readBaseRight(ctx, num).right;
	enforce(res.right !is null, `Не удалось прочитать права по идентификатору`);
	auto baseRec = TypedRecord!(typeof(objRightRecFormat), IBaseRecord)(res.right);

	if( !baseRec.isNull(`objectNum`) ) {
		Optional!size_t objNum = baseRec.get!"objectNum"();
		res.object = readObject(ctx, objNum).rightObj;
	} else if(objectNum.isSet) {
		res.object = readObject(ctx, objectNum).rightObj;
	}
	if( !baseRec.isNull(`roleNum`) ) {
		Optional!size_t roleNum = baseRec.get!"roleNum"();
		res.role = readRole(ctx, roleNum).role;
	}
	if( !baseRec.isNull(`ruleNum`) ) {
		Optional!size_t ruleNum = baseRec.get!"ruleNum"();
		res.rule = readRightRule(ctx, ruleNum).ruleRec;
	}
	return res;
}