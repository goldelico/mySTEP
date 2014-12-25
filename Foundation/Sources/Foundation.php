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

function NSLog($format)
	{
	// append \n only if not yet appended
	// NSDate::date()->description()
	echo htmlentities($format, ENT_COMPAT | ENT_SUBSTITUTE, 'UTF-8')."<br />\n";
	}

if($GLOBALS['debug']) echo "<h1>Foundation.framework</h1>";

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
        NSLog("<b>My WARNING</b> [$errno] $errstr");
        break;

    case E_USER_NOTICE:
        NSLog("<b>My NOTICE</b> [$errno] $errstr");
        break;

    default:
        NSLog("Unknown error type: [$errno] $errstr");
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
		// default error handling
		}
	
	public function __call($name, $arguments)
    		{
			$inv = new NSInvocation($name, $arguments);
        	// Note: value of $name is case sensitive.
        	echo "Calling object method '$name' "
             		. implode(', ', $arguments). "\n";
    		}

	public function self()
		{
		return $this;
		}
	public function class_()
		{ // returns class name
		return get_class($this);
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

	public static function invocationWithSelector($selector)
		{
		$r=new NSInvocation;
		$r->selector=$selector;
		return r;
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
//   echo "load bundle from $path<br>";
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
			return NSBundle::bundleForClass($NSApp->class_);	// assume that some NSApp object exists
		return NULL;	// unknown
		}
	public static function bundleForClass($class)
		{
		$reflector = new ReflectionClass($class);
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
	 * best in class:
	 *   modify:
	 *   $salt = random $salt (may include/depend on $user)
	 *   $store [$user] = $salt . hash($algo, $salt . $password, false);
	 *
	 *   check:
	 *   $salt = substring($store [$user], len);
	 *   if ( $store [$user] == $salt . hash($algo, $salt . $password, false) ) then ok
	 *
	 * oder wenn man "login" in cookie speichert:
	 *   cookie['user'] = $user
	 *   cookie['password'] = hash($algo, $salt . $password, false)
	 * 
	 *   check:
	 *   $salt = substring($store [cookie['user']], len);
	 *   if ( $store [$user] == $salt . cookie['password'] ) then ok
	 *
	 * wobei das dann einfach ein "token" wird... Sobald jemand das kennt kann er sich immer einloggen.
	 *
	 * noch besser: Eigenschaft eines NSSecureTextFields machen - so dass das nie den Text als Klartext ausspuckt!
	 * und noch besser: schon auf dem Client (JavaScript) hashen - dann kann das Formular sogar in http: übertragen werden
	 * aber: wie handhabt man dann das "salt"??? Das wäre dann jedesmal anders :(
	 * oder man trennt zwischen Password-Check-Field und Password-Eingabefeld
	 * beim Check-Field kommt das $salt aus der Datenbank (sobald man einen User-Namen gewählt hat)
	 * beim Eingabefeld wird es neu erzeugt
	 *
	 * see: http://programmers.stackexchange.com/questions/76939/why-almost-no-webpages-hash-passwords-in-the-client-before-submitting-and-hashi
	 * and although people recommend to use TLS or SSH, we know that those might not be secure as well
	 * so we never transport the password - and users who use the same password for different systems have less trouble
	 *
	 * aber es gibt Leute die das ganze Verfahren für unsicher halten...
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

			/*
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
			 */

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
					NSLog("check $doublehash with $stored");
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
//		echo "attributesOfItemAtPath($path) -> $f ";
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
