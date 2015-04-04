<?php
	/*
	 * Foundation.framework
	 * (C) Golden Delicious Computers GmbH&Co. KG, 2012-2015
	 * All rights reserved.
	 */

	/*
	 * design principle
	 * resemble Cocoa classes (exceptions: arrays and strings)
	 * - (type) method:(type) arg1 text:(type) arg2  ->  public function methodText($arg1, $arg2)
	 * + (type) method:(type) arg1 text:(type) arg2  ->  public static function methodText($arg1, $arg2)
	 * [object method:p1 text:p2] ->  $object->methodText($1, $2)
	 * [Class method:p1 text:p2] ->  Class::methodText($1, $2)
	 * iVar ->  $this->iVar
	 * [Class alloc] -> new Class --- but don't use! Use factory class methods
	 */

// global $ROOT must be set by some application
// global $debug can be set to enable/disable debugging messages

const NO=false;
const YES=true;
const nil=null;

if(!isset($GLOBALS['debug'])) $GLOBALS['debug']=false;	// disable by default

function _NSLog($format)
	{ // always logs - use with care!
	// loop through all arguments if multiple are given?
	// and get description() if possible?
	// use first as format string?
	if(is_null($format))
		$format="<nil>";
	if(!is_scalar($format))
		{
		// check if a description() method exists
		echo "<pre>";
		print_r($format);
		echo "</pre>\n";
		}
	else
		{
	// NSDate::date()->description()
		$str=$format;
		if(substr($str, -1) != '\n')
			$str.="\n";	// append \n
		echo nl2br(htmlentities($str, ENT_COMPAT | ENT_SUBSTITUTE, 'UTF-8'))."\n";
		}
	flush();
	}

function NSLog($format)
	{
	if(!$GLOBALS['debug'])
		return;	// disable
	_NSLog($format);
	}

function NSSevereError($format)
	{ // send as e-mail to developer
	}

if($GLOBALS['debug']) echo "<h1>Foundation.framework</h1>";

// error handler function
function myErrorHandler($errno, $errstr, $errfile, $errline)
{
// FIXME: should we raise an ErrorException?
	if (!(error_reporting() & $errno)) {
		// This error code is not included in error_reporting
		return false;
		}

	switch ($errno) {
	case E_USER_ERROR:
		echo "<b>ERROR</b> [$errno] $errstr<br />\n";
		echo "  Fatal error on line $errline in file $errfile";
		echo ", PHP " . PHP_VERSION . " (" . PHP_OS . ")<br />\n";
		echo "Aborting...<br />\n";
		exit(1);
		break;

	case E_USER_WARNING:
		_NSLog("<b>WARNING</b> [$errno] $errstr on line $errline in file $errfile");
		break;

	case E_USER_NOTICE:
		_NSLog("<b>NOTICE</b> [$errno] $errstr on line $errline in file $errfile");
		break;

	default:
		_NSLog("Unknown error type: [$errno] $errstr on line $errline in file $errfile");
		break;
	}

	/* Don't execute PHP internal error handler */
	return true;
}

$old_error_handler = set_error_handler("myErrorHandler");

class NSObject /* root class */
	{
	public function __construct()
		{
		}

	public function __destruct()
		{
		}

	public function forwardInvocation(NSInvocation $invocation)
		{
		$selector=$invocation->selector();
		$target=$invocation->target();
		$class=$target->classString();
		$arguments=$invocation->arguments();
		_NSLog("called unimplemented method '$class->$selector()'");
		}
	
	public function __call($name, $arguments)
    		{
		$inv = NSInvocation::invocationWithSelector($name);
		$inv->setTarget($this);
		$inv->setArguments($arguments);
		$this->forwardInvocation($inv);
    		}

	public function self()
		{
		return $this;
		}

	public function classString()
		{ // returns class name
		return get_class($this);
		}

	public function description()
		{ // simple description is class name
		return $this->classString();
		}
	}

function NSStringFromClass($class)
	{
	return $class;	// is already a string...
	}

class NSInvocation extends NSObject
	{
	protected $target;
	protected $selector;
	protected $arguments=array();

	public function invoke()
		{
		return $this->$target->$selector($args);
		}

	public function invokeWithTarget(NSObject $target)
		{
		$this->target=$target;
		return $this->invoke();
		}

	public function setArguments(array $arguments)
		{
		$this->arguments=$arguments;
		}

	public function arguments()
		{
		return $this->arguments;
		}

	public function setTarget(NSObject $target)
		{
		$this->target=$target;
		}

	public function target()
		{
		return $this->target;
		}

	public function selector()
		{
		return $this->selector;
		}

	public static function invocationWithSelector($selector)
		{
		$r=new NSInvocation;
		$r->selector=$selector;
		return $r;
		}
	}

