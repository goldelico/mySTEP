<?php
	/*
	 * Foundation.framework
	 * (C) Golden Delicious Computers GmbH&Co. KG, 2012
	 * All rights reserved.
	 */
	
// define (simple) classes for NSBundle, NSUserDefaults

class NSBundle
{ // abstract superclass
	public function mainBundle() {  }
	public function addSubview($view) { $this->subviews[]=$view; }
	public function executablePath() { }
	public function resourcePath($name, $type) { }
}

class NSUserDefaults
{ // persistent values (user settings)
// we require a valid login here - i.e. apps not requiring a specific user could run w/o login cookie
// store in MySQL backend
// if not - 	$NSApp->open("loginwindow.app");

}

class NSFileManager
	{
	
	}

// EOF
?>