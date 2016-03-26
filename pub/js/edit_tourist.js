mkk_site = mkk_site || {
	version: "0.0"
};

//Инициализация страницы
$(window.document).ready( function() {
	mkk_site.edit_tourist = new EditTourist();
} );

EditTourist = (function(_super){
	__extends(EditTourist, _super);
	
	function EditTourist()
	{
		_super.call(this);
		
		var self = this;
		this.elems = $(".b-edit_tourist");
		this.$el(".e-submit_btn").click( function(ev) { self.sendButtonClick($(this), ev); } )
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
		
		sendButtonClick: function(el) {
			var
				self = this,
				touristKey = NaN,
				touristForm = this.$el(".e-tourist_form"),
				birthYear = parseInt(this.$el(".e-birth_year").val(), 10);

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
})(webtank.WClass);