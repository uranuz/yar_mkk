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


//----- Вспомогательная функция для организации постраничного просмотра
function gotoPage(pageNum) {
	var form = window.document.getElementById("main_form");
	var pageNumInput = window.document.getElementsByName("cur_page_num")[0];
	pageNumInput.value = pageNum;
	form.submit();
}

//Вешаем обработчики на ссылки на боковой панели с выборками походов по некоторым критериям
$(window.document).ready( function() {
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
});

//Переход на страницу отображения походов с одним из фильтров из списка
function gotoPohodFilter(filterIndex) {
	var 
		filterSet = [
			//Выборки по годам
			{"begin_date_range_head__year": 2015},
			{"begin_date_range_head__year": 2014},
			{"begin_date_range_head__year": 2013},
			{"begin_date_range_head__year": 2012},
			
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

$(window.document).ready( function() {
	var 
		block = $(".b-mkk_site_auth_bar"),
		dialog = block.filter(".e-dialog_wrapper"),
		form = block.filter(".e-form"),
		loginInput = block.filter(".e-user_login"),
		passwordInput = block.filter(".e-user_password"),
		getIsDialogActive = function() {
			var activeElement = window.document.activeElement;
			if( activeElement )
			{
				if( loginInput[0] === activeElement || passwordInput[0] === activeElement )
					return true;
			}
			
			return false;
		};
		
	$(window.document).on("click", function() {
		dialog.hide();
	});
	
	block.on("click", function(event) { event.stopPropagation(); })
		
	block.filter(".e-block").hover( 
		function() {
			dialog.show();
		},
		function() {
			if( getIsDialogActive() === false )
				dialog.hide();
		}
	);
	
	dialog.hide();
});