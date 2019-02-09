define('mkk/Pohod/List/PartyInfo/PartyInfo', [
	'fir/controls/FirControl',
	'mkk/Helpers/FilteredUpdateableDialog',
	'mkk/Tourist/PlainList/PlainList'
], function(FirControl, FilteredUpdateableDialog) {
return FirClass(
	function PartyInfo(opts) {
		FirControl.call(this, opts);
		this.setDialogOptions({modal: true})
	}, FirControl, [FilteredUpdateableDialog], {
		_getRequestURI: function() {
			return '/dyn/pohod/partyInfo';
		}
	}
);
});