class NSPropertyListSerialization extends NSObject
	{
	private static function readPropertyListElementFromStream($stream)
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
					$key=readPropertyListElementFromStream($stream);
					// check if string
					$value=readPropertyListElementFromStream($stream);
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
					$value=readPropertyListElementFromStream($stream);
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
			// <data>, <date>, <true/>, <false>
		}
	public static function propertyListFromPath($path)
		{
		$filename=NSFileManager::defaultManager()->fileSystemRepresentationWithPath($path);
		NSLog("$filename =>");
		$f=@fopen($filename, "r");	// open for reading
		if($f)
			{ // file exists and can be read
				while($line=fgets($f))
					{
					$line=trim($line);
					// FIXME: this is a simple hack to read XML property lists
					// should be recursive and handle <dict> <array> <data> etc.
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
		if(isset($plist)) NSLog($plist);
		return isset($plist)?$plist:null;
		}
	private static function writePropertyListElementToFile(NSObject $element, $file)
		{
		NSLog("no idea yet how to writePropertyListElementToPath(..., $file)");
		// detect element type
		// write in XML string fromat
		}
	public static function writePropertyListToPath(NSObject $plist, $path)
		{
		// write header
		writePropertyListElementToFile($plist, path);
		// append trailer
		}
	}

function __load($path)
	{
// NSLog("load bundle from $path");
	if(file_exists($path))
		return include($path);
	return false;
	}

class NSBundle extends NSObject
{ // abstract superclass
	protected $path;
	protected static $allBundlesByPath=array();
	protected $infoDictionary;
	protected $loaded=false;
	protected static $mainBundle;
	public static function bundleWithPath($path) 
		{
		NSLog("bundleWithPath: $path");
		if(isset(self::$allBundlesByPath[$path]))
			return self::$allBundlesByPath[$path];	// return bundle object we already know
		$r=new NSBundle($path);
		$r->path=$path;
		self::$allBundlesByPath[$path]=$r;
		NSLog("bundleWithPath $path stored");
		return $r;
		}
	public static function allBundles()
		{
		return self::$allBundlesByPath;
		}
	public static function mainBundle()
		{
		if(!isset(self::$mainBundle))
			{
			// FIXME: this requires us to use AppKit.php...
			global $NSApp;
			NSLog("mainBundle");
			NSLog("class: ".$NSApp->classString());
			NSLog($_SERVER);
			if(isset($NSApp))
				self::$mainBundle=NSBundle::bundleForClass($NSApp->delegate()->classString());	// assumes that the NSApp delegate belongs to the main bundle!
			}
		return self::$mainBundle;	// unknown
		}
	public static function bundleForClass($class)
		{
		try
			{
			$reflector = new ReflectionClass($class);
			}
		catch (Exception $e)
			{
			NSLog("I don't know class $class");
			return null;
			}
//		NSLog("bundleForClass: $class");
		$path=NSFileManager::defaultManager()->stringWithFileSystemRepresentation($reflector->getFileName());	// path for .php file of given class
		$path=dirname($path);	// Versions/A/php/Something.php // Contents/php/Something.php
		$path=dirname($path);	// Versions/A/php // Contents/php
NSLog($path);
		if(substr($path, -9) != "/Contents")
			{ // appears to be a Framework bundle
			$path=dirname($path);	// Versions/A
			}
		$path=dirname($path);	// Versions // Contents
//		NSLog(" path $path");
		return NSBundle::bundleWithPath($path);
		}
	public function infoDictionary()
		{
		if(!isset($this->infoDictionary))
			{ // locate and load Info.plist
				$plistPath=$this->resourcePath();
				if(is_null($plistPath)) return null;	// there is no Info.plist
				$plistPath.="/../Info.plist";
				NSLog("read $plistPath");
				$this->infoDictionary=NSPropertyListSerialization::propertyListFromPath($plistPath);
			}
		return $this->infoDictionary;
		}
	public function executablePath()
		{
		$executable=$this->objectForInfoDictionaryKey('CFBundleExecutable');
		if(is_null($executable)) return null;
		$fm=NSFileManager::defaultManager();
		$executable=$this->path."/Contents/php/".$executable.".php";
		if(!$fm->fileExistsAtPath($executable)) return null;	// there is no executable
		return $executable;
		}
	public function resourcePath()
		{
		$fm=NSFileManager::defaultManager();
		$p=$this->path."/Versions/Current/Resources"; if($fm->fileExistsAtPath($p)) return $p;
		$p=$this->path."/Contents/Resources/"; if($fm->fileExistsAtPath($p)) return $p;
		return null;
		}
	public function pathForResourceOfType($name, $type)
		{
		$p=$this->resourcePath();
		if(is_null($p)) return null;
		$fm=NSFileManager::defaultManager();
		$p=$p."/$name";
		if($type != "")
			$p.=".$type";	// given suffix
		if($fm->fileExistsAtPath($p)) return $p;
		return null;
		}
	public function objectForInfoDictionaryKey($key)
		{
		$dict=$this->infoDictionary();
		return isset($dict[$key])?$dict[$key]:null;
		}
	public function bundleIdentifier()
		{
		return $this->objectForInfoDictionaryKey ('CFBundleIdentifier');
		}
	public static function bundleWithIdentifier($ident)
		{
NSLog("bundleWithIdentifier: $ident");
		foreach (self::$allBundlesByPath as $bundle)
			{
			NSLog("try ".$bundle->bundleIdentifier());
			if($bundle->bundleIdentifier() == $ident)
				return $bundle;	// found
			}
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
			$this->loaded=__load(NSFileManager::defaultManager()->fileSystemRepresentationWithPath($this->executablePath()));
		return $this->loaded;
	}
}
	
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

const NSGlobalDomain = "NSGlobalDomain";
const NSRegistrationDomain = "NSRegistrationDomain";
const NSArgumentDomain = "NSArgumentDomain";

class NSUserDefaults extends NSObject
{ // persistent values (user settings) - made persistent in browser cookies
	protected static $standardUserDefaults;
	protected $searchList=array();
	protected $volatileDomains=array();

	public static function standardUserDefaults()
	{
	if(!isset(self::$standardUserDefaults))
		{
		$defaults=new NSUserDefaults();	// create empty defaults
		$NSApplicationDomain="org.quantumstep.mySTEP";	// should fetch bundle identifier of Application
		$defaults->setVolatileDomainForName($_GET, NSArgumentDomain);
		$defaults->setVolatileDomainForName(array(), NSRegistrationDomain);
		$defaults->setSearchList(array(NSArgumentDomain, $NSApplicationDomain, NSGlobalDomain, /* languages, */ NSRegistrationDomain));
		self::$standardUserDefaults=$defaults;
		}
	return self::$standardUserDefaults;
	}

	public static function resetStandardUserDefaults()
	{ // force re-build
		unset(self::$standardUserDefaults);
	}

	function setSearchList($list)
	{
		$this->searchList=$list;
	}

	public function addSuiteNamed($domain)
	{
		$this->searchList[]=$domain;
	}

	public function removeSuiteNamed($domain)
	{
		unset($this->searchList[array_search($domain, $this->searchList)]);
	}

	public function persistentDomainForName($domain)
	{
		if(!isset($_COOKIES[$domain])) return null;
		return json_decode($_COOKIES[$domain], true);
	}

	public function removePersistentDomainForName($domain)
	{
		$this->setPersistentDomainForName(null, $domain, -3600);
	}

	public function setPersistentDomainForName($dict, $domain, $duration=0)
	{
		NSLog("setPersistentDomainForName($domain) duration:$duration)");
		NSLog($dict);
		if($duration == 0)
			$time=(2038-1970)*365*24*3600;	// almost for ever...
		else
			$time=time()+$duration;
		if($duration < 0)
			{ // unset
			setcookie($domain, "", $time);
			unset($_COOKIE[$domain]);
			}
		else
			{
			setcookie($domain, json_encode($dict), $time, "/", ".");	// set cookie for all domains and subpaths
			$_COOKIE[$domain]=$dict;	// replace
			}
	}

	public function persistentDomainNames()
	{
		// FIXME: don't return numeric indexes!
		return array_keys($_COOKIES);
	}

	public function volatileDomainForName($domain)
	{
		if(isset($this->voltaileDomains[$domain]))
			return $this->voltaileDomains[$domain];
		return null;
	}

	public function removeVolatileDomainForName($domain)
	{
		if(isset($this->voltaileDomains[$domain]))
			unset($this->voltaileDomains[$domain]);
	}

	public function setVolatileDomainForName($dict, $domain)
	{
		$this->voltaileDomains[$domain]=$dict;
	}

	public function volatileDomainNames()
	{
		// FIXME: don't return numeric indexes!
		return array_keys($this->volatileDomains);
	}

	public function registerDefaults($dict)
	{
		$this->setVolatileDomainForName($dict, NSRegistrationDomain);
	}

	public function objectForKey($key)
	{ // go through the domains
		foreach($this->searchList as $domain)
			{ // try all domains
			$r=$this->volatileDomainForName($domain);
			if(isset($r[$key])) return $r[$key];
			$r=$this->persistentDomainForName($domain);
			if(isset($r[$key])) return $r[$key];
			}
		return null;	// still undefined
	}

	public function dictionaryRepresentation()
	{
		// merge all values with highest precedence into single dictionary
		return $array();
	}

	public function setObjectForKey($key, $val)
	{ // write to persistent domain of bundle
		$NSApplicationDomain="org.quantumstep.mySTEP";	// should fetch bundle identifier of Application
		$r=$this->persistentDomainForName($NSApplicationDomain);
		$r[$key]=$val;	// change
		$r=$this->setPersistentDomainForName($r, $NSApplicationDomain);
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
		if(substr($path, 0, 1) == '/')
			return $ROOT.$path;	// absolute path
		return $path;
		}
	public function stringWithFileSystemRepresentation($path)
		{
		global $ROOT;
		if(substr($path, 0, strlen($ROOT)) == $ROOT)
			return "/".substr($path, strlen($ROOT));	// strip off $ROOT prefix
		return $path;
		}
	public function attributesOfItemAtPath($path)
		{
		$f=$this->fileSystemRepresentationWithPath($path);
		NSLog("attributesOfItemAtPath($path) -> $f ");
		if(!file_exists($f))
			return null;	// does not exist
		$a=stat($f);
		if($a === false)
			return null;
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
		NSLog($attribs);
		return $attribs;
		}
	public function setAttributesOfItemAtPath($path, $attributes)
		{
		}
	public function fileExistsAtPath($path)
		{
		NSLog("fileExistsAtPath($path)");
		return $this->attributesOfItemAtPath($path) != null;
		}
	public function fileExistsAtPathAndIsDirectory($path, &$isDir)
		{
		$attr=$this->attributesOfItemAtPath($path);
		if($attr == null)
			return false;
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
//			NSLog("contentsOfDirectoryAtPath($path)";
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
	}

// should we implement NSTimeZone - and initialize from NSUserDefaults?
date_default_timezone_set("Europe/Berlin");

class NSDate extends NSObject
	{
		protected $timestamp;
		public static function date() { $r=new NSDate; $r->timestamp=time(); }
		public function description()
			{
			// return formatted string
			}
	public function dateWithString($str)
		{ // YYYY-MM-DD HH:MM:SS ±HHMM
		
		}
	public function dateWithTimeIntervalSince1970($interval)
		{
		
		}
	public function dateWithTimeIntervalSinceNow()
		{
		
		}
	public function dateWithTimeIntervalSinceReferenceDate()
		{
		
		}
	public function timeIntervalSinceReference1970()
		{
		return $timestamp;
		}
	public function timeIntervalSinceNow()
		{
		
		}
	public function timeIntervalSinceReferenceDate()
		{
		
		}
	}

// until we do better, we use a html string to represent attributes

class NSAttributedString extends NSObject
	{
		protected $html;
		public function setString($string) { $this->html=nl2br(htmlentities($string, ENT_COMPAT | ENT_SUBSTITUTE, 'UTF-8')); }
		public function string() { /* decode <br>, htmlentities and remove tags */ return $this->html; }
		public function setHtmlString($string) { $this->html=$html; }
		public function htmlString() { return $this->html; }
	}

function astr($string)
	{
	$a=new NSAttributedString();
	$a->setString($string);
	return $a;
	}

function htmlstr($string)
	{
	$a=new NSAttributedString();
	$a->setHtmlString($string);
	return $a;
	}

function NSMakeRect($x, $y, $width, $height)
	{
	return array('x'=>$x, 'y'=>$y, 'width'=>$width, 'height'=>$height);
	}

function NSMinX($rect) { return $rect['x']; };
function NSMinY($rect) { return $rect['y']; };
function NSMidX($rect) { return $rect['x']+0.5*$rect['width']; };
function NSMidY($rect) { return $rect['y']+0.5*$rect['height']; };
function NSMaxX($rect) { return $rect['x']+$rect['width']; };
function NSMaxY($rect) { return $rect['y']+$rect['height']; };
function NSWidth($rect) { return $rect['width']; };
function NSHeight($rect) { return $rect['height']; };
function NSIsEmptyRect($rect) { return $rect['width'] == 0 || $rect['height'] == 0; };
// function NSStringFromRect($rect)

// EOF
?>
