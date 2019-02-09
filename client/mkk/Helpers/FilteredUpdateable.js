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
				params = {
					generalTemplate: (!this._useGeneralTemplate? 'no': undefined),
					instanceName: this.instanceName()
				},
				allowed = this._allowedFilterParams;
			if( this._filter ) {
				if( allowed != null ) {
					for( var i = 0; i < allowed.length; ++i ) {
						var field = allowed[i];
						if( this._filter[field] ) {
							params[field] = this._filter[field];
						}
					}
				} else {
					for( var field in this._filter ) {
						if( this._filter.hasOwnProperty(field) ) {
							params[field] = this._filter[field];
						}
					}
				}
			}
			return params;
		}
	}));
});