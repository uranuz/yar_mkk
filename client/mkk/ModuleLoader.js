define('mkk/ModuleLoader', [
	'fir/controls/iface/IControlModuleLoader',
	'fir/common/Deferred'
], function(
	IControlModuleLoader,
	Deferred
) {
return FirClass(
	function MKKModuleLoader(libs) {
		this._libs = libs || [];
	}, IControlModuleLoader, {
		load: function(moduleName) {
			var def = new Deferred(), res;
			try {
				res = this._doLoad(moduleName);
			} catch(ex) {
				def.reject(ex);
			}
			def.resolve(res);
			return def;
		},
		_doLoad: function(moduleName) {
			var internalModName = './' + moduleName + '.js';
			for( var i = 0; i < this._libs.length; ++i ) {
				var libName = this._libs[i];
				if( !libName ) {
					continue;
				}
				if( typeof(libName) !== 'string' && !(libName instanceof String) ) {
					throw new Error('Expected library variable name!');
				}
				var
					lib = window[libName];
				if( !lib ) {
					throw new Error('No library variable found in global scope!')
				}
				// "m" webpack function property contains modules that library exposes
				if( !lib.m.hasOwnProperty(internalModName) ) {
					continue; // There is not module in this library
				}
				return lib(internalModName);
			}
			throw new Error('Module is not contained in any registered library!');
		}
});
});