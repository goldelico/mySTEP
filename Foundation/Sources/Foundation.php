<?php

	/*
	 * Foundation.framework
	 * (C) Golden Delicious Computers GmbH&Co. KG, 2012-2017
	 * All rights reserved.
	 */

	/*
	 * design principle:
	 * resemble Cocoa classes (exceptions: arrays and strings but this will come)
	 *
	 * - (type) method ->  public function method()
	 * - (type) method:(type) arg1  ->  public function method($arg1)
	 * - (type) method:(type) arg1 arg:(type) arg2  ->  public function methodArg($arg1, $arg2)
	 * + (type) method:(type) arg1 arg:(type) arg2  ->  public static function methodArg($arg1, $arg2)
	 * [object method:p1 arg:p2] ->  $object->methodArg($1, $2)
	 * [Class method:p1 arg:p2] ->  Class::methodArg($1, $2)
	 * iVar ->  $this->iVar
	 * [Class alloc] -> new Class
	 */

// global $ROOT must be set by some application
// global $debug can be set to enable/disable debugging messages

ob_start();	// enable output buffering so that we can sent cookies and headers later than starting to write html

error_reporting(-1);	// report all PHP errors to avoid delayed issues when running on different servers

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
	if(headers_sent())
		flush();		// flush() will send headers...
	}

function NSLog($format)
	{
	if(isset($_GET['debug2log']))
		{
		$f=fopen("/tmp/mySTEP.log", "a");
		if(is_null($format))
			$format="<nil>";
		if(!is_scalar($format))
			// check if a description() method exists
			$format=var_export($format, true);
		// NSDate::date()->description()
		if(substr($format, -1) != '\n')
			$format.="\n";	// append \n
		fputs($f, $format);
		fclose($f);
		return;
		}
	if(!$GLOBALS['debug'])
		return;	// disable
	_NSLog($format);
	}

function NSSevereError($format)
	{ // send as e-mail to developer
	}

if($GLOBALS['debug']) echo "<h1>Foundation.framework</h1>";

function _print_backtrace()
{
	$trace=debug_backtrace(DEBUG_BACKTRACE_PROVIDE_OBJECT, 20);
	array_shift($trace);
	array_shift($trace);
	foreach($trace as $stack)
		{
		echo "&nbsp;&nbsp;".(isset($stack['class'])?$stack['class']:"").(isset($stack['type'])?$stack['type']:"").$stack['function']." ".basename($stack['file'])."#".$stack['line']."<br />\n";
		}
	echo "<br />\n";
}

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
		echo "<b>ERROR</b>&nbsp;&nbsp;[$errno] $errstr<br />\n";
		echo "&nbsp;&nbsp;Fatal error on line $errline in file ".basename($errfile);
		echo ", PHP " . PHP_VERSION . " (" . PHP_OS . ")<br />\n";
		_print_backtrace();
		echo "Aborting...<br />\n";
		exit(1);
		break;

	case E_USER_WARNING:
		_NSLog("<b>WARNING</b> [$errno] $errstr on line $errline in file ".basename($errfile));
		_print_backtrace();
		break;

	case E_USER_NOTICE:
		_NSLog("<b>NOTICE</b> [$errno] $errstr on line $errline in file ".basename($errfile));
		_print_backtrace();
		break;

	default:
		_NSLog("Unknown error type: [$errno] $errstr on line $errline in file ".basename($errfile));
		_print_backtrace();
		break;
	}

	/* Don't execute PHP internal error handler */
	return true;
}

$old_error_handler = set_error_handler('myErrorHandler');

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

	public function __toString()
		{ // to make it compatible to PHP strings
		return $this->description();
		}

	public function isKindOfClass($classString)
		{
		return is_a($this, $classString);
		}

	public function isMemberOfClass($classString)
		{
		return is_a($this, $classString) && !is_subclass_of($this, $classString);
		}

	public function respondsToSelector($selector)
		{
		return method_exists($this, $selector);
		}

	public function valueForUndefinedKey($key)
		{
		// should raise NSUndefinedKeyException
		return null;
		}

	public function valueForKey($key)
		{ // fetch instance variables by name
		$getter=$key;
		if($this->respondsToSelector($getter))	// getter exists
			return $this->$getter();	// call getter
		// handle is$key and $key and _$key
		$vars=get_object_vars($this);
		if(isset($vars[$key]))
			return $vars[$key];	// exists
		else
			return $this->valueForUndefinedKey($key);
		}

	public function setValueForUndefinedKey($value, $key)
		{
// _NSLog("setter for $key not found"); // check for variable
		$this->$key=$value;	// try to set directly
		}

	public function setValueForKey($value, $key)
		{ // set instance variables by name
		$setter="set".ucfirst($key);		// make name of setter method
// _NSLog($setter);
		if($this->respondsToSelector($setter))
			$this->$setter($value);	// set object
		else
			$this->setValueForUndefinedKey($value, $key); // can be overwritten
		}

