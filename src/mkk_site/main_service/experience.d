module mkk_site.main_service.experience;
import std.conv, std.string, std.utf;
import mkk_site.main_service.devkit;
import mkk_site.site_data;

import std.stdio;

//***********************Обявление метода*******************
shared static this()
{
	Service.JSON_RPCRouter.join!(getExperience)(`tourist.experience`);
	
}
//**********************************************************



import std.typecons: tuple;

//получаем данные о ФИО и г.р. туриста
   static immutable touristPersonRecFormat = RecordFormat!(
		PrimaryKey!(size_t), "keyPerson", 
		string, "familyName",
		string, "givenName",
		string, "patronymic",
		size_t, "yearBirth",
		string, "experiencePerson", 
		typeof(спортивныйРазряд), "sportsCategory", 
		typeof(судейскаяКатегория), "refereeCategory",
		bool, "showPhone",
		string, "phone",
		bool, "showMail",
		string, "mail",
		string, "coment"
	)(
		null,
		tuple(
			спортивныйРазряд,
			судейскаяКатегория
		)
	);
	
	// данные о походах
	static immutable pohodRecFormat = RecordFormat!(
		PrimaryKey!(size_t), "num",
		string, "keyBook",
		Date, "beginDate", 
		Date, "finishDate",
		typeof(видТуризма), "tourismKind",
		typeof(категорияСложности), "complexity",
		typeof(элементыКС), "complexityElems",
		size_t, "chiefNum",
		string, "organization",
		string, "pohodRegion",  //район похода 
		string, "route",// нитка маршрута
		typeof(готовностьПохода), "readiness",
		typeof(статусЗаявки), "status"
	)(
		null,
		tuple(
			видТуризма,
			категорияСложности,
			элементыКС,
			готовностьПохода,
			статусЗаявки
		)
	);



	import std.datetime: Date;
	
	
//--------------------------------------------------------
import std.json;

  JSONValue getExperience
	(
		HTTPContext context,
		Optional!size_t touristKey, //????????????
		size_t currentPage  //текущая страница
	)	
{


size_t limit = 10; // Число строк на странице	
	
bool isAuthorized 
			= context.user.isAuthenticated 
			&& ( context.user.isInRole("admin")
			 || context.user.isInRole("moder") );

	auto req = context.request;	
	
	try {
		if( "key" in req.queryForm )
			touristKey = req.queryForm["key"].to!size_t;
	} catch( std.conv.ConvException e ) {  }
	
	
	/*if( touristKey.isNull )
	{
		static immutable errorMsg = "<h3>Не задан корректный идентификатор туриста</h3>";
		Service.loger.error( errorMsg );
		return errorMsg;		
	}*/
	
		
	
	 /*данные туриста */
	immutable experiencePerson =	
	`select 
		num,family_name, given_name, patronymic,birth_year,exp, razr, sud,show_phone, phone,
		show_email, email,comment
	from tourist
	 where num = `~ touristKey.text ~ ` `;
	 
	 auto expPerson = getCommonDB()
							.query(experiencePerson)
							.getRecordSet(touristPersonRecFormat).front;
    
    
    
    
    
    /*походы туриста число строк в таблице */
    immutable experienceCount =	
		`select
			count(1)
		from pohod 
		where `~ touristKey.text ~ ` = any( unit_neim )`;
   
   size_t expCount = getCommonDB()
								.query(experienceCount)
								.get(0, 0, "0").to!size_t;
   
   
   
   /*походы туриста основная таблица */
   
   size_t pageCount = expCount/ limit + 1; //Количество страниц
		
		if(currentPage>pageCount) currentPage=pageCount; //текущая страница
		//если номер страницы больше числа страниц переходим на последнюю 
   
   size_t offset = (currentPage - 1) * limit ; //Сдвиг по числу записей
   
   immutable experienceTabl =	
		`select
			num,
			( 
				coalesce(kod_mkk,'000-00') || '<br>' || 
				coalesce(nomer_knigi,'00-00')
			) as "Номер книги", 
			begin_date as "Дата начала",
			begin_date as "Дата конца",
			vid as "Вид",
			ks as "КС",
			elem as "Элем КС",
			chef_grupp as "Ключ рук",     
			( coalesce(organization, '') || '<br>' || coalesce(region_group, '') ) as "Организация",
			region_pohod as "Район",
			coalesce(marchrut, '') as "Маршрут",
			prepar as "Готовность",
			stat as "Статус"
		from pohod 
		where `~ touristKey.text ~ ` = any( unit_neim )
		order by begin_date desc
		limit `~limit.to!string~` offset ` ~ offset.to!string ~` ` ;
		
				auto expTabl = getCommonDB()
							.query(experienceTabl)
							.getRecordSet(pohodRecFormat);
			
			
		
		//---------Сборка из всех данных------------------------
		JSONValue ExperienceSet;	
	
			ExperienceSet["expCount"]    = expCount ;
			ExperienceSet["pageCount"]   = pageCount;
			ExperienceSet["currentPage"]  = currentPage;
			ExperienceSet["expPerson"]   = expPerson.toStdJSON();
			ExperienceSet["expTabl"]     = expTabl.toStdJSON();

		return ExperienceSet;
}


//--------------------------------------------------------

