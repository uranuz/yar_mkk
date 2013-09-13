//Определяем пространство имён библиотеки
var webtank = {
	version: "0.0"
};

//Определяем пространство имен для JSON-RPC
webtank.json_rpc = {
	defaultInvokeArgs: { //Аргументы по-умолчанию для вызова ф-ции invoke
		url: "/",  //Адрес для отправки
		method: null, //Название удалённого метода для вызова в виде строки
		params: null, //Параметры вызова удалённого метода
		success: null, //Обработчик успешного вызова удалённого метода
		error: null,  //Обработчик ошибки
		id: null, //Идентификатор соединения
		generateId: true //Нужно ли генерировать id, если он пустой
	},
	invoke: function(args) { //Функция вызова удалённой процедуры
		var 
			undefined = ( function(undef){ return undef; })(),
			_defArgs = webtank.json_rpc.defaultInvokeArgs,
			_args = _defArgs;
		
		if( args !== null || args !== undefined )
			_args = args;
		
		var xhr = new window.XMLHttpRequest;
		xhr.open( "POST", _args.url, true );
		xhr.setRequestHeader("content-type", "application/json");
		xhr.onreadystatechange = function() {
			if( xhr.readyState === 4 ) {
				var responseJSON = undefined;
				try {
					responseJSON = JSON.parse(xhr.responseText);
				} catch(e) {
					_args.error();
				}
				_args.success(responseJSON);
			}
		}
		xhr.send( '{"jsonrpc":"2.0","method":"' + _args.method + '","params":' + _args.params + '}' );
	}
};	

