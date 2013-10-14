mkk_site = {
	version: "0.0"
};

//Инициализация страницы
$(window.document).ready( function() {
	
	
} );

mkk_site.edit_pohod = {
	selTouristKeys: [], //RecordSet с выбранными в поиске туристами
	//Получение списка туристов для
	searchForTourist: function() {
		var
			pohod = mkk_site.edit_pohod;
			
		$("#tourist_search_div").empty();
		selTouristKeys = [];
			
		webtank.json_rpc.invoke({
			uri: "/dyn/rpc",
			method: "турист.список_по_фильтру",
			params: $("#tourist_search_inp").val(),
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
						.text( rec.get("family_name") + " " + rec.get("given_name") + " " 
							+ rec.get("patronymic") + ", " + rec.get("birth_year") + " г.р"
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
		
// 		if( )
		
		//Перемещение DOM узла между окнами
		$(touristDiv).appendTo(  (
				touristDivParent.id === "tourist_search_div" ?
				"#tourist_select_div" : "#tourist_search_div"
			)
		);
		
		var 
			keysArrayIndex = pohod.selTouristKeys.indexOf( rec.getKey() );
		
		if( keysArrayIndex === -1 ) {
			pohod.selTouristKeys.splice(-1, 0, rec.getKey() );
		} else {
			pohod.selTouristKeys.splice(keysArrayIndex, 1);
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
		окButton = $("<input>", {
			type: "button",
			value: "OK"
		})[0],
		touristSelectDiv = $("<div>", {
			id: "tourist_select_div"
		})[0];
		
		$(touristSearchButton).on( "click", function() { 
			mkk_site.edit_pohod.searchForTourist(); 
		} );
		
		//Подтверждение выбора группы
		$(okButton).on( "click", function() { 
			
			
			
		} );
		
		searchWindow.id = "tourists_win";
		$(windowContent).append(touristSearchInp);
		$(windowContent).append(touristSearchButton);
		$(windowContent).append(touristSearchDiv);
		$(windowContent).append(touristSelectDiv);
	}
};
