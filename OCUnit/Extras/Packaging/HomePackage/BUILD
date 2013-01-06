
This file last modified on 25-Mar-2004 by William Swats.
Copyright (c) 2001-2005 Sen:te (Sente SA).  All rights reserved.

To build a OCUnit Home package for Panther perform the following steps:



	1) Use the Disk Utility app to create an empty 10MB read/write disk
	   image  (e.g. OCUnitHome-v36.dmg) and then in the 
	   Finder drag the OCUnit folder into it. Then drag the files
	   OCUnit/Extras/Packaging/HomePackage/ReadMe.rtf and
	   OCUnit/Extras/Packaging/License.html and 
	   OCUnit/Extras/Packaging/sente.gif into it. 
	   Then close it.

	2) Create a read-only compressed image of 
	   OCUnitHome-v36.dmg using the Disk Utility app.
	   Select the read/write disk image and click on the Convert menu 
	   item. Then name it OCUnitHome-v36.dmg and select the 
	   compression popup button.


	3) Build a tgz package also.
		a) Create a directory /tmp/OCUnitHome.
		b) Add the OCUnit folder into it. Then drag the files
	   	   OCUnit/Extras/Packaging/HomePackage/ReadMe.rtf and
	   	   OCUnit/Extras/Packaging/License.html and 
	   	   OCUnit/Extras/Packaging/sente.gif into it. 
		c) Run the following command:
		   cd /tmp
		   gnutar --create --file OCUnitHome-v36.tgz --gzip OCUnitHome/

