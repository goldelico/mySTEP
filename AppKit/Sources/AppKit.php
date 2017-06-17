<?php
/*
 * AppKit.framework
 * (C) Golden Delicious Computers GmbH&Co. KG, 2012-2015
 * All rights reserved.
 *
 * defines (simple) classes for NSWindow, NSView, NSButton, NSTextField, NSSecureTextField, NSForm, NSImage, NSTable, NSPopUpButton
 * draw method generates HTML and CSS output
 *
 * sendEvent and mouseDown are called when button is clicked or something modified
 */

// FIXME: make this configurabe (how?)
// through User-Defaults? Or should the web site be configured???

if(false && $_SERVER['SERVER_PORT'] != 443)
{ // try to reload page as https
	if($_SERVER['REQUEST_URI'] == "" || $_SERVER['REQUEST_URI'] == "/")
		header("location: https://".$_SERVER['HTTP_HOST']."/");
	else
		header("location: https://".$_SERVER['HTTP_HOST']."/".$_SERVER['REQUEST_URI']);
	exit;
}

const NSOnState=1;
const NSOffState=0;
const NSMixedState=-1;

global $ROOT;	// must be set by some .app
require_once "$ROOT/System/Library/Frameworks/Foundation.framework/Versions/Current/php/Foundation.php";
require_once "$ROOT/Internal/Frameworks/UserManager.framework/Versions/Current/php/UserManager.php";

const NSLeftAlignment="left";
const NSCenterAlignment="center";
const NSRightAlignment="right";

if($GLOBALS['debug'])	echo "<h1>AppKit.framework</h1>";

// these functions should be used internally only!

function _404()
{
	header($_SERVER["SERVER_PROTOCOL"]." 404 Not Found");
	header("Status: 404 Not Found");
	$_SERVER['REDIRECT_STATUS'] = 404;
	// echo "<DOCTYPE>";
	echo "<html>";
	echo "<head>";
	echo "<title>404 Not Found</title>";
	echo "<meta name=\"generator\" content=\"mySTEP.php\">";	// a hint that the script is running
	echo "</head>";
	echo "<body>";
	echo "<h1>Not Found</h1>";
	echo "<p>The requested URL ";
	echo htmlentities($_SERVER['PHP_SELF']);
	if($_SERVER['QUERY_STRING'])
		echo "?".htmlentities($_SERVER['QUERY_STRING']);
	echo " was not found on this server.</p>";
// FIXME: optionally notify someone?
	echo "</body>";
	echo "</html>";
	exit;
}

function _htmlentities($string)
{
	return NSGraphicsContext::currentContext()->_htmlentities($string);
}

function html($html)
{
	NSGraphicsContext::currentContext()->html($html);
}

function parameter($name, $value)
{
	NSGraphicsContext::currentContext()->parameter($name, $value);
}

function text($html)
{
	NSGraphicsContext::currentContext()->text($html);
}

/*
 * persistence is achieved by posting object->value relations through hidden <input> fields
 * so that they are available on next refresh of the page through $_POST;
 * a variable should be persisted
 * - if it belongs to the view state of the current window (model state should be persisted through CoreDataBase and NSUserDefaults)
 * - if it needs to survive the display (run) loop
*/

$persist=array();

function _persist($object, $default, $value=null)
{
	global $persist;	// will come back as $_POST[] next time (+ values from <input>)
	if(is_null($value))
		{ // query
		if(isset($_POST[$object]))
			$value=$_POST[$object];
		else
			$value=$default;
// _NSLog("query persist $object -> $value");
		}
	if($value === $default)
		{
// _NSLog("unset persist $object");
		unset($persist[$object]);	// default values need not waste http bandwidth
		unset($_POST[$object]);		// if we want to read back again this will return $default
		}
	else
		{
// _NSLog("set persist $object = $value");
		$persist[$object]=$value;	// store (new/non-default value) until we draw
		$_POST[$object]=$value;		// store if we overwrite and want to read back again
		}
	return $value;
}

class NSGraphicsContext extends NSObject
	{
	protected static $currentContext;
	public static function setCurrentContext(NSGraphicsContext $context) { self::$currentContext=$context; }
	public static function currentContext()
		{
		if(!isset(self::$currentContext))
			self::$currentContext=new NSHTMLGraphicsContext;
		return self::$currentContext;
		}
	}

class NSHTMLGraphicsContext extends NSGraphicsContext
	{
	const encoding='UTF-8';
	public function html($html)
		{
		echo $html;
		}
	public function _htmlentities($value)
		{
		return htmlentities($value, ENT_COMPAT | ENT_SUBSTITUTE, self::encoding);
		}
	public function parameter($name, $value)
		{
		$this->html(" $name=\"".$value."\"");
		}
	public function text($contents)
		{
		$this->html($this->_htmlentities($contents));
		}
	public function flushGraphics()
		{
		flush();
		}

// do we still need this?
// at least partially: we use link() which uses _tag(), _linkval(), _value()
// but all this is not good enough
// we need to replace it by a better abstraction, especially to hide when we must use rawurlencode() and when htmlentities()
	public function _value($name, $value)
		{
		return " $name=\"".$this->_htmlentities($value)."\"";
		}
	public function _linkval($name, $url)
		{
		return " $name=\"".$url."\"";
		}
	public function _tag($tag, $contents, $args="")
		{
		return "<$tag$args>".$contents."</$tag>";
		}
	// write output objects
	public function link($url, $contents)
		{
		$this->html($this->_tag("a", $contents, $this->_linkval("href", $url)));
		}
	public function externalURLforPath($path)
		{
		$bundles=NSBundle::allBundles();
		foreach($bundles as $bundle)
			{
			$res=$bundle->resourcePath();
			if(is_null($res)) continue;	// has no resources
// _NSLog("$res and $path");
// _NSLog($bundle);
			if(substr($path, 0, strlen($res)) == $res)
				{ // we have found a bundle where this file is stored as a resource!
// _NSLog("$res and $path");
				$path=substr($path, strlen($res));	// strip off path prefix
// _NSLog(strlen($res)." ".strlen($path)." ".$path);
				$url="?RESOURCE=".rawurlencode($path);
				if($bundle !== NSBundle::mainBundle())
					$url.="&BUNDLE=".rawurlencode($bundle->bundleIdentifier());
// _NSLog($url);
				return $url;
				}
			}
_NSLog("can't publish $path");
		return null;
		}
	
	}

class _NSHTMLGraphicsContextStore extends NSHTMLGraphicsContext
{ // collect html in an attributed string
	protected $string="";
	public function attributedString() { return $this->string; }
	public function html($html) { $this->string.=$html; }
}

class NSEvent extends NSObject
{
	protected $target;
	protected $type;
	protected $position;
	public function __construct(NSResponder $target, $type)
	{
		parent::__construct();
		$this->type=$type;
		$this->target=$target;
	}
	public function description() { return "NSEvent: ".$this->type." -> ".$this->target->description(); }
	public function type() { return $this->type; }
	public function target() { return $this->target; }
	public function position() { return $this->position; }
	public function window() { return $this->target->window(); }
	public function setPosition($pos) { $this->position=$pos; }
}

global $NSApp;

class NSResponder extends NSObject
{
	protected static $objects=array();	// all objects
	protected $elementId;	// unique object id
	public function __construct()
	{
		parent::__construct();
		$this->elementId=1+count(self::$objects);	// assign element numbers
		self::$objects[$this->elementId]=$this;	// store reference
	}

	public function _eventIsForMe()
		{ // there is some event for us!
		if(!isset($_POST['NSEvent']))
			return false;
		return $_POST['NSEvent'] == $this->elementId;
		}

	public static function _objectForId($id) { return isset(self::$objects[$id])?self::$objects[$id]:null; }
	public function elementId() { return $this->elementId; }
}

class NSApplication extends NSResponder
{
	protected $delegate;
	protected $mainWindow;
	protected $mainMenu;
	protected $eventQueue=array();

	public function _url($withrequest=true)
		{ // the URL of the script we are currently running
		$rp=empty($_SERVER['HTTPS'])?80 : 443; // default remote port
		return (!empty($_SERVER['HTTPS'])?"https://":"http://").$_SERVER['SERVER_NAME'].($_SERVER['SERVER_PORT'] != $rp ? ":".$_SERVER['SERVER_PORT'] : "").($withrequest?$_SERVER['REQUEST_URI']:"");
		}

	public function description()
		{
		// add mainBundle productName
		return $this->_url();
		}

	public function delegate() { return $this->delegate; }
	public function setDelegate(NSObject $d=null) { $this->delegate=$d; }
	public function mainWindow() { return $this->mainWindow; }
	public function setMainWindow(NSWindow $w) { $this->mainWindow=$w; }
	public function mainMenu() { return $this->mainMenu; }
	public function setMainMenu(NSMenu $m=null) { $this->mainMenu=$m; }

	public function queueEvent(NSEvent $event)
		{ // there may be multiple mouse-down events (for NSPopUpButton!)
// _NSLog("queueEvent: ".$event->description());
		$this->eventQueue[]=$event;
		}

	public function __construct()
		{
		global $NSApp;
		parent::__construct();
// _NSLog("__contruct");
		if(isset($NSApp))
			{
			_NSLog('$NSApp is already defined');
			exit;
			}
		$NSApp=$this;
		}

	public function awakeFromNib()
		{
// _NSLog("NSApplication awakeFromNib");

		if($this->mainMenu)
			return;	// already loaded
		
		// we should load the menu from the NIB as well!

		$this->mainMenu=new NSMenuView(true);	// create horizontal menu bar
		$item=new NSMenuItemView("System");
		$submenu=new NSMenuView();
		$item->setSubMenu($submenu);
		$this->mainMenu->addMenuItem($item);
		$submenu->addMenuItemWithTitleAndAction("About", "orderFrontAboutPanel", $this);
		$submenu->addMenuItemWithTitleAndAction("Settings", "openSettings", $this);
		$submenu->addMenuItemSeparator();
		// make this switch between Login... // Logout...
		$ud=NSUserDefaults::standardUserDefaults();
		$user=$ud->objectForKey('login_user');
		if(is_null($user))
			$submenu->addMenuItemWithTitleAndAction("Login...", "login", $this);
		else
			$submenu->addMenuItemWithTitleAndAction("Logout", "logout", $this);

		$appname=NSBundle::mainBundle()->objectForInfoDictionaryKey("CFBundleName");
		$item=new NSMenuItemView($appname);
		$submenu=new NSMenuView();
		$item->setSubMenu($submenu);
		$this->mainMenu->addMenuItem($item);
		$submenu->addMenuItemWithTitleAndAction("Quit", "terminate", $this);

		$item=new NSMenuItemView("File");
		$submenu=new NSMenuView();
		$item->setSubMenu($submenu);
		$this->mainMenu->addMenuItem($item);
		$submenu->addMenuItemWithTitleAndAction("New", "newDocument", $this);
		$submenu->addMenuItemWithTitleAndAction("Open", "openDocument", $this);
		$submenu->addMenuItemSeparator();
		$submenu->addMenuItemWithTitleAndAction("Save", "saveDocument", $this);

		$item=new NSMenuItemView("Edit");
		$submenu=new NSMenuView();
		$item->setSubMenu($submenu);
		$this->mainMenu->addMenuItem($item);
		$submenu->addMenuItemWithTitleAndAction("Undo", "undo", $this);

		$item=new NSMenuItemView("View");
		$submenu=new NSMenuView();
		$item->setSubMenu($submenu);
		$this->mainMenu->addMenuItem($item);
		$submenu->addMenuItemWithTitleAndAction("View", "undo", $this);

		$item=new NSMenuItemView("Window");
		$submenu=new NSMenuView();
		$item->setSubMenu($submenu);
		$this->mainMenu->addMenuItem($item);
		$submenu->addMenuItemWithTitleAndAction("Window", "undo", $this);

		$item=new NSMenuItemView("Help");
		$submenu=new NSMenuView();
		$item->setSubMenu($submenu);
		$this->mainMenu->addMenuItem($item);
		$submenu->addMenuItemWithTitleAndAction("Help", "help", $this);
		}

