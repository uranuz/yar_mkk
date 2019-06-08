define('mkk/Pohod/Edit/ExtraFileLinks/ExtraFileLinks', [
	'fir/controls/FirControl'
], function (FirControl) {
return FirClass(
	function ExtraFileLinks(opts) {
		this.superproto.constructor.call(this, opts);
		this._subscr(function() {
			this._elems("moreLinksBtn").on("click", this._reloadControl.bind(this, 'moreLinks'));
		});
		this._unsubscr(function() {
			this._elems("moreLinksBtn").off("click");
		})
	}, FirControl, {
		show: function() {
			this._reloadControl();
		},

		_getRequestURI: function(areaName) {
			return '/dyn/pohod/extraFileLinks';
		},

		_getQueryParams: function(areaName) {
			return {
				instanceName: this.instanceName(),
				generalTemplate: 'no'
			};
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
				comment = $(currInputs[1]).val(),
				num = parseInt($(tableRows[i]).data('mkkNum'), 10);
				if( isNaN(num) ) {
					num = null; // Если это новая ссылка, то номера не будет
				}

				if( $.trim(link).length && $.trim(comment).length )
					result.push([link, comment, num]);
			}
			return result;
		},

		// Сохранение списка ссылок на доп. материалы в скрытое поле формы (для отправки на сервер)
		saveFileLinksToForm: function() {
			this._elems("linksDataField").val( JSON.stringify(this.getLinkList()) );
		},
	});
});