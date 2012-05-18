<?php
	/*
	 * Foundation.framework
	 * (C) Golden Delicious Computers GmbH&Co. KG, 2012
	 * All rights reserved.
	 */
	
// define (simple) classes for NSBundle, NSUserDefaults

class NSBundle
{ // abstract superclass
	public $path;
	public static $mainBundle;
	public $infoDictionary;
	public function NSBundle($path)
		{
		$this->path=$path;
		}
	public static function mainBundle()
		{
		global $NSApp;
		if(!isset(NSBundle::$mainBundle))
			NSBundle::$mainBundle=new NSBundle($NSApp->path);
		return NSBundle::$mainBundle;
		}
	public static function bundleForClass($class) { }
	public function addSubview($view) { $this->subviews[]=$view; }
	public function executablePath() { return $path."/Contents/php/executable.php"; }
	public function infoDictionary()
	{
		if(!isset($this->infoDictionary))
			{ // locate and load Info.plist
			
			}
		return $this->infoDictionary;
	}
	public function resourcePath($name, $type) { }
	public function objectForInfoDictionaryKey($key)
	{
		$dict=$this->infoDictionary();
		return $dict[$key];
	}
	public function principalClass()
	{
		return $this->objectForInfoDictionaryKey('NSPrincipalClass');
	}
	public function load()
	{ // dynamically load the bundle classes
		$path=$this->executablePath();
		include $path;
	}
}
	
	/* set new passcode
	 *
	 * $passcode=md5($login.$password);
	 * $defaults->setStringForKey("NSUserPassword", md5($passcode.$login))
	 * setcookie("passcode", $passcode, 24*3600);
	 * $_COOKIE['passcode']=$passcode;
	 * NSUserDefaults::resetStandardUserDefaults();
	 *
	 * was bedeutet das für den aktuellen login?
	 * vermutlich, dass man sich in der aktuellen App noch bewegen kann
	 *
	 */

// FIXME: chmod("/einverzeichnis/einedatei", 0750);	auf /Users/<username>
// Problem: wenn php drankommt, dann kommt auch der WebServer dran!?!

class NSUserDefaults
{ // persistent values (user settings)
	public static $standardUserDefaults;
	public $user="";
	public $defaults;
	public $registeredDefaults=array();
	public static function standardUserDefaults()
	{
	if(!isset(self::$standardUserDefaults) || self::$standardUserDefaults->user == "")
		{ // read and check for proper login
			
			$checkPassword=false;

		if(!$checkPassword)
			$_COOKIE['login']="user";
		$defaults=new NSUserDefaults();
		if(!$checkPassword)
			self::$standardUserDefaults=$defaults;
		if(isset($defaults->user) && isset($_COOKIE['passcode']))
			{
			$doublehash=md5($_COOKIE['passcode'].$defaults->user);	// 2nd hash so that the passcode can't be determined from the file system
			if($doublehash == $defaults->stringForKey("NSUserPassword"))
				self::$standardUserDefaults=$defaults;	// does match
			}
		}
	return self::$standardUserDefaults;
	}
	public static function resetStandardUserDefaults()
	{ // force re-read
		self::$standardUserDefaults->user="";
	}
	public function NSUserDefaults()
	{
		if(isset($_COOKIE['login']) && $_COOKIE['login'] != "")
			{
			$this->user=$_COOKIE['login'];
			// if file exists and can be read
			$this->defaults=array();
			// read $this->defaults from file system ($ROOT/Users/$login/Library/Preferences/NSGlobalDomain.plist)			
			}
	}
	public function registerDefaults($dict)
	{
		$this->registeredDefaults=$dict;
	}
	public function dictionaryRepresentation()
	{
		// combine values
		return $this->defaults;
	}
	public function objectForKey($key)
	{ // go through the domains
//		print_r($this->defaults);
//		print_r($key);
		$val=$this->defaults[$key];
//		print_r($val);
		if(isset($val))
			return $val;
		$val=$this->registeredDefaults[$key];
//		print_r($this->registeredDefaults);
//		print_r($val);
		return $val;
	}
	public function setObjectForKey($key, $val)
	{
		$this->defaults[$key]=$val;
		// write to file system
	}
	public function boolForKey($key) { $val=$this->objectForKey($key); return $val=="1" || $val == "true" || $val == "YES"; }
	public function floatForKey($key) { (float) $this->objectForKey($key); }
	public function integerForKey($key) { (int) $this->objectForKey($key); }
	public function stringForKey($key) { "".$this->objectForKey($key); }
	public function setBoolForKey($key, $val) { $val=$this->setObjectForKey($key, $val?"1":"0"); }
	public function setFloatForKey($key, $val) { $this->setObjectForKey($key, $val); }
	public function setIntegerForKey($key, $val) { $this->setObjectForKey($key, $val); }
	public function setStringForKey($key, $val) { $this->setObjectForKey($key, $val); }
}

class NSFileManager
	{
	
	}

// EOF
?>