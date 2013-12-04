//Определяем пространство имён библиотеки
var webtank = {
	version: "0.0",
	inherit: function (proto) {
		function F() {}
		F.prototype = proto;
		var object = new F;
		return object;
	},
	//Глубокая копия объекта
	deepCopy: function(o) {
		if( !0 || typeof o !== "object" )
			return o;
		else
			return jQuery.extend(true, {}, o);
	},
	//Поверхностная копия объекта (если свойства объекта
	//являются объектами, то копируются лишь ссылки)
	copy: function(o) {
		return jQuery.extend({}, o);
	},
	isInteger: function(num) {
		return Math.max(0, num) === num;
	},
	isUnsigned: function(num) {
		return Math.round(num) === num;
	},
	getXMLHTTP: function() {
		var xmlhttp;
		try {
			xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
		} catch (e) {
			try {
				xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
			} catch (E) {
				xmlhttp = false;
			}
		}
		if (!xmlhttp && typeof XMLHttpRequest!='undefined') {
			xmlhttp = new XMLHttpRequest();
		}
		return xmlhttp;
	},
	parseGetParams: function () { 
		var $_GET = {}; 
		var __GET = window.location.search.substring(1).split("&"); 
		for(var i=0; i<__GET.length; i++) { 
			var getVar = __GET[i].split("="); 
			$_GET[getVar[0]] = typeof(getVar[1])=="undefined" ? "" : getVar[1]; 
		} 
		return $_GET; 
	} 
};



//Определяем пространство имен для JSON-RPC
webtank.json_rpc = 
{	defaultInvokeArgs:  //Аргументы по-умолчанию для вызова ф-ции invoke
	{	uri: "/",  //Адрес для отправки
		method: null, //Название удалённого метода для вызова в виде строки
		params: null, //Параметры вызова удалённого метода
		success: null, //Обработчик успешного вызова удалённого метода
		error: null,  //Обработчик ошибки
		complete: null, //Обработчик завершения (после success или error)
		id: null //Идентификатор соединения
	},
	_counter: 0,
	_responseQueue: [null],
	_generateId: function(args)
	{	return webtank.json_rpc._counter++;
	},
	invoke: function(args) //Функция вызова удалённой процедуры
	{	var 
			undefined = ( function(undef){ return undef; })(),
			_defArgs = webtank.json_rpc.defaultInvokeArgs,
			_args = _defArgs;
		
		if( args )
			_args = args;
		
		_args.params = webtank.json_rpc._processParams(_args.params);

		var xhr = webtank.getXMLHTTP();
		xhr.open( "POST", _args.uri, true );
		xhr.setRequestHeader("content-type", "application/json-rpc");
		//
		xhr.onreadystatechange = function() {	webtank.json_rpc._handleResponse(xhr); }
		var idStr = "";
		if( _args.error || _args.success || _args.complete )
		{	if( !_args.id )
				_args.id = webtank.json_rpc._generateId(_args);
			webtank.json_rpc._responseQueue[_args.id] = _args;
			idStr = ',"id":"' + _args.id + '"';
		}
		xhr.send( '{"jsonrpc":"2.0","method":"' + _args.method + '","params":' + _args.params + idStr + '}' );
	},
	_handleResponse: function(xhr) 
	{	if( xhr.readyState === 4 ) 
		{	var 
				responseJSON = JSON.parse(xhr.responseText),
				invokeArgs = null;
			
			if( responseJSON.id )
			{	invokeArgs = webtank.json_rpc._responseQueue[responseJSON.id];
				if( invokeArgs )
				{	delete webtank.json_rpc._responseQueue[responseJSON.id];
					if( responseJSON.error )
					{	if( invokeArgs.error )
							invokeArgs.error(responseJSON);
						else
						{	console.error("Ошибка при выполнении удалённого метода");
							console.error(responseJSON.error.toString());
						}
					}
					else
					{	if( invokeArgs.success )
							invokeArgs.success(responseJSON.result);
					}
					if( invokeArgs.complete )
						invokeArgs.complete(responseJSON);
				}
			}
		}
	},
	_processParams: function(params) {
		if( typeof params === "object" )
			return JSON.stringify(params);
		else if( (typeof params === "function") || (typeof params === "undefined") )
			return '"null"';
		else if( typeof params === "string" )
			return '"' + params + '"';
		else //Для boolean, number
			return params; 
	}
};

webtank.wui = {
	createModalWindow: function()
	{	var 
			doc = window.document,
			blackout_div = doc.createElement("div"),
			window_div = doc.createElement("div"),
			window_header_div = doc.createElement("div"),
			content_div = doc.createElement("div"),
			close_btn = doc.createElement("a"),
			title = doc.createElement("span"),
			body = doc.getElementsByTagName("body")[0];
		
		blackout_div.className = "modal_window_blackout";
		window_div.className = "modal_window";
		window_header_div.className = "modal_window_header";
		content_div.className = "modal_window_content";
		title.className = "modal_window_title";
		close_btn.className = "modal_window_close_btn";
		
		close_btn.innerText = "Закрыть";
		title.innerText = "Текст заголовка";

		close_btn.onclick = function() {
			body.removeChild(window_div);
			body.removeChild(blackout_div);
		}
		
		//Создаём структуру модального окна
		window_header_div.appendChild(title);
		window_header_div.appendChild(close_btn);
		window_div.appendChild(window_header_div);
		window_div.appendChild(content_div);
		
		body.appendChild(blackout_div);
		body.appendChild(window_div);
		
		return window_div;
	}
}


