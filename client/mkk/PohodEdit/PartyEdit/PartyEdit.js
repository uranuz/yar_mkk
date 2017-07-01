define('mkk/PohodEdit/PartyEdit/PartyEdit', [
	'fir/controls/FirControl',
	'mkk/helpers'
], function (
	FirControl,
	MKKHelpers
) {
	__extends(PartyEdit, FirControl);

	//Инциализация блока редактирования списка участников
	function PartyEdit(opts)
	{
		FirControl.call(this, opts);
		var self = this;

		this.selTouristsRS = null; //RecordSet с выбранными в поиске туристами
		this.page = 0;
		this._searchBlock = this.getChildInstanceByName('touristSearchArea');
		this._panelsArea = self._elems("panelsArea");
		this._searchPanel = self._elems("searchPanel");
		this._selectedTouristsPanel = self._elems("selectedTouristsPanel");

		this._elems("acceptBtn").on("click", function() {
			self.trigger('saveData', [self, self.selTouristsRS]);
			self.closeDialog();
		});
		
		this._elems("selectedTourists").on("click", ".e-touristDeselectBtn", this.onDeselectTouristBtn_click);
		this._container.on('dialogclose', this.onDialog_close.bind(this));
	}
	
	return __mixinProto(PartyEdit, {
		openDialog: function(recordSet)
		{
			var 
				self = this;
				
			this.selTouristsRS = recordSet;
			this.renderSelectedTourists();
			this._searchBlock.activate(this._elems("searchBlock"));
			this._searchBlock.subscribe('itemSelect', this.onSelectTourist.bind(this));
			this._container.dialog({
				modal: true, minWidth: 500,
				resize: function() {
					setTimeout( self.onDialog_resize.bind(self), 100 );
				}
			});
			
			this.onDialog_resize();
		},
		
		onDialog_resize: function() {
			if( this.selTouristsRS && this.selTouristsRS.getLength() ) {
				if( this._container.innerWidth() < 700 ) {
					this._panelsArea.css("display", "block");
					this._searchPanel.css("display", "block");
					this._searchPanel.css("width", "100%");
					this._selectedTouristsPanel.css("display", "block");
					this._selectedTouristsPanel.css("width", "100%");
				} else {
					this._panelsArea.css("display", "table");
					this._searchPanel.css("display", "table-cell");
					this._searchPanel.css("width", "50%");
					this._selectedTouristsPanel.css("display", "table-cell");
					this._selectedTouristsPanel.css("width", "50%");
				}
			}
			else
			{
				this._panelsArea.css("display", "block");
				this._searchPanel.css("display", "block");
				this._searchPanel.css("width", "100%");
				this._selectedTouristsPanel.css("display", "none");
			}
		},
		
		closeDialog: function() {
			this._container.dialog('close');
		},
		
		onDialog_close: function() {
			this._searchBlock.deactivate();
			this._searchBlock.unsubscribe('itemSelect');
		},

		//Метод образует разметку с информацией о выбранном туристе
		renderSelectedTourist: function(rec)
		{	var
				recordDiv = $("<div>", {
					class: this._elemFullClass("touristDeselectBtn")
				})
				.data('num', rec.get('num')),
				iconWrp = $("<span>", {
					class: this._elemFullClass("iconWrapper")
				}).appendTo(recordDiv),
				deselectBtn = $("<div>", {
					class: "icon-small icon-removeItem"
				}).appendTo(iconWrp),
				recordLink = $("<a>", {
					class: this._elemFullClass("touristLink"),
					href: "#!",
					text: MKKHelpers.getTouristInfoString(rec)
				})
				.appendTo(recordDiv);

			return recordDiv;
		},
		
		//Обработчик добавления найденной записи о туристе
		onSelectTourist: function(ev, rec) {
			var 
				recordDiv,
				deselectBtn;
			
			if( !this.selTouristsRS )
			{	this.selTouristsRS = new webtank.datctrl.RecordSet({
					format: rec.copyFormat()
				});
			}
			
			if( this.selTouristsRS.hasKey( rec.getKey() ) )
			{	this._elems("selectMessage").html(
					"Турист <b>" + MKKHelpers.getTouristInfoString(rec)
					+ "</b> уже находится в списке выбранных туристов"
				);
			}
			else
			{	this.selTouristsRS.append(rec);
				this.renderSelectedTourist(rec)
				.appendTo( this._elems("selectedTourists") );
			}

			this.onDialog_resize(); // Перестройка диалога
		},
		
		//Обработчик отмены выбора записи
		onDeselectTouristBtn_click: function(ev) {
			var recordDiv = $(ev.currentTarget);

			this.selTouristsRS.remove(recordDiv.data('num'));
			recordDiv.remove();
			this.onDialog_resize(); // Перестройка диалога
		},
		
		// Тык по кнопке открытия окна редактирования списка участников
		renderSelectedTourists: function() {
			var 
				self = this,
				selectedTouristsDiv = this._elems("selectedTourists"),
				rec;

			// Очистка окна списка туристов перед заполнением
			selectedTouristsDiv.empty();

			this.selTouristsRS.rewind();
			while( rec = this.selTouristsRS.next() ) {
				this.renderSelectedTourist(rec)
				.data('num', rec.get('num'))
				.appendTo(selectedTouristsDiv);
			}
		}
	});
});