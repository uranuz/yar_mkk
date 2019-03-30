module mkk_site.main_service.pohod.enums;

import mkk_site.main_service.devkit;

import mkk_site.data_model.enums;

shared static this()
{
	MainService.JSON_RPCRouter.join!(getPohodEnumTypes)(`pohod.enumTypes`);
}

/++ Возвращает JSON с перечислимыми типами, относящимися к походу +/
auto getPohodEnumTypes() {
	return tuple!(`tourismKind`, `complexity`, `progress`, `claimState`)(
		tourismKind, complexity, progress, claimState
	);
}