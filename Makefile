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
	test "$(shell lipo -archs $(TMP)/install/usr/local/bin/wget)" = "x86_64 arm64"
	codesign --verify --strict $(TMP)/install/usr/local/bin/wget
	pkgutil --check-signature wget-$(version).pkg
	spctl --assess --type install wget-$(version).pkg
	xcrun stapler validate wget-$(version).pkg


