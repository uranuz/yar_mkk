module mkk.main.right.role.right_list;

import mkk.main.devkit;
import mkk.main.right.role.list: readRole;

shared static this()
{
	MainService.JSON_RPCRouter.join!(getRoleRights)(`right.role.rights`);

	MainService.pageRouter.joinWebFormAPI!(getRoleRights)("/api/right/role/rights");
}

static immutable roleRightsQueryBase =`
with
a_objs as(
select distinct on(a_obj.num)
	a_obj.num,
	a_obj.parent_num,
	a_obj.name,
	a_obj.description,
	a_obj.num::text || ':1' surr_num,
	a_obj.parent_num::text || ':1' surr_parent,
	1 surr_type,
	a_right.inheritance,
	null::text "access_kind",
	(
		with recursive par as(
			select
				fp_obj.name,
				fp_obj.parent_num
			from access_object fp_obj
			where fp_obj.num = a_obj.parent_num

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
	) "folderName"
from access_role a_role
join access_right a_right
	on a_right.role_num = a_role.num
join access_object a_obj
	on a_obj.num = a_right.object_num
where a_role.num = $1
order by a_obj.num, a_right.inheritance desc nulls last
),
r_info as(
select
	a_right.num,
	a_obj.num "parent_num",
	a_rule.name,
	null::text description,
	a_right.num::text || ':3' surr_num,
	a_obj.num::text || ':1' surr_parent,
	3 surr_type,
	a_right.inheritance,
	a_right.access_kind,
	null::text "folderName"
from access_role a_role
join access_right a_right
	on a_right.role_num = a_role.num
join access_object a_obj
	on a_obj.num = a_right.object_num
left join access_rule a_rule
	on a_rule.num = a_right.rule_num
where a_role.num = $1
)
select * from a_objs
union all
select * from r_info
`;

static immutable roleRightsRecFormat = RecordFormat!(
	size_t, "num",
	size_t, "parent_num",
	string, "name",
	string, "description",
	PrimaryKey!string, "surr_num",
	string, "surr_parent",
	ubyte, "surr_type",
	bool, "inheritance",
	string, "access_kind",
	string, "folderName"
)();

Tuple!(
	IBaseRecordSet, `rightList`,
	IBaseRecord, `role`
)
getRoleRights(HTTPContext ctx, Optional!size_t num)
{
	enforce(ctx.user.isInRole(`admin`), `Нет разрешения на выполнение операции`);

	typeof(return) res;

	res.role = readRole(ctx, num).role;
	
	res.rightList = getAuthDB().queryParams(
		roleRightsQueryBase, num
	).getRecordSet(roleRightsRecFormat);

	return res;
}