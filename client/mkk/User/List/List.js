define('mkk/User/List/List', [
	'fir/controls/FirControl',
	'fir/network/json_rpc',
	'fir/common/helpers',
	'mkk/User/List/List.scss'
], function (FirControl, json_rpc, FirHelpers) {
var ACTION_BTNS = {
	confirmRegBtn: {
		method: 'user.confirmReg',
		title: 'Подтверждение регистрации',
		text: 'Вы действительно хотите подтвердить регистрацию пользователя?'
	},
	lockUserBtn: {
		method: 'user.lock',
		title: 'Блокировка пользователя',
		text: 'Вы действительно хотите заблокировать пользователя?'
	},
	unlockUserBtn: {
		method: 'user.unlock',
		title: 'Разблокировка пользователя',
		text: 'Вы действительно хотите разблокировать пользователя?'
	}
}, LIST_AREA = 'listView';
return FirClass(
	function UserList(opts) {
		this.superproto.constructor.call(this, opts);
		this._paging = this.getChildByName(this.instanceName() + 'Paging');
		this._reloadList = this._reloadControl.bind(this, LIST_AREA);
		FirHelpers.doOnEnter(this, 'nameField', this._reloadList);
		this._subscr(function() {
			this._elems(LIST_AREA).on('click', this._onListBlock_click.bind(this));
		});
		this._unsubscr(function() {
			this._elems(LIST_AREA).off('click');
		});

		FirHelpers.managePaging({
			control: this,
			paging: this._paging,
			areaName: LIST_AREA
		});
	}, FirControl, {
		_onListBlock_click: function(ev) {
			for( var btnName in ACTION_BTNS ) {
				if( ACTION_BTNS.hasOwnProperty(btnName) && $(ev.target).is(this._elemClass(btnName)) ) {
					this._doItemAction(ev, btnName);
					break;
				}
			}
		},
		_doItemAction: function(ev, btnName) {
			var
				itemRow = $(ev.target).closest(this._elemClass('listItem')),
				itemNum = parseInt(itemRow.data('mkk-num'), 10),
				btnConf = ACTION_BTNS[btnName],
				confirmDlg = this.getChildByName(this.instanceName() + 'ItemActionConfirmDlg');
			confirmDlg.unsubscribe('dialogControlLoad'); // Удалим старые обработчики на всякий случай
			confirmDlg.once('dialogControlLoad', function(ev, control) {
				control.once('onExecuted', this._onConfirmDialog_executed.bind(this, itemNum, btnName));
			}.bind(this));
			confirmDlg.open({
				dialogOpts: {
					title: btnConf.title
				},
				viewParams: {
					text: btnConf.text,
					withCancelButton: false
				}
			});
		},
		_onConfirmDialog_executed: function(itemNum, btnName, ev, cmd) {
			var self = this;
			if( cmd !== 'yes' ) {
				return;
			}
			json_rpc.invoke({
				uri: "/jsonrpc/",
				method: ACTION_BTNS[btnName].method,
				params: {userNum: itemNum},
				success: function() {
					self._reloadControl();
				},
				error: function(res) {
					$('<div title="Ошибка операции">' + res.message + '</div>').dialog({modal: true});
				}
			});
		},
		_getQueryParams: function() {
			return {
				name: this._elems('nameField').val(),
				nav: this._paging.getNavParams()
			};
		},
	});
});