define('mkk/Right/Role/RightList/RightList', [
	'fir/controls/FirControl',
	'css!mkk/Right/Role/RightList/RightList'
], function (FirControl) {
return FirClass(
	function RoleRightList(opts) {
		this.superproto.constructor.call(this, opts);
		this._rightEditDlg = this.getChildByName('rightEditDlg');
		this._rightDeleteDlg = this.getChildByName('rightRuleDeleteDlg');
		this._subscr(function() {
			this._elems('addRuleBtn').on('click', this._onAddRuleBtn_click.bind(this));
			this._elems('rightList').on('click', this._onListItem_click.bind(this));
		});
		this._unsubscr(function() {
			this._elems('addRuleBtn').off('click');
			this._elems('rightList').off('click');
		});
	}, FirControl, {
		_onAddRuleBtn_click: function() {
			this._rightEditDlg.open({
				queryParams: {
					roleNum: this._role.getKey()
				}
			});
		},
		_onListItem_click: function(ev) {
			var el = $(ev.target).closest(this._elemClass('itemActionBtn'));
			if( !el || !el.length ) {
				return;
			}
			var
				action = el.data('mkkAction'),
				recordNum = parseInt(el.data('recordNum'), 10) || null;
			switch( action ) {
				case 'removeRole': {
					this._rightDeleteDlg.open({
						viewParams: {
							deleteWhat: 'право доступа'
						}
					}).then(function(control) {
						control.once('onDeleteConfirm', this._onDelete_confirmed.bind(this, recordNum));
					}.bind(this), function(err) {
						console.log(err);
					});
					break;
				}
			}
		},

		/** Удаление записи подтверждено пользователем */
		_onDelete_confirmed: function(recordNum) {
			json_rpc.invoke({
				uri: "/jsonrpc/",
				method: 'right.delete',
				params: {num: recordNum},
				success: function(res) {
					this._rightDeleteDlg.close();
				}.bind(this),
				error: function(res) {
					console.error(res);
				}
			});
		},
	}
);
});