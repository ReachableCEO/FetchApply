#!/bin/bash

#Made from instructions at https://www.tunetheweb.com/performance/http2/

OPENSSL_URL_BASE="https://www.openssl.org/source/"
OPENSSL_FILE="openssl-1.1.0h.tar.gz"

NGHTTP_URL_BASE="https://github.com/nghttp2/nghttp2/releases/download/v1.31.0/"
NGHTTP_FILE="nghttp2-1.31.0.tar.gz"

APR_URL_BASE="https://archive.apache.org/dist/apr/"
APR_FILE="apr-1.6.3.tar.gz"

APR_UTIL_URL_BASE="https://archive.apache.org/dist/apr/"
APR_UTIL_FILE="apr-util-1.6.1.tar.gz"

APACHE_URL_BASE="https://archive.apache.org/dist/httpd/"
APACHE_FILE="httpd-2.4.33.tar.gz"

CURL_URL_BASE="https://curl.haxx.se/download/"
CURL_FILE="curl-7.60.0.tar.gz"


#Download and install latest version of openssl
wget $OPENSSL_URL_BASE/$OPENSSL_FILE
tar xzf $OPENSSL_FILE
cd openssl-1.1.0h 
./config enable-weak-ssl-ciphers shared zlib-dynamic -DOPENSSL_TLS_SECURITY_LEVEL=0 --prefix=/usr/local/custom-ssl/openssl-1.1.0h ; make ; make install
ln -s /usr/local/custom-ssl/openssl-1.1.0h /usr/local/openssl
cd -

#Download and install nghttp2 (needed for mod_http2).
wget $NGHTTP_URL_BASE/$NGHTTP_FILE
tar xzf $NGHTTP_FILE
cd nghttp2-1.31.0 
./configure --prefix=/usr/local/custom-ssl/nghttp ; make ; make install
cd -

#Updated ldconfig so curl build

cat <<custom-ssl > /etc/ld.so.conf.d/custom-ssl.conf
/usr/local/custom-ssl/openssl-1.1.0h/lib
/usr/local/custom-ssl/nghttp/lib
custom-ssl

ldconfig

#Download and install curl
wget $CURL_URL_BASE/$CURL_FILE
tar xzf curl-7.60.0.tar.gz
cd curl-7.60.0
./configure --prefix=/usr/local/custom-ssl/curl --with-nghttp2=/usr/local/custom-ssl/nghttp/ --with-ssl=/usr/local/custom-ssl/openssl-1.1.0h/ ; make ; make install
cd -


#Download and install latest apr
wget $APR_URL_BASE/$APR_FILE
tar xzf $APR_FILE
cd apr-1.6.3 
./configure --prefix=/usr/local/custom-ssl/apr ; make ; make install
cd -

#Download and install latest apr-util
wget $APR_UTIL_URL_BASE/$APR_UTIL_FILE
tar xzf apr-util-1.6.1.tar.gz
cd apr-util-1.6.1 
./configure --prefix=/usr/local/custom-ssl/apr-util --with-apr=/usr/local/custom-ssl/apr ; make; make install
cd -

#Download and install apache
wget $APACHE_URL_BASE/$APACHE_FILE
tar xzf httpd-2.4.33.tar.gz
cd httpd-2.4.33
cp -r ../apr-1.6.3 srclib/apr
cp -r ../apr-util-1.6.1 srclib/apr-util
./configure --prefix=/usr/local/custom-ssl/apache  --with-ssl=/usr/local/custom-ssl/openssl-1.1.0h/ --with-pcre=/usr/bin/pcre-config --enable-unique-id --enable-ssl --enable-so --with-included-apr --enable-http2 --with-nghttp2=/usr/local/custom-ssl/nghttp/
make
make install
ln -s /usr/local/custom-ssl/apache /usr/local/apache
cd -

