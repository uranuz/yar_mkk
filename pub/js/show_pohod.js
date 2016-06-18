var mkk_site = mkk_site || {};

mkk_site.ShowPohodTable = (function(_super) {
	__extends(ShowPohodTable, _super);
	
	function ShowPohodTable(opts) {
		opts = opts || {};
		opts.controlTypeName = 'mkk_site.ShowPohodTable';
		_super.call(this, opts);

		this._elems().filter(".e-show_participants_btn")
			.on( "click", this.onParticipantsBtnClick.bind(this) );
	}
	return __mixinProto(ShowPohodTable, {
		onParticipantsBtnClick: function(ev) {
			var
				el = $(ev.currentTarget);

			webtank.json_rpc.invoke({
				uri: "/dyn/jsonrpc/",  //Адрес для отправки 
				method: "mkk_site.show_pohod.participantsList", //Название удалённого метода для вызова в виде строки
				params: {"pohodNum": +el.data("pohodNum")} , //Параметры вызова удалённого метода
				success: this.showParticipantsDialog.bind(this) //Обработчик успешного вызова удалённого метода
			});
		},
		showParticipantsDialog: function(data) {
			var 
				//Создаем контейнер для списка участников
				touristList = $('<div id="gruppa" title="Участники похода"></div>');

			//Вставка текста в слой списка участников
			touristList.html(data)
				.appendTo("body")
				.dialog( { modal: true, width: 450 } );
		}
	});
})(webtank.ITEMControl);

mkk_site.PohodNavigation = (function(_super) {
	__extends(PohodNavigation, _super);

	function PohodNavigation( opts ) {
		opts = opts || {};
		opts.controlTypeName = 'mkk_site.PohodNavigation';
		_super.call(this, opts);

		this._elems().filter(".e-print_page_btn")
			.on( "click", this.onPrintPageBtnClick.bind(this) );
	}

	return __mixinProto( PohodNavigation, {
		onPrintPageBtnClick: function() {
			this._elems().filter(".e-for_print_input").val("on");
			this._elems().filter(".e-form")[0].submit();
		}
	});
})(webtank.ITEMControl);

mkk_site.PohodFilterCheckBoxList = (function(_super) {
	__extends(PohodFilterCheckBoxList, _super);

	function PohodFilterCheckBoxList( opts ) {
		opts = opts || {};
		opts.controlTypeName = 'mkk_site.PohodFilterCheckBoxList';
		_super.call(this, opts);

		this._block = this._elems().filter(".e-block");
		this._allCheckBox = $('<input>', {
			type: "checkbox",
			class: this.instanceHTMLClass() + ' e-all_checkbox'
		})
		.prependTo(this._block)
		.on( 'click', this.onAllCheckBoxClick.bind(this) );

		this._itemLabels = this._elems().filter('.e-item_label')
			.on( 'click', this.onItemClick.bind(this) );
		this._checkboxes = this._elems().filter('.e-item_input');
	}

	return __mixinProto( PohodFilterCheckBoxList, {
		onAllCheckBoxClick: function() {
			for( var i = 0; i < this._checkboxes.length; ++i ) {
				checkbox = $(this._checkboxes[i]);
				checkbox.prop( 'checked', this._allCheckBox.prop( 'checked' ) );
			}
		},
		onItemClick: function(ev) {
			var
				allChecked = true,
				allUnchecked = true,
				checkbox;

			for( var i = 0; i < this._checkboxes.length; ++i ) {
				checkbox = $(this._checkboxes[i]);
				if( checkbox.prop('checked') ) {
					allUnchecked = false;
				} else {
					allChecked = false;
				}
				if( !allUnchecked && !allChecked )
					break;
			}

			if( !allChecked && !allUnchecked ) {
				this._allCheckBox.prop( 'indeterminate', true );
			} else {
				this._allCheckBox.prop( 'indeterminate', false );
				if( allUnchecked ) {
					this._allCheckBox.prop( 'checked', false );
				} else if( allChecked ) {
					this._allCheckBox.prop( 'checked', true );
				}
			}
		}
	});
})(webtank.ITEMControl);

//Инициализация страницы
$(window.document).ready( function() {
	var
		filterCtrlNames = [
			'pohod_filter_vid',
			'pohod_filter_ks',
			'pohod_filter_prepar',
			'pohod_filter_stat'
		],
		filterCtrlName;
	mkk_site.show_pohod_table = new mkk_site.ShowPohodTable({
		controlName: "show_pohod_table"
	});
	mkk_site.show_pohod = new mkk_site.PohodNavigation({
		controlName: "pohod_navigation"
	});

	for( var i = 0; i < filterCtrlNames.length; ++i ) {
		filterCtrlName = filterCtrlNames[i];
		mkk_site[filterCtrlName] = new mkk_site.PohodFilterCheckBoxList({
			controlName: filterCtrlName
		});
	}
});