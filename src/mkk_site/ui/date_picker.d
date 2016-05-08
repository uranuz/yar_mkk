module mkk_site.ui.date_picker;

import webtank.ui.date_picker;
import webtank.common.optional: OptionalDate;

///Функция-помощник для создания списка флагов
auto bsPlainDatePicker( OptionalDate optDate = OptionalDate() )
{
	auto elemClasses = [
		"block": [],
		"list_item": [],
		"item_input": [],
		"item_label": [`checkbox-inline`]
	];

	auto ctrl = plainDatePicker(optDate);
	import std.array: join;

	foreach( elName, elClass; elemClasses )
		ctrl.addElementHTMLClasses( elName, elClass.join(' ') );

	return ctrl;
}

