define('mkk/User/Reg/FindTourist/FindTourist', [
	'fir/controls/FirControl',
	'mkk/Tourist/SearchArea/SearchArea',
	'css!mkk/User/Reg/FindTourist/FindTourist'
], function(FirControl) {
return FirClass(
	function UserRegFindTourist(opts) {
		this.superproto.constructor.call(this, opts);
		this._touristSelectArea = this.getChildByName('touristSelectArea');
		this._touristSelectArea.subscribe('itemSelect', this._onTourist_itemSelect.bind(this));
	}, FirControl, {
		_onTourist_itemSelect: function(ev, rec) {
			window.location.replace('/dyn/user/reg?num=' + rec.get('num'));
		}
	});
});