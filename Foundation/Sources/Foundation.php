<?php
	/*
	 * Foundation.framework
	 * (C) Golden Delicious Computers GmbH&Co. KG, 2012
	 * All rights reserved.
	 */

	/*
	 * design principle
	 * 1. resemble Cocoa classes (exceptions: arrays and strings)
	 * 2. use class::name() / public static function name() for class methods
	 * 3. use $this->name() / public function name() for instance methods
	 */

// global $ROOT must be set by some application

// echo "loading Foundation<br>";

// error handler function
function myErrorHandler($errno, $errstr, $errfile, $errline)
{
    if (!(error_reporting() & $errno)) {
        // This error code is not included in error_reporting
        return;
    }

    switch ($errno) {
    case E_USER_ERROR:
        echo "<b>My ERROR</b> [$errno] $errstr<br />\n";
        echo "  Fatal error on line $errline in file $errfile";
        echo ", PHP " . PHP_VERSION . " (" . PHP_OS . ")<br />\n";
        echo "Aborting...<br />\n";
        exit(1);
        break;

    case E_USER_WARNING:
        echo "<b>My WARNING</b> [$errno] $errstr<br />\n";
        break;

    case E_USER_NOTICE:
        echo "<b>My NOTICE</b> [$errno] $errstr<br />\n";
        break;

    default:
        echo "Unknown error type: [$errno] $errstr<br />\n";
        break;
    }

    /* Don't execute PHP internal error handler */
    return true;
}

$old_error_handler = set_error_handler("myErrorHandler");

