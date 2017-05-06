define('mkk/helpers', [], function () {
	return {
		/**
		 * @description Проверяет, что value - число. Если заданы low и/или high,
		 * то проверяет, что проверяет, что low <= value <= high
		 */
		checkInt: function(value, low, high) {
			value = parseInt(value);

			if (isNaN(value) || value % 1 != 0)
				return false;

			if (low != null && value < low)
				return false;

			if (high != null && value > high)
				return false;

			return true;
		},

		/**
		 * @description Скажет true, если год високосный и false, если нет
		 */
		isLeapYear: function(year) {
			if (((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0)) return true;
			else return false;
		},

		getDayCountInMonth: function(month, year) //Считает количество дней в месяце
		{
			if (month == 2) {
				if (isLeapYear(year) == true) return 29; //Исключение для високосного года
				else return 28; //28 дней в феврале, если не високосный год
			}
			else {
				var M = month; //В июле и августе по 31 день
				if (M > 7)++M; //Делаем сдвижку, начиная с августа
				if (M % 2 == 1) return 31;  //По остатку определяем 'чётность' месяца
				else return 30;
			}
		},
			
		/**
		 * @description Функции проверки даты на правильность
		 */
		isValidDate: function(day, month, year) {
			if ((month > 0) && (month <= 12)) {
				var dayCount = getDayCountInMonth(month, year);
				if ((day > 0) && (day <= dayCount)) return ''; //Возвращаем пустую строку если дата правильная
				else return ('Ошибка ввода! В месяце c номером "' + month.toString()
					+ '" количество дней равно "' + dayCount.toString() + '", но указан день "' + day.toString() + '".');
			}
			else return ('Ошибка ввода! Номер месяца должен быть целым числом в диапазоне от 1 до 20, однако "' +
				+'" указано.');
		}
	}
});