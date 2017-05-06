define('mkk/GeneralTemplate/FilterMenu', [
	'fir/controls/FirControl'
], function(FirControl) {
	__extends(PohodFilterMenu, FirControl);

	function PohodFilterMenu(opts) {
		opts = opts || {};
		_super.call(this, opts);

		this._filterSet = opts.filterSet || {};
		this._form = this._elems().filter('.e-form');
		this._itemLinks = this._elems().filter('.e-item_link');
		this._inputs = this._elems().filter('.e-filter_input');

		this._itemLinks.on('click', this.onFilterItemClick.bind(this));
	}

	return __mixinProto(PohodFilterMenu, {
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