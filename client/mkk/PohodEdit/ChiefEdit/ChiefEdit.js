define('mkk/PohodEdit/ChiefEdit/ChiefEdit', [
	'fir/controls/FirControl'
], function (FirControl) {
	__extends(ChiefEdit, FirControl);

	//Инициализация блока редактирования руководителя и зам. руководителя похода
	function ChiefEdit(opts)
	{
		FirControl.call(this, opts);
		var self = this;

		this._searchBlock = this.getChildInstanceByName(this.instanceName() + 'SearchArea');
		this._controlBar = this._elems('controlBar');
		this.isAltChief = opts.isAltChief;
		this.chiefRec = null;

		//Тык по кнопке удаления зам. руководителя похода
		this._elems("deleteBtn").on("click", this.onDeleteChief.bind(this));
		this._container.on("dialogclose", this.onDialogClose.bind(this));
	}
	
	return __mixinProto(ChiefEdit, {
		//"Тык" по кнопке выбора руководителя или зама похода
		onSelectChief: function(ev, rec) {
			this.chiefRec = rec;
			this._notify("selectChief", rec);
			this.closeDialog();
		},
		
		onDeleteChief: function(ev) {
			this.chiefRec = null;
			this._notify("deleteChief");
			this.closeDialog();
		},
		
		openDialog: function(record, isAltChief)
		{
			var dlgTitle = "";
			this.chiefRec = record;
			if( isAltChief != null ) {
				this.isAltChief = isAltChief;
			}
			if( isAltChief ) {
				this._controlBar.show();
				dlgTitle = 'Выбор зам. руководителя';
			} else {
				this._controlBar.hide();
				dlgTitle = 'Выбор руководителя';
			}
			this._searchBlock.activate(this._elems("searchBlock"));
			this._searchBlock.subscribe('itemSelect', this.onSelectChief.bind(this));
			this._container.dialog({modal: true, minWidth: 400, title: dlgTitle});
		},
		
		closeDialog: function() {
			this._container.dialog('close');
		},
		
		onDialogClose: function() {
			this._searchBlock.unsubscribe('itemSelect');
			this._searchBlock.deactivate();
		}
	});
});