	public function terminate()
		{
// FIXME:
		if($this->name == "Palmtop")
			$this->open("loginwindow.app");
		else
			$this->open("Palmtop.app");
		}
	public function sendActionToTarget(NSResponder $from, $action, $target)
		{
		if(!$action)
			return;	// no action is set
		if(!isset($target))
			{ // it $target does not exist -> take first responder
_NSLog("sendAction $action to first responder");
			$target=null;	// FIXME: locate first responder
			}
		else
{
// NSLog("sendAction $action to ".$target->description());
}
		if(method_exists($target, $action))
			$target->$action($from);
		else
			_NSLog(/*$target->description().*/"target does no handle $action");
		}
	public function updateWindows()
		{
		if(method_exists($this->delegate, "updateWindows"))
			$this->delegate->updateWindows();
		$this->mainWindow->display();
		}
	public function run()
		{
		if(isset($_GET['RESOURCE']))
			{ // serve some resource file
			$fm=NSFileManager::defaultManager();
			NSBundle::mainBundle();
			NSBundle::bundleForClass($this->classString());
// _NSLog($_GET['BUNDLE']);
			if(isset($_GET['BUNDLE']))
				$bundle=NSBundle::bundleWithIdentifier($_GET['BUNDLE']);
			else
				$bundle=NSBundle::mainBundle();
// _NSLog($bundle);
			$noopen=is_null($bundle);	// bundle not found
// _NSLog("noopen: $noopen\n");
			if(!$noopen)
				$path=$bundle->resourcePath()."/".$_GET['RESOURCE'];	// relative to Resources
			else
				$path="?";
// _NSLog("path: $path\n");
			$noopen=$noopen || strpos("/".$path."/", "/../") !== FALSE;	// if someone tries ..
// _NSLog("noopen: $noopen\n");
			$noopen=$noopen || !$fm->fileExistsAtPath($path);
// _NSLog("noopen: $noopen after fileExistsAtPath $path\n");
			if(!$noopen)
				{ // check if valid extension
				$extensions=array("png", "jpg", "jpeg", "gif", "css", "js");
				$pi=pathinfo($path);
// NSLog("extensions:");
// NSLog($extensions);
// NSLog($pi);
				$noopen = !isset($pi['extension']) || !in_array($pi['extension'], $extensions);
				}
			if($noopen)
				_404();	// simulate 404 error
			if(in_array($pi['extension'], array("css", "js")))
				header("Content-Type: text/".$pi['extension']);
			else
				header("Content-Type: image/".$pi['extension']);
// _NSLog($path);
			$ttl=1*60*60;	// cache for 1 hour
			// should use $fm->attributesOfItemAtPath($path)
			$mtime=filemtime($fm->fileSystemRepresentationWithPath($path));
			header("Expires: ".gmdate("D, d M Y H:i:s", time()+$ttl)." GMT");
			header("Last-Modified: ".gmdate("D, d M Y H:i:s", $mtime)." GMT");
			header("Cache-Control: public, max-age=$ttl");
			// header("Cache-Control: pre-check=$ttl", false);	// IE5...
			if($_SERVER['REQUEST_METHOD'] == "GET")
				{ // emit requested contents to browser (otherwise we do not need to read+echo the file)
				$file=$fm->contentsAtPath($path);
				echo $file;
				}
			exit;
			}
		do
			{ // e(elementId) onclick handler
// _NSLog($_POST);
			$targetId=_persist('NSEvent', null);	// set by the e(n) onlick handler
// _NSLog("targetId $targetId");
			if(!is_null($targetId) && $targetId)
				$target=NSResponder::_objectForId($targetId);
			else
				$target=null;
// _NSLog($target);
			if(!is_null($target))
				{ // user did click into this object when sending this form
				global $NSApp;
				$event=new NSEvent($target, 'NSMouseDown');
				$event->setPosition(array('y' => _persist('clickedRow', null), 'x' => _persist('clickedColumn', null)));
				_persist('clickedRow', "", "");	// reset
				_persist('clickedColumn', "", "");	// reset
				$this->queueEvent($event);
				}
			_persist('NSEvent', "", "");	// reset
			foreach($this->eventQueue as $event)
				$this->mainWindow->sendEvent($event);	// deliver all events
			$this->updateWindows();
			// could we run an AJAX loop here?
			} while(false);	// not really a loop in a http response...
		}
}
	
class NSColor extends NSObject
	{
	protected $rgb;
	public function name() { }
	public static function systemColorWithName($name)
		{
//		NSBundle::bundleForClass($this->classString());
		// get system colors
		}
	}

class NSCell extends NSObject
	{
	protected $controlView;
	public function controlView() { return $this->controlView; }
	public function setControlView($controlView) { $this->controlView=$controlView; }
	public function drawCell()
		{ // overwrite in subclass
		return;
		}
	}

class NSView extends NSResponder
{ // semi-abstract superclass
	protected $frame;
	protected $subviews=array();
	protected $superview;
	protected $autoResizing;
	protected $needsDisplay=true;
	protected $window;
	protected $tooltip;
	protected $hidden=false;
	public function __construct()
		{
		parent::__construct();
		// if we ever get problems with this numbering, we should derive the name from
		// the subview tree index, e.g. 0-2-3
		$this->frame=NSMakeRect(0, 0, 0, 0);
		}
	public function _persist($object, $default, $value=null)
		{
		return _persist($this->elementId."-".$object, $default, $value);	// add namespace for this view
		}
	public function frame() { return $this->frame; }
	public function setFrame($frame) { $this->frame=$frame; }
	public function setFrameSize($size) { $this->frame['width']=NSWidth($size); $this->frame['height']=NSHeight($size); }
	public function window() { return $this->window; }
	public function setWindow(NSWindow $window=null)
		{
//		NSLog("setWindow ".$window->description()." for ".$this->description());
		$this->window=$window;
		foreach($this->subviews as $view)
			$view->setWindow($window);
		$this->setNeedsDisplay();
		}
	public function superview() { return $this->superview; }
	public function _setSuperView(NSView $superview=null)
		{
		$this->superview=$superview;
		$this->setNeedsDisplay();
		}
	public function subviews() { return $this->subviews; }
	public function setSubviews($views)
		{
		foreach($this->subviews as $subview)
			$this->_removeSubView($subview);	// remove old
		foreach($views as $subview)
			$this->addSubview($subview);	// add new
		}
	public function addSubview(NSView $view)
		{
		if($this === $view || !is_null($view->superview()))
			{
			_NSLog("bug - trying to add to a second parent view");
			_NSLog($this);
			_NSLog($view);
			return;
			}
		$this->subviews[]=$view;
		$view->_setSuperView($this);
		$view->setWindow($this->window);
		$view->setNeedsDisplay();
		}
	public function _removeSubView(NSView $view)
		{
		$view->setWindow(null);
		$view->_setSuperView(null);
		if(($key = array_search($view, $this->subviews, true)) !== false)
			unset($this->subviews[$key]);
		$this->setNeedsDisplay();
		}
	public function removeFromSuperview()
		{
		$this->superview()->_removeSubView($this);
		}
	public function setNeedsDisplay()
		{
		$this->needsDisplay=true;
		if(!is_null($this->superview()))
			$this->superview()->setNeedsDisplay();	// pass upwards
		}
	public function needsDisplay()
		{
		return $this->needsDisplay;
		}
	public function isHidden()
		{
		if($this->hidden)
			return true;
		if(!is_null($this->superview()))
			return $this->superview()->isHidden();
		return false;
		}
	public function setHidden($flag)
		{
		if($flag == $this->hidden)
			return;
		$this->hidden=$flag;
		$this->setNeedsDisplay();
		}
	public function display()
		{ // draw subviews first
		if($this->hidden)
			return;	// hide - including subviews
//		NSLog("<!-- ".$this->elementId." -->");
		if(isset($this->tooltip) && $this->tooltip)
			{
			html("<span");
			parameter("title", $this->tooltip);
			html(">\n");
			}
		// if $this->class()-defaultMenu() exists -> add menu
		foreach($this->subviews as $view)
			$view->display();
		$this->draw();
		if(isset($this->tooltip) && $this->tooltip)
			html("</span>\n");
		}
	public function displayDone()
		{ // notify all subview
		foreach($this->subviews as $view)
			$view->displayDone();
		}
	public function setToolTip($str=null) { $this->tooltip=$str; }
	public function toolTip() { return $this->tooltip; }
	public function draw()
		{ // draw our own contents
		// text("plain NSView");
		}
	public function mouseDown(NSEvent $event)
		{ // nothing by default
		return;
		}
}

class NSControl extends NSView
	{
	protected $action="";	// function name
	protected $target=null;	// object
	protected $tag=0;
	protected $align="";
	protected $enabled=true;
	protected $cell;
	public function __construct()
		{ // must explicitly call!
		parent::__construct();
		}
	public function isEnabled() { return $this->enabled; }
	public function setEnabled($flag) { $this->enabled=$flag; }
	public function sendAction($action=null, NSObject $target=null)
		{
		global $NSApp;
		if(is_null($action))
			$action=$this->action;
		if(is_null($target))
			$target=$this->target;
NSLog($this->description()." sendAction $action");
		$NSApp->sendActionToTarget($this, $action, $target);
		}
	public function setActionAndTarget($action, NSObject $target)
		{
		$this->action=$action;
		$this->target=$target;
		}
	public function action() { return $this->action; }
	public function target() { return $this->target; }
	public function setTag($val) { $this->tag=$val; }
	public function tag() { return $this; }
	public function setAlign($align) { $this->align=$align; }
	public function align() { return $this->align; }
	public function draw()
		{
// _NSLog($this);
		$this->cell->drawCell();
		}
	}

