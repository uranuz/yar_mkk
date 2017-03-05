rdmd -gc -g -debug --build-only --force -version=devel "-L-l:libpq.so" "-L-l:libssl.so"  "-L/usr/local/lib/libtarsnap.a" "-L-l:libcrypto.so" "-Isrc/" "-I../webtank/src/" "-I../yar_mkk/" "-I../openssl/" "-I../" -ofmain_service_devel src/mkk_site/main_service/main.d
./main_service_devel --DRT-oncycle=ignore
