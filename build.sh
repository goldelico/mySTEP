export BUILD_FOR_PACKAGE=true
export SEND2ZAURUS=false
export RUN=false
 
echo ## Frameworks ##
for i in Foundation AppKit CoreData CoreFoundation Cocoa AddressBook Message PreferencePanes SystemUIPlugin Security SecurityFoundation SecurityInterface IOBluetooth ImageKit PDFKit QTKit ScreenSaver
	do
	(cd $i && ./build.sh) )
	done
echo ## done. ##

echo ## Extended Frameworks ##
for i in SimpleWebKit SystemConfiguration SystemStatus Tools CoreLocation MapKit CoreWLAN CoreRFID
	do
	(cd $i && ./build.sh) )
	done
echo ## done. ##

echo ## Special Frameworks ##
false && for i in UIKit
	do 
	(cd $i && ./build.sh) )
	done
echo ## done. ##

echo ## Tools ##
for i in Tools CoreData/DataBuilder CoreRFID/RFIDProbe
	do
	(cd $i && ./build.sh) )
	done
echo ## done. ##

echo ## TestApps ##
false && for i in TestApplications/NSImageRep TestApplications/NSTextTable TestApplications/NSURLConnection TestApplications/ZeroConfDistributedObjects
	do
	(cd $i && ./build.sh) )
	done
echo ## done. ##

# project settings
export SOURCES=   			  	 # no sources
export LIBS=  				   # add any additional libraries (or flags) like -ltiff etc.
export FRAMEWORKS=				   # add any additional Frameworks etc.
# export FILES="./etc ./System ./usr"		# additional files to include in package (relative to project install path)
# export DATA="./usr/bin/qssh ./usr/bin/qsx"	# additional files to include in package (relativ to root)
export INSTALL_PATH=/			   # override INSTALL_PATH for MacOS X

# global/compile settings
#export INSTALL=true                # true (or empty) will install locally to $ROOT/$INSTALL_PATH
#export SEND2ZAURUS=true		   # true (or empty) will try to install on the Zaurus at /$INSTALL_PATH (using ssh)
#export RUN=true                    # true (or empty) will finally try to run on the Zaurus (using X11 on host)

# debian package dependencies (, separated)
# this excludes the Tools and TestApps!

export DEPENDS="quantumstep-addressbook-framework, quantumstep-corefoundation-framework, quantumstep-iobluetooth-framework, quantumstep-iobluetoothui-framework, quantumstep-imagekit-framework, quantumstep-message-framework, quantumstep-qtkit-framework, quantumstep-preferencepanes-framework, quantumstep-screensaver-framework, quantumstep-securityinterface-framework, quantumstep-webkit-framework, quantumstep-systemstatus-framework, quantumstep-systemuiplugin-framework, quantumstep-corelocation-framework, quantumstep-mapkit-framework, quantumstep-corewlan-framework, quantumstep-corerfid-framework"

[ "$ROOT" ] || export ROOT=/usr/share/QuantumSTEP	# project root
/usr/bin/make -f $ROOT/System/Sources/Frameworks/mySTEP.make $ACTION
