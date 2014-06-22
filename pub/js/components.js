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