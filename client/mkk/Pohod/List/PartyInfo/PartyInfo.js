define('mkk/Pohod/List/PartyInfo/PartyInfo', [
	'fir/controls/FirControl',
	'mkk/Helpers/FilteredUpdateableDialog',
	'mkk/Tourist/PlainList/PlainList'
], function(FirControl, FilteredUpdateableDialog) {
	__extends(PartyInfo, FirControl);

	function PartyInfo(opts) {
		FirControl.call(this, opts);
		this.setDialogOptions({modal: true})
	}
	return __mixinProto(PartyInfo, [FilteredUpdateableDialog, {
		_getRequestURI: function() {
			return '/dyn/pohod/partyInfo';
		}
	}]);
});