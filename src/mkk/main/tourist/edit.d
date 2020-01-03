module mkk.main.tourist.edit;

import mkk.main.devkit;

import mkk.main.tourist.model;

import mkk.history.client;
import mkk.history.common;

shared static this()
{
	MainService.JSON_RPCRouter.join!(editTourist)(`tourist.edit`);
	MainService.JSON_RPCRouter.join!(touristDelete)(`tourist.delete`);

	MainService.pageRouter.joinWebFormAPI!(editTourist)("/api/tourist/edit/results");
}

import std.typecons: Tuple;

void _checkRequired(string field)(ref TouristDataToWrite record, string what)
{
	import std.string: strip;
	import std.range: empty;
	import std.traits: isSomeString;

	auto val = __traits(getMember, record, field);
	static if( isSomeString!(typeof(val.value)) ) {
		bool res = val.isSet && !val.value.strip.empty;
	} else {
		bool res = val.isSet;
	}
	enforce(res, "Необходимо указать " ~ what);
}

void requireFieldsForReg(TouristDataToWrite record)
{
	// При регистрации нового пользователя данные поля обязательны.
	// Считаем, что пользователь должен их знать о себе
	_checkRequired!"familyName"(record, "фамилию");
	_checkRequired!"givenName"(record, "имя");
	_checkRequired!"email"(record, "эл. почту");
	_checkRequired!"birthYear"(record, "год рождения");
	_checkRequired!"birthMonth"(record, "месяц рождения");
	_checkRequired!"birthDay"(record, "день рождения");
}

