define('mkk/UserReg/FindTourist/FindTourist', [
	'fir/controls/FirControl',
	'mkk/TouristSearchArea/TouristSearchArea',
	'css!mkk/UserReg/FindTourist/FindTourist'
], function(FirControl) {
	__extends(UserRegFindTourist, FirControl);
	function UserRegFindTourist(opts) {
		FirControl.call(this, opts);
		this._touristSelectArea = this.getChildInstanceByName('touristSelectArea');
		this._touristSelectArea.subscribe('itemSelect', this._onTourist_itemSelect.bind(this));
	}
	return __mixinProto(UserRegFindTourist, {
		_onTourist_itemSelect: function(ev, rec) {
			window.location.replace('/dyn/user/reg?num=' + rec.get('num'));
		}
	});
});