define('mkk/Stat/Stat', [
	// Подключение зависимостей: библиотек, стилей и т.п.
	'fir/controls/FirControl',
	/*'mkk/Stat/flot/jquery.js',
	'mkk/Stat/flot/jquery.flot',
	'mkk/Stat/flot/jquery.flot.time',*/
	'mkk/Stat/stat',
	'css!mkk/Stat/Stat'
], function (FirControl, Flot, FlotTime) {
	__extends(Stat, FirControl);

	function Stat(opts) {
		FirControl.call(this, opts);
		this._name = 'Test';
		this._elems('byYearBtn').on('click', this.reloadPage);
		this._elems('byComplexityBtn').on('click', this.reloadPage);
		doFlot();
		
	}; 

	return __mixinProto(Stat, {
		// Описание методов класса
		
		getName: function() {
			return this._name;
		},
		reloadPage: function()
		{
			document.forms.main_form.submit()
		}
	});
});