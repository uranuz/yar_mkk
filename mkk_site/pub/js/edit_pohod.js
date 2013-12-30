mkk_site = {
	version: "0.0"
};

//Инициализация страницы
$(window.document).ready( function() {
	
	
} );

mkk_site.edit_pohod = {
	selTouristsRS: null, //RecordSet с выбранными в поиске туристами
	//Получение списка туристов для
	searchForTourist: function() {
		var
			pohod = mkk_site.edit_pohod;
			
		$("#tourist_search_div").empty();
		selTouristKeys = [];
			
		webtank.json_rpc.invoke({
			uri: "/jsonrpc/",
			method: "mkk_site.edit_pohod.getTouristList",
			params: { "фамилия": $("#tourist_search_inp").val() },
			success: function(responseJSON) {
				var
					rs = webtank.datctrl.fromJSON(responseJSON),
					fmt = rs.getFormat(),
					rec;
					
				while( rec = rs.next() )
				{	(function(touristDiv, _rec) {

						$(touristDiv)
						.on( "click", function() {
							pohod.toggleTouristSelState.call(touristDiv, _rec);
						})
						.text( _rec.get("family_name") + " " + _rec.get("given_name") + " " 
							+ _rec.get("patronymic") + ", " + _rec.get("birth_year") + " г.р"
						)
						.appendTo("#tourist_search_div");
					})( $("<div>")[0], rec );
				}
				
// 				//Очистка контейнера
// 				for( var i = 0; i < container.children.length; i++ )
// 					container.removeChild( container.children[i] );
			}
		});
	},
	toggleTouristSelState: function(rec) {
		var 
// 		touristSelectDiv = document.getElementById("tourist_select_div"),
		touristDiv = this,
		touristDivParent = touristDiv.parentNode,
		pohod = mkk_site.edit_pohod;
		
		//Перемещение DOM узла между окнами
		$(touristDiv).appendTo(  (
				touristDivParent.id === "tourist_search_div" ?
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
	openParticipantsEditWindow: function() {
		var 
		searchWindow = webtank.wui.createModalWindow(),
		windowContent = $(searchWindow).children(".modal_window_content")[0],
		touristSearchDiv = $("<div>", {
			id: "tourist_search_div"
		})[0],
		touristSearchInp = $("<input>", {
			type: "text",
			id: "tourist_search_inp"
		})[0],
		touristSearchButton = $("<input>", {
			type: "button",
			value: "Найти"
		})[0],
		okButton = $("<input>", {
			type: "button",
			value: "     OK     "
		})[0],
		touristSelectDiv = $("<div>", {
			id: "tourist_select_div"
		})[0],
		pohod = mkk_site.edit_pohod;
		
		$(touristSearchButton).on( "click", function() { 
			mkk_site.edit_pohod.searchForTourist(); 
		} );
		
		//Подтверждение выбора группы
		$(okButton).on( "click", function() { 
			var 
				unitDiv = $("#unit_div")[0],
				unitNeimInput = $("#unit_neim")[0];
				
			$(unitDiv).empty();
			unitNeimInput.value = "";
			
			pohod.selTouristsRS.rewind();
			while( rec = pohod.selTouristsRS.next() )
			{	(function(touristDiv, _rec) {
					unitNeimInput.value += ( unitNeimInput.value.length ? "," : "" ) + _rec.getKey();
					$(touristDiv)
// 					.on( "click", function() {
// 						pohod.toggleTouristSelState.call(touristDiv, _rec);
// 					})
					.text( rec.get("family_name") + " " + rec.get("given_name") + " " 
						+ rec.get("patronymic") + ", " + rec.get("birth_year") + " г.р"
					)
					.appendTo("#unit_div");
				})( $("<div>")[0], rec );
			}
			
			$(searchWindow).remove();
			$(".modal_window_blackout").remove();
			
		} );
		
		searchWindow.id = "tourists_win";
		$(windowContent)
		.append(touristSearchInp)
		.append(touristSearchButton)
		.append(okButton)
		.append(touristSearchDiv)
		.append(touristSelectDiv);
	}
};
