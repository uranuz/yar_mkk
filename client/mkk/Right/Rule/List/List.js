define('mkk/Right/Rule/List/List', [
	'fir/controls/FirControl',
	'fir/common/helpers',
	'fir/network/json_rpc',
	'css!mkk/Right/Rule/List/List'
], function (FirControl, FirHelpers, json_rpc) {
return FirClass(
	function RightRuleList(opts) {
		this.superctor(RightRuleList, opts);
		this._navigatedArea = 'listView';
		this.rightRuleEditDlg = this.getChildByName('rightRuleEditDlg');
		this.rightRuleDeleteDlg = this.getChildByName('rightRuleDeleteDlg');
		this._paging = this.getChildByName(this.instanceName() + 'Paging');
		this._reloadList = this._reloadControl.bind(this, 'listView');
		FirHelpers.doOnEnter(this, 'nameField', this._reloadList);
		this._subscr(function() {
			this._elems('searchBtn').on('click', this._reloadList);
			this._elems('addRuleBtn').on('click', this._onAddRuleBtn_click.bind(this));
			this._elems('ruleList').on('click', this._onEditRuleBtn_click.bind(this));
		});
		this._unsubscr(function() {
			this._elems('searchBtn').off('click');
			this._elems('addRuleBtn').off('click');
			this._elems('ruleList').off('click');
		});
		this.subscribe('onAfterLoad', function(ev, areaName, opts) {
			this._ruleList = opts.ruleList;
		});
		this.rightRuleEditDlg.subscribe('dialogControlDestroy', this._reloadList);
		this.rightRuleDeleteDlg.subscribe('dialogControlDestroy', this._reloadList);

		FirHelpers.managePaging({
			control: this,
			paging: this._paging,
			areaName: 'listView'
		});
	}, FirControl, {
		/** Нажатие по кнопке "Добавить" */
		_onAddRuleBtn_click: function() {
			this.rightRuleEditDlg.open({
				queryParams: {num: null}
			});
		},

		/** Нажатие по кнопкам редактирования или удаления у записей */
		_onEditRuleBtn_click: function(ev) {
			var el = $(ev.target).closest(this._elemClass('itemActionBtn'));
			if( !el || !el.length ) {
				return;
			}
			var
				action = el.data('mkkAction'),
				recordNum = parseInt(el.data('recordNum'), 10) || null;
			switch( action ) {
				case 'removeRule': {
					this.rightRuleDeleteDlg.once(
						'dialogControlLoad',
						this._onDeleteConfirmDlg_load.bind(this, recordNum));
					this.rightRuleDeleteDlg.open({
						viewParams: {
							deleteWhat: 'правила доступа'
						}
					});
					break;
				}
				case 'editRule': {
					this.rightRuleEditDlg.open({
						queryParams: {num: recordNum}
					});
					break;
				}
				case 'selectRule': {
					this._notify('onRuleSelect', this._ruleList.getRecord(recordNum));
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
				method: 'right.rule.delete',
				params: {num: recordNum},
				success: function(res) {
					this.rightRuleDeleteDlg.close();
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