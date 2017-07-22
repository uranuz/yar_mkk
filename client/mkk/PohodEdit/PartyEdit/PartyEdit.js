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
		this._selectedTouristsCtrl = this.getChildInstanceByName('selectedTourists');
		this._searchBlock = this.getChildInstanceByName('touristSearchArea');
		this._searchBlock.subscribe('itemSelect', this.onSelectTourist.bind(this));

		this._selectedTouristRS = opts._selectedTouristRS; //RecordSet с выбранными в поиске туристами
		this._updateControlState();
		this._subscribeInternal();
	}
	
	return __mixinProto(PartyEdit, {
		_updateControlState: function() {
			this._panelsArea = this._elems("panelsArea");
			this._searchPanel = this._elems("searchPanel");
			this._selectedTouristsPanel = this._elems("selectedTouristsPanel");
		},
		_subscribeInternal: function() {
			var self = this;
			this._elems("acceptBtn").on("click", function() {
				self._notify('saveData', self._selectedTouristRS);
				self.closeDialog();
			});

			this._elems("selectedTourists").on("click", ".e-touristDeselectBtn", this.onDeselectTouristBtn_click.bind(this));
			this._container.on('dialogclose', this.onDialog_close.bind(this));
		},
		_unsubscribeInternal: function() {
			this._elems("acceptBtn").off();
			this._elems("selectedTourists").off();
			this._container.on('dialogclose').off();
		},

		openDialog: function(recordSet)
		{
			var self = this;
			this._selectedTouristRS = recordSet;
			this._selectedTouristsCtrl._reloadControl();
			this._searchBlock.activate(this._elems("searchBlock"));
			this._container.dialog({
				modal: true, minWidth: 500,
				resize: function() {
					setTimeout( self.onDialog_resize.bind(self), 100 );
				}
			});
			
			this.onDialog_resize();
		},

		onDialog_resize: function() {
			if( this._selectedTouristRS && this._selectedTouristRS.getLength() ) {
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

		//Обработчик добавления найденной записи о туристе
		onSelectTourist: function(ev, rec) {
			var 
				recordDiv,
				deselectBtn;
			
			if( !this._selectedTouristRS ) {
				this._selectedTouristRS = new webtank.datctrl.RecordSet({
					format: rec.copyFormat()
				});
			}
			
			if( this._selectedTouristRS.hasKey( rec.getKey() ) ) {
				this._elems("selectMessage").html(
					"Турист <b>" + MKKHelpers.getTouristInfoString(rec)
					+ "</b> уже находится в списке выбранных туристов"
				);
			} else {
				// Добавляем туриста в набор данных и обновляем список
				this._selectedTouristRS.append(rec);
				//this.reloadSelectedTourists();
				this._selectedTouristsCtrl._reloadControl();
			}
		},
		
		//Обработчик отмены выбора записи
		onDeselectTouristBtn_click: function(ev) {
			var recordDiv = $(ev.currentTarget);

			this._selectedTouristRS.remove(recordDiv.data('num'));
			recordDiv.remove();
			this.onDialog_resize(); // Перестройка диалога
		}
	});
});