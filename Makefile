APP_SIGNING_ID ?= Developer ID Application: Donald McCaughey
INSTALLER_SIGNING_ID ?= Developer ID Installer: Donald McCaughey
NOTARIZATION_KEYCHAIN_PROFILE ?= Donald McCaughey
TMP ?= $(abspath tmp)

version := 1.25.0
libiconv_version := 1.18
libidn2_version := 2.3.8
libpsl_version := 0.21.5
libunistring_version := 1.4.1
openssl_version := 3.5.5
pcre2_version := 10.47
zlib_version := 1.3.1
revision := 1
archs := arm64 x86_64

rev := $(if $(patsubst 1,,$(revision)),-r$(revision),)
ver := $(version)$(rev)


.SECONDEXPANSION :


.PHONY : signed-package
signed-package : $(TMP)/wget-$(ver)-unnotarized.pkg


.PHONY : notarize
notarize : wget-$(ver).pkg


.PHONY : clean
clean :
	-rm -f wget-*.pkg
	-rm -rf $(TMP)


.PHONY : check
check :
	test "$(shell lipo -archs $(TMP)/libiconv/install/usr/local/lib/libiconv.a)" = "x86_64 arm64"
	test "$(shell lipo -archs $(TMP)/libidn2/install/usr/local/lib/libidn2.a)" = "x86_64 arm64"
	test "$(shell lipo -archs $(TMP)/libpsl/install/usr/local/lib/libpsl.a)" = "x86_64 arm64"
	test "$(shell lipo -archs $(TMP)/libunistring/install/usr/local/lib/libunistring.a)" = "x86_64 arm64"
	test "$(shell lipo -archs $(TMP)/openssl/install/usr/local/lib/libcrypto.a)" = "x86_64 arm64"
	test "$(shell lipo -archs $(TMP)/openssl/install/usr/local/lib/libssl.a)" = "x86_64 arm64"
	test "$(shell lipo -archs $(TMP)/pcre2/install/usr/local/lib/libpcre2-8.a)" = "x86_64 arm64"
	test "$(shell lipo -archs $(TMP)/zlib/install/usr/local/lib/libz.a)" = "x86_64 arm64"
	test "$(shell lipo -archs $(TMP)/wget/install/usr/local/bin/wget)" = "x86_64 arm64"
	test "$(shell ./tools/dylibs --no-sys-libs --count $(TMP)/wget/install/usr/local/bin/wget) dylibs" = "0 dylibs"
	codesign --verify --strict $(TMP)/wget/install/usr/local/bin/wget
	$(TMP)/wget/install/usr/local/bin/wget --output-document - https://donm.cc > /dev/null
	pkgutil --check-signature wget-$(ver).pkg
	spctl --assess --type install wget-$(ver).pkg
	xcrun stapler validate wget-$(ver).pkg


.PHONY : libiconv
libiconv : \
		$(TMP)/libiconv/install/usr/local/include/iconv.h \
		$(TMP)/libiconv/install/usr/local/lib/libiconv.a


.PHONY : libidn2
libidn2 : \
		$(TMP)/libidn2/install/usr/local/include/idn2.h \
		$(TMP)/libidn2/install/usr/local/lib/libidn2.a

.PHONY : libpsl
libpsl : \
		$(TMP)/libpsl/install/usr/local/include/psl.h \
		$(TMP)/libpsl/install/usr/local/lib/libpsl.a


.PHONY : libunistring
libunistring : \
		$(TMP)/libunistring/install/usr/local/include/unistr.h \
		$(TMP)/libunistring/install/usr/local/lib/libunistring.a


.PHONY : openssl
openssl : \
		$(TMP)/openssl/install/usr/local/include/openssl/ssl.h \
		$(TMP)/openssl/install/usr/local/lib/libcrypto.a \
		$(TMP)/openssl/install/usr/local/lib/libssl.a


.PHONY : pcre2
pcre2 : \
		$(TMP)/pcre2/install/usr/local/include/pcre2.h \
		$(TMP)/pcre2/install/usr/local/lib/libpcre2-8.a


.PHONY : zlib
zlib : \
		$(TMP)/zlib/install/usr/local/include/zlib.h \
		$(TMP)/zlib/install/usr/local/lib/libz.a


.PHONY : wget
wget : $(TMP)/wget.pkg


.PHONY : clean-wget
clean-wget :
	rm -rf $(TMP)/wget


