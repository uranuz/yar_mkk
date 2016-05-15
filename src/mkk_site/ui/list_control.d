module mkk_site.ui.list_control;

import webtank.ui.list_control;

///Функция-помощник для создания списка флагов
auto bsCheckBoxList(T)(T valueSet)
{
	auto elemClasses = [
		"block": [],
		"list_item": [],
		"item_input": [],
		"item_label": [`checkbox-inline`]
	];
	
	auto ctrl = checkBoxList(valueSet);
	
	import std.array: join;
	
	foreach( elName, elClass; elemClasses )
		ctrl.addElementHTMLClasses( elName, elClass.join(' ') );
		
	return ctrl;
}


///Функция-помощник для создания списка флагов
auto bsListBox(T)(T valueSet)
{
	string[][string] elemClasses = [
		"block": [],
		"list_item": [],
		"item_input": [],
		"item_label": []
	];

	auto ctrl = listBox(valueSet);

	import std.array: join;

	foreach( elName, elClass; elemClasses )
		ctrl.addElementHTMLClasses( elName, elClass.join(' ') );

	return ctrl;
}
