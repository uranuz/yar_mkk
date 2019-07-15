define('mkk/Pohod/Edit/Party/Party', [
	'fir/controls/FirControl',
	'mkk/helpers',
	'fir/datctrl/RecordSet',
	'mkk/Tourist/SearchArea/SearchArea',
	'mkk/Tourist/PlainList/PlainList'
], function (
	FirControl,
	MKKHelpers,
	RecordSet
) {
'use strict';
return FirClass(
	function PartyEdit(opts) {
		this.superproto.constructor.call(this, opts);
		this._selectedTouristsCtrl = this.getChildByName('selectedTourists');
		this._panelsArea = this._elems("panelsArea");
		this._searchPanel = this._elems("searchPanel");
		this._selectedTouristsPanel = this._elems("selectedTouristsPanel");

		this._selectedTouristsCtrl.setFilterGetter(this.getPartyListFilter.bind(this));

		this.getChildByName('touristSearchArea').subscribe('itemSelect', this._onSelectTourist.bind(this));
		this._selectedTouristsCtrl.subscribe("itemActivated", this._onTouristDeselect.bind(this));
		this._selectedTouristsCtrl.subscribe("onTouristListLoaded", this._onDialog_resize.bind(this));

		this._subscr(function() {
			this._elems("acceptBtn").on("click", this._acceptBtn_click.bind(this));
		});

		this._unsubscr(function() {
			this._elems("acceptBtn").off();
		});

		this.subscribe('onAfterLoad', function(ev, areaName, opts) {
			this._onDialog_resize(); // При загрузке диалога перестраиваем его
		});
	}, FirControl, {
		_acceptBtn_click: function() {
			this._notify('saveData', this._touristList);
			this.destroy(); // Уничтожаем компонент, когда выбор завершен
		},

		_onDialog_resize: function() {
			if( this._touristList && this._touristList.getLength() ) {
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

		getPartyListFilter: function() {
			return {
				nums: this._touristList.getKeys()
			};
		},

		//Обработчик добавления найденной записи о туристе
		_onSelectTourist: function(ev, rec) {
			if( !this._touristList ) {
				this._touristList = new RecordSet({
					format: rec.getFormat().copy()
				});
			}

			if( this._touristList.hasKey( rec.getKey() ) ) {
				this._elems("selectMessage").html(
					"Турист <b>" + MKKHelpers.getTouristInfoString(rec)
					+ "</b> уже находится в списке выбранных туристов"
				);
			} else {
				// Добавляем туриста в набор данных и обновляем список
				this._touristList.append(rec);
				this._selectedTouristsCtrl._reloadControl();
			}
		},
		
		//Обработчик отмены выбора записи
		_onTouristDeselect: function(ev, rec) {
			this._touristList.remove(rec.getKey());
			this._selectedTouristsCtrl._reloadControl();
		}
	});
});