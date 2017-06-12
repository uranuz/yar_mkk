define('mkk/PohodEdit/PartyEdit/PartyEdit', [
	'fir/controls/FirControl'
], function (FirControl) {
	__extends(PartyEdit, FirControl);

	//Инциализация блока редактирования списка участников
	function PartyEdit(opts)
	{
		FirControl.call(this, opts);
		var self = this;

		this.selTouristsRS = null; //RecordSet с выбранными в поиске туристами
		this.page = 0;
		this._searchBlock = this.getChildInstanceByName('touristSearchArea');
		this.panelsArea = self._elems("panelsArea");
		this.searchPanel = self._elems("searchPanel");
		this.selectedTouristsPanel = self._elems("selectedTouristsPanel");

		this._elems("acceptBtn").on("click", function() {
			self.trigger('saveData', [self, self.selTouristsRS]);
			self.closeDialog();
		});
		
		this._elems("selectedTourists").on("click", ".e-touristDeselectBtn", this.onDeselectTourist_BtnClick);
		this._container.on('dialogclose', this.onDialogClose.bind(this));
	}
	
	return __mixinProto(PartyEdit, {
		openDialog: function(recordSet)
		{
			var 
				self = this;
				
			this.selTouristsRS = recordSet;
			this.renderSelectedTourists();
			this.searchBlock.activate(this.$el(".e-search_block"));
			this.searchBlock.$on('itemSelect', this.onSelectTourist.bind(this));
			this.dialog.dialog({
				modal: true, minWidth: 500,
				resize: function() {
					setTimeout( self.onDialogResize.bind(self), 100 );
				}
			});
			
			this.onDialogResize();
		},
		
		onDialogResize: function() {
			if( this.selTouristsRS && this.selTouristsRS.getLength() ) {
				if( this.dialog.innerWidth() < 700 ) {
					this.panelsArea.css("display", "block");
					this.searchPanel.css("display", "block");
					this.searchPanel.css("width", "100%");
					this.selectedTouristsPanel.css("display", "block");
					this.selectedTouristsPanel.css("width", "100%");
				} else {
					this.panelsArea.css("display", "table");
					this.searchPanel.css("display", "table-cell");
					this.searchPanel.css("width", "50%");
					this.selectedTouristsPanel.css("display", "table-cell");
					this.selectedTouristsPanel.css("width", "50%");
				}
			}
			else
			{
				this.panelsArea.css("display", "block");
				this.searchPanel.css("display", "block");
				this.searchPanel.css("width", "100%");
				this.selectedTouristsPanel.css("display", "none");
			}
		},
		
		closeDialog: function() {
			this.dialog.dialog('close');
		},
		
		onDialogClose: function() {
			this.searchBlock.deactivate();
			this.searchBlock.$off('itemSelect');
		},

		//Метод образует разметку с информацией о выбранном туристе
		renderSelectedTourist: function(rec)
		{	var
				recordDiv = $("<div>", {
					class: "b-pohod_party_edit e-tourist_deselect_btn"
				})
				.data( 'num', rec.get('num') ),
				iconWrp = $("<span>", {
					class: "b-pohod_party_edit e-icon_wrapper"
				}).appendTo(recordDiv),
				deselectBtn = $("<div>", {
					class: "icon-small icon-remove_item"
				}).appendTo(iconWrp),
				recordLink = $("<a>", {
					class: "b-pohod_party_edit e-tourist_link",
					href: "#!",
					text: mkk_site.utils.getTouristInfoString(rec)
				})
				.appendTo(recordDiv);
			
			return recordDiv;
		},
		
		//Обработчик добавления найденной записи о туристе
		onSelectTourist: function(ev, el, rec) {
			var 
				recordDiv,
				deselectBtn;
			
			if( !this.selTouristsRS )
			{	this.selTouristsRS = new webtank.datctrl.RecordSet({
					format: rec.copyFormat()
				});
			}
			
			if( this.selTouristsRS.hasKey( rec.getKey() ) )
			{	this.$el(".e-select_message").html(
					"Турист <b>" + mkk_site.utils.getTouristInfoString(rec)
					+ "</b> уже находится в списке выбранных туристов"
				);
			}
			else
			{	this.selTouristsRS.append(rec);
				this.renderSelectedTourist(rec)
				.appendTo( this.$el(".e-selected_tourists") );
			}
			
			this.onDialogResize(); //Перестройка диалога
		},
		
		//Обработчик отмены выбора записи
		onDeselectTourist_BtnClick: function(ev, el) {
			var 
				recId = el.data('num'),
				recordDiv = el,
				touristSelectDiv = this.$el(".e-selected_tourists");
			
			this.selTouristsRS.remove( recId );
			recordDiv.remove();
		},
		
		//Тык по кнопке открытия окна редактирования списка участников
		renderSelectedTourists: function() {
			var 
				self = this,
				selectedTouristsDiv = this.$el(".e-selected_tourists"),
				rec;
				
			//Очистка окна списка туристов перед заполнением
			selectedTouristsDiv.empty();
				
			this.selTouristsRS.rewind();
			while( rec = this.selTouristsRS.next() )
			{	this.renderSelectedTourist(rec)
				.data('num', rec.get('num'))
				.appendTo( selectedTouristsDiv );
			}
		}
	});
});