// can check for existence by wrapping property_exists($this, $key)

	public function valueForKeyPath($path)
		{
		$val=$this;
		$components=explode('.', $key);
		foreach($components as $key)
			{
			$val=$val->valueForKey($key);	// try to dereference
			if(is_null($val))
				break;
			}
		return $val;
		}
	}

function NSStringFromClass($class)
	{
	return $class;	// is already a string...
	}

class NSString extends NSObject
{
	protected $string;

	public function __construct($string="")
	{
		parent::__construct();
		$this->string=$string;
	}

	public function hasPrefix(NSString $str)
	{
	}

	public function hasSuffix(NSString $str)
	{
	}
}

class NSArray extends NSObject
{
	protected $array;

	public function __construct($array=array())
	{
		parent::__construct();
		$this->array=$array;
	}

	public function __destruct()
	{
		parent::__destruct();
	}

	public function indexForObject(NSObject $object)
	{
		return array_keys($this->array, $object, false)[0];
	}

	public function count()
	{
		return count($this->array);
	}

	public function objectAtIndex($index)
	{
		$this->array[$index];
	}

	public function indexForObjectIdenticalTo(NSObject $object)
	{
		return array_keys($this->array, $object, true)[0];
	}

}

class NSMutableArray extends NSArray
{
	public function exchangeObjectAtIndexWithObjectAtIndex($i1, $i2)
	{
		$temp=$this->array[$i1];
		$this->array[$i1]=$this->array[$i2];
		$this->array[$i2]=$temp;
	}

	public function insertObjectAtIndex(NSObject $object, $index)
	{
		array_splice($this->array, $index, 0, array($object));
	}

	public function addObject(NSObject $object)
	{
		$this->array[]=$object;
	}

	public function lastObject()
	{
		return array_pop($this->array);
	}

	public function removeObjectAtIndex($index)
	{
		array_splice($this->array, $index, 1);
	}

}

