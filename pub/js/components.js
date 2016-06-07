var mkk_site = mkk_site || {
	version: "0.0"
};

//----- Функции проверки даты на правильность
function isLeapYear(year) //Скажет true, если год високосный и false, если нет
{	if (  ( (year%4==0) && (year%100!=0) ) || (year%400==0) ) return true;
	else return false;
}

function getDayCountInMonth(month, year) //Считает количество дней в месяце
{	if (month==2)
	{	if (isLeapYear(year)==true) return 29; //Исключение для високосного года
		else return 28; //28 дней в феврале, если не високосный год
	}
	else
	{	var M=month; //В июле и августе по 31 день
		if ( M>7) ++M; //Делаем сдвижку, начиная с августа
		if ( M%2==1 ) return 31;  //По остатку определяем 'чётность' месяца
		else return 30;
	}
}

function isValidDate(day, month, year)
{	if ( (month>0) && (month<=12) )
	{	var dayCount=getDayCountInMonth(month, year);
		if ( (day>0) && (day<=dayCount) ) return ''; //Возвращаем пустую строку если дата правильная
		else return ('Ошибка ввода! В месяце c номером "'+month.toString()
		+'" количество дней равно "'+dayCount.toString()+'", но указан день "'+day.toString()+'".');
	}
	else return ('Ошибка ввода! Номер месяца должен быть целым числом в диапазоне от 1 до 20, однако "'+
		+'" указано.');
}


//----- Добавление компонента ввода даты в container
function addDatePicker(container, dayFieldName, monthFieldName, yearFieldName, startYear, endYear)
{	var Result='<select name="'+dayFieldName+'">';
	for (var i=1; i<=31; ++i)
	{	Result+='<option value="'+i.toString()+'">'+i.toString()+'</option>';
	}
	Result+='</select> &nbsp; <select name="'+monthFieldName+'">';
	for (var i=1; i<=12; ++i)
	{	Result+='<option value="'+i.toString()+'">'+i.toString()+'</option>';
	}
	Result+='</select> &nbsp; <select name="'+yearFieldName+'">';
	for (var i=startYear; i<=endYear; ++i)
	{	Result+='<option value="'+i.toString()+'">'+i.toString()+'</option>';
	}
	container.innerHTML=Result;
}

mkk_site.MainMenuAuth = (function(_super) {
	__extends(MainMenuAuth, _super);

	function MainMenuAuth(opts)
	{
		opts = opts || {};
		opts.controlTypeName = 'MainMenuAuth';
		_super.call(this, opts);
		var
			popdownBtn = this._elems().filter('.e-popdown_btn');

		this._outsideClickHdlInstance = this.addOutsideClickHandler.bind(this);
		popdownBtn.on( 'click', this.onPopdownBtnClick.bind(this) );
	}

	return __mixinProto(MainMenuAuth, {
		onPopdownBtnClick: function(ev) {
			var
				elems = this._elems(),
				popdownMenu = elems.filter('.e-popdown_menu');

				if( popdownMenu.is(':visible') ) {
					$('html').off( 'click', this._outsideClickHdlInstance );
				} else {
					$('html').on( 'click', this._outsideClickHdlInstance );
				}
				popdownMenu.toggle();
		},
		addOutsideClickHandler: function(ev) {
			var
				block = this._elems().filter('.e-block'),
				popdownMenu = this._elems().filter('.e-popdown_menu'),
				popdownBtn = this._elems().filter('.e-popdown_btn');
			if( !$(ev.target).closest(block).length ) {
					$('html').off( 'click', this._outsideClickHdlInstance );
					popdownMenu.hide();
			}
		}
	});
})(webtank.ITEMControl);

mkk_site.Pagination = (function(_super) {
	__extends(Pagination, _super);
	
	function Pagination(opts)
	{
		opts = opts || {};
		_super.call(this, ".b-pagination");

		
		
	}
	
	return __mixinProto(Pagination, {
		gotoPage: function(pageNum)
		{
			
		}
	});
})(webtank.ITEMControl);

//----- Вспомогательная функция для организации постраничного просмотра
function gotoPage(pageNum) {
	var form = window.document.getElementById("main_form");
	var pageNumInput = window.document.getElementsByName("cur_page_num")[0];
	pageNumInput.value = pageNum;
	form.submit();
}

