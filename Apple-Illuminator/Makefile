TARGET = Apple Illuminator
VERSION = 0.6.2

.PHONY: all clean

all: clean postinst prerm
	mkdir com.michael.appleilluminator_$(VERSION)_iphoneos-arm
	mkdir com.michael.appleilluminator_$(VERSION)_iphoneos-arm/DEBIAN
	cp control com.michael.appleilluminator_$(VERSION)_iphoneos-arm/DEBIAN
	mv postinst/.theos/obj/postinst prerm/.theos/obj/prerm com.michael.appleilluminator_$(VERSION)_iphoneos-arm/DEBIAN
	dpkg -b com.michael.appleilluminator_$(VERSION)_iphoneos-arm

postinst: clean
	sh make-postinst.sh

prerm: clean
	sh make-prerm.sh

clean:
	rm -rf com.michael.appleilluminator_* postinst/.theos prerm/.theos
