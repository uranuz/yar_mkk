define('mkk/Tourist/PlainList/PlainList', [
	'fir/controls/FirControl',
	'fir/datctrl/helpers',
	'css!mkk/Tourist/PlainList/PlainList'
], function (FirControl, DatctrlHelpers) {
	var strParamNames = [
		'familyName', 'givenName', 'patronymic', 'birthYear',
		'region', 'city', 'street'
	];
return FirClass(
	function TouristPlainList(opts) {
		this.superproto.constructor.call(this, opts);
		this._filter = opts.filter;
		this._mode = opts.mode;
		this._updateControlState(opts);
	}, FirControl, {
		// В этой функции мы забираем опции пришедшие при первой загрузке или перезагрузке компонента,
		// которые должны быть обновлены, если это требуется
		_updateControlState: function(opts) {
			this._touristList = DatctrlHelpers.fromJSON(opts.touristList);
			this._nav = opts.nav;
		},
		// Здесь выполняем подписки на события вёрстки этого компонента, либо события дочерних компонентов
		// Должно вызываться при загрузке и после перезагрузки компонента
		_onSubscribe: function() {
			this._elems('block').on('click', '.e-touristItem', this._onItemActivated.bind(this));
		},
		// Здесь отписываемся от событий вёрстки этого компонента, либо событий дочерних компонентов
		// Должно вызываться перед перезагрузкой компонента, либо перед уничтожением компонента,
		// чтобы избежать утечек памяти, и т.п. явлений
		_onUnsubscribe: function() {
			this._elems('block').off('click');
		},
		_getRequestURI: function() {
			return '/dyn/tourist/plainList';
		},
		_getRPCMethod: function(areaName) {
			return 'tourist.plainList';
		},
		_getNavParams: function() {
			var params = {};
			if( this._nav ) {
				if( this._nav.offset != null ) {
					params.offset = this._nav.offset;
				}
				if( this._nav.pageSize != null ) {
					params.pageSize = this._nav.pageSize;
				}
			}
			return params;
		},
		_getFilterParams: function(params) {
			var params = {};
			if( this._filter ) {
				for( var i = 0; i < strParamNames.length; ++i ) {
					var field = strParamNames[i];
					if(  this._filter[field] ) {
						params[field] = this._filter[field];
					}
				}
				if( this._filter.selectedKeys ) {
					params.nums = this._filter.selectedKeys;
				}
			}
			return params;
		},
		_getQueryParams: function() {
			return {
				nav: this._getNavParams(),
				filter: this._getFilterParams()
			};
		},
		_getViewParams: function() {
			var params = {
				instanceName: this.instanceName(),
				generalTemplate: 'no'
			};

			if( ['add', 'remove'].indexOf(this._mode) !== -1 ) {
				params.mode = this._mode;
			}
			return params;
		},
		_onAfterLoad: function() {
			this.superproto._onAfterLoad.apply(this, arguments);
			this._notify('onTouristListLoaded', this._touristList, this._nav);
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
		setMode: function(mode) {
			this._mode = mode;
		},
		setNavigation: function(nav) {
			this._nav = nav;
		},
		getTouristList: function() {
			return this._touristList;
		}
	});
});