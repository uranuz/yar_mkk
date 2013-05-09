module webtank.db.datctrl_joint;
///Функционал, объединяющий работу с БД и с набором записей

import std.conv;
import std.stdio;

import webtank.db.database;
import webtank.db.postgresql;

import webtank.datctrl.field_type;
import webtank.datctrl.record;
import webtank.datctrl.record_set;
import webtank.datctrl.data_field;

//junction, joint, link, coop

//Вспомогательный класс формата поля, наследующий общему интерфейсу
class _HelperFieldFormat: IFieldFormat
{	
protected:
	string _name;
	FieldType _type;
	bool _isNullable;
	bool _isWriteable;
	IField _linkField;

public:
	this( IFieldFormat fldFormat )
	{	_name = fldFormat.name;
		_type = fldFormat.type;
		_isNullable = fldFormat.isNullable;
		_linkField = fldFormat.linkField;
	}
	
	this( IFieldFormat fldFormat, size_t someIndex )
	{	this(fldFormat);
		index = someIndex;
	}
	
	this() {}
	
	override {
		string name() @property
		{	return _name; }
		FieldType type() @property
		{	return _type; }
		bool isNullable() @property
		{	return _isNullable; }
		bool isWriteable() @property
		{	return _isWriteable; }
		IField linkField()  @property //Связанное поле (пока предполагается, что ключевое)
		{	return _linkField; }
	}
	
	void name(string fieldName) @property
	{	_name = fieldName; }
	void type(FieldType fieldType) @property
	{	_type = fieldType; }
	void isNullable(bool nullable) @property
	{	_isNullable = nullable; }
	void isWriteable(bool writeable) @property
	{	_isWriteable = writeable; }
	void linkField(IField linkField) @property
	{	_linkField = linkField; }
	
	//Чтобы не писать всякие дурацкие функции, просто добавим открытое поле
	size_t index; //Номер поля
}

RecordSet getRecordSet(ref IDBQueryResult queryResult, ref RecordFormat recFormat)
{	if( queryResult is null ) //Если передать ничто, то получим ничто
		return null;
	
	if( queryResult.type == DBMSType.postgreSQL )  //Обрабатываем результат запроса из PostgreSQL
	{	auto resultRS = new RecordSet;
		auto tQueryRes = cast(PostgreSQLQueryResult) queryResult;
		size_t queryResFieldCount = tQueryRes.fieldCount();
		size_t fieldCount = //Из двух количеств полей берём меньшее
			( queryResFieldCount < recFormat.types.length ) ? queryResFieldCount : recFormat.types.length;
		
		KeyField keyField;
		
		//Вспомогательная функция создания формата
		_HelperFieldFormat createFieldFormat(size_t i)
		{	auto fldFormat = new _HelperFieldFormat;
			fldFormat.name = recFormat.names[i];
			fldFormat.type = recFormat.types[i];
			fldFormat.isNullable = recFormat.nullableFlags[i];
			fldFormat.index = i;
			fldFormat.linkField = keyField;
			return fldFormat;
		}
		
		alias _GetFieldDataFromPGQueryResult getField;
		bool keyFieldFound = false;
		
		for( size_t i = 0; i < fieldCount; ++i )
		{	if( recFormat.types[i] == FieldType.IntKey )
			{	if( !keyFieldFound )
				{	keyFieldFound = true;
					keyField = cast(KeyField) getField!(FieldType.IntKey)( tQueryRes, createFieldFormat(i) );
					resultRS.addField( keyField );
				}
				else
					assert(0, `Разрешено добавление только одного ключевого поля в набор записей`);
			}
		}
		if( !keyFieldFound )
			assert(0, `В формате записи должно быть указано ключевое поле`);
		
		with( FieldType )
		{
		for( size_t i = 0; i < fieldCount; ++i )
		{	FieldType fldType = recFormat.types[i];
			if( fldType == IntKey ) continue;
			IField curField;
			switch( fldType )
			{	case Int:
				{	curField = getField!(Int)( tQueryRes, createFieldFormat(i) );
					break;
				}
				case Str:
				{	curField = getField!(Str)( tQueryRes, createFieldFormat(i) );
					break;
				}
				break;
				case Bool:
				{	curField = getField!(Bool)( tQueryRes, createFieldFormat(i) );
					break;
				}
				break;
				default:
					//Do nothing
				break;
			}
			resultRS.addField( curField );
		}
		} //with( FieldType )
		return resultRS;
	}
	assert(0);
}

template _GetFieldDataFromPGQueryResult(FieldType Type)
{	IField _GetFieldDataFromPGQueryResult( PostgreSQLQueryResult queryResult, _HelperFieldFormat fldFormat )
	{	
		size_t recordCount = queryResult.recordCount(); //Количество записей в ответе
		auto fmt = new _HelperFieldFormat(fldFormat, fldFormat.index);
		
		//Если имя поля не задано в формате, то берем из результата запроса
		if( fldFormat.name.length == 0  )
			fmt.name = queryResult.getFieldName(fmt.index);
		else 
			fmt.name = fldFormat.name;
		
		//Заранее выделяем память под данные
		alias GetFieldValueType!(Type) ValueType;
		ValueType[] data;
		data.length = recordCount;
		
		static if( Type != FieldType.IntKey )
		{	bool[] nullFlags;
			if( fmt.isNullable )
				nullFlags.length = recordCount;
		}

		for( size_t j = 0; j < recordCount; ++j )
		{	static if( Type == FieldType.IntKey ) //Ветка для ключевого поля
				data[j] = fldConv!(Type)( queryResult.getValue(j, fmt.index) ); 
			else //Ветка для типов-значений
			{	if( fmt.isNullable ) //Если не обнуляемый, то флаги пустоты не вытаскиваем
					nullFlags[j] = queryResult.getIsNull(j, fmt.index);
				//Вытаскиваем значение только если не пусто
				if( (fmt.isNullable && !nullFlags[j]) || !fmt.isNullable )
					data[j] = fldConv!(Type)( queryResult.getValue(j, fmt.index) ); 
			}
		}
		
		static if( Type == FieldType.IntKey )
		{	auto resultField = new KeyField( fmt.name );
			resultField.addData( data ); //Добавляем ключи в ключевое поле
		}
		else
		{	auto resultField = new Field!(Type)( fmt );
			resultField.addData( data, nullFlags ); //Добавляем данные в поле данных
		}
		return resultField;
	}
}