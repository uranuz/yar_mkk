define('mkk/TouristSearchArea/TouristSearchArea', [
	'fir/controls/FirControl'
], function (FirControl) {
	__extends(TouristSearchArea, FirControl);

	function TouristSearchArea(opts)
	{
		FirControl.call(this, opts);
		
		var self = this;

		this.resultsPanel = this._elems('searchResultsPanel');

		this._elems("searchBtn").on("click", self.onSearchTourists_BtnClick);
		this._elems("goSelectedBtn").on("click", self.onGoSelected_BtnClick);
		this._elems("goNextBtn").on("click", self.onGoNext_BtnClick);
		this._elems("goPrevBtn").on("click", self.onGoPrev_BtnClick);
		
		this._elems("foundTourists").on("click", ".e-tourist_select_btn", function(ev, el) {
			var record = self.recordSet.getRecord($(el).data('id'))
			self.$trigger('itemSelect', [self, record]);
		});
		
		this._elems('block').hide();
	}

	return __mixinProto(TouristSearchArea, {
		// Тык по кнопке поиска туристов 
		onSearchTourists_BtnClick: function() {
			this.$el(".e-page_selected").val(1);
			this.onSearchTourists(); //Переход к действию по кнопке Искать
		},
		
		// Тык по кнопке Перехода на нужную страницу 
		onGoSelected_BtnClick: function(ev, el) {
			var
				self = this,
				selected_page_value = this.$el(".e-page_selected").val(),
				selected_page_obg = this.$el(".e-page_selected");
			
			// ограничения значений страницы в окошечке	
			if( selected_page_value < 1 )
				this.$el(".e-page_selected").val(1); 
			if( selected_page_value > self.page ) 
				this.$el(".e-page_selected").val(self.page);
			
			this.onSearchTourists();//Переход к действию 
		},
		
		//Тык по кнопке Предыдущая страница
		onGoPrev_BtnClick: function(ev, el) {
			var
				selected_page_value = this.$el(".e-page_selected").val();

			this.$el(".e-page_selected").val( +selected_page_value - 1 );
			this.onGoSelected_BtnClick(el, ev);//Переход к действию 
		},
		
		//Тык по кнопке Следующая страница
		onGoNext_BtnClick: function(ev, el) {
			var
				selected_page_value = this.$el(".e-page_selected").val();
			this.$el(".e-page_selected").val( +selected_page_value + 1 );
			this.onGoSelected_BtnClick(el, ev);//Переход к действию 
		},

		// переход от Тыка по  любой из  выше описанных кнопок  
		onSearchTourists: function(event) {
			var
				self = this,
				messageDiv = this.$el(".e-select_message"),
				selected_page_value = this.$el(".e-page_selected").val();

			webtank.json_rpc.invoke({
				uri: "/jsonrpc/",
				method: "mkk_site.edit_pohod.getTouristList",
				params: { 
					"фамилия": this.$el(".e-family_filter").val(), 
					"имя": this.$el(".e-name_filter").val(),
					"отчество": this.$el(".e-patronymic_filter").val(),
					"год_рождения": this.$el(".e-year_filter").val(),
					"регион": this.$el(".e-region_filter").val() ,  
					"город": this.$el(".e-city_filter").val(),  
					"улица": this.$el(".e-street_filter").val(),
					"страница": this.$el(".e-page_selected").val()
				},
				success: function(json)// исполняется по приходу результата
				{
					var
						rec,
						searchResultsDiv = self.$el(".e-found_tourists"),
						summaryDiv = self.$el(".e-tourists_found_summary"),
						selected_submit = self.$el(".e-go_selected_btn"),
						prev_submit = self.$el(".e-go_prev_btn"),
						next_submit = self.$el(".e-go_next_btn"),
						navigBar = self.$el(".e-page_navigation_bar"),
						pageCountDiv = self.$el(".e-page_count"),
						col_str = json.recordCount;// Количество строк
						perPage = json.perPage || 10;
					
					self.recordSet = webtank.datctrl.fromJSON(json.rs);
					self.recordSet.rewind();
					
					searchResultsDiv.empty();
					while( rec = self.recordSet.next() )
						self.renderFoundTourist(rec).appendTo(searchResultsDiv);
					
					self.resultsPanel.show();

					if( col_str > 0 )
						self.page = Math.ceil(col_str/perPage);
					else
						self.page = 0;
					// ограничения кнопки перейти при наличи одой и менее страниц кнопка не видима
					if( self.page <= 1 ) 
						selected_submit.css('visibility', 'hidden');
					else 
						selected_submit.css('visibility', 'visible');
					
					//  состояние кнопки предыдущая 
					if( selected_page_value < 2 || self.page <= 1 )
						prev_submit.css('visibility', 'hidden');
					else 
						prev_submit.css('visibility', 'visible');

					// состояние кнопки далее
					if( selected_page_value >= self.page || self.page <= 1 ) 
						next_submit.css('visibility', 'hidden');
					else 
						next_submit.css('visibility', 'visible');

					if( col_str < 1 )
					{	summaryDiv.text("По данному запросу не найдено туристов");
						navigBar.hide();
					}
					else
					{
						summaryDiv.text("Найдено " + col_str + " туристов");
						pageCountDiv.text(self.page);
						navigBar.show();
					}
				}
			});// конец webtank.json_rpc.invoke
		},
		
		renderFoundTourist: function(record) {
			var
				recordDiv = $("<div>", {
					class: "b-tourist_search e-tourist_select_btn",
				})
				.data("id", record.getKey()),
				iconWrp = $("<span>", {
					class: "b-tourist_search e-icon_wrapper"
				}).appendTo(recordDiv),
				button = $("<div>", {
					class: "icon-small icon-append_item"
				}).appendTo(iconWrp),
				recordLink = $("<a>", {
					class: "b-tourist_search e-tourist_link",
					href: "#!",
					text: mkk_site.utils.getTouristInfoString(record)
				}).appendTo(recordDiv);
			
			return recordDiv;
		},
		
		activate: function(place)
		{
			this._container.detach().appendTo(place).show();
			if( this.recordSet && this.recordSet.getLength() )
				this.resultsPanel.show();
			else
				this.resultsPanel.hide()
		},
		
		deactivate: function(place)
		{
			this._container.detach().appendTo('body').hide();
		}
	});
});