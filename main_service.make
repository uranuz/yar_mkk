rdmd -g -debug --build-only --force -version=devel -version=IvyTotalDebug "-L-l:libpq.so" "-L-l:libssl.so" "-L-l:libcrypto.so" "-Llib/libtarsnap.a" "-Isrc/" "-I../webtank/src/" "-I../yar_mkk/" "-I../openssl/" "-I../" -ofmain_service_devel src/mkk_site/main_service/main.d
./main_service_devel --DRT-oncycle=ignore
