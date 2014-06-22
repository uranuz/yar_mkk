module mkk_site.pohod;

import std.conv, std.string, std.utf,std.stdio;//  strip()       Уибират начальные и конечные пробелы
import std.file; //Стандартная библиотека по работе с файлами

import webtank.datctrl.data_field, webtank.datctrl.record_format, webtank.db.postgresql, webtank.db.datctrl_joint, webtank.datctrl.record, webtank.net.http.handler, webtank.templating.plain_templater, webtank.net.http.context,webtank.net.utils;

import mkk_site;


//Функция отсечки SQL иньекций.отсечь все символы кромье букв и -

//----------------------
immutable(string) thisPagePath;

shared static this()
{	
	thisPagePath = dynamicPath ~ "pohod";
	PageRouter.join!(netMain)(thisPagePath);
}

void netMain(HTTPContext context)
{	
 	
	
	enum string [int] видТуризма=[0:"", 1:"пешеходный",2:"лыжный",3:"горный",
		4:"водный",5:"велосипедный",6:"автомото",7:"спелео",8:"парусный",
		9:"конный",10:"комбинированный" ];

	auto rq = context.request;
	auto rp = context.response;
	
	//auto pVars = rq.postVars;
	auto qVars = rq.queryForm;
	string content ;//  содержимое страницы 	
	//---------------------------
	string output; //"Выхлоп" программы 
	scope(exit) rp.write(output);
	string js_file = "../../js/page_view.js";
	//------------------------------------
	
		auto tpl = getGeneralTemplate(context);
	
		auto dbase = getCommonDB;
		if ( !dbase.isConnected )
		{	tpl.set( "content", "<h3>База данных МКК не доступна!</h3>" );
			rp ~= tpl.getString();
			return; //Завершаем
		}
		
		size_t pohodKey;
		try {
			pohodKey = qVars.get("key", "0").to!size_t;
		}
		catch(std.conv.ConvException e)
		{	pohodKey = 0; }
		
		
	
	
	content=`<h1> `~pohodKey.to!string ~`<hr></br></h1>`~ "\r\n";
//////////////////////////////////*
	//Функция "очистки" текста от HTML-тэгов  module webtank.net.utils;
//string HTMLEscapeText(string srcStr)
	////////////////////////////////////


	
string participantsList( size_t pohodNum ) //функция получения списка участников
{
	auto dbase = new DBPostgreSQL(commonDBConnStr);
	if ( !dbase.isConnected )
		return null;
	
	auto рез_запроса = dbase.query(`with tourist_nums as (
select unnest(unit_neim) as num from pohod where pohod.num = ` ~ pohodNum.to!string ~ `
)
select coalesce(family_name, '')||coalesce(' '||given_name,'')
||coalesce(' '||patronymic, '')||coalesce(', '||birth_year::text,'') from tourist_nums 
left join tourist
on tourist.num = tourist_nums.num
	`);
	

	
	string result;//список туристов
	
	
	
	if( рез_запроса.recordCount<1) result ~=`Сведения об участниках <br> отсутствуют`;
	else
	   {
	      for( size_t i = 0; i < рез_запроса.recordCount; i++ )
	           {	result ~=HTMLEscapeText(рез_запроса.get(0, i, "")) ~ `<br>`;	}
	   }        
	           
	return result;
	
	
}

string linkList( size_t pohodNum ) //функция получения списка ссылок
{
	auto dbase = new DBPostgreSQL(commonDBConnStr);
	if ( !dbase.isConnected )
		return null;
	 auto рез_запроса= dbase.query(`select unnest(links) as num from pohod where pohod.num = ` ~ pohodNum.to!string ~ ` `); 
	  
   string result;//список ссылок	
	
	if( рез_запроса.recordCount<1) result ~=`Ссылки отсутствуют`;
	else
	{  //result ~=`Cписок ссылок	 `;
		for( size_t i = 0; i < рез_запроса.recordCount; i++ )
		{	string[] linkPair = parseExtraFileLink( рез_запроса.get(0, i, "") );
			string link = HTMLEscapeText(linkPair[0]);
			string linkComment = ( linkPair[1].length ? HTMLEscapeText(linkPair[1]) : link );
			result ~=`<p><a href="` ~ link ~ `">` ~ linkComment ~ `</a></p>`;
			
		}
	}        
	           
	return result;
	
	 
}
/////////////////////////////////////////////////////



////////////////////////////////////////////////////

	string queryStr = // основное тело запроса
	`
	

	  select pohod.num,
   (coalesce(kod_mkk,'')) as  kod_mkk,
   (coalesce(nomer_knigi,'')) as nomer_knigi,
   (coalesce(organization,'')||' '||coalesce(region_group,'')) as organiz, 
     (
    date_part('day', begin_date)||'.'||
    date_part('month', begin_date)||'.'||
    date_part('YEAR', begin_date) 
    
      ||' по '||
    date_part('day', finish_date)||'.'||
    date_part('month', finish_date)||'.'||
    date_part('YEAR', finish_date)
     ) as dat ,  
      coalesce( vid, '0' ) as vid,
      coalesce( ks, '9' ) as ks,
      coalesce( elem, '0' ) as elem,

     region_pohod , 
     (coalesce(marchrut::text,'')) as marchrut,
      (coalesce(pohod.unit,'')) as kol_tur,
        (
    coalesce(chef.family_name,'нет данных')||'  '
  ||coalesce(chef.given_name,'')||'  '
  ||coalesce(chef.patronymic,'')||' '
  ||coalesce(chef.birth_year::text,'')
        ) as chef_fio ,  
     
      (
    coalesce(a_chef.family_name,'нет данных')||' '
  ||coalesce(a_chef.given_name,'')||' '
  ||coalesce(a_chef.patronymic,'')||' '
  ||coalesce(a_chef.birth_year::text,'')
        ) as a_chef_fio,
     coalesce(alt_chef,'0') as a_ch,
     
     coalesce(prepar,'0') as prepar,
        coalesce(stat,'0') as stat ,
         coalesce(chef_coment,'') as chef_coment ,
         coalesce("MKK_coment",'') as mkk_coment
             from pohod 
               
       left outer join
  tourist chef on pohod.chef_grupp = chef.num
       left outer join
  tourist a_chef on pohod.alt_chef = a_chef.num  

       `;     
      
		queryStr~=` where	pohod.num=` ~pohodKey.to!string ~` ` ;
		
		
		
		
		
		
		// добавляем фильтрации
		
		//queryStr~=` order by  pohod.begin_date DESC  LIMIT `~ limit.to!string ~` OFFSET `~ offset.to!string ~` `;
	
	auto response = dbase.query(queryStr); //запрос к БД
	
	//auto rs = response.getRecordSet(pohodRecFormat);  //трансформирует ответ БД в RecordSet (набор записей)
	
	
	if( response.fieldCount > 5 && response.recordCount == 1 )
	content ~=`<p>Код МКК <font color="#006400" ><b>`~HTMLEscapeText(response.get(1,0)) ~`.</b></font></p>`~ "\r\n";
	content ~=`<p>Маршрутная  книжка <font color="#006400" ><b>№   `~HTMLEscapeText(response.get(2,0)) ~`.</b></font></p>`~ "\r\n";
	content ~=`<p>Группа туристов<font color="#006400" ><b> `~HTMLEscapeText(response.get(3,0)) ~`.</b></font></p>`~ "\r\n";
	content ~=`<p>Сроки похода<font color="#006400" ><b> с `~response.get(4,0) ~`.</b></font></p>`~ "\r\n";
	content ~=`<p>Вид туризма:<font color="#006400" ><b> `~видТуризма[response.get(5,0).to!int] ~`</b></font></p>`~ "\r\n";
	content ~=`<p>Категория сложности<font color="#006400"><b> `~категорияСложности[response.get(6,0).to!int]~`</b></font>`;
	
	if(response.get(7,0).to!int> response.get(6,0).to!int   )content ~=`<font color="#006400"><b> c  `~элементыКС[response.get(7,0).to!int]~`.</b></font></p>`~ "\r\n";
	
	content ~=`<p>Регион похода <font color="#006400"><b>  `~HTMLEscapeText(response.get(8,0)) ~`.</b></font><br></p>`~ "\r\n";
	content ~=`<p>По маршруту:<br> <font color="#006400">`~HTMLEscapeText(response.get(9,0)) ~`</font></p>`~ "\r\n";
	content ~=`<p>&nbsp&nbsp&nbsp<br> </p>`~ "\r\n";
	content ~=`<p>В составе:<font color="#006400" ><b>  `~response.get(10,0) ~`</b></font> человек</p>`~ "\r\n";
	content ~=`<p>&nbsp&nbsp&nbsp<br> </p>`~ "\r\n";
	content ~=`<p>Руководитель группы: <font color="#006400" ><b>  `~HTMLEscapeText(response.get(11,0)) ~`</b></font></p>`~ "\r\n";
	if(response.get(13,0).to!int != 0 )
	content ~=`<p>Зам руководителя группы:<font color="#006400" ><b>   `~HTMLEscapeText(response.get(12,0)) ~`</b></font></p>`~ "\r\n";
	content ~=`<p>&nbsp&nbsp&nbsp<br> </p>`~ "\r\n";
	content ~=`<p>Состав группы:<br> <font color="#556B2F" > `~participantsList( pohodKey ) ~`</font></p>`~ "\r\n";
	content ~=`<p>&nbsp&nbsp&nbsp<br> </p>`~ "\r\n";
	content ~=`<p>Готовность похода: <font color=" 	#006400" ><b> `~готовностьПохода[response.get(14,0).to!int] ~`</b></font></p>`~ "\r\n";
	content ~=`<p>&nbsp&nbsp&nbsp<br> </p>`~ "\r\n";
	content ~=`<p>Статус заявки: <font color=" 	#006400" ><b> `~статусЗаявки[response.get(15,0).to!int] ~`</b></font></p>`~ "\r\n";
	content ~=`<p>&nbsp&nbsp&nbsp<br> </p>`~ "\r\n";	
	content ~=`<p>Коментарий руководителя: <font color="#006400"><b>  `~HTMLEscapeText(response.get(16,0)) ~`.</b></font><br></p>`~ "\r\n";
	content ~=`<p>Коментарий MKK: <font color="#006400"><b>  `~HTMLEscapeText(response.get(17,0)) ~`.</b></font><br></p>`~ "\r\n";
		content ~=`<p>Список ссылок:<br>  `~linkList( pohodKey ) ~`</p>`~ "\r\n";
	//content ~=`<p>Коментарий МКК: <font color="#006400"><b>  `~HTMLEscapeText(response.get(17,0)) ~`.</b></font><br></p>`~ "\r\n";
	content ~= "\r\n";
	
	
	tpl.set( "content", content ); //Устанваливаем содержимое по метке в шаблоне

	output ~= tpl.getString(); //Получаем результат обработки шаблона с выполненными подстановками
}