class NSButton extends NSControl
	{
	protected $tag;
	protected $title;
	protected $altTitle;
	protected $state;
	protected $buttonType;
	protected $keyEquivalent;	// set to "\r" to make it the default button
	protected $backgroundColor;
	public function __construct($newtitle = "NSButton", $type="Button")
		{
		parent::__construct();
// _NSLog("NSButton $newtitle ".$this->elementId);
		$this->title=$newtitle;
		$this->buttonType=$type;
		if($type != "NSPopupButton")
			{
			$this->state=$this->_persist("state", NSOffState);
			if($this->_eventIsForMe())
				{ // has been clicked by e() mechanism
				_persist('clickedRow', "", $state);	// pass through NSEvent to mouseDown
				$this->_persist("ck", "", "");	// unset
				}
			else if(!is_null($this->_persist("ck", null)))
				{ // non-java-script detection
				global $NSApp;
				$this->_persist("ck", "", "");  // unset
// _NSLog("ck: ".$this->classString());
				$NSApp->queueEvent(new NSEvent($this, 'NSMouseDown')); // queue a mouseDown event for us
				}
			}
		}
	public function isSelected()
		{
		return $this->state == NSOnState;
		}
	public function setSelected($value)
		{
/*		_NSLog("setSelected");
		_NSLog($this->state);
		_NSLog($value);
*/
		$this->setState($value?NSOnState:NSOffState);
		}
	public function description() { return parent::description()." ".$this->title; }
	public function tag() { return $this->tag; }
	public function setTag($tag) { $this->tag=$tag; }
	public function title() { return $this->title; }
	public function setTitle($title)
		{
		if($title == $this->title)
			return;
		$this->title=$title;
		$this->setNeedsDisplay();
		}
	public function alternateTitle() { return $this->altTitle; }
	public function setAlternateTitle($title)
		{
		if($title == $this->altTitle)
			return;
		$this->altTitle=$title;
		$this->setNeedsDisplay();
		}
	public function backgroundColor() { return $this->backgroundColor; }
	public function setBackgroundColor($color)
		{
		if($color == $this->backgroundColor)
			return;
		$this->backgroundColor=$color;
		$this->setNeedsDisplay();
		}
	public function state() { return $this->state; }
	public function setState($value)
		{
/*
_NSLog("setState");
_NSLog($this->state);
_NSLog($value);
*/
		if($value == $this->state)
			return;
		$this->state=$this->_persist("state", $value);
		$this->setNeedsDisplay();
// _NSLog($this->state);
		}
	public function setObjectValue($val) { /*_NSLog("setObjectValue"); _NSLog($val);*/ $this->setSelected($val != ""); /*_NSLog($this->state);*/ }
	public function setButtonType($type) { $this->buttonType=$type; $this->setNeedsDisplay(); }
	public function mouseDown(NSEvent $event)
	{ // this button may have been pressed
// _NSLog("NSButton mouseDown");
// _NSLog($event->position());
		// _NSLog($event);
		// NSLog($this);
		// if radio button or checkbox, watch for value
		// but then the mouseDown is handled by the superview
		// FIXME: handle checkbox tristate
		if($this->buttonType == "Radio" || $this->buttonType == "CheckBox")
			$this->setState(!$this->state());
		$this->sendAction();
	}
	public function keyEquivalent() { return $this->keyEquivalent; }
	public function setKeyEquivalent($str) { $this->keyEquivalent=$str; }
	public function draw()
		{
		html("<input");
		parameter("id", $this->elementId);
// FIXME: if default button (shortcut "\r"): invert the selected state
		if($this->keyEquivalent == "\r")
			parameter("class", "NSButton ".(!$this->isSelected()?"NSOnState":"NSOffState"));
		else
			parameter("class", "NSButton ".($this->isSelected()?"NSOnState":"NSOffState"));
		if($this->backgroundColor)
			parameter("style", "background-color: ".$this->backgroundColor);
		switch($this->buttonType)
			{
// if checkbox/radio action is defined -> add onclick handler
				case "Radio":
					parameter("type", "radio");
					$super=$this->superview();
					if($super->classString() == "NSMatrix")
						{
						parameter("name", $super->elementId."-ck");
						if($super->getRowColumnOfCell($row, $column, $this))
							{
							if(is_null($super->action()))
								parameter("onclick", "e('".$super->elementId."');"."r($row);"."c($column)");	// don't submit
							else
								parameter("onclick", "e('".$super->elementId."');"."r($row);"."c($column)".";s()");
							}
						}
					else
						{ // stand-alone
						parameter("name", $this->elementId."-ck");
						if(!is_null($this->target) && !is_null($this->action))
							parameter("onclick", "e('".$this->elementId."');s()");
						}
					break;
				case "CheckBox":
					parameter("type", "checkbox");
					parameter("name", $this->elementId."-ck");
					if(!is_null($this->target) && !is_null($this->action))
						parameter("onclick", "e('".$this->elementId."');s()");
					break;
				default:
					parameter("type", "submit");
					parameter("name", $this->elementId."-ck");
					parameter("value", _htmlentities($this->title));
			}
		if(!$this->enabled)
			parameter("disabled", "");
		if(isset($this->altTitle))
			{ // use CSS to change contents on hover
			}
		if($this->isSelected())
			parameter("checked", "checked");
		html("/>");
		switch($this->buttonType)
			{
				case "CheckBox":
				case "Radio":
					html(_htmlentities($this->title));
				break;
			}
		html("\n");
		}
	}

// FIXME: we currently do not correctly separate between NSMenu/NSMenuItem and NSMenuView/NSMenuItemView

class NSMenuItemView extends NSButton
	{	
		protected $icon;
		protected $shortcut;
		protected $subMenuView;
		protected $isSelected;
		public function isSelected() { return $this->isSelected; }
		public function setSelected($sel) { $this->isSelected=$this->_persist("isSelected", 0, $sel); }
		public function __construct($label)
			{
			parent::__construct($label);
			$this->isSelected=$this->_persist("isSelected", 0);
			}
		public function setSubmenu(NSMenu $submenu) { $this->subMenuView=$submenu; $this->setNeedsDisplay(); }
		public function submenu() { return $this->subMenuView; }
		public function draw()
			{
			// FXIME: use <style>
			// if no action -> grey out
			NSGraphicsContext::currentContext()->text($this->title);
			if(isset($this->subMenuView))
				{
				html("<select");
				parameter("id", $this->elementId);
				parameter("class", "NSMenuItemView");
				parameter("name", $this->elementId);
				parameter("onclick", "e('".$this->elementId."');s()");
				parameter("size", 1);	// make a popup not a combo-box
				html(">\n");
				$index=0;
				foreach($this->subMenuView->menuItems() as $item)
				{ // add menu buttons and switching logic
					html("<option");
					parameter("class", "NSMenuItem");
					if($item->isSelected())
						parameter("selected", "selected");	// mark menu title as selected
					html(">");
					$item->draw();	// draws the title
					html("</option>\n");
					$index++;
				}
				html("</select>\n");
				}
			else if(isset($this->shortcut))
				html(_htmlentities(" ".$this->shortcut));
			}
	}

class NSMenuItemSeparator extends NSMenuItemView
	{	
		public function NSMenuItemSeparator()
		{
			parent::__construct("---");
		}
		public function draw()
		{
			html("<hr>\n");
		}
	}

class NSMenu extends NSControl
{ // FIXME: NSMenu is not a view!
	public function __construct()
		{
		parent::__construct();
		}
}

class NSMenuView extends NSMenu
	{
	protected $border=1;
	protected $width="100%";
	protected $isHorizontal;
	protected $menuItems;
	protected $selectedItem=-1;
	public function __construct($horizontal=false)
		{
		parent::__construct();
		$this->isHorizontal=$horizontal;
//		NSLog($this->isHorizontal?"horizontal":"vertical");
		$this->selectedItem=$this->_persist("selectedIndex", -1);
		$menuItems=array();
		}
	public function menuItems() { return $this->menuItems; }
	public function menuItemAtIndex($index) { return $this->menuItems[$index]; }
	public function addMenuItem(NSMenuItemView $item) { $this->menuItems[]=$item; $this->setNeedsDisplay(); }
	public function addMenuItemWithTitleAndAction($title, $action, NSObject $target)
		{
		$item=new NSMenuItemView($title);
		$item->setActionAndTarget($action, $target);
		// FIXME: make subview???
		$this->addMenuItem($item);
		return $item;
		}
	public function addMenuItemSeparator()
		{
		$item=new NSMenuItemSeparator();
		$this->addMenuItem($item);
		}
	public function draw()
		{
		if(0)
			{ // show menu as buttons
			$this->_persist("selectedIndex", -1, $this->selectedItem);
			html("<table");
			parameter("border", $this->border);
			if($this->isHorizontal)
				parameter("width", $this->width);
			html(">\n");
			html("<tr");
			parameter("class", "NSMenuItemView");
			html(">\n");
			$index=0;
			foreach($this->menuItems as $item)
			{ // add menu buttons and switching logic
				html("<td");
				parameter("class", "NSMenuItem ".($this->selectedItem == $index?"NSOnState":"NSOffState"));
				html(">\n");
				$item->setSelected($this->selectedItem == $index);
				$item->draw();
				html("</td>\n");
				$index++;
			}
			html("</tr>\n");
			html("</table>\n");
			}
		else
			{ // show menu as popup items
				// HTML5 hat <menu> und <menuitem> tags!
				if($this->isHorizontal)
					{ // draw all submenus because we are top-level
						html("<div");
						parameter("class", "NSMenuView");
						html(">\n");
						foreach($this->menuItems as $item)
						{ // add menu buttons and switching logic
							$item->draw();
						}
						html("</div>\n");
					}
				else
					{
					html("vertical menu on top level");
					// will be drawn by NSMenuItemView
					}
			}
		}
	}

class NSPopUpButton extends NSButton
	{
	protected $menu;
	protected $pullsDown=true;
	protected $selectedItemIndex;

	public function __construct()
		{
		parent::__construct("", "NSPopupButton");
		$this->menu=array();
// _NSLog($this->elementId()." created");
		$this->selectedItemIndex=$this->_persist("selectedIndex", -1);
// _NSLog($this->elementId()." selected item ".$this->selectedItemIndex);
		if($this->_eventIsForMe())
			{
			// Warning - this only works if titles are unique!
			$title=_persist($this->elementId, "");	// read selected item title
			_persist($this->elementId, "", "");	// and remove
			_persist('clickedRow', "", $title);	// pass through NSEvent to mouseDown
			}
		}

	public function pullsDown() { return $this->pullsDown; }
	public function setPullsDown($flag)
		{
		if($flag == $this->pullsDown)
			return;
		$this->pullsDown=$flag;
		$this->setNeedsDisplay();
		}

	public function addItemWithTitle($title) { $this->menu[]=$title; $this->setNeedsDisplay(); }
	public function addItemsWithTitles($titleArray) { foreach($titleArray as $title) $this->addItemWithTitle($title); }
	public function insertItemWithTitleAtIndex($title, $index) { }
	public function removeAllItems() { $this->menu=array(); $this->setNeedsDisplay(); }
	public function removeItemWithTitle($title) { }
	public function removeItemWithTitles($titleArray) { }
	public function selectedItem() { return null;	/* NSMenuItem! */ }
	public function indexOfSelectedItem() { return $this->selectedItemIndex >= count($this->menu)?-1:$this->selectedItemIndex; }
	public function titleOfSelectedItem() { return $this->selectedItemIndex < 0 ? null : $this->menu[$this->selectedItemIndex]; }
	public function selectItemAtIndex($index)
		{
		$this->selectedItemIndex=$this->_persist("selectedIndex", -1, $index);
// _NSLog("selectItemAtIndex $index -> ".$this->selectedItemIndex);
		$this->setNeedsDisplay();
		}
	public function selectItemWithTitle($title) { $this->selectItemAtIndex($this->indexOfItemWithTitle($title)); }
	public function menu() { return $this->menu; }
	public function itemArray() { return $this->menu; }
	public function itemWithTitle($title)
		{
		$idx=$this->indexOfItemWithTitle($title);
		return $idx < 0 ? null : $this->menu[$idx];
		}
	public function indexOfItemWithTitle($title)
		{ // search by title
// _NSLog("indexOfItemWithTitle($title)");
// _NSLog("count()=".count($this->menu));
		for($idx=0; $idx<count($this->menu); $idx++)
			{
// _NSLog($this->menu[$idx]." == ".$title);
			if($this->menu[$idx] == $title)
				return $idx;
			}
		return -1;
		}
	public function mouseDown(NSEvent $event)
		{
// _NSLog($event);
// _NSLog("NSPopupButton mousedown ");
		$pos=$event->position();
// _NSLog($event->target()->elementId());
// _NSLog($this->elementId());
// _NSLog($pos);
		// Warning - this only works if titles are unique!
		$this->selectItemAtIndex($this->indexOfItemWithTitle($pos['y']));
		$this->sendAction();
		}
	public function draw()
		{
// _NSLog($this->elementId()." draw selected item ".$this->selectedItemIndex);
		NSGraphicsContext::currentContext()->text($this->title);
		html("<select");
		parameter("id", $this->elementId);
		parameter("class", "NSPopUpButton");
		parameter("name", $this->elementId);
		parameter("onclick", "e('".$this->elementId."');".";s()");
		parameter("size", 1);	// to make it a popup and not a combo-box
		html(">\n");
		$index=0;
		foreach($this->menu as $item)
			{ // add options
			html("<option");
			parameter("class", "NSMenuItem");
			if($index == $this->selectedItemIndex)
				parameter("selected", "selected");	// mark menu title as selected
			html(">");
			text($item);	// draws the title
			html("</option>\n");
			$index++;
			}
		html("</select>\n");
		}
	}

