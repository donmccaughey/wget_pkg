TMP ?= $(abspath tmp)

version := 1.21.2
revision := 1
archs := arm64 x86_64


.SECONDEXPANSION :


.PHONY : signed-package
signed-package : wget-$(version).pkg


.PHONY : clean
clean :
	-rm -f wget-*.pkg
	-rm -rf $(TMP)


.PHONY : openssl
openssl : $(TMP)/openssl/installed.stamp.txt


.PHONY : check
check :
	test "$(shell lipo -archs $(TMP)/openssl/install/usr/local/lib/libcrypto.a)" = "x86_64 arm64"
	test "$(shell lipo -archs $(TMP)/openssl/install/usr/local/lib/libssl.a)" = "x86_64 arm64"
	test "$(shell lipo -archs $(TMP)/wget/install/usr/local/bin/wget)" = "x86_64 arm64"
	codesign --verify --strict $(TMP)/install/usr/local/bin/wget
	pkgutil --check-signature wget-$(version).pkg
	spctl --assess --type install wget-$(version).pkg
	xcrun stapler validate wget-$(version).pkg


.PHONY : openssl
openssl : $(TMP)/openssl/installed.stamp.txt


.PHONY : wget
wget : $(TMP)/wget/install/usr/local/bin/wget


##### openssl ##########

openssl_config_options := \
		no-filenames \
		no-shared \
		no-stdio \
		no-tests

openssl_sources := $(shell find openssl -type f \! -name .DS_Store)

openssl_install_files := \
		$(TMP)/openssl/install/usr/local/include/openssl/ssl.h \
		$(TMP)/openssl/install/usr/local/lib/libcrypto.a \
		$(TMP)/openssl/install/usr/local/lib/libssl.a

$(openssl_install_files) : $(TMP)/openssl/installed.stamp.txt
	@:

$(TMP)/openssl/installed.stamp.txt : \
				$(TMP)/openssl/build/libssl.a \
				$(TMP)/openssl/build/libcrypto.a \
				| $(TMP)/openssl/install
	cd $(TMP)/openssl/build && $(MAKE) DESTDIR=$(TMP)/openssl/install install_sw
	date > $@

$(TMP)/openssl/build/libssl.a \
$(TMP)/openssl/build/libcrypto.a : $(TMP)/openssl/built.stamp.txt | $$(dir $$@)
	@:

$(TMP)/openssl/built.stamp.txt : $(TMP)/openssl/configured.stamp.txt | $$(dir $$@)
	cd $(TMP)/openssl/build && $(MAKE)
	date > $@

$(TMP)/openssl/configured.stamp.txt : $(openssl_sources) | $(TMP)/openssl/build
	cd $(TMP)/openssl/build && sh $(abspath openssl/config) $(openssl_config_options)
	date > $@

$(TMP)/openssl \
$(TMP)/openssl/build \
$(TMP)/openssl/install :
	mkdir -p $@


##### wget ##########

wget_configure_options := \
		--disable-silent-rules \
		--with-ssl=openssl \
		--with-libssl-prefix=$(TMP)/openssl/install/usr/local

wget_sources := $(shell find wget -type f \! -name .DS_Store)

$(TMP)/wget/install/usr/local/bin/wget : $(TMP)/wget/build/src/wget | $(TMP)/wget/install
	cd $(TMP)/wget/build && $(MAKE) DESTDIR=$(TMP)/wget/install install

$(TMP)/wget/build/src/wget : $(TMP)/wget/build/config.status $(wget_sources)
	cd $(TMP)/wget/build && $(MAKE)

$(TMP)/wget/build/config.status : \
				wget/configure \
				$(openssl_install_files) \
				| $(TMP)/wget/build
	cd $(TMP)/wget/build && sh $(abspath wget/configure) $(wget_configure_options)

$(TMP)/wget/build \
$(TMP)/wget/install :
	mkdir -p $@

