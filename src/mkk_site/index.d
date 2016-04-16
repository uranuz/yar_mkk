module mkk_site.index;

import std.conv, std.string, std.array, std.typecons;

import mkk_site.page_devkit;

static immutable(string) thisPagePath;

shared static this()
{	
	thisPagePath = dynamicPath ~ "index";
	PageRouter.join!(netMain)(thisPagePath);
}

class Index
{
public:
	import std.datetime: Date;
	
	static immutable pohodRecFormat = RecordFormat!(
		PrimaryKey!(size_t), "Ключ", 
		string, "Номер книги", 
		Date, "Дата начала", 
		Date, "Дата конца",
		typeof(видТуризма), "Вид", 
		typeof(категорияСложности), "КС", 
		typeof(элементыКС), "Элем КС",
		string, "Район",
		size_t, "Ключ рук",
		string, "Фамилия рук",
		string, "Имя рук",
		string, "Отчество рук",
		string, "Организация",
		string, "Маршрут",
		string, "Коментарий рук",
	)(
		null,
		tuple(
			видТуризма,
			категорияСложности,
			элементыКС
		)
	);
	
	static immutable recentPohodQuery =
`select pohod.num as "Ключ",
	( 
		coalesce(kod_mkk, '000-00') || ' ' ||
		coalesce(nomer_knigi, '00-00')
	) as "Номер книги",
	begin_date as "Дата начала",
	finish_date as "Дата конца",
	vid as "Вид",
	ks as "КС",
	elem as "Элем КС",
	region_pohod as "Район",
	chef.num as "Ключ рук",
	chef.family_name as "Фамилия рук",
	chef.given_name as "Имя рук",
	chef.patronymic as "Отчество рук",
	( coalesce(organization, '') || '<br>' || coalesce(region_group, '') ) as "Организация", 
	( coalesce(marchrut, '') ) as "Маршрут", 
	( coalesce(chef_coment, '') ) as "Коментарий рук"
from pohod 
left outer join tourist as chef
	on chef.num = pohod.chef_grupp
where  (pohod.reg_timestamp is not null ) 
order by pohod.reg_timestamp desc 
limit 10
;`;
	
	static auto pohodList()
	{
		return getCommonDB()
			.query(recentPohodQuery)
			.getRecordSet(pohodRecFormat);
	}
	

}

class IndexView
{
	static immutable string siteDescription;
	
	shared static this()
	{
		siteDescription =
`
	 <h5>Добро пожаловать на сайт!</h5></br>

	<p><h4>Сведения о базе МКК</h4>
  Ресурс хранит сведения о планируемых, заявленных, пройденных и защищённых походах <br>
  и их участниках.</p>
<p> <h5>Задачей ресурса ставится: </h5></p>

<p>
<div>
<ul style="margin-left: 20px;">
<li>создание достоверной информационной базы <br>
  по пройденным и планируемым туристским походам;<br> </li> 
 <li>облегчения поиска информации о планируемых походах;</li> 
 <li>создание интернет площадки для формирования туристских групп;</li> 
 <li>создания системы дистанционной заявки на туристские маршруты.</li> 
</ul><br>

<p><a href="` ~ dynamicPath ~ `inform" > 
Подробнее</a>
</p>
  </div>
        </p>
       <p></p>`;
	}
	
	
	static string render(RS)(RS rs)
	{
		auto resp = appender!string();
		
		resp ~= siteDescription;
		
		
		resp ~= `<div class="b-recent_pohod e-block">`
			~ `<h4 class="b-recent_pohod e-block_title">Недавно добавленные походы</h4>` ~ "\r\n";
	
		foreach(rec; rs)
		{
			import std.string: strip;
			import std.range: take, empty;
			import std.conv: text;
			import std.datetime: Date;
			
			string chefFamilyName = strip( rec.getStr!"Фамилия рук"() );
			string chefGivenName = rec.getStr!"Имя рук"().strip().take(1).text();
			string chefPatro = rec.getStr!"Отчество рук"().strip().take(1).text();
			string chefName;
			if( chefFamilyName.length > 0 )
			{
				chefName ~= chefFamilyName;
				if( !chefGivenName.empty )
				{
					chefName ~= " " ~ chefGivenName ~ ".";
					if( !chefPatro.empty )
						chefName ~= " " ~ chefPatro ~ ".";
				}
			}
			chefName = HTMLEscapeText(chefName);
			
			string chefComment = HTMLEscapeText( rec.getStr!("Коментарий рук").take(100).text() );
			
			
			string beginDate;
			string endDate;
			
			if( !rec.isNull("Дата начала") )
			{	Date date = rec.get!"Дата начала"();
				beginDate = date.day.text 
					~ "." ~ ( cast(ubyte) date.month ).text
					~ "." ~ date.year.text;
			}
			
			if( !rec.isNull("Дата конца") )
			{	Date date = rec.get!"Дата конца"();
				endDate = date.day.text 
					~ "." ~ ( cast(ubyte) date.month ).text
					~ "." ~ date.year.text;
			}
			
			string dateSpan;
			if( !beginDate.empty )
				dateSpan ~= " с " ~ beginDate;
			
			if( !endDate.empty )
				dateSpan ~= " до " ~ endDate;
			
			resp ~= `<div class="b-recent_pohod e-item_block">`;
			
				resp ~= `<a class="b-recent_pohod e-title_link" href="` 
					~ dynamicPath ~ `pohod?key=`
					~ rec.getStr!("Ключ")() ~ `">` ~ rec.getStr!("Вид")() ~ ` `
					~ rec.getStr!("КС")() ~ ` ` ~ rec.getStr!("Элем КС")("")
					~ ` к.с. в районе ` ~ HTMLEscapeText( rec.getStr!("Район")() ) ~ ` </a>`~ "\r\n";

				resp ~= 
					  `<div class="b-recent_pohod e-item_details_block">`
						~ `<p class="b-recent_pohod e-route_par">`
							~ `<span class="b-recent_pohod e-route_label">По маршруту: </span>` 
							~ `<span class="b-recent_pohod e-route">` ~ HTMLEscapeText( rec.getStr!("Маршрут")() ) ~ `</span>`
						~ `</p>`
						~ `<div class="b-recent_pohod e-details_par">`
							~ `<span class="b-recent_pohod e-chef_label">Руководитель: </span>`
							~ `<a class="b-recent_pohod e-chef_link" href="` ~ dynamicPath ~ `show_pohod_for_tourist?key=` 
							~ rec.get!"Ключ рук"().text ~ `">` ~ chefName ~ `</a>` 
							~ `<p class="b-recent_pohod e-date_interval_par">Сроки похода` 
							~ ( dateSpan.empty ? ` неизвестны` : `: ` ~ dateSpan ) ~ `</p>`
						~ `</div>`
					~ `</div>`
					~ `<div class="b-recent_pohod e-chef_comment_block">` 
					~ ( chefComment.empty ? `` : `Описание: ` ~ chefComment ) ~ `</div>`
				;
			resp ~= `</div>`;
		}
		resp ~= `</div>`;

		return resp.data();
	}
}

string netMain(HTTPContext context)
{	
	auto rs = Index.pohodList();
	
	return IndexView.render(rs);
}