class NSComboBox extends NSControl
	{
	// use <select size > 1>
	}

class NSImage extends NSObject
{
	protected static $images=array();
	protected $gd;	// GD image (if created)
	protected $url;
	protected $name;
	protected $size=null;
	public function _gd() { $this->size(); return $this->gd; }
	public function size()
		{
		if(is_null($this->size) && !isset($this->gd))
			{ // not explicitly set and not (yet) derived
			$c=parse_url($this->url);
// _NSLog($c);
			if($c['scheme'] == "file")
				{ // FIXME: check for file://
// _NSLog($c['path']);
				$data=NSFileManager::defaultManager()->contentsAtPath($c['path']);
// _NSLog($data);
				$this->gd=imagecreatefromstring($data);
				if($this->gd === false)
					{
					_NSLog("can't open ".$this->url);
					$this->size=NSMakeSize(32, 32);
					}
				else
					$this->size=NSMakeSize(imagesx($this->gd), imagesy($this->gd));
				}
			else
				$this->size=NSMakeSize(0, 0);	// unknown
// _NSLog($this->size);

			}
		return $this->size;
		}
	public function setSize($size)
		{
// _NSLog($size);
		$this->size=$size;
		}
	public static function imageNamed($name)
		{
		if($name == "NSApplication")	// replace by icon defined in Info.plist
			$name=NSBundle::mainBundle()->objectForInfoDictionaryKey('CFBundleIconFile');
		if(isset(self::$images[$name]))
			return self::$images[$name];	// known
		$image=new NSImage();	// create
		if($image->setName($name))
			return $image;
		return null;	// was not found
		}
	public function __construct()
		{
		parent::__construct();
		}
	public function name()
		{
		return $this->name;
		}
	public function composite()
		{
		html("<img");
//		parameter("id", $this->elementId);
		// FIXME: if we don't know the url but a path -> make a data: URL
		$c=parse_url($this->url);
		if(isset($c['scheme']) && $c['scheme'] == "file")
			{ // make external ref to internal file
			$url=NSHTMLGraphicsContext::currentContext()->externalURLForPath($c['path']);
			parameter("src", _htmlentities($url));
			}
		else
			parameter("src", _htmlentities($this->url));
		if(isset($this->name))
			{
			parameter("name", _htmlentities($this->name));
			parameter("alt", _htmlentities($this->name));
			}
		else
			parameter("alt", _htmlentities("unnamed image"));
		$size=$this->size();
		if(NSWidth($size) != 0.0)
			parameter("style", "width:".NSWidth($size)."px; height:".NSHeight($size)."px;");
		html(">\n");
		}
	public function setName($name)
		{
		if($this->name != "")
			unset(self::$images[$this->name]);	// delete current name
		if(!is_null($name) && $name != "")
			{
			if(!isset($this->url))
				{ // not initialized by referencing file/url
				$bundles=array(NSBundle::mainBundle(), NSBundle::bundleForClass($this->classString()));
				foreach($bundles as $bundle)
					{
// _NSLog($bundle);
					$path=$bundle->pathForResourceOfType($name, "");	// check w/o suffix (or suffix in $name)
					if(is_null($path)) $path=$bundle->pathForResourceOfType($name, "png");
					if(is_null($path)) $path=$bundle->pathForResourceOfType($name, "jpg");
					if(is_null($path)) $path=$bundle->pathForResourceOfType($name, "jpeg");
					if(is_null($path)) $path=$bundle->pathForResourceOfType($name, "gif");
// _NSLog($path);
					if(!is_null($path))
						return $this->initByReferencingFile($path);	// found
					}
				return false;	// not found
				}
			$this->name=$name;
			self::$images[$name]=$this;	// store in list of known images
			}
		return true;
		}
	public function initByReferencingURL($url)
		{
// _NSLog($url);
		$this->url=$url;
		$c=parse_url($url);
		if(isset($c['path']))
			{ // use filename (without extension)
			$parts=pathinfo($c['path']);
			$this->name=$parts['filename'];
			self::$images[$this->name]=$this;
			}
		return $this;
		}
	public function initByReferencingFile($path)
		{
		return $this->initByReferencingURL("file://$path");
		}
}

class NSImageView extends NSControl
{
	protected $image;
	protected $resize=false;
	public function __construct()
		{
		parent::__construct();
		}
	public function image()
		{
		return $this->image;
		}
	public function setImage(NSImage $img=null)
		{
		$this->image=$img;
// _NSLog($img);
		$this->setNeedsDisplay();
		}
	public function setObjectValue(NSObject $img=null) { $this->setImage($img); }
	public function setFrameSize($size)
		{
// _NSLog("setFrameSize($size)");
		parent::setFrameSize($size);
		$this->resize=true;
// _NSLog($this);
		}
	public function draw()
		{
// _NSLog($this);
//		NSLog($this->image);
		if(isset($this->image))
			{
			if($this->resize)
				$this->image->setSize(NSSize($this->frame));
			$this->image->composite();
			}
		}
}

class NSCollectionView extends NSControl
{
	protected $columns=1;
	protected $border=0;
	protected $width="100%";
// control alignment of elements, e.g. left, centered, right

	public function content() { return $this->subviews(); }
	public function setContent($items)
		{
		foreach($this->subviews() as $item)
			$item->removeFromSuperview();	// remove existing items from hierarchy
		foreach($items as $item)
			$this->addSubview($item);	// add new ones to hierarchy
		}
	public function addCollectionViewItem($item)
		{ // alternate function name
			$this->addSubview($item);
		}
	public function setBorder($border) { $this->border=0+$border; $this->setNeedsDisplay(); }
	public function setColumns($columns) { $this->columns=0+$columns; $this->setNeedsDisplay(); }

// allow to define colspan and rowspan objects
// allow to modify alignment

	public function __construct($cols=0, $objects=null)
		{
		parent::__construct();
		$this->columns=$cols;
		if($objects)
_NSLog("NSCollectionView with 2 parameters is deprecated");
		}
	public function mouseDown(NSEvent $event)
		{
		}
	public function display()
		{
		if($this->hidden)
			return;
		if($this->columns > 0)
			{
			html("<table");
			parameter("class", "NSCollectionView");
			parameter("id", $this->elementId);
			parameter("border", $this->border);
			parameter("width", $this->width);
			html(">\n");
			}
		$col=1;
		foreach($this->subviews as $item)
			{
			if($this->columns == 0)
				{
				html("<span");
				parameter("class", "NSCollectionView");
				parameter("id", $this->elementId);
				parameter("column", $col++);
				parameter("style", "display: inline-block");
				html(">\n");
				$item->display();
				html("</span>");
				continue;
				}
			if($col == 1)
				html("<tr>");
			html("<td");
			parameter("class", "NSCollectionViewItem");
			if($this->align)
				parameter("align", $this->align);
			html(">\n");
			$item->display();
			html("</td>");
			$col++;
			if($col > $this->columns)
				{
				html("</tr>\n");
				$col=1;
				}
			}
		if($this->columns == 0)
			return;
		if($col > 1)
			{ // handle missing colums
				html("</tr>\n");
			}
		html("</table>\n");
		}
}

// FIXME: handle multiple selections...

class NSMatrix extends NSControl
	{ // matrix of several buttons or fields - radio buttons are grouped
	protected $columns=1;
	protected $selectedColumn=-1;
	protected $selectedRow=-1;
	protected $clickedColumn=-1;
	protected $clickedRow=-1;
	protected $border=0;
	protected $width="100%";
	protected $currentCell;
	protected $currentRow;
	protected $currentColumn;

	public function numberOfColumns() { return $this->columns; }
	public function numberOfRows() { return (count($this->subviews)+$this->columns-1)/$this->columns; }
	public function setColumns($columns) { $this->columns=0+$columns; $this->setNeedsDisplay(); }

	public function selectedRow()
		{
		return ($this->selectedRow<$this->numberOfRows())?$this->selectedRow:-1;
		}

	public function selectedColumn()
		{
		return ($this->selectedColumn<$this->numberOfColumns())?$this->selectedColumn:-1;
		}

	public function __construct($cols=1)
		{
		parent::__construct();
		$this->columns=$cols;
		$this->selectedRow=$this->_persist("selectedRow", -1);
		$this->selectedColumn=$this->_persist("selectedColumn", -1);
// _NSLog("init $this->elementId: $this->selectedRow / $this->selectedColumn");
		}

	public function getRowColumnOfCell(&$row, &$col, $cell)
		{ // here we use 0..n-1 coordinates!
		if($cell === $this->currentCell)
			{ // same as last time...
			$row=$this->currentRow;
			$col=$this->currentColumn;
			return true;
			}
		$row=0;
		$col=0;
		foreach($this->subviews as $item)
			{
			if($item == $cell)
				{
				$this->currentRow=$row;
				$this->currentColumn=$col;
				$this->currentCell=$cell;
				return true;
				}
			$col++;
			if($col >= $this->columns)
				{
				$row++;
				$col=0;
				}
			}
		return false;
		}

	public function cellAtRowColumn($row, $column)
		{
		if($row < 0 || $row >= $this->numberOfRows())
			return null;
		if($column < 0 || $column >= $this->columns)
			return null;
		$idx=$row*$this->columns+$column;
		return $this->subviews[$idx];
		}

	public function selectedCell()
		{
		return $this->cellAtRowColumn($this->selectedRow, $this->selectedColumn);
		}

	public function selectRowColumn($row, $column)
		{
// _NSLog("select old $this->elementId: $this->selectedRow / $this->selectedColumn");
		$this->selectedRow=$this->_persist("selectedRow", -1, $row);
		$this->selectedColumn=$this->_persist("selectedColumn", -1, $column);
// _NSLog("select new $this->elementId: $this->selectedRow / $this->selectedColumn");
		$item=$this->cellAtRowColumn($row, $column);
		if(!is_null($item))
			$item->setSelected(true);	// set item selected
		$this->setNeedsDisplay();
		}

	public function mouseDown(NSEvent $event)
		{
		$pos=$event->position();
		$this->clickedColumn=$pos['x'];
		$this->clickedRow=$pos['y'];
// _NSLog("mouseDown $this->elementId: $this->clickedRow / $this->clickedColumn");
		$this->selectRowColumn($this->clickedRow, $this->clickedColumn);
		$this->sendAction();
		}

	public function display()
		{
		if($this->hidden)
			return;
		html("<table");
		parameter("class", "NSMatrixView");
		parameter("id", $this->elementId);
		parameter("border", $this->border);
		parameter("width", $this->width);
		html(">\n");
		$row=0;
		$col=0;
		foreach($this->subviews as $item)
			{
			if($col == 0)
				html("<tr>");
			html("<td");
			parameter("class", "NSMatrixItem");
			if($this->align)
				parameter("align", $this->align);
			html(">\n");
			$item->setSelected($row == $this->selectedRow && $col == $this->selectedColumn);	// set item selected
			$this->currentCell=$item;	// use cache when calling getRowColumnOfCell from within $item->display()
			$this->currentRow=$row;
			$this->currentColumn=$col;
			$item->display();
			html("</td>");
			$col++;
			if($col >= $this->columns)
				{
				html("</tr>\n");
				$row++;
				$col=0;
				}
			}
		if($col > 1)
			{ // handle missing colums
				// &nbsp; ?
				html("</tr>\n");
			}
		html("</table>\n");
		}
	}