class NSObject
	{
	public function forwardInvocation(NSInvocation $invocation)
		{
		// default error handling
		}
	
	public function __call($name, $arguments)
    		{
			$inv = new NSInvocation($name, $arguments);
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
	protected $target;
	protected $selector;
	protected $args=array();

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

class NSPropertyListSerialization extends NSObject
	{
	private static function readPropertyListElementFromFile($file, $thisline)
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
	private static function writePropertyListElementToFile($element, $file)
		{
		echo "no idea yet how to writePropertyListElementToPath(..., $file)<br>";
		// detect element type
		// write in XML string fromat
		}
	public static function writePropertyListToPath($plist, $path)
		{
		// write header
		writePropertyListElementToFile($plist, path);
		// append trailer
		}
	}

function __load($path)
   {
//   echo "load bundle from $path<br>";
   return include($path);
   }

class NSBundle extends NSObject
{ // abstract superclass
	protected $path;
	protected static $mainBundle;
	protected $allBundles;
	protected $infoDictionary;
	protected $loaded=false;
	public function __contructor($path)
		{
		parent::__constructor();
		$this->path=$path;
		$allBundles[]=$this;
		}
	public static function bundleWithPath($path) { return new NSBundle($path); }
	public static function allBundles() { return $allBundles; }
	public static function mainBundle()
		{
		global $NSApp;
		if(!isset(NSBundle::$mainBundle))
			NSBundle::$mainBundle=new NSBundle($NSApp->path);
		return NSBundle::$mainBundle;
		}
	public static function bundleForClass($class)
		{
		echo "no idea how to get bundleForClass($class)<br>";
		// get_declared_classes()
		exit;
		}
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
	public function executablePath() { return $this->path."/Contents/php/".($this->objectForInfoDictionaryKey('CFBundleExecutable')).".php"; }
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
	public static function bundleWithIdentifier($ident)
		{
		foreach ($allBundles as $bundle)
			if($bundle->bundleIdentifier() == $ident)
				return $bundle;	// found
		return NULL;
		}
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
	$ud=NSUserDefaults::standardUserDefaults();
	if(!isset($ud))
		return @"/";
	return NSHomeDirectoryForUser($ud->user());
	}
	
class NSUserDefaults extends NSObject
{ // persistent values (user settings)
	protected static $standardUserDefaults;
	protected $user="";
	protected $defaults;
	protected $registeredDefaults=array();
	public static function standardUserDefaults()
	{
	if(!isset(self::$standardUserDefaults) || self::$standardUserDefaults->user == "")
		{ // read and check for proper login
			//			echo "read and check for proper login ";
			
			// FIXME: should be some site specific setting?
			$checkPassword=true;

			$defaults=new NSUserDefaults();
			self::$standardUserDefaults=$defaults;
			// FIXME: check if this is really best in class passwort handling for web/php
			if(!$checkPassword)
				{ // dummy initialization
					$defaults->user="N.N.";
					$defaults->defaults=array();
				}
			else if($defaults->user != "" && isset($_COOKIE['passcode']))
				{ // check passcode
					$doublehash=md5($_COOKIE['passcode'].$defaults->user);	// 2nd hash so that the passcode can't be determined from the file system
					$stored=$defaults->stringForKey("NSUserPassword");
					echo "check $doublehash with $stored<br>";
					if($doublehash != $stored)
						$this->resetStandardUserDefaults();	// does not match
				}
		}
	return self::$standardUserDefaults;
	}
	public static function resetStandardUserDefaults()
	{ // force re-read
		unset(self::$standardUserDefaults);
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
	const NSFileName="NSFileName";
	const NSFileType="NSFileType";
	const NSFileTypeDirectory="NSFileTypeDirectory";
	const NSFileTypeRegular="NSFileTypeRegular";
	protected static $defaultManager;
	protected $user="";
	protected $defaults;
	protected $registeredDefaults=array();
	public static function defaultManager()
	{
		if(!isset(self::$defaultManager))
			{ // read and check for proper login
			self::$defaultManager=new NSFileManager();
			}
		return self::$defaultManager;
	}
	public function fileSystemRepresentationWithPath($path)
		{
		global $ROOT;
		// check for absolute vs. relative paths???
		return $path;
		}
	public function stringWithFileSystemRepresentation($path)
		{
		global $ROOT;
		// strip off $ROOT/ prefix
		return $path;
		}
	public function attributesOfItemAtPath($path)
		{
		$f=$this->fileSystemRepresentationWithPath($path);
//		echo "attributesOfItemAtPath($path) -> $f ";
		$a=stat($f);
		if($a === FALSE)
			return NULL;
		$attribs=array();
/*
 * collect real file access permissions as defined by file system, local and global .htaccess etc.
 *
 * user:
 * group:
 * other: defines access as through web server
 */
		$attribs[NSFileManager::NSFileName]=$path;
		$attribs[NSFileManager::NSFileType]=is_dir($f)?NSFileManager::NSFileTypeDirectory:NSFileManager::NSFileTypeRegular;
		return $attribs;
		}
	public function setAttributesOfItemAtPath($path, $attributes)
		{
		}
	public function fileExistsAtPath($path)
		{
		return $this->attributesOfItemAtPath($path) != NULL;
		}
	public function fileExistsAtPathAndIsDirectory($path, &$isDir)
		{
		$attr=$this->attributesOfItemAtPath($path);
		if($attr == NULL)
			return NO;
		$isDir=$attr[NSFileManager::NSFileType] == NSFileManager::NSFileTypeDirectory;
		return true;
		}
	// fixme: allow to control access rights by writing to .htaccess so that we can hide private files and directories from web-access
	// this means we have "owner" and "other"
	public function isReadableAtPath($path)
		{
		$attr=$this->attributesOfItemAtPath($path);
		// check for posix read permissions
		return YES;
		}
	public function changeCurrentDirectoryPath($path)
		{
		// change in PHP or file manager only?
		}
	public function currentDirectoryPath()
		{
		// change in PHP or file manager only?
		}
	public function contentsAtPath($path)
		{
		// read as string
		}
	public function contentsOfDirectoryAtPath($path)
		{ // return directory contents as array
//			echo "contentsOfDirectoryAtPath($path) ";
		$dir=opendir($this->fileSystemRepresentation($path));
		if(!$dir)
			return NULL;
		$files=array();
		while($sub=readdir($dir))
			$r[]=$sub;
		closedir($dir);
		return $r;
		}
	public function subpathsAtPath($path)
		{
		// read recursive as array
		}
/*
createDirectoryAtPath:withIntermediateDirectories:attributes:error:
createFileAtPath:contents:attributes:
*/
	/* non-standard - we need this to convert file system paths into an external URL */
	public function externalURLforPath($path)
		{
		// enable read (only) access to file (if not yet possible)
		echo "path: $path"."<br>";
		echo "__FILE__: ".$__FILE__."<br>";
		print_r($_SERVER);
		echo "<br>";
		}
	}

class HTML
	{
		const encoding='UTF-8';
		public function value($name, $value)
		{
		return " $name=\"".htmlentities($value, ENT_COMPAT | ENT_SUBSTITUTE, self::encoding)."\"";
		}
		public function linkval($name, $url)
		{
			return " $name=\"".rawurlencode($url)."\"";
		}
		public static function tag($tag, $contents, $args="")
		{
			return "<$tag$args>".$contents."</$tag>";
		}
		public static function text($contents)
		{
			return htmlentities($string, ENT_COMPAT | ENT_SUBSTITUTE, self::encoding);
		}
		public static function bold($contents)
		{
			return tag("b", $contents);
		}
		public static function link($url, $contents)
		{
			return tag("a", $contents, linkval("src", $url));
		}
		public static function img($url)
		{
			return tag("img", "", linkval("src", $url));
		}
		public static function input($size, $value)
		{
			return tag("input", "", value("size", $size).value("value", $value));
		}
		public static function textarea($size, $value)
		{
			return tag("textarea", $value, value("size", $size));
		}
	}

// EOF
?>
