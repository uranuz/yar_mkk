define('mkk/Right/Role/List/List', [
	'fir/controls/FirControl',
	'fir/common/helpers',
	'fir/network/json_rpc',
	'mkk/Right/Role/List/List.scss'
], function (FirControl, FirHelpers, json_rpc) {
var LIST_AREA = 'listView';
return FirClass(
	function RightRoleList(opts) {
		this.superctor(RightRoleList, opts);
		this.rightRoleEditDlg = this.getChildByName('rightRoleEditDlg');
		this.rightRoleDeleteDlg = this.getChildByName('rightRoleDeleteDlg');
		this._paging = this.getChildByName(this.instanceName() + 'Paging');
		this._reloadList = this._reloadControl.bind(this, LIST_AREA);
		FirHelpers.doOnEnter(this, 'nameField', this._reloadList);
		this._subscr(function() {
			this._elems('searchBtn').on('click', this._reloadList);
			this._elems('addRoleBtn').on('click', this._onAddRoleBtn_click.bind(this));
			this._elems('roleList').on('click', this._onEditRoleBtn_click.bind(this));
		});
		this._unsubscr(function() {
			this._elems('searchBtn').off('click');
			this._elems('addRoleBtn').off('click');
			this._elems('roleList').off('click');
		});
		this.subscribe('onAfterLoad', function(ev, areaName, opts) {
			this._roleList = opts.roleList;
		});
		this.rightRoleEditDlg.subscribe('dialogControlDestroy', this._reloadList);
		this.rightRoleDeleteDlg.subscribe('dialogControlDestroy', this._reloadList);

		FirHelpers.managePaging({
			control: this,
			paging: this._paging,
			areaName: LIST_AREA
		});
	}, FirControl, {
		/** Нажатие по кнопке "Добавить" */
		_onAddRoleBtn_click: function() {
			this.rightRoleEditDlg.open({
				queryParams: {num: null}
			});
		},

		/** Нажатие по кнопкам редактирования или удаления у записей */
		_onEditRoleBtn_click: function(ev) {
			var el = $(ev.target).closest(this._elemClass('itemActionBtn'));
			if( !el || !el.length ) {
				return;
			}
			var
				action = el.data('mkkAction'),
				recordNum = parseInt(el.data('recordNum'), 10) || null;
			switch( action ) {
				case 'removeRole': {
					this.rightRoleDeleteDlg.open()
						.then(function(control) {
							control.once(
								'onDeleteConfirm',
								this._onDelete_confirmed.bind(this, recordNum));
						}.bind(this),
						function(err) {
							console.log(err);
						});
					break;
				}
				case 'editRole': {
					this.rightRoleEditDlg.open({
						queryParams: {num: recordNum}
					});
					break;
				}
				case 'selectRole': {
					this._notify('onRoleSelect', this._roleList.getRecord(recordNum));
				}
			}
		},

		/** Удаление записи подтверждено пользователем */
		_onDelete_confirmed: function(recordNum) {
			json_rpc.invoke({
				uri: "/jsonrpc/",
				method: 'right.role.delete',
				params: {num: recordNum},
				success: function(res) {
					this.rightRoleDeleteDlg.close();
				}.bind(this),
				error: function(res) {
					console.error(res);
				}
			});
		},

		/** Возвращает параметры для вызова метода списка правил доступа */
		_getQueryParams: function(areaName) {
			return {
				name: this._elems('nameField').val(),
				nav: this._paging.getNavParams()
			};
		},
		_getViewParams: function() {
			return {
				isSelect: this._isSelect
			}
		}
	}
);
});