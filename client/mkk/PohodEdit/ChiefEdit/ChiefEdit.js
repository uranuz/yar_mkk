define('mkk/PohodEdit/ChiefEdit/ChiefEdit', [
	'fir/controls/FirControl'
], function (FirControl) {
	__extends(ChiefEdit, FirControl);

	//Инициализация блока редактирования руководителя и зам. руководителя похода
	function ChiefEdit(opts)
	{
		FirControl.call(this, opts);
		var self = this;

		this._searchBlock = this.getChildInstanceByName('chiefSearchArea');
		this._controlBar = this._elems('controlBar');
		this.isAltChef = opts.isAltChief;
		this.chefRec = null;

		//Тык по кнопке удаления зам. руководителя похода
		this._elems("deleteBtn").on("click", function() {
			self.$trigger('deleteChef', [self]);
			self.closeDialog();
		});
		
		this._container.on("dialogclose", this.onDialogClose.bind(this));
	}
	
	return __mixinProto(ChiefEdit, {
		//"Тык" по кнопке выбора руководителя или зама похода
		onSelectChef: function(ev, el, rec) {
			this.chefRec = rec;
			this.$trigger("selectChef", [this, rec]);
			this.closeDialog();
		},
		
		onDeleteChef: function(ev, el) {
			this.chefRec = null;
			this.trigger("selectChef", [this]);
			this.closeDialog();
		},
		
		openDialog: function(record, isAltChef)
		{
			var dlgTitle = "";
			this.chefRec = record;
			if( isAltChef != null ) {
				this.isAltChef = isAltChef;
			}
			if( isAltChef ) {
				this._controlBar.show();
				dlgTitle = 'Выбор зам. руководителя';
			} else {
				this._controlBar.hide();
				dlgTitle = 'Выбор руководителя';
			}
			this._searchBlock.activate(this._elems("searchBlock"));
			this._searchBlock.subscribe('itemSelect', this.onSelectChef.bind(this));
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