class NSFormCell extends NSView /* NSCell - but then we can't addSubview() */
{
	protected $label;
	protected $value;
	public function __construct()
		{
		$this->label=new NSTextField();
		$this->label->setAttributedStringValue("Label:");
		$this->addSubview($this->label);
		$this->value=new NSTextField();
		$this->addSubview($this->value);
		}
	public function setTitle($string)
		{
		$this->label->setAttributedStringValue($string);
		}
	public function setStringValue($string)
		{
		$this->value->setStringValue($string);
		}
	public function setPlaceholderString($string)
		{
		$this->value->setPlaceholderString($string);
		}
	public function setEditable($flag)
		{
		$this->value->setEditable($flag);
		}
	public function stringValue()
		{
		return $this->value->stringValue();
		}
	public function setSelected($status)
		{
		}
	public function setToolTip($str)
		{
		$this->value->setToolTip($str);
		}
}

class NSForm extends NSMatrix
{
	public function __construct()
		{
		parent::__construct(1);	// 1 column matrix
		}
	public function addEntry($title)
		{
		$cell=new NSFormCell();
		$cell->setTitle($title);
		$this->addSubview($cell);
		return $cell;
		}
}

class NSBox extends NSControl
{
	protected $border=0;
	protected $width="100%";
	public function setBorder($border) { $this->border=0+$border; }

// allow to define colspan and rowspan objects
// allow to modify alignment

	public function __construct($cols=1)
		{
		parent::__construct();
		$this->columns=$cols;
		}
	public function mouseDown(NSEvent $event)
		{
		}
	public function display()
		{
		if($this->hidden)
			return;
		html("<div");
		parameter("class", "NSBox");
		parameter("id", $this->elementId);
		html(">\n");
		foreach($this->subviews as $item)
			{
			html("<div");
			parameter("class", "NSBoxItem");
			html(">\n");
			$item->display();
			}
		html("</div>\n");
		}
}

class NSSegmentedControl extends NSControl
	{
	protected $segments;
	protected $selectedIndex=0;
	}

class NSTabViewItem extends NSObject
	{
	protected $identifier;
	protected $label;
	protected $view;

	public function identifier() { return $this->label; }
	public function label() { return $this->label; }
	public function view() { return $this->view; }
	public function setIdentifier($identifier) { $this->identifier=$identifier; }
	public function setLabel($label) { $this->label=$label; }
	public function setView(NSView $view) { $this->view=$view; }
	public function __construct($label, NSView $view)
		{
//		parent::__construct();
		$this->identifier=$label;	// use same...
		$this->label=$label;
		$this->view=$view;
		}

	/* AppKit.php extension */
	protected $hidden;
	public function isHidden() { return $this->hidden; }
	public function setHidden($flag) { $this->hidden=$flag; }
	}

class NSTabView extends NSControl
	{
	protected $border=1;
	protected $width="100%";
	protected $tabViewItems=array();
	protected $selectedIndex;
	protected $clickedItemIndex=-1;
	protected $delegate;
	protected $segmentedControl;
	public function __construct($items=array())
		{
		parent::__construct();
		foreach($items as $item)
			$this->addTabViewItem($item);
		$this->selectedIndex=$this->_persist("selectedIndex", 0);
		}
	public function delegate() { return $this->delegate; }
	public function setDelegate(NSObject $d=null) { $this->delegate=$d; }
	public function tabViewItems() { return $this->tabViewItems; }
	public function tabViewItemAtIndex($i) { return $this->tabViewItems[$i]; }
	public function addTabViewItem(NSTabViewItem $item)
		{
		if(!is_null($this->_persist(count($this->tabViewItems), null)))
			{ // this index was clicked
			global $NSApp;
			$this->_persist(count($this->tabViewItems), "", "");	// reset event
			$this->clickedItemIndex=count($this->tabViewItems);
			NSLog($this->classString()." index ".$this->clickedItemIndex);
			$NSApp->queueEvent(new NSEvent($this, 'NSMouseDown')); // queue a mouseDown event for us
			}
		$this->tabViewItems[]=$item;
		$this->setNeedsDisplay();
		}
	public function indexOfSelectedTabViewItem() { return $this->selectedIndex; }
	public function selectedTabViewItem()
		{
		if(isset($this->tabViewItems[$this->selectedIndex]))
			return $this->tabViewItems[$this->selectedIndex];
		return null;
		}
	public function indexOfTabViewItem(NSTabViewItem $item)
		{
		$index=0;
		foreach($this->tabViewItems as $i)
			{
			if($i == $item)
				return $index;
			$index++;			
			}
		return -1;
		}
	public function indexOfTabViewItemWithIdentifier($identifier)
		{
		$index=0;
		foreach($this->tabViewItems as $i)
			{
			if($i->identifier() == $identifier)
				return $index;
			$index++;			
			}
		return -1;
		}
	public function selectTabViewItemAtIndex($index)
		{
		if($index < 0 || $index >= count($this->tabViewItems))
			return;	// ignore (or could rise an exception)
		if($this->tabViewItems[$index]->isHidden())
			return;	// can't select (or we might be able to unhide a tab by a fake POST)
		NSLog("selectTabViewItemAtIndex $index");
		if(method_exists($this->delegate, "tabViewShouldSelectTabViewItem"))
			if(!$this->delegate->tabViewShouldSelectTabViewItem($this, $this->tabViewItems[$index]))
				return;	// reject selection
		if(method_exists($this->delegate, "tabViewWillSelectTabViewItem"))
			$this->delegate->tabViewWillSelectTabViewItem($this, $this->tabViewItems[$index]);
		$this->selectedIndex=$this->_persist("selectedIndex", 0, $index);
		if(method_exists($this->delegate, "tabViewDidSelectTabViewItem"))
			$this->delegate->tabViewDidSelectTabViewItem($this, $this->tabViewItems[$index]);
		NSLog("selectTabViewItemAtIndex $index done");
		$this->setNeedsDisplay();
		}
	public function selectTabViewItemWithIdentifier($identifier)
		{
		$this->selectTabViewItemAtIndex($this->indexOfTabViewItemWithIdentifier($identifier));
		}
	public function setBorder($border) { $this->border=0+$border; $this->setNeedsDisplay(); }
	public function mouseDown(NSEvent $event)
		{
// _NSLog("tabview item ".$this->clickedItemIndex." was clicked: ".$event->description());
		$this->selectTabViewItemAtIndex($this->clickedItemIndex);
		}
	public function display()
		{
		html("<table");
		parameter("id", $this->elementId);
		parameter("border", $this->border);
		parameter("width", $this->width);
		html(">\n");
		html("<tr>");
		html("<td");
		parameter("class", "NSTabViewItemsBar");
		html(">\n");
		$index=0;
		foreach($this->tabViewItems as $item)
			{ // add tab buttons and switching logic
			if(!$item->isHidden())
				{
// FIXME: buttons must be able to change state!
// i.e. these buttons should be made in a way that calling their action
// will make selectTabViewItemAtIndex being called
// FIXME: use NSButton or NSMenuItem?

// yes, use ordinary NSButtons and use setTag(tabindex)
// or we us a NSMatrix of NSButtons as a single subview

				html("<input");
				parameter("id", $this->elementId."-".$index);
				parameter("class", "NSTabViewItemsButton ".($item == $this->selectedTabViewItem()?"NSOnState":"NSOffState"));
				parameter("type", "submit");
				parameter("name", $this->elementId."-".$index);
				parameter("value", _htmlentities($item->label()));
				html(">\n");
				}
			$index++;
			}
		html("</td>");
		html("</tr>\n");
		html("<tr>");
		html("<td");
		parameter("align", "center");
		html(">\n");
		$selectedItem=$this->selectedTabViewItem();
		if(!is_null($selectedItem))
			$selectedItem->view()->display();
		else
			html(_htmlentities("No tab for index ".$this->selectedIndex));
		html("</td>");
		html("</tr>\n");
		html("</table>\n");
		}
	}

// should we embed that into a NSClipView which provides the $visibleRows and $firstVisibleRow?
// should we embed the NSClipView into a NSScrollView which can somehow (JavaScript? CSS?) show a scroller?

class NSTableColumn extends NSObject
{
	protected $title;
	protected $identifier="";
	protected $width="*";
	protected $isEditable=false;
	protected $hidden=false;
	protected $align="";
	protected $headerCell;
	protected $dataCell;
	// allow to define colspan and rowspan values

	public function title() { return $this->title; }
	public function setTitle($title) { $this->title=$title; }
	public function identifier() { return $this->identifier; }
	public function setIdentifier($identifier) { $this->identifier=$identifier; }
	public function isHidden() { return $this->hidden; }
	public function setHidden($flag) { $this->hidden=$flag; }
	public function isEditable() { return $this->isEditable; }
	public function setEditable($flag) { $this->isEditable=$flag; }
	public function align() { return $this->align; }
	public function setAlign($align) { $this->align=$align; }
	public function width() { return $this->width; }
	public function setWidth($width) { $this->width=$width; }
	public function dataCell() { return $this->dataCell; }
	public function headerCell() { return $this->headerCell; }
	public function setDataCell(NSView $cell) { $this->dataCell=$cell; }
	public function setHeaderCell(NSView $cell) { $this->headerCell=$cell; }
}

// IDEA:
// we can implement some firstVisibleRow and scrollToVisible
// through appending e.g. #31-5-0 to the URL (send modified "Location:" header instructing the browser to reload)

