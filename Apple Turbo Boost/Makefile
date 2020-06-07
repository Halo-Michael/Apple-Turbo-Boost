TARGET = Apple Turbo Boost
VERSION = 0.6.0

.PHONY: all clean

all: clean postinst prerm
	mkdir com.michael.appleturboboost_$(VERSION)_iphoneos-arm
	mkdir com.michael.appleturboboost_$(VERSION)_iphoneos-arm/DEBIAN
	cp control com.michael.appleturboboost_$(VERSION)_iphoneos-arm/DEBIAN
	mv postinst/.theos/obj/postinst prerm/.theos/obj/prerm com.michael.appleturboboost_$(VERSION)_iphoneos-arm/DEBIAN
	dpkg -b com.michael.appleturboboost_$(VERSION)_iphoneos-arm

postinst: clean
	sh make-postinst.sh

prerm: clean
	sh make-prerm.sh

clean:
	rm -rf com.michael.appleturboboost_* postinst/.theos prerm/.theos
