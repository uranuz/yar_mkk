server {
	listen 80;
	listen 443 ssl;
	server_name yar-mkk.ru localhost;

	# Форсируем перенаправление на HTTPS тех пользователей, что зашли по имени сайта.
	# При обращении через локальный адрес пускаем по обычному HTTP, т.к. необходимо внутренних вызовов
	set $scheme_with_host $scheme://$host;
	if ($scheme_with_host ~* "^http://yar-mkk.ru") {
		return 301 https://yar-mkk.ru$request_uri;
	}

	proxy_set_header Host $host;
	proxy_set_header X-Real-IP $remote_addr;
	proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
	proxy_set_header X-Forwarded-Host $host;
	proxy_set_header X-Forwarded-Proto $scheme;
	proxy_set_header X-Forwarded-Port $server_port;

	location /pub/ {
		root /home/yar_mkk/sites/mkk/;
		index index.html index.htm;
	}

	location /jsonrpc/ {
		proxy_pass http://127.0.0.1:8083;
		proxy_redirect off;
	}

	location /api/ {
		proxy_pass http://127.0.0.1:8083;
		proxy_redirect off;
	}

	location /history/api/ {
		proxy_pass http://127.0.0.1:8084;
		proxy_redirect off;
	}

	location /history/jsonrpc/ {
		proxy_pass http://127.0.0.1:8084;
		proxy_redirect off;
	}

	location /dyn/ {
		proxy_pass http://127.0.0.1:8082;
		proxy_redirect off;
	}

	location / {
		proxy_pass http://127.0.0.1:8082/dyn/index;
		proxy_redirect off;
	}
}