class NSTableView extends NSControl
	{
	protected $columns;
	protected $border=0;
	protected $width="100%";
	protected $delegate;
	protected $dataSource;
	protected $visibleRows=0;	// 0 = infinite
	protected $firstVisibleRow=0;
	protected $selectedRow=-1;
	protected $selectedColumn=-1;
	protected $clickedRow;
	protected $clickedColumn;
	protected $doubleAction;
	public function delegate() { return $this->delegate; }
	public function setDelegate(NSObject $d=null) { $this->delegate=$d; }
	public function setDataSource(NSObject $source=null) { $this->dataSource=$source; $this->reloadData(); }
	public function setBorder($border) { $this->border=0+$border; $this->setNeedsDisplay(); }
	public function setVisibleRows($rows) { $this->visibleRows=0+$rows; $this->setNeedsDisplay(); }
	public function numberOfRows() { if(!isset($this->dataSource)) return 1; return $this->dataSource->numberOfRowsInTableView($this); }
	public function numberOfColumns() { return count($this->headers); }
	public function doubleAction() { return $this->doubleAction; }
	public function setDoubleAction($sel) { $this->doubleAction=$sel; }
	public function __construct($headers=array("Column1"), $visibleRows=0)
		{
       		parent::__construct();
		if(!is_array($headers))
			_NSLog('please specify column headers of new NSTableView($headers) as array()');
		$this->visibleRows=$visibleRows;
		$this->selectedRow=$this->_persist("selectedRow", -1);
		$this->selectedColumn=$this->_persist("selectedColumn", -1);
		$this->columns=array();
		foreach($headers as $title)
			{
			$col=new NSTableColumn();
			$col->setTitle($title);
			$col->setIdentifier($title);
			$this->addColumn($col);
			}
		NSLog($this->classString());
		}
	public function reloadData() { $this->setNeedsDisplay(); }
	public function columns()
		{
		return $this->columns;
		}
	public function setColumns($columns)
		{
		if(is_null($columns))
			return;
		NSLog("set columns");
		NSLog($columns);
		$this->columns=$columns;
		$this->reloadData();
		}
	public function addColumn(NSTableColumn $column)
		{
		$this->columns[]=$column;
		$this->reloadData();
		}
	public function removeColumnAtIndex($index)
		{
		unset($this->columns[$index]);
		$this->reloadData();
		}
	public function selectedRow()
		{
		return ($this->selectedRow<$this->numberOfRows())?$this->selectedRow:-1;
		}
	public function selectedColumn()
		{
		return ($this->selectedColumn<$this->numberOfColumns())?$this->selectedColumn:-1;
		}
	public function selectRow($row, $extend=false)
		{
		NSLog("selectRow $row extend ".($extend?"yes":"no"));
		// if ! extend -> delete previous otherwise merge into set
		$this->selectedRow=$this->_persist("selectedRow", -1, $row);
		$this->setNeedsDisplay();
		$delegate=$this->delegate();
		if(is_object($delegate) && $delegate->respondsToSelector("selectionDidChange"))
			$delegate->selectionDidChange($this);
		}
	public function mouseDown(NSEvent $event)
		{
		$pos=$event->position();
		$this->clickedColumn=$pos['x'];
		$this->clickedRow=$pos['y'];
		if(false && $this->clickedRow == -1)
			; // select column
		// if this clickedRow is already selected we may have a double-click
		// then call doubleAction (if defined) or check if NSTableColumn is editable
		$this->selectRow($this->clickedRow);
		}
	public function draw() { _NSLog("don't call NSTableView -> draw()"); }
	public function display()
		{
		$rows=$this->numberOfRows();	// may trigger a callback that changes something
		if(!isset($this->dataSource))
			{
			// NSFatalError("table has no dataSource");
			html("table has no data source");
			return;
			}
		NSLog("numberOfRows: $rows");
		html("<table");
		parameter("id", $this->elementId);
		parameter("border", $this->border);
		parameter("width", $this->width);
		html(">\n");
		html("<tr");
		parameter("class", "NSHeaderView");
		html(">\n");
		foreach($this->columns as $index => $column)
			{
			if($column->isHidden())
				continue;
			html("<th");
			parameter("id", $this->elementId."-".$index);
			parameter("name", $column->identifier());
			parameter("class", "NSTableHeaderCell");
			parameter("onclick", "e('".$this->elementId."');"."r(-1);"."c($index)".";s()");
			parameter("width", $column->width());
			html(">\n");
			html(_htmlentities($column->title()));
			html("</th>\n");
			}
		html("</tr>\n");
		$row=$this->firstVisibleRow;
		while(($this->visibleRows == 0 && $row<$rows) || $row<$this->firstVisibleRow+$this->visibleRows)
			{
			html("<tr");
			parameter("id", $this->elementId."-".$row);
			parameter("class", "NSTableRow");
			// add id="even"/"odd" so that we can define bgcolor by CSS?
			html(">\n");
			foreach($this->columns as $index => $column)
				{
				if($column->isHidden())
					continue;
				html("<td");
				parameter("id", $this->elementId."-".$row."-".$index);
				parameter("name", $column->identifier());
				parameter("class", "NSTableCell ".($row == $this->selectedRow?"NSSelected":"NSUnselected")." ".($row%2 == 0?"NSEven":"NSOdd"));
				if($column->align()) parameter("align", $column->align());
				parameter("width", $column->width());
// FIXME: make the element handle onclick...
				parameter("onclick", "e('".$this->elementId."');"."r($row);"."c($index)".";s()");
				html(">\n");
				if($row < $rows)
					{ // ask delegate for the value to show
					$item=$this->dataSource->tableView_objectValueForTableColumn_row($this, $column, $row);
					$cell=$column->dataCell();
					if(!is_null($cell))
						{ // insert value into cell and let the cell do the formatting
						// how can we pass down the onclick handler?
						$cell->setObjectValue($item);
						$cell->draw();
						}
					// compatibility if no cells are defined
					else if(is_object($item) && $item->respondsToSelector("draw"))
						{
						$item->draw();
						}
					else
						{
						html(_htmlentities($item));
						}
					}
				else
					html("&nbsp;");	// add empty rows
				html("</td>");
				}
			html("</tr>\n");
			$row++;
			}
		html("</table>\n");
		}
	}
	
class NSTextField extends NSControl
{
	protected $stringValue;	// should this be a property of NSControl?
	protected $placeholder="";
	protected $htmlValue;
	protected $backgroundColor;
	protected $align;
	protected $type="text";
	protected $width;
	protected $isEditable=true;
	protected $textColor;
	protected $wraps=false;
	protected $name;	// name of this <input>
	public function stringValue() { return $this->stringValue; }
	public function attributedStringValue() { return $this->htmlValue; }
	public function setStringValue($str) { $this->stringValue=$str; $this->htmlValue=htmlentities($str, ENT_COMPAT | ENT_SUBSTITUTE, NSHTMLGraphicsContext::encoding); $this->setNeedsDisplay(); }
	// should be used for static text fields
	public function setAttributedStringValue($astr) { $this->htmlValue=$astr; $this->isEditable=false; $this->wraps=true; $this->setNeedsDisplay(); }
	public function isEditable() { return $this->isEditable; }
	public function setEditable($flag, $name=null)
		{
		$this->isEditable=$flag;
		if(!is_null($name))
			{
			$this->name=$name;	// override
			$this->setStringValue(_persist($this->name, ""));
			}
		$this->setNeedsDisplay();
		}
	public function placeholderString() { return $this->placeholder; }
	public function setPlaceholderString($str) { $this->placeholder=$str; $this->setNeedsDisplay(); }
	public function backgroundColor() { return $this->backgroundColor; }
	public function setBackgroundColor($color)
		{
		if($color == $this->backgroundColor)
			return;
		$this->backgroundColor=$color;
		$this->setNeedsDisplay();
		}
	public function __construct($width=30, $stringValue = null, $name = null)
	{
       		parent::__construct();
		if(is_null($name))
			$this->name=$this->elementId."-string";	// default name
		else
			$this->name=$name;	// override
// _NSLog("__contruct NSTextField ".$this->name);
		$this->setStringValue(_persist($this->name, ""));
		// the second parameter should be depreacted and be replaced by an explicit setStringValue() only ...
		if(!is_null($stringValue))
			$this->setStringValue($stringValue);	// overwrite
		// should be depreacted and replaced by setFrame() ...
		$this->width=$width;
	}
	public function mouseDown(NSEvent $event)
		{ // user has pressed return in this (search)field
// _NSLog("mouseDown");
// _NSLog($this);
		$this->sendAction();
		}
	public function displayDone()
		{
		if($this->isHidden())
			{ // persist stringValue even if text field is currently hidden
			if($this->isEditable && $this->type != "password")
				_persist($this->name, $this->stringValue);
			}
		else if($this->isEditable)
			_persist($this->name, "", "");	// remove from persistence store (because we have our own <input>)
		parent::displayDone();
		}
	public function draw()
		{
		if($this->isEditable)
			{
			html("<input");
			parameter("id", $this->elementId);
			parameter("class", "NSTextField");
			parameter("type", $this->type);
			parameter("size", $this->width);
			if($this->backgroundColor)
				parameter("style", "background-color: ".$this->backgroundColor);
			if($this->placeholder)
				parameter("placeholder", $this->placeholder);
			// FIXME: _setName should allow to set a global name, e.g. "username" or "password"
			parameter("name", $this->name);
			if($this->type != "password")
				parameter("value", _htmlentities($this->stringValue));	// password is always shown cleared/empty
			switch($this->type)
				{ // special types
				case "search":
					parameter("onsearch", "e('".$this->elementId."');s('search')");
					break;
				case "search":
					parameter("onchange", "e('".$this->elementId."');s('change')");
					break;
				case "range":
					parameter("oninput", "e('".$this->elementId."');s('input')");
					break;
				}
			html("/>\n");
			}
		else
			{
			if($this->wraps)
				html(nl2br($this->htmlValue));
			else
				html($this->htmlValue);
			}
		}
}

class NSSecureTextField extends NSTextField
{
	public function __construct($width=30, $name=null)
	{
		parent::__construct($width, null, $name);
		$this->type="password";
	}

}

class NSSearchField extends NSTextField
{
	public function __construct($width=30, $name=null)
	{
		parent::__construct($width, null, $name);
		$this->type="search";
	}

}

class NSSlider extends NSTextField
{
	public function __construct()
	{
		parent::__construct();
		$this->type="range";
	}

}

class NSTextView extends NSControl
{
	protected $string;
	public function __construct($width = 80, $height = 20)
		{
       		parent::__construct();
		$this->frame=NSMakeRect(0, 0, $width, $height);
		$this->string=$this->_persist("string", "");
		}
	public function setString($string)
		{
		if($string == $this->string)
			return;	// no change
		// FIXME: doesn't this conflict with posting a changed string?
		$this->string=$this->_persist("string", "", $string);
		$this->setNeedsDisplay();
		}
	public function string() { return $this->string; }
	public function mouseDown(NSEvent $event)
		{ // some button has been pressed
		}
	public function draw()
		{
		html("<textarea");
		parameter("id", $this->elementId);
		parameter("width", NSWidth($this->frame));
		parameter("height", NSHeight($this->frame));
		parameter("name", $this->elementId."-string");
		html(">");
		html(_htmlentities($this->string));
		html("</textarea>\n");
		}
	public function displayDone()
		{
		$this->_persist("string", "", "");	// remove from persistence store
		parent::displayDone();
		}
}

// NSClipView? with different overflow-setting?

