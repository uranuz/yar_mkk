rdmd -gc -g --build-only --force -version=devel "-L/usr/local/postgresql/lib/libpq.a" "-L/home/uranuz/sources/yar_mkk/lib/libtarsnap.a" "-L/usr/lib/x86_64-linux-gnu/libssl.a" "-L/usr/lib/x86_64-linux-gnu/libcrypto.a" "-Isrc/" "-I../webtank/src/" "-I../yar_mkk/" "-I../openssl/" "-I../" -ofmain_service_devel src/mkk_site/main_service/main.d
./main_service_devel --DRT-oncycle=ignore
