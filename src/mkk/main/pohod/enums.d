module mkk.main.pohod.enums;

import mkk.main.devkit;

import mkk.main.enums;

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