//Переход на страницу отображения походов с одним из фильтров из списка
function gotoPohodFilter(filterIndex) {
	var 
		filterSet = [
			//Выборки по годам
			{"begin_date_range_head__year": 2016, "end_date_range_tail__year": 2016},
			{"begin_date_range_head__year": 2015, "end_date_range_tail__year": 2015},
			{"begin_date_range_head__year": 2014, "end_date_range_tail__year": 2014},
			{"begin_date_range_head__year": 2013, "end_date_range_tail__year": 2013},
			{"begin_date_range_head__year": 2012, "end_date_range_tail__year": 2012},
			
			//Выборки по видам
			{"vid": 4}, //водный
			{"vid": 3}, //горный
			{"vid": 1}, //пеший
			{"vid": 5}, //велосипедный
			{"vid": 2}, //лыжный
			
			//Выборки по статусу похода
			{"prepar": 1}, //планируется
			{"prepar": 2}, //набор группы
			{"prepar": 3}, //набор завершен
			{"prepar": 4}, //подготовка
			{"prepar": 5}, //на маршруте
		],
		filterForm = $(".b-pohod_filter_collection.e-form"),
		filterRecord = filterSet[filterIndex],
		filterName;
		
	for( filterName in filterRecord ) //На будущее, если будет фильтр с неск. критериями
	{
		//Ищем нужный элемент формы и пихаем туда значение фильтра
		$(".b-pohod_filter_collection.e-filter__" + filterName).val(filterRecord[filterName]);
	}
	
	filterForm[0].submit();
}

mkk_site._initTemplateService = function() {
	var 
		tplr = webtank.templating.plain_templater;
	
	mkk_site.templateService = new tplr.TemplateService(
		"/dyn/jsonrpc/",
		"mkk_site.template_service.getTemplates",
		[]
	);
	
	mkk_site.templateService.getMultAsync(["pohod_for_tourist.html"], function(templates, names) {
		console.log("Templates loaded: ", names);
	});
};

//Вешаем обработчики на ссылки на боковой панели с выборками походов по некоторым критериям
mkk_site._initPohodFilters = function() {
	var 
		pohod_filter_items = $(".b-pohod_filter_collection.e-list_item"),
		i;
		
	for( i = 0; i < pohod_filter_items.length; i++ )
	{
		(function(ii) {
			$(pohod_filter_items[ii]).on( "click", function() {
				gotoPohodFilter(ii);
			});
		})(i);
	}
};

mkk_site._initAuthBar = function() {
	mkk_site.main_menu_auth = new mkk_site.MainMenuAuth({
		controlName: "main_menu_auth"
	});
};

mkk_site._initPagination = function() {
	var tplr = webtank.templating.plain_templater
	
	mkk_site.paging = {};
	mkk_site.paging.renderPohods = function(data)
	{
		var rec,
			tp = mkk_site.templateService.getTemplater("pohod_for_tourist.html"),
			rs = webtank.datctrl.fromJSON(data.pohodsRS),
			result = "", pohodKey = "";
			
		function rusFormat(date) {
			var dt = new Date(date);
			return dt.getDate() + "." + ( dt.getMonth() + 1 ) + "." + dt.getFullYear();
		}
			
		while( rec = rs.next() ) {
			tplr.fillFromRecord(tp, rec);
			tp.set( "Сроки", 
				rusFormat( rec.get("Дата начала") ) 
				+ "<br>\r\n" + rusFormat( rec.get("Дата конца") ) 
			);
			
			if( data.isAuthorized ) {
				pohodKey = rec.get("Ключ", "") + '';
				tp.set( "Колонка ключ",  '<td>' + pohodKey + '</td>' );
				tp.set( "Колонка изменить", '<td><a href="' + data.dynamicPath + 'edit_pohod?key='
					+ pohodKey + '">Изменить</a></td>' );
			}
			
			tp.set( "Должность", 
				data.touristKey == rec.get("Ключ рук") ? 'Руков' : 'Участ'
			);
			
			result += tp.getString();
		}
		return result;
	};
	mkk_site.paging.loadAndRenderPohods = function(touristKey, pageNum) {
		webtank.json_rpc.invoke({
			uri: '/dyn/jsonrpc/',
			method: 'mkk_site.show_pohod_for_tourist.getPohodsForTourist',
			params: {touristKey: touristKey, curPageNum: pageNum },
			success: function(data) { 
				var content = mkk_site.paging.renderPohods(data);
				
				$(".b-tourist_info.e-pohod_list").html(content);
			}
		})
	};
	
	$(".do-smth_btn").on("click", function() {
		var 
			curPageNum = parseInt( $(".cur_page_num").val() ),
			touristKey = parseInt( webtank.parseGetParams()["key"] );
		mkk_site.paging.loadAndRenderPohods( touristKey, curPageNum );
	});
};

(function() {
	$(window.document).ready( function() {
		mkk_site._initPohodFilters();
		mkk_site._initAuthBar();
		mkk_site._initTemplateService();
		mkk_site._initPagination();
	});
})();