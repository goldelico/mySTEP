<?php
/*
 * PreferencePanes.framework
 * (C) Golden Delicious Computers GmbH&Co. KG, 2012
 * All rights reserved.
 *
 * defines (simple) classes for NSWindow, NSView, NSButton, NSTextField, NSSecureTextField, NSForm, NSImage, NSTable, NSPopUpButton
 * draw method generates html output
 * hitTest, sendEvent and mouseDown called when button is clicked or something modified
 */

echo "loading PreferencePanes<br>";

require_once "$ROOT/System/Library/Frameworks/AppKit.framework/Versions/Current/php/executable.php";		

class NSPreferencePane
	{
	public $bundle;
	public $mainView;
	public function NSPreferencePane($bundle)
		{
		$this->bundle=$bundle;
		}
	public function loadMainView()
		{
		$this->mainView=new NSStaticTextField("loadMainView not overwritten");
		}
	public function mainView() { return $this->mainView; }
	}

// EOF
?>