module webtank.datctrl_test;

import std.typetuple, std.typecons, std.stdio, std.conv;

import webtank.datctrl.field_type, webtank.datctrl.data_field, webtank.datctrl.record_format, webtank.datctrl.record, webtank.datctrl.record_set;
import webtank.db.database_field;

void main()
{	
	alias FieldType ft;
	auto format = RecordFormat!(ft.IntKey, "Количество", ft.Int, "Цена", ft.Str, "Название", ft.Bool, "Условие")
		([true, true, true, false]);
	
	getFieldSpecByName!("Количество", format.fieldSpecs).valueType var;
	writeln( typeid( var ).to!string );
	writeln( format.types() );
	writeln( format.names() );
	writeln( format.nullableFlags );
	
	
	writeln( typeid( getTupleOfByFieldSpec!(IField, format.fieldSpecs) ).to!string  );
	alias  getTupleOfByFieldSpec!(DatabaseField, format.fieldSpecs)[2] DBFieldType;
	auto field = new DBFieldType;
	writeln( typeid( field ).to!string  );
	writeln( field.isNullable() );
	
	alias RecordSet!format RSType;
	
	writeln( typeid( RSType ).to!string  );
	
	writeln( getFieldSpecIndex!("Количество", format.fieldSpecs) );
	
	auto rs = new RSType;
	auto countFld = new DatabaseField!(FieldType.IntKey);
	
	rs._setField!("Количество")(countFld);
	
}