class NSInvocation extends NSObject
	{
	protected $target;
	protected $selector;
	protected $arguments=array();

	public function __construct()
		{
		parent::__construct();
		}

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
	protected static $plists;
	public function __construct()
		{
		parent::__construct();
		}
	private static function readPropertyListElementFromElement(SimpleXMLElement $xml)
		{ // process XML property list entries
//		_NSLog($xml->getName());
		switch($xml->getName())
			{
			case "plist":	foreach($xml->children() as $key => $node)
						return self::readPropertyListElementFromElement($node);
			case "dict":	$dict=array();
					foreach($xml->children() as $key => $node)
						{
						$val=self::readPropertyListElementFromElement($node);
						if($key == "key")	// <key>
							$k=$val;
						else
							$dict[$k]=$val;
						}
					return $dict;
			case "array":	$array=array();
					foreach($xml->children() as $key => $node)
						$array[]=self::readPropertyListElementFromElement($node);	// append to array
					return $array;
			case "key":
			case "string":	return $xml->__toString();	// return contents
			case "number":	return 0+($xml->__toString());	// return contents
			case "true":	return true;
			case "false":	return false;
			// date, data
			}
		return null;	// parse error
		}
	public static function _propertyListFromPath($filename)
		{
// FIXME: potentially use a cache on disk shared between PHP apps?
		if(isset(self::$plists) && isset(self::$plists[$filename]))
			return self::$plists[$filename];	// get from cache
		NSLog("$filename =>");
		$xml=@simplexml_load_file($filename);
		if($xml === false)
			return null;
		$pl=self::readPropertyListElementFromElement($xml);
		if(!isset(self::$plists))
			self::$plists=array();
		self::$plists[$filename]=$pl;	// store in cache
		return $pl;
		}
	public static function propertyListFromPath($path)
		{
		$filename=NSFileManager::defaultManager()->fileSystemRepresentationWithPath($path);
		return self::_propertyListFromPath($filename);	// process file
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

class NSJSONSerialization extends NSObject
{
	public static function JSONObjectWithDataOptionsError($data, $options=0, &$error)
	{
		/* translate options
		JSON_BIGINT_AS_STRING
		*/
		$val = json_decode($object);
		if($val === null)
			{
			$error=json_last_error_msg();
			return null;
			}
		return $val;
	}

	public static function dataWithJSONObjectOptionsError(NSObject $object, $options=0, &$error)
	{
		/* translate options
		JSON_HEX_QUOT, JSON_HEX_TAG, JSON_HEX_AMP, JSON_HEX_APOS, JSON_NUMERIC_CHECK, JSON_PRETTY_PRINT, JSON_UNESCAPED_SLASHES, JSON_FORCE_OBJECT, JSON_PRESERVE_ZERO_FRACTION, JSON_UNESCAPED_UNICODE
		*/
		$val = json_encode($object);
		if($val === false)
			{
			$error=json_last_error_msg();
			return null;
			}
		return $val;
	}

	public static function isValidJSONObject($object)
	{
		return dataWithJSONObjectOptionsError($object, 0, $error);
	}

}

class NSBundle extends NSObject
{ // abstract superclass
	protected $path;
	protected static $allBundlesByPath=array();
	protected $infoDictionary;
	protected $loaded=false;
	protected static $mainBundle;
	public function __construct()
		{
		parent::__construct();
		}
	public static function bundleWithPath($path) 
		{
// _NSLog("bundleWithPath: $path");
// FIXME: do we return null if there is no valid bundle?
// _NSLog("realpath: $path");
		if(isset(self::$allBundlesByPath[$path]))
			return self::$allBundlesByPath[$path];	// return bundle object we already know
		$r=new NSBundle($path);
		$r->path=$path;
		self::$allBundlesByPath[$path]=$r;
// _NSLog("bundleWithPath $path stored");
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
// _NSLog($_SERVER['SCRIPT_FILENAME']);
// _NSLog(realpath($_SERVER['SCRIPT_FILENAME']));
			$path=realpath($_SERVER['SCRIPT_FILENAME']);	// Bundle/Contents/php/Something.php
// _NSLog($path);
			$path=NSFileManager::defaultManager()->stringWithFileSystemRepresentation($path);	// use internal representation
			$path=dirname($path);	// Bundle/Contents/php
			$path=dirname($path);	// Bundle/Contents
			if(substr($path, -9) != "/Contents")
				{
				_NSLog("not an application bundle: $path");
				return null;
				}
			$path=dirname($path);	// Bundle/
// _NSLog($path);
			self::$mainBundle=NSBundle::bundleWithPath($path);
			self::$mainBundle->loaded=true;
			}
		return self::$mainBundle;
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
// _NSLog("bundleForClass: $class");
		$path=$reflector->getFileName();	// path for .php file of given class
		$path=NSFileManager::defaultManager()->stringWithFileSystemRepresentation($path);	// Bundle/Contents/php/Something.php
		$path=dirname($path);	// Bundle/Versions/A/php // Bundle/Contents/php
		$path=dirname($path);	// Bundle/Versions/A // Bundle/Contents
// _NSLog($path);
		if(substr($path, -9) != "/Contents")
			{ // appears to be a Framework bundle
			$path=dirname($path);	// Bundle/Versions
			}
		$path=dirname($path);	// Bundle
// _NSLog(" bundleForClass $class path $path");
		return NSBundle::bundleWithPath($path);
		}
	public function bundlePath() { return $this->path; }
	public function infoDictionary()
		{
		if(!isset($this->infoDictionary))
			{ // locate and load Info.plist
				$plistPath=$this->_contentsPath();
// _NSLog("contents $plistPath");
				if(is_null($plistPath)) return null;	// there are no contents
				$plistPath.="Info.plist";
				// can there be a localized Info.plist???
// _NSLog("read $plistPath");
				$this->infoDictionary=NSPropertyListSerialization::propertyListFromPath($plistPath);
			}
		return $this->infoDictionary;
		}
	public function executablePath()
		{
		$executable=$this->objectForInfoDictionaryKey('CFBundleExecutable');
		if(is_null($executable)) return null;
		$fm=NSFileManager::defaultManager();
		$executable=$this->_contentsPath()."php/".$executable.".php";
		if(!$fm->fileExistsAtPath($executable)) return null;	// there is no executable
		return $executable;
		}
	public function _contentsPath()
		{ // note: already has / suffix!
		$fm=NSFileManager::defaultManager();
		$p=$this->path."/Versions/Current/"; if($fm->fileExistsAtPath($p)) return $p;
		$p=$this->path."/Contents/"; if($fm->fileExistsAtPath($p)) return $p;
// _NSLog("_contentsPath for $p not found");
		return null;
		}
	public function resourcePath()
		{
		$fm=NSFileManager::defaultManager();
		$p=$this->_contentsPath()."Resources/"; if($fm->fileExistsAtPath($p)) return $p;
// _NSLog("resourcePath for $p not found");
		return null;
		}
	public function pathForResourceOfType($name, $type)
		{
// _NSLog($this);
		$fm=NSFileManager::defaultManager();
		$rp=$this->resourcePath();
		if(is_null($rp)) return null;
		$subdirs=array("English.lproj/", "");
		foreach($subdirs as $dir)
			{
			$p=$rp.$dir.$name;	// $p or $dir already ends in / suffix!
			if($type != "")
				$p.=".".$type;	// given suffix
// _NSLog("try $p");
			if($fm->fileExistsAtPath($p)) return $p;
			}
		return null;
		}
	public function objectForInfoDictionaryKey($key)
		{
		$dict=$this->infoDictionary();
// _NSLog($dict);
		return isset($dict[$key])?$dict[$key]:null;
		}
	public function bundleIdentifier()
		{
		return $this->objectForInfoDictionaryKey ('CFBundleIdentifier');
		}
	public static function bundleWithIdentifier($ident)
		{
// _NSLog("bundleWithIdentifier: $ident");
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
	$user=$ud->objectForKey('login_user');
	if(is_null($user))
		return @"/";
	return NSHomeDirectoryForUser($user);
	}

const NSGlobalDomain = "NSGlobalDomain";
const NSRegistrationDomain = "NSRegistrationDomain";
const NSArgumentDomain = "NSArgumentDomain";

class NSUserDefaults extends NSObject
{ // persistent values (user settings) - made persistent in browser cookies
	protected static $standardUserDefaults;
	protected $searchList=array();
	protected $volatileDomains=array();

	public function __construct()
		{
		parent::__construct();
		}
	public static function standardUserDefaults()
	{
	if(!isset(self::$standardUserDefaults))
		{
		$defaults=new NSUserDefaults();	// create empty defaults
		$NSApplicationDomain=NSBundle::mainBundle()->bundleIdentifier();
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
		$domain=str_replace('.', '_', $domain);	// cookies don't accept . in name
		if(!isset($_COOKIE[$domain])) return null;
		return json_decode($_COOKIE[$domain], true);
	}

	public function removePersistentDomainForName($domain)
	{
		$this->setPersistentDomainForName(null, $domain, -3600);
	}

	public function setPersistentDomainForName($dict, $domain, $duration=0)
	{ // NOTE: $domain is the NSUserDefaults domain and has nothing to do with the setcookie(... $domain) parameter
		$domain=str_replace('.', '_', $domain);	// cookies don't accept . in name
// _NSLog("setPersistentDomainForName($domain) duration:$duration)");
// _NSLog($dict);
// _NSLog("before");
// _NSLog($_COOKIE);
		if($duration == 0)
			$time=(2038-1970)*365*24*3600;	// almost for ever...
		else
			$time=time()+$duration;
		if($duration < 0)
			{ // unset coockie completely
			setcookie($domain, false, $time, "/", "");
			unset($_COOKIE[$domain]);
			}
		else
			{
			$dict=json_encode($dict);
			setcookie($domain, $dict, $time, "/", "");	// set cookie for all domains and subpaths
			$_COOKIE[$domain]=$dict;	// replace
			}
// _NSLog("after");
// _NSLog($_COOKIE);
	}

	public function persistentDomainNames()
	{
		// FIXME: don't return numeric indexes!
		// FIXME: replace _ by . (which means we should not use domains with _)
		return array_keys($_COOKIE);
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
		$NSApplicationDomain=NSBundle::mainBundle()->bundleIdentifier();
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

const NSFileName="NSFileName";
const NSFileType="NSFileType";
const NSFileTypeDirectory="NSFileTypeDirectory";
const NSFileTypeRegular="NSFileTypeRegular";
const NSFileSize="NSFileSize";
const NSFileCreationDate="NSFileCreationDate";
const NSFileModificationDate="NSFileModificationDate";
const NSFilePosixPermissions="NSFilePosixPermissions";

class NSFileManager extends NSObject
	{
	protected static $defaultManager;
	protected $user="";
	protected $defaults;
	protected $registeredDefaults=array();

	public function __construct()
		{
		parent::__construct();
		}
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
		if(!isset($ROOT))
			{
			_NSLog("fileSystemRepresentationWithPath: $ROOT is not set");
			exit;
			}
		if(substr($ROOT, -1) != "/")
			_NSLog("invalid \$ROOT (must end in /): $ROOT");	// must end in /
		if(substr($path, 0, 5) == '/tmp/' && substr($path, 5, 2) != '..')
			// FIXME: protected against /tmp/../anything
			return $path;	// map /tmp directly to host
		if(substr($path, 0, 1) == '/')
			return realpath(substr($ROOT, 0, strlen($ROOT)-1).$path);	// absolute path - but don't duplicate the /
		return $path;	// relative path
		}
	public function stringWithFileSystemRepresentation($path)
		{
		global $ROOT;
		if(!isset($ROOT))
			{
			_NSLog("fileSystemRepresentationWithPath: $ROOT is not set");
			exit;
			}
		$rpath=realpath($path);	// canonicalize
		if($rpath === false)
			return $path;	// can't find out
		if(substr($ROOT, -1) != "/")
			_NSLog("invalid \$ROOT (must end in /): $ROOT");	// must end in /
		if(substr($rpath, 0, strlen($ROOT)) == $ROOT)
			return substr($rpath, strlen($ROOT)-1);	// strip off $ROOT prefix but keep /
		return $rpath;
		}
	public function attributesOfItemAtPath($path)
		{
		$f=$this->fileSystemRepresentationWithPath($path);
// _NSLog("attributesOfItemAtPath($path) -> $f ");
		if(!file_exists($f))
			return null;	// does not exist
		$a=stat($f);
		if($a === false)
			return null;
// _NSLog($a);
		$attribs=array();
/*
 * collect real file access permissions as defined by file system, local and global .htaccess etc.
 *
 * user:
 * group:
 * other: defines access as through web server

    [dev] => 16777220
    [ino] => 39319525
    [mode] => 16877
    [nlink] => 8
    [uid] => 503
    [gid] => 503
    [rdev] => 0
    [size] => 272
    [atime] => 1459098675
    [mtime] => 1441134056
    [ctime] => 1459098674
    [blksize] => 4096
    [blocks] => 0

 */
		$attribs[NSFileName]=$path;
		$attribs[NSFileType]=is_dir($f)?NSFileTypeDirectory:NSFileTypeRegular;
// _NSLog($attribs);
		$attribs[NSFileSize]=$a['size'];
		$attribs[NSFileCreationDate]=$a['ctime'];
		$attribs[NSFileModificationDate]=$a['mtime'];
		return $attribs;
		}
	public function setAttributesOfItemAtPath($path, $attributes)
		{
		_NSLog("setAttributesOfItemAtPath not implemented");
		}
	public function fileExistsAtPath($path)
		{
		NSLog("fileExistsAtPath($path)");
		return $this->attributesOfItemAtPath($path) != null;
		}
	public function fileExistsAtPathAndIsDirectory($path, &$isDir)
		{
		$attr=$this->attributesOfItemAtPath($path);
// _NSLog($attr);
		if($attr == null)
			return false;
		$isDir=$attr[NSFileType] == NSFileTypeDirectory;
// _NSLog("isdir $isDir");
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
// _NSLog("read ".NSFileManager::defaultManager()->fileSystemRepresentationWithPath($path));
		return @file_get_contents(NSFileManager::defaultManager()->fileSystemRepresentationWithPath($path));
		}
	public function contentsOfDirectoryAtPath($path)
		{ // return directory contents as array
		// FIXME: use scandir?
//			NSLog("contentsOfDirectoryAtPath($path)";
		$dir=@opendir($this->fileSystemRepresentationWithPath($path));
		if(!$dir)
			return NULL;
		$files=array();
		while($sub=readdir($dir))
			$r[]=$sub;
		closedir($dir);
		return $r;
		}
	public function subpathsAtPath($path)
		{ // read recursively into array
		$result=array();
		$files=$this->contentsOfDirectoryAtPath($path);
		foreach($files as $file)
			{
			if($file == "." || $file == "..")
				continue;	// skip
			$file=$path."/".$file;
			if($this->fileExistsAtPathAndIsDirectory($file, $isDir))
				{
				if($isDir)
					$result=array_merge($result, $this->subpathsAtPath($file));
				else
					$result[]=$file;
				}
			}
		return $result;
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
	protected static $distantPast;
	protected /* float */ $timestamp;

	public function __construct($timestamp=null)
		{
		parent::__construct();
		if(is_null($timestamp))
			$timestamp=microtime(true);
		$this->timestamp=$timestamp;
		}

	public static function date() { return new NSDate(); }
	public static function dateWithTimeIntervalSinceNow($interval)
		{
		return new NSDate(microtime(true)+$interval);
		}

	public static function dateWithTimeIntervalSince1970($interval)
		{ // seconds since 1 January 1970 00:00:00 UTC
		return new NSDate($interval);
		}

	public static function dateWithTimeIntervalSinceReferenceDate($interval)
		{ // seconds since 1 January 2001 00:00:00 UTC
		return new NSDate(REF+$interval);
		}

	public static function dateWithComponents($year, $month, $day, $hour, $minute, $second)
		{
// FIXME: handle fraction of seconds by truncation/rounding
		new NSDate(mktime($hour, $minute, $second, $month, $day, $year));				}

	public static function dateWithString($string)
		{ // prose...
		return new NSDate(strtotime($string));
		}

	public static function distantPast()
		{
		if(!isset(NSDate::$distantPast))
			NSDate::$distantPast=NSDate::dateWithTimeIntervalSince1970(0);
		return NSDate::$distantPast;
		}

	public function isDistantPast()
		{
		return $this->timestamp == 0;
		}

	public static function distantFuture()
		{
// make a singleton
		return dateWithTimeIntervalSince1970(1<<31);
		}

	public function timeIntervalSinceReference1970()
		{
		return $this->timestamp;
		}

	public function timeIntervalSinceNow()
		{
		return $this->timestamp-microtime(true);
		}

	public function timeIntervalSinceReferenceDate()
		{
		return $this->timestamp-REF;		
		}

	public function stringFromDate($str)
		{ // uses POSIX formatting and not PHP!
		setlocale(LC_TIME, "C");
		return strftime($str, $this->timestamp);
		}

	public function description()
		{ // YYYY-MM-DD HH:MM:SS ±HHMM
		return $this->stringFromDate("%Y-%m-%d %H:%M:%S %Z");
		}

// should this go to CoreDataBase?

	public static function dateWithSQLDateTime($string)
		{ // YYYY-MM-DD [HH:MM:SS]
// $string="2013-13-41 12:13:14";
// $string="2013-13-41";
// _NSLog("dateWithSQLDateTime: '$string'");
		if($string == "0000-00-00 00:00:00" || $string == "0000-00-00")
			return NSDate::distantPast();
		$dt=date_create_from_format("Y-m-d H:i:s", $string);	// DATETIME (YYYY-MM-DD HH-MM-SS)
		$errs=date_get_last_errors();
// _NSLog($errs);
		if($errs['error_count'] + $errs['warning_count'] == 0)
			return new NSDate(date_timestamp_get($dt));
		$dt=date_create_from_format("Y-m-d|", $string);	// try again as TIME (YYYY-MM-DD)
		$errs=date_get_last_errors();
		if($errs['error_count'] + $errs['warning_count'] == 0)
			return new NSDate(date_timestamp_get($dt));
_NSLog("dateWithSQLDateTime conversion error for: $string");
_NSLog($errs);
		return nil;
		}

	public function sqldate()
		{ // "YYYY-MM-DD HH:MM:SS"
		if($this->timestamp == 0)
			return "0000-00-00 00:00:00";	// distantPast
		return $this->stringFromDate("%Y-%m-%d %H:%M:%S");
		}

	}

class NSTimer extends NSObject
{
	protected $fireDate;
	protected $interval;
	protected $target;
	protected $action;
	protected $userInfo;
	protected $repeats;
	protected $hash;	// unique identifier for runloop being able to separate multiple timer

	public function __construct($timestamp=null)
		{
		parent::__construct();
		$trace=debug_backtrace();
_NSLog($trace);
		$trace=json_encode($trace);	// make a hopefully unique hash that only depends on code location (not creation sequence) where the timer is created
_NSLog($trace);
		$trace=md5($trace);
_NSLog($trace);
		$this->hash=$trace;
		}

	public static function scheduledTimerWithTimeInterval($interval, $target, $selector, $userInfo=null, $repeats=false)
		{
		$fireDate=NSDate::dateWithTimeIntervalSinceNow($interval);
		$timer=new NSTimer();
		$timer=$timer->initWithFireDate($fireDate, $interval, $target, $selector, $userInfo, $repeats);
// this should make timer persistent...
// and add to local list so that we can call NSRunLoop::currentRunLoop()->_fireExpiredTimers();
		// NSRunLoop::currentRunLoop()->addTimer($timer, "");
		return $timer;
		}

	public function initWithFireDate(NSDate $fireDate, $interval, $target, $selector, $userInfo=null, $repeats=false)
		{
		$this->fireDate=$fireDate;
		$this->interval=$interval;
		$this->target=$target;
		$this->selector=$selector;
		$this->userInfo=$userInfo;
		$this->repeats=$repeats;
		return $this;
		}

	public function fire()
		{
		if(!is_null($this->fireDate))
			{
			$action=$this->selector;
			if(method_exists($target, $action))
				$target->$action($from);
			else
				_NSLog(/*$target->description().*/"target does no handle $action");
			if($this->repeats)
				{
				$time=$this->fireDate->timeIntervalSince1970()+$this->interval;
				$date=NSDate::dateWithTimeIntervalSince1970($time);
				$this->fireDate=$date;
				}
			else
				$this->invalidate();
			}
		}

	public function _fireIfExpired()
		{
		if(!is_null($this->fireDate) && $this->fireDate->timeIntervalSinceNow() < 0)
			$this->fire();
		}

	public function invalidate() { $this->fireDate=nil; }
	public function isValid() { return !is_null($this->fireDate); }
	public function fireDate() { return $this->fireDate; }
	public function timeInterval() { return $this->timeInterval; }
	public function userInfo() { return $this->userInfo; }
	public function hash() { return $this->hash; }
}

class NSProcessInfo extends NSObject
{
	protected static $processInfo;
	public static function processInfo()
	{
		if(!isset(self::$processInfo))
			{
			self::$processInfo=new NSProcessInfo();
			}
		return self::$processInfo;
	}
	public function globallyUniqueString()
	{ // inspired by PHP Manual examples
		global $_SERVER;
		$ip=$_SERVER['SERVER_ADDR'];
		$server="";
		$part=explode('.', $ip);
		for ($i=0; $i<=count($part)-1; $i++)
			$server.=substr("0".dechex($part[$i]),-2);
		$ip=$_SERVER['REMOTE_ADDR'];
		$client="";
		$part=explode('.', $ip);
		for ($i=0; $i<=count($part)-1; $i++)
			$client.=substr("0".dechex($part[$i]),-2);
		$t=explode(" ", microtime());
		return sprintf('%08s-%08s-%08s-%04s-%04x%04x',
			$server,
			$client,
			substr("00000000".dechex($t[1]),-8),   // get 8HEX of unixtime
			substr("0000".dechex(round($t[0]*65536)),-4), // get 4HEX of microtime
			mt_rand(0,0xffff), mt_rand(0,0xffff));
	}
}

class NSTask extends NSObject
{
	protected $pid;
	protected $launched=false;
	protected $launchPath="/bin/unknown";
	protected $directory=null;
	protected $arguments=array();
	protected $stdin=null;
	protected $stdout=null;
	protected $stderr=null;

	public function __construct($identifier="NSTask")
		{
		// check if identifier is already known
		// yes: fetch pid
		// check if process is still running
		// if no, trigger termination handler (later) and remove identifier
		}

	public function arguments() { return $this->arguments; }
	public function setArguments($args) { $this->arguments=$args; }
	public function currentDirectoryPath() { return $this->directory; }
	public function setCurrentDirectoryPath($dir) { $this->directory=$dir; }
	public function launchPath() { return $this->launchPath; }
	public function setLaunchPath($path) { $this->launchPath=$path; }
	public function processIdentifier() { return $this->pid; }
	public function terminate() { $this->interrupt(9); }
	public function standardInputFile() { return $this->stdin; }
	public function setStandardInputFile($file) { $this->stdin=$file; }
	public function standardOutputFile() { return $this->stdout; }
	public function setStandardOutputFile($file) { $this->stdout=$file; }
	public function standardErrorFile() { return $this->stderr; }
	public function setStandardErrorFile($file) { $this->stderr=$file; }

	public function isRunning()
		{
// _NSLog("isRunning? ".$this->pid);
		if(!$this->launched)
			return 0;	// wasn't launched yet
		// check if we were just launched - pid may not yet been found
		// could also try "kill -0 $PID"
		exec("ps -p ".$this->pid." >/dev/null 2>&1", $status);
// _NSLog($output);
_NSLog($status);
		return $status == 0;	// 0 is ok
		}

	public function launch()
		{
		if($this->launched)
			{
_NSLog("task already launched");
			return false;	// already running
			}
		$fm=NSFileManager::defaultManager();
		// FIXME: handle proper quoting so that we can pass ' and \
		if(!is_null($this->directory))
			$cmd="cd '".$fm->fileSystemRepresentationWithPath($this->directory)."' && ";
		else
			$cmd="";
		$cmd.="'".$fm->fileSystemRepresentationWithPath($this->launchPath)."'";
		foreach($this->arguments as $arg)
			$cmd.=" '".$arg."'";
		if(is_null($this->stdin))
			$cmd.=" </dev/null";
		else
			$cmd.=" <'".$fm->fileSystemRepresentationWithPath($this->stdin)."'";
		if(is_null($this->stdout))
			$cmd.=" >/dev/null";
		else
			$cmd.=" >'".$fm->fileSystemRepresentationWithPath($this->stdout)."'";
		if(is_null($this->stderr))
			$cmd.=" 2>/dev/null";
		else if($this->stderr == $this->stdout)
			$cmd.=" 2>&1";
		else
			$cmd.=" 2>'".$fm->fileSystemRepresentationWithPath($this->stderr)."'";
		$cmd.=" & echo $!";	// return process id
// _NSLog("exec $cmd");
		exec($cmd, $r);
// _NSLog($r);
		// error handling
		$this->pid=$r[0];
		$this->launched=true;
		return true;
		}

	public function interrupt($signal=15)
		{
		if(!$this->launched)
			return false;	// wasn't set
		$cmd="kill $signal ".$this->pid;
// _NSLog("exec $cmd");
		system($cmd);
		return true;
		}
}

// until we do better, we use a html string to represent attributes

class NSAttributedString extends NSObject
	{
	protected $html;

	public function __construct()
		{
		parent::__construct();
		}
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

function NSMakePoint($x, $y)
	{
	return array('x'=>$x, 'y'=>$y);
	}

function NSMakeSize($width, $height)
	{
	return array('width'=>$width, 'height'=>$height);
	}

function NSMakeRect($x, $y, $width, $height)
	{
	return array('x'=>$x, 'y'=>$y, 'width'=>$width, 'height'=>$height);
	}

// can be applied to points, sizes and rects
function NSMinX($rect) { return $rect['x']; };
function NSMinY($rect) { return $rect['y']; };
function NSWidth($rect) { return $rect['width']; };
function NSHeight($rect) { return $rect['height']; };

// derived values
function NSMidX($rect) { return NSMinX($rect)+0.5*NSWidth($rect); };
function NSMidY($rect) { return NSMinY($rect)+0.5*NSHeight($rect); };
function NSMaxX($rect) { return NSMinX($rect)+NSWidth($rect); };
function NSMaxY($rect) { return NSMinY($rect)+NSHeight($rect); };
function NSIsEmptyRect($rect) { return NSWidth($rect) == 0 || NSHeight($rect) == 0; };
function NSSize($rect) { return NSMakeSize(NSWidth($rect), NSHeight($rect)); };
function NSPoint($rect) { return NSMakePoint(NSMinX($rect), NSMinY($rect)); };

// function NSStringFromRect($rect) { return "{ ".NSStringFromPoint($rect).", ".NSStringFromSize($rect)." }"; }

// EOF
?>
