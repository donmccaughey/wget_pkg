APP_SIGNING_ID ?= Developer ID Application: Donald McCaughey
INSTALLER_SIGNING_ID ?= Developer ID Installer: Donald McCaughey
NOTARIZATION_KEYCHAIN_PROFILE ?= Donald McCaughey
TMP ?= $(abspath tmp)

version := 1.21.2
libiconv_version := 1.16
openssl_version := 1.1.1m
revision := 2
archs := arm64 x86_64

rev := $(if $(patsubst 1,,$(revision)),-r$(revision),)
ver := $(version)$(rev)


.SECONDEXPANSION :


.PHONY : signed-package
signed-package : wget-$(ver).pkg


.PHONY : notarize
notarize : $(TMP)/stapled.stamp.txt


.PHONY : clean
clean :
	-rm -f wget-*.pkg
	-rm -rf $(TMP)


.PHONY : check
check :
	test "$(shell lipo -archs $(TMP)/openssl/install/usr/local/lib/libcrypto.a)" = "x86_64 arm64"
	test "$(shell lipo -archs $(TMP)/openssl/install/usr/local/lib/libssl.a)" = "x86_64 arm64"
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


.PHONY : wget
wget : $(TMP)/wget.pkg


.PHONY : clean-wget
clean-wget :
	rm -rf $(TMP)/wget


##### compilation flags ##########

arch_flags = $(patsubst %,-arch %,$(archs))

CFLAGS += $(arch_flags)


##### libiconv ##########

libiconv_config_options := --disable-shared

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


##### wget ##########

wget_configure_options := \
		--disable-silent-rules \
		--with-ssl=openssl \
		--with-libiconv-prefix=$(TMP)/libiconv/install/usr/local \
		--with-libssl-prefix=$(TMP)/openssl/install/usr/local \
		CFLAGS='$(CFLAGS)'

wget_sources := $(shell find wget -type f \! -name .DS_Store)

$(TMP)/wget/install/usr/local/bin/wget : $(TMP)/wget/build/src/wget | $(TMP)/wget/install
	cd $(TMP)/wget/build && $(MAKE) DESTDIR=$(TMP)/wget/install install

$(TMP)/wget/build/src/wget : $(TMP)/wget/build/config.status $(wget_sources)
	cd $(TMP)/wget/build && $(MAKE)

$(TMP)/wget/build/config.status : \
				wget/configure \
				$(TMP)/libiconv/install/usr/local/include/iconv.h \
				$(TMP)/libiconv/install/usr/local/lib/libiconv.a \
				$(TMP)/openssl/install/usr/local/include/openssl/ssl.h \
				$(TMP)/openssl/install/usr/local/lib/libcrypto.a \
				$(TMP)/openssl/install/usr/local/lib/libssl.a \
				| $(TMP)/wget/build
	cd $(TMP)/wget/build && sh $(abspath wget/configure) $(wget_configure_options)

$(TMP)/wget/build \
$(TMP)/wget/install :
	mkdir -p $@


##### pkg ##########

# sign executable

$(TMP)/signed.stamp.txt : $(TMP)/wget/install/usr/local/bin/wget | $$(dir $$@)
	xcrun codesign \
		--sign "$(APP_SIGNING_ID)" \
		--options runtime \
		$<
	date > $@

# uninstall

$(TMP)/wget/install/usr/local/bin/uninstall-wget : \
		./uninstall-wget \
		$(TMP)/wget/install/etc/paths.d/wget.path \
		$(TMP)/wget/install/usr/local/bin/wget \
		| $$(dir $$@)
	cp $< $@
	cd $(TMP)/wget/install && find . -type f \! -name .DS_Store | sort >> $@
	sed -e 's/^\./rm -f /g' -i '' $@
	chmod a+x $@

$(TMP)/wget.pkg : \
		$(TMP)/signed.stamp.txt \
		$(TMP)/wget/install/etc/paths.d/wget.path \
		$(TMP)/wget/install/usr/local/bin/uninstall-wget
	pkgbuild \
		--root $(TMP)/wget/install \
		--identifier cc.donm.pkg.wget \
		--ownership recommended \
		--version $(version) \
		$@

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

wget-$(ver).pkg : \
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
	printf 'Installer Revision: %s\n' "$(revision)" >> $@
	printf 'Architectures: %s\n' "$(arch_list)" >> $@
	printf 'macOS Version: %s\n' "$(macos)" >> $@
	printf 'Xcode Version: %s\n' "$(xcode)" >> $@
	printf 'Tag Version: v%s-r%s\n' "$(version)" "$(revision)" >> $@
	printf 'APP_SIGNING_ID: %s\n' "$(APP_SIGNING_ID)" >> $@
	printf 'INSTALLER_SIGNING_ID: %s\n' "$(INSTALLER_SIGNING_ID)" >> $@
	printf 'TMP directory: %s\n' "$(TMP)" >> $@
	printf 'CFLAGS: %s\n' "$(CFLAGS)" >> $@
	printf 'Release Title: wget %s for macOS rev %s\n' "$(version)" "$(revision)" >> $@
	printf 'Description: A signed macOS installer package for `wget` %s.\n' "$(version)" >> $@

$(TMP)/distribution.xml \
$(TMP)/resources/welcome.html : $(TMP)/% : % | $$(dir $$@)
	sed \
		-e 's/{{arch_list}}/$(arch_list)/g' \
		-e 's/{{date}}/$(date)/g' \
		-e 's/{{macos}}/$(macos)/g' \
		-e 's/{{libiconv_version}}/$(libiconv_version)/g' \
		-e 's/{{openssl_version}}/$(openssl_version)/g' \
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

$(TMP)/submit-log.json : wget-$(ver).pkg | $$(dir $$@)
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

$(TMP)/stapled.stamp.txt : wget-$(ver).pkg $(TMP)/notarized.stamp.txt
	xcrun stapler staple $<
	date > $@

