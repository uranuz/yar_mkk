var mkk_site = mkk_site || {
	version: "0.0"
};

mkk_site.EditTourist = (function(_super){
	__extends(EditTourist, _super);
	
	function EditTourist()
	{
		_super.call(this);
		
		var self = this;
		this.elems = $(".b-edit_tourist");
		this.$el(".e-submit_btn").click( this.sendButtonClick.bind(this) )

		this.birthDatePicker = new webtank.ui.PlainDatePicker({
			controlName: "birth_date"
		});
	}
	
	return __mixinProto(EditTourist, {
		processSimilarTourists: function(data) {
			var
				touristForm = this.$el(".e-tourist_form"),
				dialog = this.$el(".e-similars_dlg").dialog({title: "Редактирование туриста", modal: true});

			if( data )
			{
				this.$el(".e-similars_list").html(data);
				this.$el(".e-force_submit_btn").click( function() { touristForm.submit(); });
			}
			else
				touristForm.submit();
		},

		showErrorDialog: function( errorMsg ) {
			$('<div title="Ошибка ввода">' + errorMsg + '</div>').dialog({ modal: true, width: 350 });
		},

		// Проверка данных формы
		validateFormData: function() {
			var
				self = this,
				birthYear = this.birthDatePicker.rawYear(),
				birthMonth = this.birthDatePicker.rawMonth(),
				birthDay = this.birthDatePicker.rawDay();

			if( birthDay.length && !mkk_site.checkInt( birthDay, 1, 31 ) ) {
				self.showErrorDialog( 'День рождения должен быть целым числом в диапазоне [1, 31]' );
				return false;
			}

			if( birthYear.length && !mkk_site.checkInt( birthYear, 1000, 9999 ) ) {
				self.showErrorDialog( 'Год рождения похода должен быть четырехзначным целым числом' );
				return false;
			}

			return true;
		},
		
		sendButtonClick: function(ev) {
			var
				self = this,
				el = $(ev.target),
				touristKey = NaN,
				touristForm = this.$el(".e-tourist_form"),
				birthYear = parseInt(this.$el(".e-birth_year").val(), 10);

			if( !self.validateFormData() ) {
				ev.preventDefault();
				return;
			}

			if( isNaN(birthYear) )
				birthYear = null;
			
			try {
				touristKey = parseInt( webtank.parseGetParams().key );
			} catch(e) { touristKey = NaN; }
			
			if( isNaN(touristKey) )
			{	//Добавление нового
				webtank.json_rpc.invoke({
					uri: "/jsonrpc/",
					method: "mkk_site.edit_tourist.тестНаличияПохожегоТуриста",
					params: {
						"имя": this.$el(".e-given_name").val(),
						"фамилия": this.$el(".e-family_name").val(),
						"отчество": this.$el(".e-patronymic").val(),
						"годРожд": birthYear
					},
					success: function(data){ self.processSimilarTourists(data); }
				});
			}
			else
			{	//Редактирование существующего
				touristForm.submit();
			}
		}
	});
})(webtank.ITEMControl);

//Инициализация страницы
$(window.document).ready( function() {
	mkk_site.edit_tourist = new mkk_site.EditTourist();
} );