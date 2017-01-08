rdmd -gc -g --build-only --force -version=devel "--DRT-oncycle=ignore" "-L/usr/local/postgresql/lib/libpq.a" "-L/home/uranuz/sources/yar_mkk/lib/libtarsnap.a" "-L/usr/lib/x86_64-linux-gnu/libssl.a" "-L/usr/lib/x86_64-linux-gnu/libcrypto.a" "-Isrc/" "-I../webtank/src/" "-I../yar_mkk/" "-I../openssl/" "-I../" -ofmkk_site_devel src/mkk_site/site_build_package.d
./mkk_site_devel --DRT-oncycle=ignore
