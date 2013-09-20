//Определяем пространство имён библиотеки
var webtank = {
	version: "0.0"
};

//Определяем пространство имен для JSON-RPC
webtank.json_rpc = 
{	defaultInvokeArgs:  //Аргументы по-умолчанию для вызова ф-ции invoke
	{	uri: "/",  //Адрес для отправки
		method: null, //Название удалённого метода для вызова в виде строки
		params: null, //Параметры вызова удалённого метода
		onresult: null, //Обработчик успешного вызова удалённого метода
		onerror: null,  //Обработчик ошибки
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

		var xhr = new window.XMLHttpRequest;
		xhr.open( "POST", _args.uri, true );
		xhr.setRequestHeader("content-type", "application/json-rpc");
		//
		xhr.onreadystatechange = function()
		{	webtank.json_rpc._handleResponse(xhr);
		}
		var idStr = "";
		if( _args.onerror || _args.onresult )
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
					{	if( invokeArgs.onerror )
							invokeArgs.onerror(responseJSON.error);
						else
						{	console.error("Ошибка при выполнении удалённого метода");
							console.error(responseJSON.error.toString());
						}
					}
					else
					{	if( invokeArgs.onresult )
							invokeArgs.onresult(responseJSON.result);
					}
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

