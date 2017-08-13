define('mkk/TouristPlainList/TouristPlainList', [
	'fir/controls/FirControl',
	'fir/datctrl/helpers',
	'css!mkk/TouristPlainList/TouristPlainList'
], function (FirControl, DatctrlHelpers) {
	__extends(TouristPlainList, FirControl);

	function TouristPlainList(opts) {
		FirControl.call(this, opts);
		this._filter = opts.filter;
		this._mode = opts.mode;
		this._updateControlState(opts);
	}
	return __mixinProto(TouristPlainList, {
		// В этой функции мы забираем опции пришедшие при первой загрузке или перезагрузке компонента,
		// которые должны быть обновлены, если это требуется
		_updateControlState: function(opts) {
			this._touristList = DatctrlHelpers.fromJSON(opts.touristList);
			this._nav = opts.nav;
		},
		// Здесь выполняем подписки на события вёрстки этого компонента, либо события дочерних компонентов
		// Должно вызываться при загрузке и после перезагрузки компонента
		_subscribeInternal: function() {
			this._elems('block').on('click', '.e-touristItem', this._onItemActivated.bind(this));
		},
		// Здесь отписываемся от событий вёрстки этого компонента, либо событий дочерних компонентов
		// Должно вызываться перед перезагрузкой компонента, либо перед уничтожением компонента,
		// чтобы избежать утечек памяти, и т.п. явлений
		_unsubscribeInternal: function() {
			this._elems('block').off('click');
		},
		_getRequestURI: function() {
			return '/dyn/tourist/plainList';
		},
		_getQueryParams: function() {
			var
				strParamNames = [
					'familyName', 'givenName', 'patronymic', 'birthYear',
					'region', 'city', 'street'
				],
				params = [];

			if( this._filter ) {
				for( var i = 0; i < strParamNames.length; ++i ) {
					if(  this._filter[ strParamNames[i] ] ) {
						params.push(strParamNames[i] + '=' + this._filter[ strParamNames[i] ]);
					}
				}
				if( this._filter.selectedKeys ) {
					params.push('nums=' + this._filter.selectedKeys.join(','));
				}
			}
			if( ['add', 'remove'].indexOf(this._mode) !== -1 ) {
				params.push('mode=' + this._mode);
			}
			params.push('instanceName=' + this.instanceName());
			return params.join('&');
		},
		_onAfterLoad: function() {
			FirControl.prototype._onAfterLoad.call(this, arguments);
			this._notify('onTouristListLoaded', [this._touristList, this._nav]);
		},
		_onItemActivated: function(ev) {
			var
				num = $(ev.currentTarget).data('num'),
				rec = this._touristList.getRecord(num);
			if (this._mode === 'remove') {
				this._touristList.remove(num);
				ev.currentTarget.remove();
			}
			this._notify('itemActivated', rec);
		},
		setFilter: function(filter) {
			this._filter = filter;
		},
		getTouristList: function() {
			return this._touristList;
		}
	});
});