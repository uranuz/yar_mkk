define('mkk/Right/Role/List/List', [
	'fir/controls/FirControl',
	'fir/controls/Mixins/Navigation',
	'fir/network/json_rpc',
	'fir/common/helpers',
	'css!mkk/Right/Role/List/List'
], function (FirControl, NavigationMixin, json_rpc, helpers) {
return FirClass(
	function RightRoleList(opts) {
		this.superctor(RightRoleList, opts);
		this._navigatedArea = 'listView';
		this.rightRoleEditDlg = this.getChildByName('rightRoleEditDlg');
		this.rightRoleDeleteDlg = this.getChildByName('rightRoleDeleteDlg');
		this._subscr(function() {
			helpers.doOnEnter(this._elems('nameField'), this._onStartSearchBtn_click.bind(this));
			this._elems('searchBtn').on('click', this._onStartSearchBtn_click.bind(this));
			this._elems('addRoleBtn').on('click', this._onAddRoleBtn_click.bind(this));
			this._elems('roleList').on('click', this._onEditRoleBtn_click.bind(this));
		});
		this._unsubscr(function() {
			this._elems('nameField').off('keyup');
			this._elems('searchBtn').off('click');
			this._elems('addRoleBtn').off('click');
			this._elems('roleList').off('click');
		});
		this.subscribe('onAfterLoad', function(ev, areaName, opts) {
			this._roleList = opts.roleList;
		});
		this.rightRoleEditDlg.subscribe('dialogControlDestroy', this._onSetCurrentPage.bind(this));
		this.rightRoleDeleteDlg.subscribe('dialogControlDestroy', this._onSetCurrentPage.bind(this));
	}, FirControl, [NavigationMixin], {
		_onStartSearchBtn_click: function() {
			this._reloadControl(this._navigatedArea);
		},

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
					this.rightRoleDeleteDlg.once(
						'dialogControlLoad',
						this._onDeleteConfirmDlg_load.bind(this, recordNum));
					this.rightRoleDeleteDlg.open({
						viewParams: {
							deleteWhat: 'роли доступа'
						}
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

		/** Загрузка диалога подтверждения удаления записи */
		_onDeleteConfirmDlg_load: function(recordNum, ev, confirmControl) {
			confirmControl.once(
				'onDeleteConfirm',
				this._onDelete_confirmed.bind(this, recordNum));
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
				nav: this.getNavParams()
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