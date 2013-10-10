mkk_site = {
	version: "0.0"
};

mkk_site.edit_pohod = {
	selectedTouristsRS: null, //RecordSet с выбранными в поиске туристами
	//Получение списка туристов для
	searchForTourist: function() {
		var 
			searchInp = $("#tourist_search_inp"),
			pohod = mkk_site.edit_pohod;
			
		webtank.json_rpc.invoke({
			uri: "/dyn/rpc",
			method: "турист.список_по_фильтру",
			params: searchInp.value,
			onresult: function(responseJSON) {
				var 
					container = $("#tourist_search_div"),
					rs = webtank.datctrl.fromJSON(responseJSON),
					fmt = rs.getFormat(),
					rec,
					touristDiv;
					
				while( rec = rs.next() )
				{	touristDiv = $("<div>", {
						onclick: function() {
							pohod.addTouristToGroup(rec);
						}
					});
					
					$(touristDiv).text( rec.get("family_name") + " "
						+ rec.get("given_name") + " " + rec.get("patronymic") + ", "
						+ rec.get("birth_year") + " г.р"
					);
					
					$(touristDiv).appendTo(container);
				}
				
// 				//Очистка контейнера
// 				for( var i = 0; i < container.children.length; i++ )
// 					container.removeChild( container.children[i] );
			}
		});
	},
	addTouristToGroup: function(rec) {
		var 
		touristSelectDiv = document.getElementById("tourist_select_div"),
		touristDiv = this;
			
		touristDiv.parentNode.removeChild(touristDiv);
		touristSelectDiv.appendChild(touristDiv);
		if( !touristSelectRS )
		{	selectedTouristsRS = new RecordSet();
			selectedTouristsRS._fmt = rec.getFormat();
			
			
		}
		
	},
	openParticipantsEditWindow: function() {
		var 
		searchWindow = webtank.wui.createModalWindow(),
		windowContent = $(searchWindow).children(".modal_window_content")[0];
		touristSearchDiv = $("<div/>", {
			id: "tourist_search_div"
		}),
		touristSearchInp = $("<input/>", {
			type: "text",
			id: "tourist_search_inp"
		}),
		touristSearchButton = $("<input/>", {
			type: "button",
			value: "Найти"
		}),
		touristSelectDiv = $("<div/>", {
			id: "tourist_select_div"
		});
		
		touristSearchButton.onclick = function() {
			mkk_site.edit_pohod.searchForTourist();
		};
		
		searchWindow.id = "tourists_win";
		$(windowContent).append(touristSearchInp);
		$(windowContent).append(touristSearchButton);
		$(windowContent).append(touristSearchDiv);
		$(windowContent).append(touristSelectDiv);
	}
};