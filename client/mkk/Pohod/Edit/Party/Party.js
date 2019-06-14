define('mkk/Pohod/Edit/Party/Party', [
	'fir/controls/FirControl',
	'mkk/helpers',
	'mkk/Tourist/SearchArea/SearchArea',
	'mkk/Tourist/PlainList/PlainList'
], function (
	FirControl,
	MKKHelpers
) {
return FirClass(
	function PartyEdit(opts) {
		this.superproto.constructor.call(this, opts);
		this._selectedTouristsCtrl = this.getChildByName('selectedTourists');
		this._searchBlock = this.getChildByName('touristSearchArea');
		this._subscr(function() {
			this._elems("acceptBtn").on("click", this._acceptBtn_click.bind(this));
			this._getContainer().on('dialogclose', this.onDialog_close.bind(this));

			this._selectedTouristsCtrl.subscribe("itemActivated", this._onTouristDeselect.bind(this));
			// После загрузки списка обновляем состояние отображения
			this._selectedTouristsCtrl.subscribe("onTouristListLoaded", this._onDialog_resize.bind(this));			
			this._searchBlock.subscribe('itemSelect', this._onSelectTourist.bind(this));
		});

		this._unsubscr(function() {
			this._elems("acceptBtn").off();
			this._elems("selectedTourists").off();
			this._getContainer().off('dialogclose');
			this._searchBlock.unsubscribe('itemSelect');
		});

		this.subscribe('onAfterLoad', function(ev, areaName, opts) {
			this._panelsArea = this._elems("panelsArea");
			this._searchPanel = this._elems("searchPanel");
			this._selectedTouristsPanel = this._elems("selectedTouristsPanel");
			this._partyList = opts.partyList; //RecordSet с выбранными в поиске туристами
		});
	}, FirControl, {
		_acceptBtn_click: function() {
			this._notify('saveData', self._partyList);
			this.closeDialog();
		},

		openDialog: function(rs) {
			var self = this;
			this._partyList = rs;
			this._reloadPartyList();
			this._searchBlock.activate(this._elems("searchBlock"));
			this._getContainer().dialog({
				modal: true,
				minWidth: 500,
				width: 1000,
				resize: function() {
					setTimeout(self._onDialog_resize.bind(self), 100);
				}
			});
		},

		_onDialog_resize: function() {
			if( this._partyList && this._partyList.getLength() ) {
				if( this._getContainer().innerWidth() < 999 ) {
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
			this._getContainer().dialog('close');
		},
		
		onDialog_close: function() {
			this._searchBlock.deactivate();
		},

		_reloadPartyList: function() {
			this._selectedTouristsCtrl._reloadControl(null, {
				queryParams: {
					filter: {
						selectedKeys: this._partyList.getKeys()
					}
				}
			});
		},
		//Обработчик добавления найденной записи о туристе
		_onSelectTourist: function(ev, rec) {
			var 
				recordDiv,
				deselectBtn;

			if( !this._partyList ) {
				this._partyList = new webtank.datctrl.RecordSet({
					format: rec.getFormat().copy()
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