module mkk.main.right.object_list;

import mkk.main.devkit;

shared static this()
{
	MainService.JSON_RPCRouter.join!(getObjectList)(`right.objectList`);
	MainService.JSON_RPCRouter.join!(readObject)(`right.object.read`);
	MainService.JSON_RPCRouter.join!(readObjectWithRights)(`right.object.readWithRights`);
	MainService.JSON_RPCRouter.join!(getObjectRightList)(`right.object.rightList`);

	MainService.pageRouter.joinWebFormAPI!(getObjectList)("/api/right/object/list");
	MainService.pageRouter.joinWebFormAPI!(readObject)("/api/right/object/read");
	MainService.pageRouter.joinWebFormAPI!(readObjectWithRights)("/api/right/object/readWithRights");
	MainService.pageRouter.joinWebFormAPI!(getObjectRightList)("/api/right/object/right/list");
}

import std.meta: AliasSeq;

static immutable rightObjectRecFormat = RecordFormat!(
	PrimaryKey!size_t, "num",
	string, "name",
	string, "description",
	size_t, "parentNum",
	string, "folderName"
)();

static immutable rightObjectQueryBase =
`select r_obj.*,
	(
		with recursive par as(
			select
				fp_obj.name,
				fp_obj.parent_num
			from access_object fp_obj
			where fp_obj.num = r_obj.parent_num

			union all

			select
				coalesce(t_obj.name || '.', '') || par.name,
				t_obj.parent_num
			from par
			join access_object t_obj
				on t_obj.num = par.parent_num
		)
		select par.name from par
		where par.parent_num is null
	) as folderName
from(
	select 
	%s
	from access_object a_obj
	%s
) as r_obj
`;

static immutable rightObjectFieldsSub = `
	a_obj.num,
	a_obj.name,
	a_obj.description,
	a_obj.parent_num
`;

static immutable rightObjectParentFieldsSub = `
	null::integer "num",
	null::text "name",
	null::text "description",
	a_obj.num "parent_num"
`;

Tuple!(IBaseRecordSet, `objectList`)
getObjectList(HTTPContext ctx)
{
	import std.format: format;

	enforce(ctx.user.isInRole(`admin`), `Недостаточно прав для вызова метода`);

	return typeof(return)(
		getAuthDB().query(
			rightObjectQueryBase.format(
				rightObjectFieldsSub,`order by a_obj.name`)
		).getRecordSet(rightObjectRecFormat));
}

Tuple!(IBaseRecord, `rightObj`)
readObject(
	HTTPContext ctx,
	Optional!size_t num = Optional!size_t(),
	Optional!size_t parentNum = Optional!size_t()
) {
	import std.format: format;
	import webtank.datctrl.detatched_record: makeMemoryRecord;
	enforce(ctx.user.isInRole(`admin`), `Недостаточно прав для вызова метода`);

	if( num.isNull && parentNum.isNull ) {
		return typeof(return)(makeMemoryRecord(rightObjectRecFormat));
	}
	enforce(num.isNull || parentNum.isNull, `Нужно задать идентификатор объекта или идентификатор родителя, но не оба`);

	return typeof(return)(
		getAuthDB().queryParams(
			rightObjectQueryBase.format(
				(num.isSet? rightObjectFieldsSub: rightObjectParentFieldsSub),
				`where a_obj.num = $1::integer`),
				(num.isSet? num: parentNum)
		).getRecord(rightObjectRecFormat));
}

Tuple!(
	IBaseRecord, `rightObj`,
	IBaseRecordSet, `objectRightList`
)
readObjectWithRights(
	HTTPContext ctx,
	Optional!size_t num = Optional!size_t(),
	Optional!size_t parentNum = Optional!size_t()
) {
	return typeof(return)(
		readObject(ctx, num, parentNum).rightObj,
		getObjectRightList(ctx, num).objectRightList
	);
}

static immutable objRightRecFormat = RecordFormat!(
	PrimaryKey!size_t, "num",
	string, "accessKind",
	string, "roleName",
	string, "ruleName",
	bool, "inheritance"
)();

Tuple!(IBaseRecordSet, `objectRightList`)
getObjectRightList(HTTPContext ctx, Optional!size_t num)
{
	enforce(ctx.user.isInRole(`admin`), `Недостаточно прав для вызова метода`);
	return typeof(return)(getAuthDB().queryParams(`
	select
		rgh.num,
		rgh."access_kind" "accessKind",
		a_role.name "roleName",
		a_rule.name "ruleName",
		rgh.inheritance
	from access_right rgh
	left join access_role a_role
		on a_role.num = rgh.role_num
	left join access_rule a_rule
		on a_rule.num = rgh.rule_num
	where rgh.object_num = $1::integer`, num
	).getRecordSet(objRightRecFormat));
}