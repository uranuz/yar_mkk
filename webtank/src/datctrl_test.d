module webtank.datctrl_test;

import std.typetuple, std.typecons, std.stdio, std.conv;

import webtank.datctrl.field_type, webtank.datctrl.data_field, webtank.datctrl.record_format, webtank.datctrl.record, webtank.datctrl.record_set;
import webtank.db.database_field, webtank.db.datctrl_joint, webtank.db.postgresql;

void main()
{	
	alias FieldType ft;
	auto format = RecordFormat!(ft.IntKey, "Количество", ft.Int, "Цена", ft.Str, "Название", ft.Bool, "Условие")
		([true, true, true, false]);
	
	getFieldSpec!("Количество", format.fieldSpecs).valueType var;
	writeln( typeid( var ).to!string );
	writeln( format.types() );
	writeln( format.names() );
	writeln( format.nullableFlags );
	
	
	writeln( typeid( getTupleTypeOf!(IField, format.fieldSpecs) ).to!string  );
	alias  getTupleTypeOf!(DatabaseField, format.fieldSpecs)[2] DBFieldType;
	
	alias RecordSet!( typeof(format) ) RSType;
	
	writeln( typeid( RSType ).to!string  );
	
	writeln( getFieldIndex!("Количество", format.fieldSpecs) );
	
	string connStr = "dbname=postgres host=localhost user=postgres password=postgres";
	auto dbase = new DBPostgreSQL(connStr);
	assert( dbase.isConnected );
	
	auto bookRecFormat = RecordFormat!(ft.IntKey, "Ключ", ft.Str, "Название", ft.Str, "Автор", ft.Str, "Жанр", ft.Int, "Цена", ft.Bool, "Скидка", ft.Bool, "Переплет")();
	
	string query = `select * from book`;
	auto book_rs = dbase.query(query).getRecordSet(bookRecFormat);
	foreach( rec; book_rs )
	{	write( rec.getStr("Цена") );
// 		writeln( " - " ~ typeid( rec.getS"Цена"() ).to!string );
	}
}