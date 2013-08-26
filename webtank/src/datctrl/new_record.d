module webtank.datctrl.new_record;


import std.typetuple, std.stdio, std.conv;




template Record(Args ...)
{	
	template parseSpecs(Specs...)
	{
		static if( Specs.length == 0 )
		{	
// 			static assert(0, "Запись должна содержать хотя бы одно поле!");
			alias TypeTuple!() parseSpecs;
		}
		else static if( is( Args[0] ) )
		{	static if( is( typeof( Args[1] ) : string ) )
			{	alias TypeTuple!(FieldSpec!(Specs[0 .. 2]), parseSpecs!(Specs[2 .. $])) parseSpecs;
			}
			else 
			{
				alias TypeTuple!(FieldSpec!(Specs[0]), parseSpecs!(Specs[1 .. $])) parseSpecs;
			}
			
			
		}
	}
	
	
	template FieldSpec( T, string s = "" )
	{	alias T type;
		alias s name;
		
	}
	
	alias parseSpecs!Args fieldSpecs;
	
	template getFieldSpecByName(string fieldName)
	{	
		alias generalGetFieldSpecByName!( fieldName, fieldSpecs ) getFieldSpecByName;
	}
	
	template generalGetFieldSpecByName(string fieldName, FldSpecs...)
	{	static if( FldSpecs.length == 0 )
		{	static assert(0, "Field with name \"" ~ fieldName ~ "\" is not found in container!!!");
		}
		else static if( FldSpecs[0].name == fieldName )
		{	alias FldSpecs[0] generalGetFieldSpecByName;
		}
		else
		{	alias generalGetFieldSpecByName!(fieldName, FldSpecs[1 .. $]) generalGetFieldSpecByName;
		}
	}
	
// 	class Record
// 	{	
// 		template get(string fieldName)
// 		{	
// 			
// 			
// 		}
// 		
// 		get()
// 		
// 		
// 	}
	
}


alias Record!(int, "Количество", double, "Цена", string, "Название", bool, "Условие") MyRecord;

void main()
{	MyRecord.getFieldSpecByName!("Говно").type var;
	writeln( typeid( var ).to!string );
	
}