module webtank.db.datctrl_joint;
///Функционал, объединяющий работу с БД и с набором записей

import std.conv, std.stdio;

import webtank.db.database, webtank.db.database_field;

import webtank.datctrl.field_type, webtank.datctrl.record_format, webtank.datctrl.record_set, webtank.datctrl.data_field;

//junction, joint, link, coop



auto getRecordSet(RecFormat)(IDBQueryResult queryResult, RecFormat format)
{	alias RecordSet!RecFormat RecSet;
	auto recordSet = new RecSet(format);
	foreach( i, fldSpec; RecFormat.fieldSpecs )
	{	auto field = new DatabaseField!(fldSpec.fieldType)(queryResult, i);
		recordSet._setField!(fldSpec.name)( field );
		static if( fldSpec.fieldType == FieldType.StrEnum )
		{	recordSet._initEnum( format.enumValues.get( fieldSpec.name, null ) );
		}
	}
	recordSet.setKeyField(0);
	return recordSet;
}