##### compilation flags ##########

arch_flags = $(patsubst %,-arch %,$(archs))

CFLAGS += $(arch_flags)


##### libiconv ##########

libiconv_config_options := \
		--disable-shared \
		CFLAGS='$(CFLAGS)'

libiconv_sources := $(shell find libiconv -type f \! -name .DS_Store)

$(TMP)/libiconv/install/usr/local/include/iconv.h \
$(TMP)/libiconv/install/usr/local/lib/libiconv.a : \
		$(TMP)/libiconv/installed.stamp.txt
	@:

$(TMP)/libiconv/installed.stamp.txt : \
		$(TMP)/libiconv/build/include/iconv.h \
		$(TMP)/libiconv/build/lib/.libs/libiconv.a \
		| $$(dir $$@)
	cd $(TMP)/libiconv/build && $(MAKE) DESTDIR=$(TMP)/libiconv/install install
#	libpsl `make` chokes on relocated libtool .la files so remove them
	rm -f $(TMP)/libiconv/install/usr/local/lib/*.la
	date > $@

$(TMP)/libiconv/build/include/iconv.h \
$(TMP)/libiconv/build/lib/.libs/libiconv.a : \
		$(TMP)/libiconv/built.stamp.txt \
		| $$(dir $$@)
	@:

$(TMP)/libiconv/built.stamp.txt : \
		$(TMP)/libiconv/configured.stamp.txt \
		| $$(dir $$@)
	cd $(TMP)/libiconv/build && $(MAKE)
	date > $@

$(TMP)/libiconv/configured.stamp.txt : \
		$(libiconv_sources) \
		| $(TMP)/libiconv/build
	cd $(TMP)/libiconv/build \
			&& $(abspath libiconv/configure) $(libiconv_config_options)
	date > $@

$(TMP)/libiconv \
$(TMP)/libiconv/build \
$(TMP)/libiconv/install :
	mkdir -p $@


##### libidn2 ##########

libidn2_config_options := \
		--disable-doc \
		--disable-shared \
		--with-included-libunistring \
		--with-libiconv-prefix='$(TMP)/libiconv/install/usr/local' \
		--with-libunistring-prefix='$(TMP)/libunistring/install/usr/local' \
		CFLAGS='$(CFLAGS)'

libidn2_sources := $(shell find libidn2 -type f \! -name .DS_Store)

$(TMP)/libidn2/install/usr/local/include/idn2.h \
$(TMP)/libidn2/install/usr/local/lib/libidn2.a : $(TMP)/libidn2/installed.stamp.txt
	@:

$(TMP)/libidn2/installed.stamp.txt : \
		libidn2/lib/idn2.h \
		$(TMP)/libidn2/build/lib/.libs/libidn2.a \
		| $$(dir $$@)
	cd $(TMP)/libidn2/build && $(MAKE) DESTDIR=$(TMP)/libidn2/install install
#	libpsl `make` chokes on relocated libtool .la files so remove them
	rm -f $(TMP)/libidn2/install/usr/local/lib/*.la
	date > $@

$(TMP)/libidn2/build/lib/.libs/libidn2.a : $(TMP)/libidn2/built.stamp.txt | $$(dir $$@)
	@:

$(TMP)/libidn2/built.stamp.txt : $(TMP)/libidn2/configured.stamp.txt | $$(dir $$@)
	cd $(TMP)/libidn2/build && $(MAKE)
	date > $@

$(TMP)/libidn2/configured.stamp.txt : \
		$(libidn2_sources) \
		$(TMP)/libiconv/install/usr/local/include/iconv.h \
		$(TMP)/libiconv/install/usr/local/lib/libiconv.a \
		$(TMP)/libunistring/install/usr/local/include/unistr.h \
		$(TMP)/libunistring/install/usr/local/lib/libunistring.a \
		| $(TMP)/libidn2/build
	cd $(TMP)/libidn2/build \
			&& $(abspath libidn2/configure) $(libidn2_config_options)
	date > $@

$(TMP)/libidn2 \
$(TMP)/libidn2/build \
$(TMP)/libidn2/install :
	mkdir -p $@


##### libpsl ##########

libpsl_config_options := \
		--disable-gtk-doc-html \
		--disable-man \
		--disable-shared \
		--enable-runtime=libidn2 \
		--enable-static \
		--with-libiconv-prefix=$(TMP)/libiconv/install/usr/local \
		CFLAGS='$(CFLAGS) -I$(TMP)/libiconv/install/usr/local/include -I$(TMP)/libunistring/install/usr/local/include' \
		LDFLAGS='-L$(TMP)/libiconv/install/usr/local/lib -L$(TMP)/libunistring/install/usr/local/lib' \
		LIBIDN2_CFLAGS='-I$(TMP)/libidn2/install/usr/local/include' \
		LIBIDN2_LIBS='-lidn2 -L$(TMP)/libidn2/install/usr/local/lib'

libpsl_sources := $(shell find libpsl -type f \! -name .DS_Store)

$(TMP)/libpsl/install/usr/local/include/libpsl.h \
$(TMP)/libpsl/install/usr/local/lib/libpsl.a : \
		$(TMP)/libpsl/installed.stamp.txt
	@:

$(TMP)/libpsl/installed.stamp.txt : \
		$(TMP)/libpsl/build/include/libpsl.h \
		$(TMP)/libpsl/build/src/.libs/libpsl.a \
		| $$(dir $$@)
	cd $(TMP)/libpsl/build && $(MAKE) DESTDIR=$(TMP)/libpsl/install install
	date > $@

$(TMP)/libpsl/build/include/libpsl.h \
$(TMP)/libpsl/build/src/.libs/libpsl.a : \
		$(TMP)/libpsl/built.stamp.txt \
		| $$(dir $$@)
	@:

$(TMP)/libpsl/built.stamp.txt : \
		$(TMP)/libpsl/configured.stamp.txt \
		| $$(dir $$@)
	cd $(TMP)/libpsl/build && $(MAKE)
	date > $@

$(TMP)/libpsl/configured.stamp.txt : \
		$(libpsl_sources) \
		$(TMP)/libiconv/install/usr/local/include/iconv.h \
		$(TMP)/libiconv/install/usr/local/lib/libiconv.a \
		$(TMP)/libidn2/install/usr/local/include/idn2.h \
		$(TMP)/libidn2/install/usr/local/lib/libidn2.a \
		$(TMP)/libunistring/install/usr/local/include/unistr.h \
		$(TMP)/libunistring/install/usr/local/lib/libunistring.a \
		| $(TMP)/libpsl/build
	cd $(TMP)/libpsl/build \
			&& $(abspath libpsl/configure) $(libpsl_config_options)
	date > $@

$(TMP)/libpsl \
$(TMP)/libpsl/build \
$(TMP)/libpsl/install :
	mkdir -p $@


##### libunistring ##########

libunistring_config_options := \
		--disable-shared \
		--with-libiconv-prefix='$(TMP)/libiconv/install/usr/local' \
		CFLAGS='$(CFLAGS)'

libunistring_sources := $(shell find libunistring -type f \! -name .DS_Store)

$(TMP)/libunistring/install/usr/local/include/unistr.h \
$(TMP)/libunistring/install/usr/local/lib/libunistring.a : \
		$(TMP)/libunistring/installed.stamp.txt
	@:

$(TMP)/libunistring/installed.stamp.txt : \
		$(TMP)/libunistring/build/lib/unistr.h \
		$(TMP)/libunistring/build/lib/.libs/libunistring.a \
		| $$(dir $$@)
	cd $(TMP)/libunistring/build \
			&& $(MAKE) DESTDIR=$(TMP)/libunistring/install install
#	libpsl `make` chokes on relocated libtool .la files so remove them
	rm -f $(TMP)/libunistring/install/usr/local/lib/*.la
# 	libunistring `make install` adds this empty file to the dist directory
	rm -f libunistring/lib/libunistring.sym-t1
	date > $@

$(TMP)/libunistring/build/lib/unistr.h \
$(TMP)/libunistring/build/lib/.libs/libunistring.a : \
		$(TMP)/libunistring/built.stamp.txt \
		| $$(dir $$@)
	@:

$(TMP)/libunistring/built.stamp.txt : \
		$(TMP)/libunistring/configured.stamp.txt \
		$(TMP)/libiconv/install/usr/local/include/iconv.h \
		$(TMP)/libiconv/install/usr/local/lib/libiconv.a \
		| $$(dir $$@)
	cd $(TMP)/libunistring/build && $(MAKE)
# 	libunistring `make` adds this empty file to the dist directory
	rm -f libunistring/lib/libunistring.sym-t1
	date > $@

$(TMP)/libunistring/configured.stamp.txt : \
		$(libunistring_sources) \
		| $(TMP)/libunistring/build
	cd $(TMP)/libunistring/build \
			&& $(abspath libunistring/configure) $(libunistring_config_options)
	date > $@

$(TMP)/libunistring \
$(TMP)/libunistring/build \
$(TMP)/libunistring/install :
	mkdir -p $@


##### openssl ##########

openssl_config_options := \
		--openssldir=/etc/ssl \
		no-filenames \
		no-shared \
		no-tests

openssl_sources := $(shell find openssl -type f \! -name .DS_Store)

$(TMP)/openssl :
	mkdir -p $@


##### openssl arm64 ##########

$(TMP)/openssl/arm64/install/usr/local/include/openssl/ssl.h \
$(TMP)/openssl/arm64/install/usr/local/lib/libcrypto.a \
$(TMP)/openssl/arm64/install/usr/local/lib/libssl.a : \
		$(TMP)/openssl/arm64/installed.stamp.txt
	@:

$(TMP)/openssl/arm64/installed.stamp.txt : \
				$(TMP)/openssl/arm64/build/libssl.a \
				$(TMP)/openssl/arm64/build/libcrypto.a \
				| $(TMP)/openssl/arm64/install
	cd $(TMP)/openssl/arm64/build \
			&& $(MAKE) DESTDIR=$(TMP)/openssl/arm64/install install_sw
	date > $@

$(TMP)/openssl/arm64/build/libssl.a \
$(TMP)/openssl/arm64/build/libcrypto.a : \
		$(TMP)/openssl/arm64/built.stamp.txt \
		| $$(dir $$@)
	@:

$(TMP)/openssl/arm64/built.stamp.txt : \
		$(TMP)/openssl/arm64/configured.stamp.txt \
		| $$(dir $$@)
	cd $(TMP)/openssl/arm64/build && $(MAKE)
	date > $@

$(TMP)/openssl/arm64/configured.stamp.txt : \
		$(openssl_sources) \
		| $(TMP)/openssl/arm64/build
	cd $(TMP)/openssl/arm64/build \
			&& $(abspath openssl/Configure) \
					$(openssl_config_options) darwin64-arm64-cc
	date > $@

$(TMP)/openssl/arm64 \
$(TMP)/openssl/arm64/build \
$(TMP)/openssl/arm64/install :
	mkdir -p $@


##### openssl x86_64 ##########

$(TMP)/openssl/x86_64/install/usr/local/include/openssl/ssl.h \
$(TMP)/openssl/x86_64/install/usr/local/lib/libcrypto.a \
$(TMP)/openssl/x86_64/install/usr/local/lib/libssl.a : \
		$(TMP)/openssl/x86_64/installed.stamp.txt
	@:

$(TMP)/openssl/x86_64/installed.stamp.txt : \
				$(TMP)/openssl/x86_64/build/libssl.a \
				$(TMP)/openssl/x86_64/build/libcrypto.a \
				| $(TMP)/openssl/x86_64/install
	cd $(TMP)/openssl/x86_64/build \
			&& $(MAKE) DESTDIR=$(TMP)/openssl/x86_64/install install_sw
	date > $@

$(TMP)/openssl/x86_64/build/libssl.a \
$(TMP)/openssl/x86_64/build/libcrypto.a : \
		$(TMP)/openssl/x86_64/built.stamp.txt \
		| $$(dir $$@)
	@:

$(TMP)/openssl/x86_64/built.stamp.txt : \
		$(TMP)/openssl/x86_64/configured.stamp.txt \
		| $$(dir $$@)
	cd $(TMP)/openssl/x86_64/build && $(MAKE)
	date > $@

$(TMP)/openssl/x86_64/configured.stamp.txt : \
		$(openssl_sources) \
		| $(TMP)/openssl/x86_64/build
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
		$(TMP)/openssl/arm64/install/usr/local/include/openssl/ssl.h \
		| $(TMP)/openssl/install/usr/local/include
	cp -R $(dir $<) $(dir $@)

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


##### pcre2 ##########

pcre2_config_options := \
		--disable-shared \
		--enable-jit \
		--enable-static \
		CFLAGS='$(CFLAGS)'

pcre2_sources := $(shell find pcre2 -type f \! -name .DS_Store)

$(TMP)/pcre2/install/usr/local/include/pcre2.h \
$(TMP)/pcre2/install/usr/local/lib/libpcre2-8.a : \
		$(TMP)/pcre2/installed.stamp.txt
	@:

$(TMP)/pcre2/installed.stamp.txt : \
		$(TMP)/pcre2/build/src/pcre2.h \
		$(TMP)/pcre2/build/.libs/libpcre2-8.a \
		| $$(dir $$@)
	cd $(TMP)/pcre2/build && $(MAKE) DESTDIR=$(TMP)/pcre2/install install
	date > $@

$(TMP)/pcre2/build/src/pcre2.h \
$(TMP)/pcre2/build/.libs/libpcre2-8.a : \
		$(TMP)/pcre2/built.stamp.txt \
		| $$(dir $$@)
	@:

$(TMP)/pcre2/built.stamp.txt : $(TMP)/pcre2/configured.stamp.txt | $$(dir $$@)
	cd $(TMP)/pcre2/build && $(MAKE)
	date > $@

$(TMP)/pcre2/configured.stamp.txt : $(pcre2_sources) | $(TMP)/pcre2/build
	cd $(TMP)/pcre2/build \
			&& $(abspath pcre2/configure) $(pcre2_config_options)
	date > $@

$(TMP)/pcre2 \
$(TMP)/pcre2/build \
$(TMP)/pcre2/install :
	mkdir -p $@


##### zlib ##########

zlib_config_options := \
		--static \
		--archs="$(arch_flags)"

zlib_sources := $(shell find zlib -type f \! -name .DS_Store)

$(TMP)/zlib/install/usr/local/include/zlib.h \
$(TMP)/zlib/install/usr/local/lib/libz.a : $(TMP)/zlib/installed.stamp.txt
	@:

$(TMP)/zlib/installed.stamp.txt : \
		$(TMP)/zlib/build/zconf.h \
		$(TMP)/zlib/build/libz.a \
		| $$(dir $$@)
	cd $(TMP)/zlib/build && $(MAKE) DESTDIR=$(TMP)/zlib/install install
	date > $@

$(TMP)/zlib/build/zconf.h \
$(TMP)/zlib/build/libz.a : $(TMP)/zlib/built.stamp.txt | $$(dir $$@)
	@:

$(TMP)/zlib/built.stamp.txt : $(TMP)/zlib/configured.stamp.txt | $$(dir $$@)
	cd $(TMP)/zlib/build && $(MAKE)
	date > $@

$(TMP)/zlib/configured.stamp.txt : $(zlib_sources) | $(TMP)/zlib/build
	cd $(TMP)/zlib/build \
			&& $(abspath zlib/configure) $(zlib_config_options)
	date > $@

$(TMP)/zlib \
$(TMP)/zlib/build \
$(TMP)/zlib/install :
	mkdir -p $@


##### wget ##########

wget_configure_options := \
		--disable-silent-rules \
		--disable-pcre \
		--without-libpsl \
		--with-ssl=openssl \
		--with-libiconv-prefix=$(TMP)/libiconv/install/usr/local \
		--with-libssl-prefix=$(TMP)/openssl/install/usr/local \
		CFLAGS='$(CFLAGS)' \
		LIBIDN2_CFLAGS='-I$(TMP)/libidn2/install/usr/local/include' \
		LIBIDN2_LIBS='$(TMP)/libidn2/install/usr/local/lib/libidn2.a' \
		LIBPSL_CFLAGS='-I$(TMP)/libpsl/install/usr/local/include' \
		LIBPSL_LIBS='$(TMP)/libpsl/install/usr/local/lib/libpsl.a' \
		PCRE2_CFLAGS='-I$(TMP)/pcre2/install/usr/local/include' \
		PCRE2_LIBS='$(TMP)/pcre2/install/usr/local/lib/libpcre2-8.a' \
		ZLIB_CFLAGS='-I$(TMP)/zlib/install/usr/local/include' \
		ZLIB_LIBS='-lz -L$(TMP)/zlib/install/usr/local/lib'

wget_sources := $(shell find wget -type f \! -name .DS_Store)

$(TMP)/wget/install/usr/local/bin/wget : \
		$(TMP)/wget/build/src/wget \
		| $(TMP)/wget/install
	cd $(TMP)/wget/build && $(MAKE) DESTDIR=$(TMP)/wget/install install
	xcrun codesign \
		--sign "$(APP_SIGNING_ID)" \
		--options runtime \
		$@

$(TMP)/wget/build/src/wget : $(TMP)/wget/build/config.status $(wget_sources)
	cd $(TMP)/wget/build && $(MAKE)

$(TMP)/wget/build/config.status : \
		wget/configure \
		$(TMP)/libiconv/install/usr/local/include/iconv.h \
		$(TMP)/libiconv/install/usr/local/lib/libiconv.a \
		$(TMP)/libidn2/install/usr/local/include/idn2.h \
		$(TMP)/libidn2/install/usr/local/lib/libidn2.a \
		$(TMP)/libpsl/install/usr/local/include/libpsl.h \
		$(TMP)/libpsl/install/usr/local/lib/libpsl.a \
		$(TMP)/libunistring/install/usr/local/include/unistr.h \
		$(TMP)/libunistring/install/usr/local/lib/libunistring.a \
		$(TMP)/openssl/install/usr/local/include/openssl/ssl.h \
		$(TMP)/openssl/install/usr/local/lib/libcrypto.a \
		$(TMP)/openssl/install/usr/local/lib/libssl.a \
		$(TMP)/pcre2/install/usr/local/include/pcre2.h \
		$(TMP)/pcre2/install/usr/local/lib/libpcre2-8.a \
		$(TMP)/zlib/install/usr/local/include/zlib.h \
		$(TMP)/zlib/install/usr/local/lib/libz.a \
		| $(TMP)/wget/build
	cd $(TMP)/wget/build \
			&& sh $(abspath wget/configure) $(wget_configure_options)

$(TMP)/wget/build \
$(TMP)/wget/install :
	mkdir -p $@


##### pkg ##########

$(TMP)/wget.pkg : $(TMP)/wget/install/usr/local/bin/uninstall-wget
	pkgbuild \
		--root $(TMP)/wget/install \
		--identifier cc.donm.pkg.wget \
		--ownership recommended \
		--version $(version) \
		$@

$(TMP)/wget/install/usr/local/bin/uninstall-wget : \
		./uninstall-wget \
		$(TMP)/wget/install/etc/paths.d/wget.path \
		$(TMP)/wget/install/usr/local/bin/wget \
		| $$(dir $$@)
	cp $< $@
	cd $(TMP)/wget/install && find . -type f \! -name .DS_Store | sort >> $@
	sed -e 's/^\./rm -f /g' -i '' $@
	chmod a+x $@

$(TMP)/wget/install/etc/paths.d/wget.path : wget.path | $$(dir $$@)
	cp $< $@

$(TMP)/wget/install/etc/paths.d :
	mkdir -p $@


##### product ##########

arch_list := $(shell printf '%s' "$(archs)" | sed "s/ / and /g")
date := $(shell date '+%Y-%m-%d')
macos:=$(shell \
	system_profiler -detailLevel mini SPSoftwareDataType \
	| grep 'System Version:' \
	| awk -F ' ' '{print $$4}' \
	)
xcode:=$(shell \
	system_profiler -detailLevel mini SPDeveloperToolsDataType \
	| grep 'Version:' \
	| awk -F ' ' '{print $$2}' \
	)

$(TMP)/wget-$(ver)-unnotarized.pkg : \
		$(TMP)/wget.pkg \
		$(TMP)/build-report.txt \
		$(TMP)/distribution.xml \
		$(TMP)/resources/background.png \
		$(TMP)/resources/background-darkAqua.png \
		$(TMP)/resources/licenses.html \
		$(TMP)/resources/welcome.html
	productbuild \
		--distribution $(TMP)/distribution.xml \
		--resources $(TMP)/resources \
		--package-path $(TMP) \
		--version v$(version)-r$(revision) \
		--sign '$(INSTALLER_SIGNING_ID)' \
		$@

$(TMP)/build-report.txt : | $$(dir $$@)
	printf 'Build Date: %s\n' "$(date)" > $@
	printf 'Software Version: %s\n' "$(version)" >> $@
	printf 'libiconv Version: %s\n' "$(libiconv_version)" >> $@
	printf 'libidn2 Version: %s\n' "$(libidn2_version)" >> $@
	printf 'libpsl Version: %s\n' "$(libpsl_version)" >> $@
	printf 'libunistring Version: %s\n' "$(libunistring_version)" >> $@
	printf 'OpenSSL Version: %s\n' "$(openssl_version)" >> $@
	printf 'PCRE2 Version: %s\n' "$(pcre2_version)" >> $@
	printf 'zlib Version: %s\n' "$(zlib_version)" >> $@
	printf 'Installer Revision: %s\n' "$(revision)" >> $@
	printf 'Architectures: %s\n' "$(arch_list)" >> $@
	printf 'macOS Version: %s\n' "$(macos)" >> $@
	printf 'Xcode Version: %s\n' "$(xcode)" >> $@
	printf 'APP_SIGNING_ID: %s\n' "$(APP_SIGNING_ID)" >> $@
	printf 'INSTALLER_SIGNING_ID: %s\n' "$(INSTALLER_SIGNING_ID)" >> $@
	printf 'TMP directory: %s\n' "$(TMP)" >> $@
	printf 'CFLAGS: %s\n' "$(CFLAGS)" >> $@
	printf 'Tag: v%s-r%s\n' "$(version)" "$(revision)" >> $@
	printf 'Tag Title: wget %s' "$(version)" >> $@
	printf ' for macOS rev %s\n' "$(revision)" >> $@
	printf 'Tag Message: A signed and notarized universal installer' >> $@
	printf ' package for `wget` %s, built with' "$(version)" >> $@
	printf ' libiconv %s,' "$(libiconv_version)" >> $@
	printf ' libidn2 %s,' "$(libidn2_version)" >> $@
	printf ' libpsl %s,' "$(libpsl_version)" >> $@
	printf ' libunistring %s,' "$(libunistring_version)" >> $@
	printf ' OpenSSL %s,' "$(openssl_version)" >> $@
	printf ' PCRE2 %s' "$(pcre2_version)" >> $@
	printf ' and zlib %s.\n' "$(zlib_version)" >> $@

$(TMP)/distribution.xml \
$(TMP)/resources/welcome.html : $(TMP)/% : % | $$(dir $$@)
	sed \
		-e 's/{{arch_list}}/$(arch_list)/g' \
		-e 's/{{date}}/$(date)/g' \
		-e 's/{{macos}}/$(macos)/g' \
		-e 's/{{libiconv_version}}/$(libiconv_version)/g' \
		-e 's/{{libidn2_version}}/$(libidn2_version)/g' \
		-e 's/{{libpsl_version}}/$(libpsl_version)/g' \
		-e 's/{{libunistring_version}}/$(libunistring_version)/g' \
		-e 's/{{openssl_version}}/$(openssl_version)/g' \
		-e 's/{{pcre2_version}}/$(pcre2_version)/g' \
		-e 's/{{zlib_version}}/$(zlib_version)/g' \
		-e 's/{{revision}}/$(revision)/g' \
		-e 's/{{version}}/$(version)/g' \
		-e 's/{{xcode}}/$(xcode)/g' \
		$< > $@

$(TMP)/resources/background.png \
$(TMP)/resources/background-darkAqua.png \
$(TMP)/resources/licenses.html : $(TMP)/% : % | $$(dir $$@)
	cp $< $@

$(TMP) \
$(TMP)/resources :
	mkdir -p $@


##### notarization ##########

$(TMP)/submit-log.json : $(TMP)/wget-$(ver)-unnotarized.pkg | $$(dir $$@)
	xcrun notarytool submit $< \
		--keychain-profile "$(NOTARIZATION_KEYCHAIN_PROFILE)" \
		--output-format json \
		--wait \
		> $@

$(TMP)/submission-id.txt : $(TMP)/submit-log.json | $$(dir $$@)
	jq --raw-output '.id' < $< > $@

$(TMP)/notarization-log.json : $(TMP)/submission-id.txt | $$(dir $$@)
	xcrun notarytool log "$$(<$<)" \
		--keychain-profile "$(NOTARIZATION_KEYCHAIN_PROFILE)" \
		$@

$(TMP)/notarized.stamp.txt : $(TMP)/notarization-log.json | $$(dir $$@)
	test "$$(jq --raw-output '.status' < $<)" = "Accepted"
	date > $@

wget-$(ver).pkg : $(TMP)/wget-$(ver)-unnotarized.pkg $(TMP)/notarized.stamp.txt
	cp $< $@
	xcrun stapler staple $@

