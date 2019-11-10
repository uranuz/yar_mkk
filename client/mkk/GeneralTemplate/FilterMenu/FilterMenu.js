define('mkk/GeneralTemplate/FilterMenu/FilterMenu', [
	'fir/controls/FirControl',
	'mkk/GeneralTemplate/FilterMenu/FilterMenu.scss'
], function(FirControl) {
return FirClass(
	function PohodFilterMenu(opts) {
		this.superproto.constructor.call(this, opts);

		this._subscr(function() {
			this._elems('itemLink').on('click', this.onFilterItemClick.bind(this));
		});
		this._unsubscr(function() {
			this._elems('itemLink').off('click');
		});
	}, FirControl, {
		onFilterItemClick: function(ev) {
			var itemPos = $(ev.currentTarget).attr('data-mkk-item_pos').split('/');

			if (itemPos.length != 2)
				return;

			var
				sectionIndex = +itemPos[0],
				itemIndex = +itemPos[1],
				filterData = this._pohodFilterSections[sectionIndex].items[itemIndex].fields;

			if (!filterData)
				return;

			for (var fieldName in filterData) {
				// Для фильтра с неск. критериями
				// Ищем нужный элемент формы и пихаем туда значение фильтра
				this._elems('filterInput')
					.filter('.e-filter__' + fieldName)
					.val(filterData[fieldName]);
			}

			this._elems('form')[0].submit();
		}
	});
});