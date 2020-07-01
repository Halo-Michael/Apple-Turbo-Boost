TARGET = Apple Illuminator
VERSION = 0.6.7
CC = xcrun -sdk ${THEOS}/sdks/iPhoneOS13.0.sdk clang -arch arm64 -arch arm64e -fobjc-arc -miphoneos-version-min=11.0
LDID = ldid

.PHONY: all clean

all: clean postinst prerm postrm
	mkdir com.michael.appleilluminator_$(VERSION)_iphoneos-arm
	mkdir com.michael.appleilluminator_$(VERSION)_iphoneos-arm/DEBIAN
	cp control com.michael.appleilluminator_$(VERSION)_iphoneos-arm/DEBIAN
	mv postinst prerm postrm com.michael.appleilluminator_$(VERSION)_iphoneos-arm/DEBIAN
	dpkg -b com.michael.appleilluminator_$(VERSION)_iphoneos-arm

postinst: clean
	$(CC) postinst.m -o postinst
	strip postinst
	$(LDID) -Sentitlements.xml postinst

prerm: clean
	$(CC) prerm.m -o prerm
	strip prerm
	$(LDID) -Sentitlements.xml prerm

postrm: clean
	$(CC) postrm.m -o postrm
	strip postrm
	$(LDID) -Sentitlements.xml postrm

clean:
	rm -rf com.michael.appleilluminator_* postinst prerm postrm
