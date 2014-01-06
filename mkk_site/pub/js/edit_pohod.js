mkk_site = {
	version: "0.0"
};

//Инициализация страницы
$(window.document).ready( function() {
	
	
} );

mkk_site.edit_pohod = {
	selTouristsRS: null, //RecordSet с выбранными в поиске туристами

	//Вывод списка туристов из набора записей (rs) в контейнер (container)
	renderTouristList: function(rs, container) {
		var 
			rec,
			pohod = mkk_site.edit_pohod,
			touristListDiv = ( container ? container : $("<div>") );
		
		rs.rewind();
			
		while( rec = rs.next() )
		{	( function(_rec) {
				return $( "<div>", {
					text: _rec.get("family_name") + " " + _rec.get("given_name") + " " 
						+ _rec.get("patronymic") + ", " + _rec.get("birth_year") + " г.р"
				} )
				.on( "click", _rec, pohod.onTouristDivClick )
				.appendTo(touristListDiv);
			} )(rec);
		}
		
		return touristListDiv;
	},
	
	//Получение списка туристов для
	searchForTourist: function() {
		var
			pohod = mkk_site.edit_pohod;
			
		$("#tourist_search_div").empty();
			
		webtank.json_rpc.invoke({
			uri: "/jsonrpc/",
			method: "mkk_site.edit_pohod.getTouristList",
			params: { "фамилия": $("#tourist_search_inp").val() },
			success: function(responseJSON) {
				var
					rs = webtank.datctrl.fromJSON(responseJSON);
					
				mkk_site.edit_pohod.renderTouristList(rs, $("#tourist_search_div"));
			}
		});
	},
	onTouristDivClick: function(event) {
		var 
			rec = event.data,
			$touristDiv = $(this),
			pohod = mkk_site.edit_pohod;
		
		//Перемещение DOM узла между окнами
		$touristDiv.appendTo(  (
				$touristDiv.parent().attr("id") === "tourist_search_div" ?
				"#tourist_select_div" : "#tourist_search_div"
			)
		);
		
		//TODO: Убрать потом, наверное
		if( !pohod.selTouristsRS )
		{	pohod.selTouristsRS = new webtank.datctrl.RecordSet();
			pohod.selTouristsRS._fmt = rec._fmt;
		}
		
		if( pohod.selTouristsRS.hasKey( rec.getKey() ) ) {
			pohod.selTouristsRS.remove( rec.getKey() );
		} else {
			pohod.selTouristsRS.append( rec );
		}
		
	},
	onTouristSelWinOkBtnCLick: function() {
		var 
			unitNeimInput = $("#unit_neim")[0],
			searchWindow = $("#tourist_select_window"),
			windowContent = $(searchWindow).children(".modal_window_content"),
			pohod = mkk_site.edit_pohod;
			
		$("#unit_div").empty();
		unitNeimInput.value = "";
		
		if( !pohod.selTouristsRS )
		{	$(searchWindow).remove();
			$(".modal_window_blackout").remove();
			return;
		}
		
		pohod.selTouristsRS.rewind();
		while( rec = pohod.selTouristsRS.next() )
		{	( function(_rec) {
				unitNeimInput.value += ( unitNeimInput.value.length ? "," : "" ) + _rec.getKey();
				$( "<div>", {
						text: rec.get("family_name") + " " + rec.get("given_name") + " " 
					+ rec.get("patronymic") + ", " + rec.get("birth_year") + " г.р"
					}
				)
// 					.on( "click", function() {
// 						pohod.onTouristDivClick.call(touristDiv, _rec);
// 					})
				.appendTo("#unit_div");
			} )(rec);
		}
		
		$(searchWindow).remove();
		$(".modal_window_blackout").remove();
	},
	openParticipantsEditWindow: function() {
		var 
			pohod = mkk_site.edit_pohod,
			searchWindow = webtank.wui.createModalWindow(),
			windowContent = $(searchWindow).children(".modal_window_content"),
			touristSearchDiv = $("<div>", {
				id: "tourist_search_div"
			}),
			touristSearchInp = $("<input>", {
				type: "text",
				id: "tourist_search_inp"
			}),
			touristSearchButton = $("<input>", {
				type: "button",
				value: "Найти"
			}),
			okButton = $("<input>", {
				type: "button",
				value: "     OK     "
			}),
			touristSelectDiv = $("<div>", {
				id: "tourist_select_div"
			});
		
		if( pohod.selTouristsRS )
			pohod.renderTouristList(pohod.selTouristsRS, touristSelectDiv);
		
		$(touristSearchButton)
		.on( "click", mkk_site.edit_pohod.searchForTourist ); 
		
		//Подтверждение выбора группы
		$(okButton).on( "click", pohod.onTouristSelWinOkBtnCLick );
		
		searchWindow.id = "tourist_select_window";
		$(windowContent)
		.append(touristSearchInp)
		.append(touristSearchButton)
		.append(okButton)
		.append(touristSearchDiv)
		.append(touristSelectDiv);
	}
};
