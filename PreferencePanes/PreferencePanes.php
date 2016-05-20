<?php
/*
 * PreferencePanes.framework
 * (C) Golden Delicious Computers GmbH&Co. KG, 2012-2015
 * All rights reserved.
 *
 */

// echo "loading PreferencePanes.framework<br>";

global $ROOT;	// must be set by some .app
require_once "$ROOT/System/Library/Frameworks/AppKit.framework/Versions/Current/php/AppKit.php";		

class NSPreferencePane extends NSObject
	{
	public $bundle;
	public $mainView;
	public function NSPreferencePane($bundle)
		{
		$this->bundle=$bundle;
		}
	public function loadMainView()
		{
		$this->mainView=new NSextField();
		$this->mainView->setAttributedStringValue("loadMainView of ".$this->bundle->description()." is not overwritten");
		}
	public function mainView()
		{
		return $this->mainView;
		}
	public function mainViewDidLoad()
		{ // override to initialize with current preference settings
		return;
		}
	}

// EOF
?>