
This file last modified on 27-Jan-2005 by William Swats.
Copyright (c) 2001-2005 Sen:te (Sente SA).  All rights reserved.

To build a OCUnit Root package for Panther using the PackageMaker application. Use OCUnitRoot.pmsp in OCUnit/Extras/Packaging/RootPackage and perform the following steps.

	1) cd to some place nice (like /Users/william/Distributions/OCUnit). If an old directory by the name of OCUnitRootPackage exists then delete it. It is left over from the previous build of the root package.

	2) Run the bash script named buildRootPackage using sudo with one argument.
		- The absolute path to the OCUnit workarea.

		
		Here is an example:

		sudo /Users/william/Projects/OCUnit/Extras/Packaging/RootPackage/buildRootPackage /Users/william/Projects/OCUnit

		This script performs the following functions:

			a) Creates a folder by the name of OCUnitRootPackage
				and then creates the following directories under it:
				Root/Developer/Examples
				Root/Developer/Tools
				Root/Developer/Source
				Root/Library/Application Support/Apple/Developer Tools/File Templates/Cocoa
				Root/Library/Application Support/Apple/Developer Tools/Project Templates/Application
				Root/Library/Application Support/Apple/Developer Tools/Project Templates/Bundle
				Root/Library/Application Support/Apple/Developer Tools/Project Templates/Framework
				Root/Library/Application Support/Apple/Developer Tools/Target Templates/Cocoa
				Root/Library/Frameworks

			b) Copies the following files and/or directories to the directories created above:

				OCUnit/Extras/Xcode Integration/Tools/RunTargetUnitTests to Developer/Tools/
				OCUnit/SourceCode/SenTestingKit/Documentation/IntroSenTestingKit.html to Developer/Documentation/OCUnit/
				SenTestingKit.framework to Library/Frameworks/
				OCUnit/Extras/Xcode Integration/Templates/File Templates to  Library/Application Support/Apple/Developer Tools/
				OCUnit/Extras/Xcode Integration/Templates/Project Templates to  Library/Application Support/Apple/Developer Tools/
				OCUnit/Extras/Xcode Integration/Templates/Target Templates to  Library/Application Support/Apple/Developer Tools/


			c) Builds the SenTestingKit framework using the RootDeployment
			   style and then copies the results to Root/Library/Frameworks.

			d) Builds the otest tool using the RootDeployment style and then copies
			   the results to Root/Developer/Tools.

			e) Deletes all the CVS directories.

			f) Deletes all the hidden .DS_Store files so as not to confuse the finder when
	   			the above directory contents are installed.

			g) Changes the owner and group of the directory and files to root and staff.

			h) Creates a Resource folder (e.g. OCUnitRootPackage/Resources) and copies 
	   			the following files to it:
				- Welcome.rtf
				- IFRequirement.strings
	3) Open PackageMaker by double clicking on OCUnit/Extras/Packaging/OCUnitRoot.pmsp

	3a) Change the version number in two places (Description and Version).

	4) Set the Package Root Directory of OCUnitRoot.pmsp document
	   to your recently created folder (i.e. OCUnitRootPackage/Root).

	5) Set the Package Resources Directory of OCUnitRoot.pmsp document
	   to your recently created folder (i.e. OCUnitRootPackage/Resources).

	6) Create your package by selecting the menu item "File -> Create Package". Change the package name
           to OCUnitRoot.pkg and (maybe the path) path (i.e. /Users/william/Distributions/OCUnit/OCUnitRoot.pkg).

	7) Insert the contents of IFRequirementsInfo.plist into the info.plist found in 
	   the package just created (i.e. OCUnitRoot.pkg). Note: every time the "Create 
	   Package" menu item is run in the PackageMaker application, the info.plist will
	   be created without the contents of IFRequirementsInfo.plist. So after each 
	   creation of a new package this step will need to be repeated. Insert the contents
	   above the last two lines in the info.plist. These are the last two lines:

		</dict>
		</plist>

	8) Use the Disk Utility app to create an empty 2.5MB read/write disk image 
	   (e.g. OCUnitRoot-v34.dmg) and then in the Finder drag the OCUnitRoot.pkg into it.
	   Create a read-only compressed image of OCUnitRoot-v34.dmg using the Disk Utility app.
	   Select the read/write disk image and click on the Convert menu item. Then name it
	   and select the compression popup button.


