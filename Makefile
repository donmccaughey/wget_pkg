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


##### openssl ##########

openssl_config_options := no-shared

openssl_sources := $(shell find openssl -type f \! -name .DS_Store)

openssl_install_files := \
		$(TMP)/openssl/install/usr/local/ssl/include/openssl/ssl.h \
		$(TMP)/openssl/install/usr/local/ssl/lib/libcrypto.a \
		$(TMP)/openssl/install/usr/local/ssl/lib/libssl.a

$(openssl_install_files) : $(TMP)/openssl/installed.stamp.txt
	@:

$(TMP)/openssl/installed.stamp.txt : \
				$(TMP)/openssl/build/ssl/ssl.h \
				$(TMP)/openssl/build/libssl.a \
				$(TMP)/openssl/build/libcrypto.a \
				| $(TMP)/openssl/install
	cd $(TMP)/openssl/build && $(MAKE) DESTDIR=$(TMP)/openssl/install install_sw
	date > $@

$(TMP)/openssl/build/ssl/ssl.h \
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


