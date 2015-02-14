<?php
	/*
	 * Foundation.framework
	 * (C) Golden Delicious Computers GmbH&Co. KG, 2012
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

function NSLog($format)
	{
	if(!isset($GLOBALS['debug']) || !$GLOBALS['debug'])
		return;	// disable
	if(!is_scalar($format))
		{
		// check if a description method exists
		echo "<pre>";
		print_r($format);
		echo "</pre>";
		}
	else
		{
	// NSDate::date()->description()
		// append \n only if not yet appended
		echo htmlentities($format, ENT_COMPAT | ENT_SUBSTITUTE, 'UTF-8')."<br />\n";
		}
	flush();
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
        echo "<b>My ERROR</b> [$errno] $errstr<br />\n";
        echo "  Fatal error on line $errline in file $errfile";
        echo ", PHP " . PHP_VERSION . " (" . PHP_OS . ")<br />\n";
        echo "Aborting...<br />\n";
        exit(1);
        break;

    case E_USER_WARNING:
        NSLog("<b>My WARNING</b> [$errno] $errstr on line $errline in file $errfile");
        break;

    case E_USER_NOTICE:
        NSLog("<b>My NOTICE</b> [$errno] $errstr on line $errline in file $errfile");
        break;

    default:
	$debug=$GLOBALS['debug'];
	$GLOBALS['debug']=true;
        NSLog("Unknown error type: [$errno] $errstr on line $errline in file $errfile");
	$GLOBALS['debug']=$debug;
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
		NSLog("called unimplemented method '$class->$selector()'");
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

	public function invokeWithTarget($target)
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

	public function setTarget($target)
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
//		NSLog("$filename =>");
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
//		NSLog($plist);
		return $plist;
		}
	private static function writePropertyListElementToFile($element, $file)
		{
		NSLog("no idea yet how to writePropertyListElementToPath(..., $file)");
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
//   NSLog("load bundle from $path");
   return include($path);
   }

class NSBundle extends NSObject
{ // abstract superclass
	protected $path;
	protected static $mainBundle;
	protected $allBundlesByPath;
	protected $infoDictionary;
	protected $loaded=false;
	public static function bundleWithPath($path) 
		{
//		NSLog("bundleWithPath: $path");
		if(isset($allBundlesByPath[$path]))
			return $allBundlesByPath[$path];	// return bundle object we already know
		$r=new NSBundle($path);
		$r->path=$path;
		$allBundles[$path]=$r;
//		NSLog("bundleWithPath stored");
		return $r;
		}
	public static function allBundles()
		{
		return $allBundlesByPath;
		}
	public static function mainBundle()
		{
		// FIXME: this requires us to use AppKit.php...
		global $NSApp;
		NSLog("mainBundle");
		if(isset($NSApp))
			return NSBundle::bundleForClass($NSApp->classString());	// assumes that some NSApp object exists
		return NULL;	// unknown
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
		$path=$reflector->getFileName();	// path for .php file of given class
//		NSLog(" path $path");
		// FIXME: this is tailored for .framework bundles! .app bundles may look differently
		$path=dirname($path);	// Versions/A/php/Something.php
		$path=dirname($path);	// Versions/A/php
		$path=dirname($path);	// Versions/A
		$path=dirname($path);	// Versions
//		NSLog(" path $path");
		return NSBundle::bundleWithPath($path);
		}
	public function infoDictionary()
		{
		if(!isset($this->infoDictionary))
			{ // locate and load Info.plist
				$plistPath=$this->pathForResourceOfType("Info", "plist");
//				NSLog("read $plistPath");
				$this->infoDictionary=NSPropertyListSerialization::propertyListFromPath($plistPath);
			}
		return $this->infoDictionary;
		}
	public function executablePath()
		{
		return $this->path."/Contents/php/".($this->objectForInfoDictionaryKey('CFBundleExecutable')).".php";
		}
	public function pathForResourceOfType($name, $type)
		{
		$fm=NSFileManager::defaultManager();
		$p=$this->path."/Contents/$name.$type"; if($fm->fileExistsAtPath($p)) return $p;
		$p=$this->path."/Contents/Resources/$name.$type"; if($fm->fileExistsAtPath($p)) return $p;
		$p=$this->path."/Resources/$name.$type"; if($fm->fileExistsAtPath($p)) return $p;
		return NULL;
		}
	public function objectForInfoDictionaryKey($key)
		{
		$dict=$this->infoDictionary();
		return $dict[$key];
		}
	public function bundleIdentifier() { return $this->objectForInfoDictionaryKey('CFBundleIdentifier'); }
	public static function bundleWithIdentifier($ident)
		{
		foreach ($allBundlesByPath as $bundle)
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
	public function user() { return $this->user; }
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
//		NSLog("attributesOfItemAtPath($path) -> $f ");
		if(!file_exists($f))
			return NULL;	// does not exist
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
//		NSLog("fileExistsAtPath($path)");
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

// EOF
?>
