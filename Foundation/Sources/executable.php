<?php
	/*
	 * Foundation.framework
	 * (C) Golden Delicious Computers GmbH&Co. KG, 2012
	 * All rights reserved.
	 */

// echo "loading Foundation<br>";

class NSObject
	{
	public function forwardInvocation(NSInvocation $invocation)
		{
		// default error handling
		}
	
	public function __call($name, $arguments)
    		{
		// convert into forwardInvocation
        	// Note: value of $name is case sensitive.
        	echo "Calling object method '$name' "
             		. implode(', ', $arguments). "\n";
    		}

	public function __construct()
		{ // empty constructor
		}
	}

class NSInvocation extends NSObject
	{
	public $target;
	public $selector;
	public $args=array();

	public function invoke()
		{
		return $this->$target->$selector($args);
		}

	public function invokeWithTarget($target)
		{
		$this->target=$target;
		return $this->invoke();
		}

	public function __constructor($selector)
		{
		parent::__constructor();
		$this->$selector=$selector;
		}
	}

// define (simple) classes for NSBundle, NSUserDefaults, etc.

class NSPropertyListSerialization extends NSObject
	{
	static function readPropertyListElementFromFile($file, $thisline)
		{ // read next element
			$line=trim($thisline);
				// this is a hack to read XML property lists
			if(substr($line, 0, 6) == "<dict>")
				{
				$ret=array();
				while($thisline=fgets($line))
					{
					$line=trim($thisline);
					if(substr($line, 0, -7) == "</dict>")
						break;
					$key=readPropertyListElementFromFile($file, $thisline);
					$value=readPropertyListElementFromFile($file, $thisline);
					$ret[$key]=$value;
					}
				return $ret;
				}
			if(substr($line, 0, 8) == "<array>")
				{
				$ret=array();
				while($thisline=fgets($line))
					{
					$line=trim($thisline);
					if(substr($line, 0, -9) == "</array>")
						break;
					$value=readPropertyListElementFromFile($file, $thisline);
					$ret[]=$value;
					}
				return $ret;
				}
			if(substr($line, 0, 5) == "<key>" || substr($line, 0, 8) == "<string>")
				{
				if(substr($line, 0, 5) == "<key>")
					$thisline=substr($line, 6);
				else
					$thisline=substr($line, 8);
				while(true)
					{
					$line=trim($thisline);
					if(substr($line, 0, -6) == "</key>" || substr($line, 0, -9) == "</string>")
						{
						$ret.=html_entity_decode(substr(substr($line, 5), 0, -6));	// append last fragment
						break;
						}
					$ret.=$thisline;
					$thisline=fgets($line);
					}
				return $ret;
				}
			if(substr($line, 0, 8) == "<number>")
				{
				
				}
		}
	public static function propertyListFromPath($path)
		{
		$filename=NSFileManager::fileSystemRepresentationWithPath($path);
//		echo "$filename =><br>";
		$f=fopen($filename, "r");	// open for reading
		if($f)
			{ // file exists and can be read
				while($line=fgets($f))
					{
					$line=trim($line);
					// this is a hack to read XML property lists
					if(substr($line, 0, 5) == "<key>")
						{
						$key=html_entity_decode(substr(substr($line, 5), 0, -6));
						continue;
						}
					if(substr($line, 0, 8) == "<string>")
						{
						// FIXME: handle multi-line strings
						$val=html_entity_decode(substr(substr($line, 8), 0, -9));
						$plist[$key]=$val;
						}
					}
				fclose($f);
			}
//		print_r($plist);
//		echo "<br>";
		return $plist;
		}
	static function writePropertyListElementToFile($element, $file)
		{
		// detect element type
		// write in XML string fromat
		}
	public static function writePropertyListToPath($plist, $path)
		{
		echo "no idea yet how to writePropertyListToPath($path)<br>";
		exit;		
		}
	}

function __load($path)
   {
//   echo "load bundle from $path<br>";
   return include($path);
   }

