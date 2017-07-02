define('mkk/TouristSearchArea/TouristSearchArea', [
	'fir/controls/FirControl',
	'fir/network/json_rpc',
	'fir/datctrl/helpers',
	'mkk/helpers'
], function(
	FirControl,
	json_rpc,
	datctrl,
	MKKHelpers
) {
	__extends(TouristSearchArea, FirControl);

	function TouristSearchArea(opts)
	{
		FirControl.call(this, opts);
		var self = this;

		this._resultsPanel = this._elems('searchResultsPanel');
		this._pagination = this.findInstanceByName(this.instanceName() + 'Pagination');

		this._elems('searchBtn').on('click', self.onSearchTourists_BtnClick.bind(this));

		this._elems("foundTourists").on("click", ".e-touristSelectBtn", function(ev) {
			var record = this.recordSet.getRecord($(ev.currentTarget).data('id'))
			this._notify('itemSelect', record);
		}.bind(this));
		this._pagination.subscribe('onSetCurrentPage', this.onSearchTourists.bind(this));
		
		this._elems('block').hide();
	}

	return __mixinProto(TouristSearchArea, {
		/** Тык по кнопке поиска туристов  */
		onSearchTourists_BtnClick: function() {
			this._pagination.setCurrentPage(0);
			this.onSearchTourists(); //Переход к действию по кнопке Искать
		},

		/** Поиск туристов и отображение результата в диалоге */
		onSearchTourists: function() {
			var
				self = this,
				messageDiv = this._elems("selectMessage"),
				currentPage = this._pagination.getCurrentPage(),
				pageSize = 10;

			json_rpc.invoke({
				uri: '/jsonrpc/',
				method: 'tourist.plainSearch',
				params: { 
					filter: {
						familyName: this._elems("familyFilter").val() || undefined, 
						givenName: this._elems("nameFilter").val() || undefined,
						patronymic: this._elems("patronymicFilter").val() || undefined,
						birthYear: parseInt(this._elems("yearFilter").val(), 10) || undefined,
						region: this._elems("regionFilter").val() || undefined,
						city: this._elems("cityFilter").val() || undefined,
						street: this._elems("streetFilter").val() || undefined
					},
					nav: {
						offset: currentPage * pageSize,
						limit: pageSize
					}
				},
				success: function(json) {
					var
						rec,
						searchResultsDiv = self._elems("foundTourists"),
						summaryDiv = self._elems("touristsFoundSummary"),
						navigBar = self._elems("pageNavigationBar"),
						pageCountDiv = self._elems("pageCount"),
						recordCount = json.recordCount; // Количество записей, удовлетворяющих фильтру
						pageSize = json.pageSize || 10;
					
					self.recordSet = datctrl.fromJSON(json.rs);
					self.recordSet.rewind();

					searchResultsDiv.empty();
					while( rec = self.recordSet.next() )
						self.renderFoundTourist(rec).appendTo(searchResultsDiv);

					self._resultsPanel.show();
					self._pagination.setNavigation(json.nav);

					if( recordCount < 1 ) {
						summaryDiv.text("По данному запросу туристов не найдено");
						navigBar.hide();
					} else {
						summaryDiv.text("Найдено " + recordCount + " туристов");
						navigBar.show();
					}
				}
			});
		},
		
		renderFoundTourist: function(record) {
			var
				recordDiv = $("<div>", {
					class: this._elemFullClass('touristSelectBtn'),
				})
				.data("id", record.getKey()),
				iconWrp = $("<span>", {
					class: this._elemFullClass('iconWrapper')
				}).appendTo(recordDiv),
				button = $("<div>", {
					class: 'icon-small icon-appendItem'
				}).appendTo(iconWrp),
				recordLink = $("<a>", {
					class: this._elemFullClass('touristLink'),
					href: "#!",
					text: MKKHelpers.getTouristInfoString(record)
				}).appendTo(recordDiv);
			return recordDiv;
		},
		
		activate: function(place)
		{
			this._container.detach().appendTo(place).show();
			if( this.recordSet && this.recordSet.getLength() )
				this._resultsPanel.show();
			else
				this._resultsPanel.hide()
		},
		
		deactivate: function(place)
		{
			this._container.detach().appendTo('body').hide();
		}
	});
});