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
openssl : \
				$(TMP)/openssl/install/usr/local/include/openssl/ssl.h \
				$(TMP)/openssl/install/usr/local/lib/libcrypto.a \
				$(TMP)/openssl/install/usr/local/lib/libssl.a


.PHONY : wget
wget : $(TMP)/wget/install/usr/local/bin/wget


##### compilation flags ##########

arch_flags = $(patsubst %,-arch %,$(archs))

CFLAGS += $(arch_flags)


##### openssl ##########

openssl_config_options := \
		no-filenames \
		no-shared \
		no-stdio \
		no-tests

openssl_sources := $(shell find openssl -type f \! -name .DS_Store)

$(TMP)/openssl :
	mkdir -p $@


##### openssl arm64 ##########

openssl_install_files_arm64 := \
		$(TMP)/openssl/arm64/install/usr/local/include/openssl/ssl.h \
		$(TMP)/openssl/arm64/install/usr/local/lib/libcrypto.a \
		$(TMP)/openssl/arm64/install/usr/local/lib/libssl.a

$(openssl_install_files_arm64) : $(TMP)/openssl/arm64/installed.stamp.txt
	@:

$(TMP)/openssl/arm64/installed.stamp.txt : \
				$(TMP)/openssl/arm64/build/libssl.a \
				$(TMP)/openssl/arm64/build/libcrypto.a \
				| $(TMP)/openssl/arm64/install
	cd $(TMP)/openssl/arm64/build && $(MAKE) DESTDIR=$(TMP)/openssl/arm64/install install_sw
	date > $@

$(TMP)/openssl/arm64/build/libssl.a \
$(TMP)/openssl/arm64/build/libcrypto.a : $(TMP)/openssl/arm64/built.stamp.txt | $$(dir $$@)
	@:

$(TMP)/openssl/arm64/built.stamp.txt : $(TMP)/openssl/arm64/configured.stamp.txt | $$(dir $$@)
	cd $(TMP)/openssl/arm64/build && $(MAKE)
	date > $@

$(TMP)/openssl/arm64/configured.stamp.txt : $(openssl_sources) | $(TMP)/openssl/arm64/build
	cd $(TMP)/openssl/arm64/build \
			&& $(abspath openssl/Configure) \
					$(openssl_config_options) darwin64-arm64-cc
	date > $@

$(TMP)/openssl/arm64 \
$(TMP)/openssl/arm64/build \
$(TMP)/openssl/arm64/install :
	mkdir -p $@


##### openssl x86_64 ##########

openssl_install_files_x86_64 := \
		$(TMP)/openssl/x86_64/install/usr/local/include/openssl/ssl.h \
		$(TMP)/openssl/x86_64/install/usr/local/lib/libcrypto.a \
		$(TMP)/openssl/x86_64/install/usr/local/lib/libssl.a

$(openssl_install_files_x86_64) : $(TMP)/openssl/x86_64/installed.stamp.txt
	@:

$(TMP)/openssl/x86_64/installed.stamp.txt : \
				$(TMP)/openssl/x86_64/build/libssl.a \
				$(TMP)/openssl/x86_64/build/libcrypto.a \
				| $(TMP)/openssl/x86_64/install
	cd $(TMP)/openssl/x86_64/build && $(MAKE) DESTDIR=$(TMP)/openssl/x86_64/install install_sw
	date > $@

$(TMP)/openssl/x86_64/build/libssl.a \
$(TMP)/openssl/x86_64/build/libcrypto.a : $(TMP)/openssl/x86_64/built.stamp.txt | $$(dir $$@)
	@:

$(TMP)/openssl/x86_64/built.stamp.txt : $(TMP)/openssl/x86_64/configured.stamp.txt | $$(dir $$@)
	cd $(TMP)/openssl/x86_64/build && $(MAKE)
	date > $@

$(TMP)/openssl/x86_64/configured.stamp.txt : $(openssl_sources) | $(TMP)/openssl/x86_64/build
	cd $(TMP)/openssl/x86_64/build \
			&& $(abspath openssl/Configure) \
					$(openssl_config_options) darwin64-x86_64-cc
	date > $@

$(TMP)/openssl/x86_64 \
$(TMP)/openssl/x86_64/build \
$(TMP)/openssl/x86_64/install :
	mkdir -p $@


##### openssl fat binaries ##########

$(TMP)/openssl/install/usr/local/include/openssl/ssl.h : \
				$(TMP)/openssl/install/usr/local/include \
				$(TMP)/openssl/arm64/installed.stamp.txt
	cp -R $(TMP)/openssl/arm64/install/usr/local/include/openssl $</openssl

$(TMP)/openssl/install/usr/local/lib/libcrypto.a : \
				$(TMP)/openssl/arm64/install/usr/local/lib/libcrypto.a \
				$(TMP)/openssl/x86_64/install/usr/local/lib/libcrypto.a \
				| $$(dir $$@)
	lipo -create $^ -output $@


$(TMP)/openssl/install/usr/local/lib/libssl.a : \
				$(TMP)/openssl/arm64/install/usr/local/lib/libssl.a \
				$(TMP)/openssl/x86_64/install/usr/local/lib/libssl.a \
				| $$(dir $$@)
	lipo -create $^ -output $@

$(TMP)/openssl/install/usr/local/include \
$(TMP)/openssl/install/usr/local/lib :
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
				$(TMP)/openssl/install/usr/local/include/openssl/ssl.h \
				$(TMP)/openssl/install/usr/local/lib/libcrypto.a \
				$(TMP)/openssl/install/usr/local/lib/libssl.a \
				| $(TMP)/wget/build
	cd $(TMP)/wget/build && sh $(abspath wget/configure) $(wget_configure_options)

$(TMP)/wget/build \
$(TMP)/wget/install :
	mkdir -p $@