class NSClipView extends NSView
{
}

// initially we only control the scrollers of the NSWindow and keep them stable after reload
class NSScrollView extends NSView
{
	protected $point;

	public function __construct()
		{
// FIXME: does not work properly :(
       		parent::__construct();
		$this->point=NSMakePoint(_persist('scrollerX', null), _persist('scrollerX', null));
// _NSLog("point");
// _NSLog($this->point);
		}

	public function scrollTo($point)
		{ // use NSMakePoint
		$this->point=$point;
		}

	public function display()
		{
		if($this->hidden)
			return;
//		html("<div");
//		parameter("style", "width: ".NSWidth($this->frame)."; height: ".NSHeight($this->frame)."; overflow: scroll");
//		html(">");
		// +0 is to protect against code injection through manipulated point coordinates not being numerical
		$x=$this->point['x']+0;
		$y=$this->point['y']+0;
		if($x != 0 || $y != 0)
			{
			html("<script");
			parameter("type", "text/javascript");
			html(">");
			html("window.scrollTo($x, $y)");
			html("</script>\n");
			}
		parent::display();
//		html("</div>");
		}
}

class NSWindow extends NSResponder
{
	protected $title;
	protected $scrollView;
	protected $heads="";

	public function contentView()
		{
		if(isset($this->scrollView->subviews()[0]))
			return $this->scrollView->subviews()[0];	// first subview
		return null;
		}
	public function setContentView(NSView $view)
		{
		$cv=$this->contentView();
		if(!is_null($cv))
			$this->scrollView->_removeSubView($cv);
		$this->scrollView->addSubView($view);
		$this->scrollView->setWindow($this);
		}
	public function title() { return $this->title; }
	public function setTitle($title) { $this->title=$title; }
	public function _addToHead($line) { $this->heads.=$line."\n"; }

	public function __construct()
		{
		global $NSApp;
		parent::__construct();
		$this->scrollView=new NSScrollView();
		$this->scrollView->addSubView(new NSClipView());	// add empty container for more subviews
		if(is_null($NSApp->mainWindow()))
			$NSApp->setMainWindow($this);
// NSLog($NSApp);
		}
	public function hitTest(NSEvent $event)
		{
		return $event->target();
		}
	public function sendEvent(NSEvent $event)
		{
		global $NSApp;
		NSLog("sendEvent: ".$event->description());
		$window=$target=$event->window();
		if(is_null($window))
			$window=$NSApp->mainWindow();
		$target=$window->hitTest($event);
		$target->mouseDown($event);
		}
	public function update()
		{
		// should send NSWindowDidUpdateNotification
		return;
		}
	public function display() 
		{
		global $NSApp;

		if(headers_sent($file, $line))
			_NSLog("AppKit error: headers already sent in $file#$line");
		html("<!DOCTYPE html");
		if(true)	// use HTML4
			{
			html(" PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\"");
			html(" \"http://www.w3.org/TR/html401/loose.dtd\"");
			}
		html(">\n");
		html("<html>\n");
		html("<head>\n");
		html("<meta");
		parameter("http-equiv", "content-type");
		parameter("content", "text/html; charset=".NSHTMLGraphicsContext::encoding);
		html(">\n");
		html("<meta");
		parameter("name", "generator");
		parameter("content", "mySTEP.php");
		html(">\n");

		html("<meta");
		parameter("name", "viewport");
		parameter("content", "width=device-width");	// iOS specific setup
		html(">\n");

		$r=NSBundle::bundleForClass($this->classString())->pathForResourceOfType("AppKit", "css");
		if(isset($r))
			{
			$r=NSHTMLGraphicsContext::currentContext()->externalURLforPath($r);
			if(!is_null($r))
				{
				html("<link");
				parameter("rel", "stylesheet");
				parameter("href", htmlentities($r));
				parameter("type", "text/css");
				html(">\n");
				}
			}
		// onclick handlers should only be used if necessary since they require JavaScript enabled
		html("<script");
		parameter("type", "text/javascript");
		html(">");
		html("function e(v){document.forms[0].NSEvent.value=v;};");
		html("function r(v){document.forms[0].clickedRow.value=v;};");
		html("function c(v){document.forms[0].clickedColumn.value=v;}");
		html("function s(){document.forms[0].scrollerX.value=window.pageXOffset;document.forms[0].scrollerY.value=window.pageYOffset;document.forms[0].submit();}");
		html("</script>");
		$r=NSBundle::bundleForClass($this->classString())->pathForResourceOfType("AppKit", "js");
		if(isset($r))
			{
			$r=NSHTMLGraphicsContext::currentContext()->externalURLforPath($r);
			if(!is_null($r))
				{
				html("<script");
				parameter("src", $r);
				parameter("type", "text/javascript");
				html(">\n");
				html("</script>\n");
				}
			}
		html("<noscript>Your browser does not support JavaScript!</noscript>\n");
		if(isset($this->title))
			html("<title>"._htmlentities($this->title)."</title>\n");
		html($this->heads);	// additional tags
		html("</head>\n");
		html("<body>\n");

		html("<form");
//		parameter("action", "?");	// delete any query parameter - does not work correctly in all situations :(
		parameter("id", "NSWindow");
		parameter("class", "NSWindow");
		parameter("accept_charset", NSHTMLGraphicsContext::encoding);
		parameter("method", "POST");	// a window is a big form to handle all persistence and mouse events through POST - and goes back to the same
		parameter("enctype", NSHTMLGraphicsContext::encoding);
		html(">\n");
		// scan whole tree for first non-hidden NSButton with $this->keyEquivalent() == "\r" and title() != ""
		if(false)
			{ // define default button if Enter is pressed in some text field
			html("<input");
			parameter("type", "hidden");
			parameter("name", $button->elementId()."-ck");
			parameter("value", _htmlentities($button->title()));
			html(">\n");
			}
		html("<input");
		parameter("type", "hidden");
		parameter("name", "NSEvent");
		parameter("value", "");	// can be set by the e(e) function in JavaScript
		html(">\n");
		html("<input");
		parameter("type", "hidden");
		parameter("name", "clickedRow");
		parameter("value", "");	// can be set by the r(n) function in JavaScript
		html(">\n");
		html("<input");
		parameter("type", "hidden");
		parameter("name", "clickedColumn");
		parameter("value", "");	// can be set by the c(n) function in JavaScript
		html(">\n");
		html("<input");
		parameter("type", "hidden");
		parameter("name", "scrollerX");
		parameter("value", "");	// can be set by the s(n) function in JavaScript
		html(">\n");
		html("<input");
		parameter("type", "hidden");
		parameter("name", "scrollerY");
		parameter("value", "");	// can be set by the s(n) function in JavaScript
		html(">\n");
		$mm=$NSApp->mainMenu();
		if(isset($mm))
			$mm->display();	// draw main menu before content view
		// add App-Icon, menu/status bar
		$this->scrollView->display();	// handles isHidden
		$this->scrollView->displayDone();	// can handle special persistence processing
		// append all values we want (still) to see persisted if someone presses a send button in the form
		global $persist;
		foreach($persist as $object => $value)
			{
			NSLog(@"persist $object $value");
			html("<input");
			parameter("type", "hidden");
			parameter("name", $object);
			// JSON-Encode values?
			parameter("value", $value);
			html(">\n");
			}
		html("</form>\n");
		html("</body>\n");
		html("</html>\n");
		NSGraphicsContext::currentContext()->flushGraphics();
	}
}