webtank.datctrl = {
	Record: function() {
		var dctl = webtank.datctrl;
		//Создаём Record
		var rec = {
			_fmt: null, //Формат записи (RecordFormat)
			_d: [], //Данные (массив)
			//Метод получения значения из записи по имени поля
			get: function(index) {
				if( webtank.isUnsigned(index) )
				{	//Вдруг там массив - лучше выдать копию
					return webtank.deepCopy( rec._d[ index ] );
				}
				else
				{	//Вдруг там массив - лучше выдать копию
					return webtank.deepCopy( rec._d[ rec._fmt.getIndex(index) ] );
				}
			},
			getLength: function() {
				return rec._d.length;
			},
			getFormat: function() {
				return webtank.deepCopy( rec._fmt );
			},
			getKey: function() {
				return rec._d[ rec._fmt._keyFieldIndex ];
			},
			getKeyFieldIndex: function() {
				return rec._fmt._keyFieldIndex;
			},
			set: function() {
				
			}
		};
		return rec;
	},
	//
	RecordSet: function() {
		var
			dctl = webtank.datctrl;
		//Создаём RecordSet
		var rs = {
			_fmt: null, //Формат записи (RecordFormat)
			_d: [], //Данные (двумерный массив)
			_recIndex: 0,
			//Возращает след. запись или null, если их больше нет
			next: function() {
				if( rs._recIndex >= rs._d.length )
					return null;
				else {
					var rec = new dctl.Record();
					rec._d = webtank.deepCopy( rs._d[rs._recIndex] );
					rec._fmt = webtank.deepCopy( rs._fmt );
					rs._recIndex++;
					return rec;
				}
			},
			//Возвращает true, если есть ещё записи, иначе - false
			hasNext: function() {
				return (rs._recIndex < rs._d.length);
			},
			//Сброс итератора на начало
			rewind: function() {
				_recIndex = 0;
			},
			getFormat: function()
			{	return webtank.deepCopy(rs._fmt);
			},
			getLength: function() {
				return rs._d.length;
			},
// 			getRecord: function(key) {
// 				return rs.getRecordAt( rs._fmt._indexes[key] )
// 			},
			getRecordAt: function(index) {
				var rec = new dctl.Record();
				rec._d = webtank.deepCopy( rs._d[rs.index] );
				rec._fmt = webtank.deepCopy( rs._fmt );
			},
			getKey: function(index) {
				return rs._d[ rs._fmt._keyFieldIndex ][index];
			},
			hasKey: function(key) {
				for( var i = 0; i < rs._d.length; i++ ) {
					if( rs._d[i][ rs._fmt._keyFieldIndex ] === key )
						return true;
				}
				return false;
			},
			getKeyFieldIndex: function() {
				return rs._fmt._keyFieldIndex;
			},
			append: function(rec) {
				if( rs._fmt.equals(rec._fmt) )
					rs._d.push(rec._d);
				else
					console.error("Формат записи не совпадает с форматом набора данных!!!");
			},
			remove: function(key) {
				for( var i=0; i < rs._d.length; i++)
				{	if( rs._d[i][ rs._fmt._keyFieldIndex ] === key )
						return rs._d.splice(i, 1);
				}
				console.error("Запись с ключом " + key + " не содержится в наборе данных!!!");
			}
		};
		return rs;
	},
	RecordFormat: function() {
		var 
			dctl = webtank.datctrl;
		//Создаём формат записи
		var fmt = {
			_f: [],
			_indexes: {},
			_keyFieldIndex: 0,
			//Функция расширяет текущий формат, добавляя к нему format
			extend: function(format) {
				for( var i=0; i<format._f.length; i++ )
				{	fmt._f.push(format._f[i]);
					fmt._indexes[format.n] = format._f.length;
				}
			},
			//Получить индекс поля по имени
			getIndex: function(name) {
				return fmt._indexes[name];
			},
			//Получить имя поля по индексу
			getName: function(index) {
				return fmt._f[ index ].n;
			},
			//Получить тип поля по имени или индексу
			getType: function(index) {
				if( webtank.isUnsigned(index) )
					return fmt._f[ index ].t;
				else
					return fmt._f[ fmt.getFieldIndex(index) ].t;
			},
			getKeyFieldIndex: function() {
				return fmt._keyFieldIndex;
			},
			equals: function(format) {
				return fmt._f.length === format._f.length;
			}
		}
		return fmt;
	},
	//трансформирует JSON в Record или RecordSet
	fromJSON: function(json) {
		var 
			dctl = webtank.datctrl,
			jsonObj = json;
		
		if( jsonObj.t === "record" || jsonObj.t === "recordset" )
		{	var fmt = new dctl.RecordFormat();
			
			fmt._f = jsonObj.f;
			fmt._keyFieldIndex = jsonObj.kfi || 0;
			
			for( var i = 0; i < jsonObj.f.length; i++ )
				fmt._indexes[ jsonObj.f[i].n ] = i;
				
			if( jsonObj.t === "record" )
			{	var rec = new dctl.Record();
				rec._fmt = fmt;
				rec._d = jsonObj.d;
				return rec;
			}
			else if( jsonObj.t === "recordset" )
			{	var rs = new dctl.RecordSet();
				rs._fmt = fmt;
				rs._d = jsonObj.d;
				return rs;
			}
		}
			
	}
}

