mkk_site = {
	version: "0.0"
};

mkk_site.edit_pohod = {
	//Получение списка туристов для
	searchForTourist: function() {
		var searchInp = document.getElementById("tourist_search_inp")
		webtank.json_rpc.invoke({
			uri: "/dyn/rpc",
			method: "турист.список_по_фильтру",
			params: searchInp.value,
			onresult: function(responseJSON) {
				var 
					container = document.getElementById("tourist_search_div"),
					touristTable = document.createElement("table"),
					touristHeadTr = document.createElement("tr");
					
				
				for( i in responseJSON.f )
				{	var fieldTh = document.createElement("th");
					fieldTh.innerText = responseJSON.f[i].n;
					touristHeadTr.appendChild( fieldTh );
				}
				touristTable.appendChild(touristHeadTr);
				
				for( i in responseJSON.d )
				{	var
						rec = responseJSON.d[i],
						touristRecTr = document.createElement("tr");
					for( j in rec )
					{	var touristRecTd = document.createElement("td");
						touristRecTd.innerText = rec[j];
						touristRecTr.appendChild(touristRecTd);
					}
					touristTable.appendChild(touristRecTr);
				}
				
				container.appendChild(touristTable);
			}
		});
	},
	addTouristToGroup: function(touristData) {
		var 
			touristListDiv = document.getElementById("unit_div"),
			touristListInp = document.getElementById("unit_inp");
			
		touristListDiv.innerHTML += touristData.family_name + " " 
			+ touristData.given_name + " " + touristData.patronymic + ", "
			+ touristData.birth_year + " г.р";
		touristListInp.innerHTML += touristData.num;
		
	},
	openParticipantsEditWindow: function() {
		var 
			modWin = webtank.wui.createModalWindow(),
			touristSearchDiv = document.createElement("div"),
			touristSearchInp = document.createElement("input"),
			touristSearchButton = document.createElement("input");
			
		touristSearchInp.type = "text";
		touristSearchInp.id = "tourist_search_inp";
		touristSearchButton.type = "button";
		touristSearchButton.value = "Найти";
		touristSearchButton.onclick = function() {
			mkk_site.edit_pohod.searchForTourist();
		}
		modWin.window.id = "tourists_win";
		touristSearchDiv.id = "tourist_search_div";
		modWin.content.appendChild(touristSearchInp);
		modWin.content.appendChild(touristSearchButton);
		modWin.content.appendChild(touristSearchDiv);
		
	}
};