define('mkk/PohodEdit/PartyEdit/PartyEdit', [
	'fir/controls/FirControl',
	'fir/datctrl/helpers',
	'mkk/helpers',
	'mkk/TouristSearchArea/TouristSearchArea',
	'mkk/TouristPlainList/TouristPlainList'
], function (
	FirControl,
	DatctrlHelpers,
	MKKHelpers
) {
	__extends(PartyEdit, FirControl);

	//Инциализация блока редактирования списка участников
	function PartyEdit(opts) {
		FirControl.call(this, opts);
		this._selectedTouristsCtrl = this.getChildInstanceByName('selectedTourists');
		this._searchBlock = this.getChildInstanceByName('touristSearchArea');

		this._updateControlState(opts);
	}
	
	return __mixinProto(PartyEdit, {
		_updateControlState: function(opts) {
			this._panelsArea = this._elems("panelsArea");
			this._searchPanel = this._elems("searchPanel");
			this._selectedTouristsPanel = this._elems("selectedTouristsPanel");
			this._partyList = DatctrlHelpers.fromJSON(opts.partyList); //RecordSet с выбранными в поиске туристами
		},
		_subscribeInternal: function() {
			var self = this;
			this._elems("acceptBtn").on("click", function() {
				self._notify('saveData', self._partyList);
				self.closeDialog();
			});

			this._selectedTouristsCtrl.subscribe("itemActivated", this._onTouristDeselect.bind(this));
			this._container.on('dialogclose', this.onDialog_close.bind(this));
			this._searchBlock.subscribe('itemSelect', this._onSelectTourist.bind(this));
		},
		_unsubscribeInternal: function() {
			this._elems("acceptBtn").off();
			this._elems("selectedTourists").off();
			this._container.off('dialogclose');
			this._searchBlock.unsubscribe('itemSelect');
		},

		openDialog: function(rs) {
			var self = this;
			this._partyList = rs;
			this._reloadPartyList();
			this._searchBlock.activate(this._elems("searchBlock"));
			this._container.dialog({
				modal: true,
				minWidth: 500,
				width: 850,
				resize: function() {
					setTimeout(self._onDialog_resize.bind(self), 100);
				}
			});

			this._onDialog_resize();
		},

		_onDialog_resize: function() {
			if( this._partyList && this._partyList.getLength() ) {
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
		},

		_reloadPartyList: function() {
			var
				selectedKeys = [],
				rec;
			this._partyList.rewind();
			while( rec = this._partyList.next() ) {
				selectedKeys.push(rec.getKey());
			}
			this._selectedTouristsCtrl.setFilter({
				selectedKeys: selectedKeys
			});
			this._selectedTouristsCtrl._reloadControl();
		},
		//Обработчик добавления найденной записи о туристе
		_onSelectTourist: function(ev, rec) {
			var 
				recordDiv,
				deselectBtn;

			if( !this._partyList ) {
				this._partyList = new webtank.datctrl.RecordSet({
					format: rec.copyFormat()
				});
			}

			if( this._partyList.hasKey( rec.getKey() ) ) {
				this._elems("selectMessage").html(
					"Турист <b>" + MKKHelpers.getTouristInfoString(rec)
					+ "</b> уже находится в списке выбранных туристов"
				);
			} else {
				// Добавляем туриста в набор данных и обновляем список
				this._partyList.append(rec);
				this._reloadPartyList();
			}
		},
		
		//Обработчик отмены выбора записи
		_onTouristDeselect: function(ev, rec) {
			this._partyList.remove(rec.getKey());
			this._onDialog_resize(); // Перестройка диалога
		}
	});
});