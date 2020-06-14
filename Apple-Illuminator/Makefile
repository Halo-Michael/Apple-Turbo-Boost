TARGET = Apple Illuminator
VERSION = 0.6.6

.PHONY: all clean

all: clean postinst prerm postrm
	mkdir com.michael.appleilluminator_$(VERSION)_iphoneos-arm
	mkdir com.michael.appleilluminator_$(VERSION)_iphoneos-arm/DEBIAN
	cp control com.michael.appleilluminator_$(VERSION)_iphoneos-arm/DEBIAN
	mv postinst/.theos/obj/postinst prerm/.theos/obj/prerm postrm/.theos/obj/postrm com.michael.appleilluminator_$(VERSION)_iphoneos-arm/DEBIAN
	dpkg -b com.michael.appleilluminator_$(VERSION)_iphoneos-arm

postinst: clean
	sh make-postinst.sh

prerm: clean
	sh make-prerm.sh

postrm: clean
	sh make-postrm.sh

clean:
	rm -rf com.michael.appleilluminator_* postinst/.theos prerm/.theos postrm/.theos
