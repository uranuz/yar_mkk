define('mkk/Helpers/FilteredUpdateable', [], function() {
	function FilteredUpdateable() {}

	return new (__mixinProto(FilteredUpdateable, {
		getFilter: function() {
			return this._filter;
		},
		setFilter: function(filter) {
			this._filter = filter;
		},
		setAllowedFilterParams: function(paramNames) {
			this._allowedFilterParams = paramNames;
		},
		_getQueryParams: function(areaName) {
			var
				params = [],
				allowed = this._allowedFilterParams;
			if( this._filter ) {
				if( allowed != null ) {
					for( var i = 0; i < allowed.length; ++i ) {
						if( this._filter[ allowed[i] ] ) {
							params.push(allowed[i] + '=' + this._filter[ allowed[i] ]);
						}
					}
				} else {
					for( var key in this._filter ) {
						if( this._filter.hasOwnProperty(key) ) {
							params.push(key + '=' + this._filter[key]);
						}
					}
				}
			}
			if( !this._useGeneralTemplate ) {
				params.push('generalTemplate=no');
			}
			params.push('instanceName=' + this.instanceName());
			return params.join('&');
		}
	}));
});