class NSBundle extends NSObject
{ // abstract superclass
	public $path;
	public static $mainBundle;
	public $infoDictionary;
	public $loaded=false;
	public function __contructor($path)
		{
		parent::__constructor();
		$this->path=$path;
		}
	public static function bundleWithPath($path) { return new NSBundle($path); }
	public static function mainBundle()
		{
		global $NSApp;
		if(!isset(NSBundle::$mainBundle))
			NSBundle::$mainBundle=new NSBundle($NSApp->path);
		return NSBundle::$mainBundle;
		}
	public static function bundleForClass($class)
		{
		echo "no idea yet how to get bundleForClass($class)<br>";
		// get_declared_classes()
		exit;
		}
	public function executablePath() { return $this->path."/Contents/php/executable.php"; }
	public function infoDictionary()
	{
		if(!isset($this->infoDictionary))
			{ // locate and load Info.plist
				$plistPath=$this->pathForResourceOfType("Info", "plist");
				echo "read $plistPath<br>";
				$this->infoDictionary=NSPropertyListSerialization::propertyListFromPath($plistPath);
			}
		return $this->infoDictionary;
	}
	public function pathForResourceOfType($name, $type)
		{
		// should apply search path and look in /Contents/Resources, /Resources until we find an existing file
		return $this->path."/Contents/$name.$type";
		}
	public function objectForInfoDictionaryKey($key)
		{
		$dict=$this->infoDictionary();
		return $dict[$key];
		}
	public function bundleIdentifier() { return $this->objectForInfoDictionaryKey('CFBundleIdentifier'); }
	public function principalClass()
		{
		$this->load();
		return $this->objectForInfoDictionaryKey('NSPrincipalClass');
		}
	public function load()
	{ // dynamically load the bundle classes
		if(!$this->loaded)
			$this->loaded=__load(NSFileManager::fileSystemRepresentationWithPath($this->executablePath()));
		return $this->loaded;
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

function NSHomeDirectoryForUser($user)
	{
	if($user == "")
		return "???";
	// we must make sure that nobody can try "username/../something"...
	return "/Users/".rawurlencode($user);
	}

function NSHomeDirectory()
	{
	return NSHomeDirectoryForUser(NSUserDefaults::standardUserDefaults()->user);
	}
	
class NSUserDefaults extends NSObject
{ // persistent values (user settings)
	public static $standardUserDefaults;
	public $user="";
	public $defaults;
	public $registeredDefaults=array();
	public static function standardUserDefaults()
	{
	if(!isset(self::$standardUserDefaults) || self::$standardUserDefaults->user == "")
		{ // read and check for proper login
//			echo "read and check for proper login ";
			
			$checkPassword=true;

		$defaults=new NSUserDefaults();
		self::$standardUserDefaults=$defaults;
		if(!$checkPassword)
			{ // dummy initialization
			$defaults->user="unchecked";
			$defaults->defaults=array();
			}
		else if($defaults->user != "" && isset($_COOKIE['passcode']))
			{ // check passcode
			$doublehash=md5($_COOKIE['passcode'].$defaults->user);	// 2nd hash so that the passcode can't be determined from the file system
			$stored=$defaults->stringForKey("NSUserPassword");
			echo "check $doublehash with $stored<br>";
			if($doublehash != $stored)
				$defaults->user="";	// does not match
			}
		}
	return self::$standardUserDefaults;
	}
	public static function resetStandardUserDefaults()
	{ // force re-read
		self::$standardUserDefaults->user="";
	}
	public function __constructor()
	{
		parent::__constructor();
		if(isset($_COOKIE['login']) && $_COOKIE['login'] != "")
			{
			$this->user=$_COOKIE['login'];
			$plist=NSHomeDirectoryForUser($this->user)."/Library/Preferences/NSGlobalDomain.plist";
			$this->defaults=NSPropertyListSerialization::propertyListFromPath($plist);
			if(!isset($this->defaults))
				$this->user="";
			}
		else
			$this->user="";
	}
	public function registerDefaults($dict)
	{
		$this->registeredDefaults=$dict;
	}
	public function dictionaryRepresentation()
	{
		// combine values into single return dictionary
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
	public function floatForKey($key) { return (float) $this->objectForKey($key); }
	public function integerForKey($key) { return (int) $this->objectForKey($key); }
	public function stringForKey($key) { return "".$this->objectForKey($key); }
	public function setBoolForKey($key, $val) { $val=$this->setObjectForKey($key, $val?"1":"0"); }
	public function setFloatForKey($key, $val) { $this->setObjectForKey($key, $val); }
	public function setIntegerForKey($key, $val) { $this->setObjectForKey($key, $val); }
	public function setStringForKey($key, $val) { $this->setObjectForKey($key, $val); }
}

class NSFileManager extends NSObject
	{
	public static function fileSystemRepresentationWithPath($path)
		{
		global $ROOT;
		return "$ROOT/$path";
		}
	}

// EOF
?>