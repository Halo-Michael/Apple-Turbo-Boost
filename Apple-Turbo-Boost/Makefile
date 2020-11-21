TARGET = Apple Turbo Boost
VERSION = 0.7.0
CC = xcrun -sdk ${THEOS}/sdks/iPhoneOS13.0.sdk clang -arch arm64 -arch arm64e -miphoneos-version-min=11.0
LDID = ldid

.PHONY: all clean

all: clean postinst prerm postrm
	mkdir com.michael.appleturboboost_$(VERSION)_iphoneos-arm
	mkdir com.michael.appleturboboost_$(VERSION)_iphoneos-arm/DEBIAN
	cp control com.michael.appleturboboost_$(VERSION)_iphoneos-arm/DEBIAN
	mv postinst prerm postrm com.michael.appleturboboost_$(VERSION)_iphoneos-arm/DEBIAN
	dpkg -b com.michael.appleturboboost_$(VERSION)_iphoneos-arm

postinst: clean
	$(CC) postinst.m -fobjc-arc -o postinst
	strip postinst
	$(LDID) -Sentitlements.xml postinst

prerm: clean
	$(CC) prerm.m -fobjc-arc -o prerm
	strip prerm
	$(LDID) -Sentitlements.xml prerm

postrm: clean
	$(CC) postrm.c -o postrm
	strip postrm
	$(LDID) -Sentitlements.xml postrm

clean:
	rm -rf com.michael.appleturboboost_* postinst prerm postrm
