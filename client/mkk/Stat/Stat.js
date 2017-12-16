define('mkk/Stat/Stat', [
	// Подключение зависимостей: библиотек, стилей и т.п.
	'fir/controls/FirControl',
	/*'mkk/Stat/flot/jquery.js',
	'mkk/Stat/flot/jquery.flot',
	'mkk/Stat/flot/jquery.flot.time',*/
	'css!mkk/Stat/Stat'
], function (FirControl, Flot, FlotTime) {
	__extends(Stat, FirControl);

	function Stat(opts) {
		FirControl.call(this, opts);
		this._elems('byYearBtn').on('click', this.reloadPage);
		this._elems('byComplexityBtn').on('click', this.reloadPage);
		this._opts = opts;
		this._tooltipWindow = this._elems('plotTooltip');
		this.doFlot();
	};

	return __mixinProto(Stat, {
		_subscribeInternal: function() {
			var self = this;
			this._elems('plot').on('plothover', this._onPlot_over.bind(this));
			// Сохраняем обработчик привязанный к классу, чтобы корректно отписаться от события
			this._resizeBeginHandler = this._onWindow_ResizeBegin.bind(this);
			$(window).on('resize', this._resizeBeginHandler);
		},
		_unsubscribeInternal: function() {
			this._elems('plot').off();
			$(window).off('resize', this._resizeBeginHandler);
		},
		getName: function() {
			return this._name;
		},
		reloadPage: function() {
			document.forms.main_form.submit()
		},
		/** Обработчик добавляет задержку перед запуском операции,
		 * запускаемой по изменению размеру окна, чтобы уменьшить нагрузку на браузер
		 */
		_onWindow_ResizeBegin: function() {
			clearTimeout(this._resizeTimerId); // Удаляем таймер, запущенный недавно
			this._resizeTimerId = setTimeout(this._onWindow_Resize.bind(this), 100);
		},
		_onWindow_Resize: function() {
			this.doFlot(); // Перерисовываем график по изменению размера окна
		},
		_onPlot_over: function (event, pos, item) {
			this._tooltipWindow.remove();
			if( !item ) return;
			var
				grafMode = this._opts.select.conduct,
				k_s = ["н/к", "1 кс", "2 кс", "3 кс", "4 кс", "5 кс", "6 кс", "пут."],
				x = item.datapoint[0].toFixed(2),
				y = item.datapoint[1].toFixed(2),
				dates = new Date(Number(x)),
				label = '';
				if( grafMode == 0 )
					label = item.series.label + "<br/>" +  Math.floor(y) + " чел.<br/> " + dates.getFullYear() + " г.";
				if( grafMode == 1 )
					label = item.series.label + "<br/>"+  Math.floor(y) + " чел. <br/>" + k_s[Number(x)];

			this.showTooltip(item.pageX, item.pageY,  label);
		},
		showTooltip: function (x, y, contents) {
			this._tooltipWindow.css({
				top: y + 5,
				left: x + 5
			}).html(contents).appendTo("body").fadeIn(200);
		},
		/**
		 * Подготовка данных для построения графика
		 */
		preparePlotData: function() {
			if( this._dataSeries && this._chartConfig ) {
				return; // Данные готовы - не пересчитываем их
			}

			var
				grafMode = this._opts.select.conduct,
				boolGraf = this._opts.data.boolGraf,
				graf = this._opts.data.graf,
				grafLength = this._opts.data.grafLength,
				dataSeries = [
					{ label: "Пеший" },
					{ label: "Лыжный" },
					{ label: "Горный" },
					{ label: "Водный" },
					{ label: "Вело" },
					{ label: "Авто" },
					{ label: "Спелео" },
					{ label: "Парус" },
					{ label: "Конный" },
					{ label: "Комби" },
					{
						label: "Все",
						lines: {
							show: true,
							lineWidth: 8,
							fill: true,
							fillColor: 'rgba(107, 142, 35, 0.3)'
						}
					}
				],
				xAxisData = [];
		
			if( grafMode == 0 ) {
				for( var j = 0; j < grafLength; j += 1 ) {
					xAxisData.push(Date.parse(graf[0][j]));
				}
			}
					
			if( grafMode == 1 ) {
				xAxisData = graf[0];
				grafLength = 8;
			}
		
			for( var i = 0; i < grafLength; ++i ) {
				// i - номер точки с данными для графика
				for( var m = 0; m < graf.length; ++m ) {
					// m - номер графика
					// 0 позиция в boolGraf и graf занята для оси x
					if(boolGraf[m+1]) {
						// В dataSeries ось x не нужна т.к., передается через xAxisData
						dataSeries[m].data = dataSeries[m].data || [];
						dataSeries[m].data.push([xAxisData[i], graf[m+1][i]]);
					}
				}
			}

			var chartConfig = {
				xaxis: {
					ticks: (grafMode === 0? null: [
						[0, "н/к"],
						[1, "1 кс"],
						[2, "2 кс"],
						[3, "3 кс"],
						[4, "4 кс"],
						[5, "5 кс"],
						[6, "6 кс"],
						[7, "пут."]
					]),
					mode: (grafMode === 0? "time": null),
					min: (grafMode === 0? 570000022408: 0)
				},
				legend: {
					show: true,
					container: this._elems('plotLegend')
				},
				yaxis: {
					min: 0
				},
				x2axis: {},
				y2axis: {},
				points: {
					show: true, //узловые точки
					radius: 4, //радиус кружка
					fill: true //заполнить кружок
					//fillColor: "grid" //цвет заполнения
				},
				lines: {
					show: true,
					lineWidth: 4,
					fill: false,
					fillColor: '#ca0000'
				},
				bars: {
					show: false,
					horizontal: false, // столбцы горизонтально
					shadowSize: 0, // тени размер
					barWidth: 0.5 //ширина столбца
				},
				grid: {
					clickable: true,
					hoverable: true,
					autoHighlight: true,
					mouseActiveRadius: 15
				},
				selection: {},
				shadowSize: 5, //тени
				colors: [
					'#228B22', // пеший
					'#AFEEEE', // лыжный
					'#F4A460', // горный
					'#1E90FF', // водный
					'#696969', // вело
					'#151B54', // авто
					'#3EA99F', // спелео
					'#E0FFFF', // парус
					'#7E3517', // конный
					'#9400D3', // комби
					'#DC143C' // все
				] // цвета графиков
			};
			this._dataSeries = dataSeries;
			this._chartConfig = chartConfig;
		},
		doFlot: function () {
			this.preparePlotData();
			// и строим саму диагрумму
			$.plot(this._elems('plot'), this._dataSeries, this._chartConfig);
		}
	});
});