Tuple!(Optional!size_t, `touristNum`)
editTourist(
	HTTPContext ctx,
	TouristDataToWrite record
) {
	import std.meta: AliasSeq, staticMap;
	import std.algorithm: canFind, countUntil;
	import std.conv: text, ConvException;
	import mkk.main.enums: sportsCategory, refereeCategory;
	import std.json: JSONValue;
	import webtank.security.right.access_exception: AccessException;

	bool allowEdit = ctx.rights.hasRight(`tourist.item`, `edit`);
	bool allowRegUser = ctx.rights.hasRight(`tourist.item`, `reg_user`);
	auto userNumPtr = "userNum" in ctx.user.data;
	enforce(userNumPtr !is null, "Не удаётся определить идентификатор пользователя");

	static immutable NO_RIGHTS = `Недостаточно прав для редактирования туриста!`;
	enforce!AccessException(allowEdit || allowRegUser, NO_RIGHTS);
	if( allowRegUser && !allowEdit ) {
		// Выданы права для добавления записи в процедуре регистрации, но не выданы права на редактирования
		// Кто-то пытается изменить существущую запись туриста без соответствующих прав
		enforce!AccessException(!record.num.isSet, NO_RIGHTS);

		requireFieldsForReg(record);

		// Добавление записи туриста при регистрации пользователя происходит уже под сессией этого нового пользователя
		// Разрешаем зарегистрировать только одного туриста, который будет привязан к пользователю
		// Повторные попытки расцениваем как попытки регистрации туристов под неподтвержденым пользователем и запрещаем
		bool alreadyRegSmth = getCommonDB().queryParams(`
select exists(
	select 1
	from tourist tour
	where
		tour.registrator_num = $1::integer
		or
		tour.last_editor_num = $1::integer
	limit 1
)
`, *userNumPtr).getScalar!bool();
		enforce(!alreadyRegSmth, `Неподтвержденный пользователь не может добавлять новых туристов`);
	}
	checkStructEditRights(record, ctx, [`edit`, `reg_user`]); // Проверка прав


	string[] fieldNames; // имена полей для записи
	string[] fieldValues; // значения полей для записи

	alias TouristEnums = AliasSeq!(
		tuple("sportsCategory", sportsCategory),
		tuple("refereeCategory", refereeCategory)
	);
	enum string GetFieldName(alias E) = E[0];
	enum enumFieldNames = [staticMap!(GetFieldName, TouristEnums)];

	mixin(WalkFields!(`record`, q{
		// Проверка данных
		static if( enumFieldNames.canFind(fieldName) )
		{
			auto enumFormat = TouristEnums[enumFieldNames.countUntil(fieldName)][1];
			enforce!ConvException(
				!field.isSet || field.value in enumFormat,
				`Выражение "` ~ field.value.text ~ `" не является значением типа "` ~ fieldName ~ `"!!!`);
		}

		static if( fieldName == "birthMonth" )
		{
			fieldNames ~= dbFieldName;
			enforce(
				!record.birthDay.isSet || (1 <= record.birthDay && record.birthDay <= 31),
				"День месяца должен быть числом от 1 до 31!");
			enforce(
				!record.birthMonth.isSet || (1 <= record.birthMonth && record.birthMonth <= 12),
				"Номер месяца должен быть числом от 1 до 12!");

			if( record.birthDay.isNull && record.birthMonth.isNull ) {
				fieldValues ~= "NULL";
			} else {
				fieldValues ~= (record.birthDay.isSet? record.birthDay.text: null)
					~ `.` ~ (record.birthMonth.isSet? record.birthMonth.text: null);
			}
		} else static if( fieldName == "birthDay" ) {
			// Ничего не делаем - специально оставлено пусто
		} else {
			fieldNames ~= dbFieldName;
			fieldValues ~= field.toPGString();
		}
	}));

	auto res = typeof(return)(record.num);
	if( fieldNames.empty ) {
		return res;
	}

	//Запись автора последних изменений и даты этих изменений
	fieldNames ~= "last_editor_num";
	fieldValues ~= *userNumPtr;

	// Это постоянные, которые НЕ экранируются в запросе
	string[] safeFieldNames = ["last_edit_timestamp"];
	string[] safeFieldValues = ["current_timestamp"];

	if( !record.num.isSet )
	{
		// При создании записи сохраняем - кто и когда ее создал
		fieldNames ~= "registrator_num";
		fieldValues ~= *userNumPtr;

		safeFieldNames ~= "reg_timestamp";
		safeFieldValues ~= "current_timestamp";
	}

	// Создадим транзакцию для записи информации
	import webtank.db.transaction: makeTransaction;
	auto trans = getCommonDB().makeTransaction();
	scope(failure) trans.rollback();
	scope(success) trans.commit();

	res.touristNum = getCommonDB().insertOrUpdateTableByNum(
		`tourist`, fieldNames, fieldValues, record.num, safeFieldNames, safeFieldValues);
	if( !res.touristNum.isSet ) {
		return res;
	}

	auto fullRec = getCommonDB().query(
		touristFullQuery ~ ` where num = ` ~ res.touristNum.text
	).getRecord(touristFullFormat);

	JSONValue jFullData;
	foreach( field; touristFullFormat.names ) {
		jFullData[field] = fullRec.getField(field).getStdJSONValue(fullRec.recordIndex);
	}
	
	// Сохранение истории действий и изменений
	import webtank.common.std_json.to: toStdJSON;
	record.dbSerializeMode = true; // Пишем в JSON имена полей как в БД
	HistoryRecordData historyData = {
		tableName: `tourist`,
		recordNum: res.touristNum,
		data: jFullData,
		recordKind: (record.num.isSet? HistoryRecordKind.Update: HistoryRecordKind.Insert)
	};
	sendToHistory(ctx, (record.num.isSet? `Редактирование туриста`: `Добавление туриста`), historyData);

	return res;
}

/++ Простой, но опасный метод, который удаляет туриста по ключу. Требует прав админа! +/
void touristDelete(HTTPContext ctx, size_t num)
{
	import webtank.security.right.access_exception: AccessException;

	enforce!AccessException(
		ctx.rights.hasRight(`tourist.item`, `delete`),
		`Недостаточно прав для удаления туриста!`);

	HistoryRecordData historyData = {
		tableName: `tourist`,
		recordNum: num,
		recordKind: HistoryRecordKind.Delete
	};
	sendToHistory(ctx, `Удаление туриста`, historyData);
	getCommonDB().queryParams(`delete from tourist where num = $1`, num);
	getCommonDB().queryParams(`delete from pohod_party where tourist_num = $1`, num);
}
