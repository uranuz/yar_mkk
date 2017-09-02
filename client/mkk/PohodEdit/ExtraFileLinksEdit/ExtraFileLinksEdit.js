define('mkk/PohodEdit/ExtraFileLinksEdit/ExtraFileLinksEdit', [
	'fir/controls/FirControl'
], function (FirControl) {
	__extends(ExtraFileLinksEdit, FirControl);

	function ExtraFileLinksEdit(opts) {
		FirControl.call(this, opts);
	}
	return __mixinProto(ExtraFileLinksEdit, {
		_subscribeInternal: function() {
			this._elems("moreLinksBtn").on("click", this._reloadControl.bind(this, 'moreLinks'));
		},
		_unsubscribeInternal: function() {
			this._elems("moreLinksBtn").off("click");
		},
		show: function() {
			this._reloadControl();
		},

		_getRequestURI: function(areaName) {
			return '/dyn/pohod/extraFileLinks';
		},

		_getQueryParams: function(areaName) {
			return 'instanceName=extraFileLinksEdit';
		},

		_updateControlMarkup: function(state) {
			if (state.areaName === 'moreLinks') {
				this._elems('linksTableBody').append(state.controlTag.children());
			} else {
				FirControl._updateControlMarkup.call(this, state.areaName);
			}
		},

		/** Возвращает список ссылок в виде массива из 2х-элементых массивов: [ссылка, описание] */
		getLinkList: function() {
			var
				self = this,
				tableRows = this._elems("linksTableBody").children("tr"),
				currInputs, link, comment,
				result = [],
				i = 0;

			for( ; i < tableRows.length; i++ )
			{
				currInputs = $(tableRows[i]).children("td").children("input");
				link = $(currInputs[0]).val();
				comment = $(currInputs[1]).val();

				if( $.trim(link).length && $.trim(link).length )
					result.push([link, comment]);
			}
			return result;
		},

		// Сохранение списка ссылок на доп. материалы в скрытое поле формы (для отправки на сервер)
		saveFileLinksToForm: function() {
			this._elems("linksDataField").val( JSON.stringify(this.getLinkList()) );
		},
	});
});