class NSWorkspace extends NSObject
{
	protected static $sharedWorkspace;
	protected static $knownApplications;
	protected static $knownSuffixes;
	public static function sharedWorkspace()
		{
		if(!isset($sharedWorkspace))
			$sharedWorkspace=new NSWorkspace();
		return $sharedWorkspace;
		}
	public static function knownApplications()
		{
		if(isset(self::$knownApplications))
			return self::$knownApplications;	// already analysed
		$appdirs=array("/Applications", "/Applications/Games", "/Applications/Work", "/Applications/Utilities", "/System/Library/CoreServices", "/Developer/Applications", "/Internal/Applications");
		self::$knownApplications=array();
		$fm=NSFileManager::defaultManager();
		foreach($appdirs as $dir)
			{
// _NSLog("$dir");
			// FIXME: implement NSFileManager directory enumerator
			$f=opendir($fm->fileSystemRepresentationWithPath($dir));
			if($f)
				{
				while($bundle=readdir($f))
					{
// _NSLog("knownApps check: $dir/$bundle");
					if(substr($bundle, -4) != ".app")	// should we check that???
						continue;
// _NSLog("candidate: $dir/$bundle");
					if(!NSWorkspace::sharedWorkspace()->isFilePackageAtPath("$dir/$bundle"))
						continue;	// is not a bundle
// _NSLog("is bundle: $dir/$bundle");
					$b=NSBundle::bundleWithPath("$dir/$bundle");
					if(is_null($b->executablePath()))
						continue;	// no PHP executable
					/* control which apps the user may see - could also be handled by more sophisticated file access checks */
					$privs=$b->objectForInfoDictionaryKey("Privileges");
					if(is_null($privs))
						$privs="admin";	// no Privileges means this app requires "admin" rights by default, i.e. is almost hidden
					$ok=false;
					// $ok=true;
					$um=UserManager::sharedUserManager();
					$userprivs=$um->privileges();
// _NSLog($um->privileges());
					foreach(explode(',', $privs) as $priv)
						{
// _NSLog($priv);
						if($priv == "public" || in_array($priv, $userprivs))
							{ // yes, user has sufficient privilege(s) for this app
							$ok=true;
							break;
							}
						}
					if(!$ok)
						continue;	// user does not have sufficient privileges to "see" this bundle
// _NSLog("is exectutable: $dir/$bundle");
					$r=array(
						"NSApplicationName" => $b->objectForInfoDictionaryKey("CFBundleName"),
						"NSApplicationPath" => "$dir/$bundle",
						"NSApplicationDomain" => $dir,
						"NSApplicationBundle" => $b
						);
					self::$knownApplications[$bundle]=$r;
					$ext=$b->objectForInfoDictionaryKey('CFBundleTypeExtensions');
					if(!is_null($ext))
						{
						// FIXME: loop over multiple suffixes
						$suffix=$ext;
						// FIXME: handle multiple apps serving the same suffix
						self::$knownSuffixes[$suffix]=$r;
						}
					}
				closedir($f);
				}
			}
// _NSLog(NSBundle::allBundles());
// _NSLog(self::$knownApplications);
		return self::$knownApplications;
		}
	public function fullPathForApplication($name)
		{
// FIXME: should work with or w/o .app suffix!
		if(substr($name, 0, 1) == "/")
			return $name;	// already a full path
		NSWorkspace::knownApplications();	// update list
// _NSLog("fullPathForApplication: $name)";
		if(isset(self::$knownApplications[$name]))
			return self::$knownApplications[$name]["NSApplicationPath"];
		_NSLog("fullPathForApplication:$name not found");
		_NSLog(self::$knownApplications);
		return null;
		}
	public function iconForFile($path)
		{ // find the NSImage that represents the given file -- FIXME: incomplete
		if($this->isFilePackageAtPath($path))
			{ // path represents a bundle
			$bundle=NSBundle::bundleWithPath($path);
			$icon=$bundle->objectForInfoDictionaryKey('CFBundleIconFile');
//_NSLog("$icon for $path");
			if(is_null($icon))
				return NSImage::imageNamed("NSApplication");	// entry wasn't found
			$file=$bundle->pathForResourceOfType($icon, "");
			if(is_null($file))
				$file=$bundle->pathForResourceOfType($icon, "png");
			if(is_null($file))
				$file=$bundle->pathForResourceOfType($icon, "jpg");
			if(is_null($file))
				$file=$bundle->pathForResourceOfType($icon, "gif");
// _NSLog($file);
			if(is_null($file))
				return NSImage::imageNamed("NSApplication");	// file wasn't found
			$img=new NSImage();
			return $img->initByReferencingFile($file);
			}
		$pi=pathinfo($file);
		if(!isset($pi['extension']))
			$ext="";
		else
			$ext=$pi['extension'];
		if(!isset(self::$knownSuffixes[$ext]))
			return NSImage::imageNamed("NSFile");	// unknown suffix
		$app=self::$knownSuffixes[$ext];
		$bundle=$app['NSApplicationBundle'];
		$exts=$bundle->objectForInfoDictionaryKey('CFBundleTypeExtensions');
_NSLog("find document icon by extensions");
_NSLog($exts);
		// else find application by suffix
		return null;
		}
	private function _scanDirectoryForExecutable($real, $symbolic, $exec, $indexes=array())
		{ // scan for executable at the end of a symlink
 // _NSLog("try $real for $symbolic");
		$r=array();
		$d=@opendir($real);
		if($d)
			{
			while($sub=readdir($d))
				{
				if(substr($sub, 0, 1) == ".")
					continue;	// skip hidden files and directories
				switch($sub)
					{
					case "bin":
					case "gcc":
					case "build":
						continue 2;	// special cases to prune the search
					case "Versions":
					case "Resources":
					case "Headers":
						continue 2;	// skip Frameworks
// FIXME: we should check if the realpath is still within $ROOT tree
					case "Network":
					case "Volumes":
					case "Sources":
// what about Users?
						continue 2;	// skip other area with links
					case "Contents":
						$sub.="/php";	// go down straight to the php executable
						break;
					}
				$p=realpath("$real/$sub");	// follow symlinks
				if(is_dir($p))
					{ // recursion
					$r=array_merge($r, $this->_scanDirectoryForExecutable($p, $symbolic."/".$sub, $exec, $indexes));
					continue;
					}
// _NSLog("compare $p = $exec");
				if($p == $exec)
					{ // file found!
// _NSLog("found $symbolic/$sub");
					if(in_array($sub, $indexes))
						$r[]="$symbolic";	// index file found
					else
						$r[]="$symbolic/$sub";	// full symbolic path
					}
				}
			closedir($d);
			}
		return $r;
		}
	public function _externalURLForPath($path)
		{ // translate executable path into external URL
		$fm=NSFileManager::defaultManager();
		$exec=$fm->fileSystemRepresentationWithPath($path);
		$exec=realpath($exec);	// expand symlinks
		$plist=NSPropertyListSerialization::propertyListFromPath('/Library/WebServer/mapping.plist');
// _NSLog($plist);
		if($plist)
			{
			$servers=$plist['server-setup'];	// get mapping pairs
			$shortest="";
			foreach($servers as $server)
				{
// _NSLog($server);
				$external=$server['web'];	// external root URL
				$internal=$server['directory'];	// internal root
				$internal=realpath($internal);	// expand symlinks
// _NSLog("$exec vs. $internal -> $external");
				$paths=$this->_scanDirectoryForExecutable($internal, $external, $exec, array("index.html", "index.php"));
// _NSLog($paths);
				foreach($paths as $path)
					{
// _NSLog("path: $path");
					if(!$shortest || strlen($path) < strlen($shortest))
						$shortest=$path;
					}
				}
// _NSLog("shortest: $shortest");
			if($shortest)
				return $shortest;
			}
		else
			NSLog("no /Library/WebServer/mapping.plist available");
// _NSLog("not found: file://localhost$exec");
		return null;	// can't translate
		}
	public function openFile($file)
		{ // locate application and open with passing the $file
		return $this->openFileWithApplication($file);
		}
	public function openFileWithApplication($file, $app=null)
		{
// _NSLog("openFile $file with $app");
		if(is_null($file))
			{
			$file=$app;
			$app=null;
			}
		else if(is_null($app))
			{ // search by file suffix
			$pi=pathinfo($file);
			if(!isset($pi['extension']))
				$ext="";
			else
				$ext=$pi['extension'];
// _NSLog("launch by extension '$ext'");
			if($ext == "app")
				return $this->openApplicationWithArguments($file);	// $file is the app
			if(!isset(self::$knownSuffixes[$ext]))
				{
// _NSLog("unknown extension '$ext'");
				return false;	// unknown suffix
				}
			$app=self::$knownSuffixes[$ext]['NSApplicationPath'];
			}
		return $this->openApplicationWithArguments($app, array($file));
		}
	public function openApplicationWithArguments($app, $args=array())
		{ // switch to a different app
		$bundle=NSBundle::bundleWithPath($this->fullPathForApplication($app));
// _NSLog($bundle);
		if(!is_null($bundle))
			{
// _NSLog("open: ".$bundle->description());
			$exec=$bundle->executablePath();
// _NSLog("open: ".$exec);
			$url=$this->_externalURLForPath($exec);
			if(!is_null($url))
				{
				$delim='?';
				foreach($args as $key => $value)
					{ // append arguments - if specified
					$url.=$delim.rawurlencode($key)."=".rawurlencode($value);
					$delim='&';
					}
// _NSLog("new URL: $url");
				header("location: ".$url);	// how to handle special characters here? rawurlencode?
				exit;
				}
			}
		NSLog("$app not found");
		return false;
		}
	public function openSettings(NSResponder $sender)
		{
		$this->openFile("/System/Library/CoreServices/Settings.app");
		}
	public function isFilePackageAtPath($path)
		{
// _NSLog("isFilePackageAtPath $path");
		$fm=NSFileManager::defaultManager();
		// FIXME: should be true for framework bundles (detect by "$path/Version")
		if($fm->fileExistsAtPathAndIsDirectory($path, $dir) && $dir && $fm->fileExistsAtPathAndIsDirectory("$path/Contents", $dir) && $dir)
		   return true;
		return false;
		}
}

class WebView extends NSView
{ // allows to embed foreign content in this page
	protected $url;
	protected $width="90%";
	protected $height="90%";
	public function setMainFrameUrl($urlString)
		{
		$this->url=$urlString;
		}
	public function draw()
		{
		html("<iframe");
		parameter("width", $this->width);
		parameter("height", $this->height);
		parameter("src", $this->url);
		html(">");
		NSGraphicsContext::currentContext()->text("your browser does not support iframes. Please use this link: ".$this->url);
		html("</iframe>");
		}

}

class NSNib extends NSObject
{
	protected $objects;
	protected $objectDicts;
	protected $connections;

	public function initWithNibAndBundle($name, $bundle)
	{
// _NSLog($name);
		$nibfile=$bundle->pathForResourceOfType($name, "pnib");
// _NSLog($nibfile);
		$plist=NSPropertyListSerialization::propertyListFromPath($nibfile);
// _NSLog($this->plist);
		if(is_null($plist))
			return null;	// could not open or parse
		$this->objectDicts=$plist['objects'];
		$this->connections=$plist['connections'];
		$this->objects=array();
		return $this;
	}

	private function instantiateObject($objdict, $nametable)
		{
		if(!isset($objdict['class']))
			return;
		$class=$objdict['class'];
		if(!$class)
			return null;	// can't instantiate
// _NSLog($objdict);
		// Obj-C uses alloc+init to provide a singleton for NSApplication!
		if(isset($objdict['objectname']))
			{
			$name=$objdict['objectname'];
// _NSLog($name);
// _NSLog($nametable[$name]);
			if(isset($nametable[$name]))
				$object=$nametable[$name];	// use externally provided object
			else
				$object=new $class();	// create a new instance
			$this->objects[$name]=$object;	// store reference in object table
			}
		else
			$object=new $class();
// _NSLog($object);
		// init object
		foreach($objdict as $key => $value)
			{
// _NSLog($key);
			switch($key)
				{
				case 'class':
				case 'objectname':
					// PHP treats continue like break in switch() - but we want to continue the foreach loop
					continue 2;	// already processed
				case 'contentView':
				case 'subviews':
					{ // special case: decode subview and subviews array
// _NSLog($value);
					if(isset($value['class']))
						$v=$this->instantiateObject($value, $nametable);	// single subview
					else
					foreach($value as $subview)
						$v[]=$this->instantiateObject($subview, $nametable);	// array of subviews
					$value=$v;
// _NSLog($v);
					}
				}
			$object->setValueForKey($value, $key);	// set value as defined by plist
			}
// _NSLog($object);
		return $object;
		}

	public function instantiateNibWithExternalNameTable($nametable)
	{
		foreach($this->objectDicts as $value)
			{ // create objects
			$this->instantiateObject($value, $nametable);
			}
//_NSLog($this->objects);
		foreach($this->connections as $value)
			{ // connect objects
// _NSLog("connect");
// _NSLog($value);
			$source=$this->objects[$value['source']];	// look up by name
			$target=isset($value['target'])?$this->objects[$value['target']]:null;	// allows to specify first responder
			if(isset($value['action']))
				{ // source.target/action = target/action
				$source->setActionAndTarget($value['action'], $target);
				}
			else
				{ // source.key = target
				$source->setValueForKey($target, $value['key']);
				}
			}
// _NSLog($this->objects);
		foreach($this->objects as $object)
			{ // awake objects
			if($object->respondsToSelector("awakeFromNib"))
				$object->awakeFromNib();
			}
		return;
	}
}

/* main function */

function NSApplicationMain($name)
{
	global $NSApp;
	global $ROOT;
	if(!isset($ROOT))
		{
		echo '$ROOT is not set globally!';
		exit;
		}
NSLog("_POST:");
NSLog($_POST);
	if($GLOBALS['debug']) echo "<h1>NSApplicationMain($name)</h1>";
	$mainBundle=NSBundle::mainBundle();
	$pclass=$mainBundle->principalClass();
	if(!$pclass)
		{
_NSLog("bundle has no principal class");
/*
		_NSLog($mainBundle);
		exit;
*/
		$pclass="NSApplication";	// default
		}
	$NSApp=new $pclass($name);
	$loaded=false;
	$nibname=$mainBundle->objectForInfoDictionaryKey("NSMainNibFile");
	if($nibname)
		{
		$nib=new NSNib();
		$nib=$nib->initWithNibAndBundle($nibname, $mainBundle);
		if(!is_null($nib))
			{
			$nib->instantiateNibWithExternalNameTable(array("NSOwner" => $NSApp));	// load nib with NSApp object as NSOwner
			$loaded=true;
			}
		}
	if(!$loaded)
		{ // define default (there is no awakeFromNib!)
// _NSLog("no PNIB");
// exit;
		$NSApp->setDelegate(new AppController());	// assume that a class AppController exists
		}
	$delegate=$NSApp->delegate();
	if(is_object($delegate) && $delegate->respondsToSelector("didFinishLoading"))
		$delegate->didFinishLoading();
// _NSLog($NSApp);
	$NSApp->run();
}

// EOF
?>
