APP_SIGNING_ID ?= Developer ID Application: Donald McCaughey
INSTALLER_SIGNING_ID ?= Developer ID Installer: Donald McCaughey
NOTARIZATION_KEYCHAIN_PROFILE ?= Donald McCaughey
TMP ?= $(abspath tmp)

version := 1.21.4
libiconv_version := 1.17
openssl_version := 1.1.1s
zlib_version := 1.2.13
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
	test "$(shell lipo -archs $(TMP)/openssl/install/usr/local/lib/libcrypto.a)" = "x86_64 arm64"
	test "$(shell lipo -archs $(TMP)/openssl/install/usr/local/lib/libssl.a)" = "x86_64 arm64"
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


.PHONY : openssl
openssl : \
			$(TMP)/openssl/install/usr/local/include/openssl/ssl.h \
			$(TMP)/openssl/install/usr/local/lib/libcrypto.a \
			$(TMP)/openssl/install/usr/local/lib/libssl.a


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
$(TMP)/libiconv/install/usr/local/lib/libiconv.a : $(TMP)/libiconv/installed.stamp.txt
	@:

$(TMP)/libiconv/installed.stamp.txt : \
			$(TMP)/libiconv/build/include/iconv.h \
			$(TMP)/libiconv/build/lib/.libs/libiconv.a \
			| $$(dir $$@)
	cd $(TMP)/libiconv/build && $(MAKE) DESTDIR=$(TMP)/libiconv/install install
	date > $@

$(TMP)/libiconv/build/include/iconv.h \
$(TMP)/libiconv/build/lib/.libs/libiconv.a : $(TMP)/libiconv/built.stamp.txt | $$(dir $$@)
	@:

$(TMP)/libiconv/built.stamp.txt : $(TMP)/libiconv/configured.stamp.txt | $$(dir $$@)
	cd $(TMP)/libiconv/build && $(MAKE)
	date > $@

$(TMP)/libiconv/configured.stamp.txt : $(libiconv_sources) | $(TMP)/libiconv/build
	cd $(TMP)/libiconv/build \
			&& $(abspath libiconv/configure) $(libiconv_config_options)
	date > $@

$(TMP)/libiconv \
$(TMP)/libiconv/build \
$(TMP)/libiconv/install :
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
$(TMP)/openssl/arm64/install/usr/local/lib/libssl.a : $(TMP)/openssl/arm64/installed.stamp.txt
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

$(TMP)/openssl/x86_64/install/usr/local/include/openssl/ssl.h \
$(TMP)/openssl/x86_64/install/usr/local/lib/libcrypto.a \
$(TMP)/openssl/x86_64/install/usr/local/lib/libssl.a : $(TMP)/openssl/x86_64/installed.stamp.txt
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


#### zlib ##########

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
		--disable-iri \
		--disable-pcre2 \
		--disable-pcre \
		--without-libpsl \
		--with-ssl=openssl \
		--with-libiconv-prefix=$(TMP)/libiconv/install/usr/local \
		--with-libssl-prefix=$(TMP)/openssl/install/usr/local \
		CFLAGS='$(CFLAGS)' \
		ZLIB_CFLAGS='-I $(TMP)/zlib/install/usr/local/include' \
		ZLIB_LIBS='-lz -L$(TMP)/zlib/install/usr/local/lib'

wget_sources := $(shell find wget -type f \! -name .DS_Store)

$(TMP)/wget/install/usr/local/bin/wget : $(TMP)/wget/build/src/wget | $(TMP)/wget/install
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
				$(TMP)/openssl/install/usr/local/include/openssl/ssl.h \
				$(TMP)/openssl/install/usr/local/lib/libcrypto.a \
				$(TMP)/openssl/install/usr/local/lib/libssl.a \
				$(TMP)/zlib/install/usr/local/include/zlib.h \
				$(TMP)/zlib/install/usr/local/lib/libz.a \
				| $(TMP)/wget/build
	cd $(TMP)/wget/build && sh $(abspath wget/configure) $(wget_configure_options)

$(TMP)/wget/build \
$(TMP)/wget/install :
	mkdir -p $@


##### pkg ##########

$(TMP)/wget.pkg : \
		$(TMP)/wget/install/usr/local/bin/uninstall-wget
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
	printf 'OpenSSL Version: %s\n' "$(openssl_version)" >> $@
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
	printf 'Tag Title: wget %s for macOS rev %s\n' "$(version)" "$(revision)" >> $@
	printf 'Tag Message: A signed and notarized universal installer package for `wget` %s, built with libiconv %s, OpenSSL %s and zlib %s.\n' \
		"$(version)" "$(libiconv_version)" "$(openssl_version)" "$(zlib_version)" >> $@

$(TMP)/distribution.xml \
$(TMP)/resources/welcome.html : $(TMP)/% : % | $$(dir $$@)
	sed \
		-e 's/{{arch_list}}/$(arch_list)/g' \
		-e 's/{{date}}/$(date)/g' \
		-e 's/{{macos}}/$(macos)/g' \
		-e 's/{{libiconv_version}}/$(libiconv_version)/g' \
		-e 's/{{openssl_version}}/$(openssl_version)/g' \
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

