define('mkk/GeneralTemplate/FilterMenu/FilterMenu', [
	'fir/controls/FirControl',
	'css!mkk/GeneralTemplate/FilterMenu/FilterMenu'
], function(FirControl) {
return FirClass(
	function PohodFilterMenu(opts) {
		this.superproto.constructor.call(this, opts);

		this._filterSet = opts.pohodFilterSections;
		this._form = this._elems('form');
		this._itemLinks = this._elems('itemLink');
		this._inputs = this._elems('filterInput');

		this._itemLinks.on('click', this.onFilterItemClick.bind(this));
	}, FirControl, {
		onFilterItemClick: function(ev) {
			var
				itemPos = $(ev.currentTarget).attr('data-mkk-item_pos').split('/'),
				sectionIndex, itemIndex, filterData, sectionElem, inputElem;

			if (itemPos.length != 2)
				return;

			sectionIndex = +itemPos[0];
			itemIndex = +itemPos[1];
			filterData = this._filterSet[sectionIndex].items[itemIndex].fields;

			if (!filterData)
				return;

			for (var fieldName in filterData) {
				// Для фильтра с неск. критериями
				// Ищем нужный элемент формы и пихаем туда значение фильтра
				this._inputs.filter('.e-filter__' + fieldName).val(filterData[fieldName]);
			}

			this._form[0].submit();
		}
	});
});