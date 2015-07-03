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

global $ROOT;	// must be set by some .app
require_once "$ROOT/System/Library/Frameworks/Foundation.framework/Versions/Current/php/Foundation.php";

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

// FIXME: make this a public function of NSWindow and $persist a local variable of it
// because it is more or less persisting values through the server in a html-response + browser-reload sequence
// the problem becomes that $view->_persist can only be called if it is attached to a NSWindow!

function _persist($object, $default, $value=null)
{
	global $persist;	// will come back as $_POST[] next time (+ values from <input>)
	if(is_null($value))
		{ // query
// _NSLog("query persist $object");
		if(isset($_POST[$object]))
			$value=$_POST[$object];
		else
			$value=$default;
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
// _NSLog("can't publish $path");
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
	public static function _objectForId($id) { return isset(self::$objects[$id])?self::$objects[$id]:null; }
	protected function elementId() { return $this->elementId; }
}

class NSApplication extends NSResponder
{
	// FIXME: part of this belongs to NSWorkspace!?!
	protected $argv;	// arguments (?)
	protected $delegate;
	protected $mainWindow;
	protected $mainMenu;
	protected $queuedEvent;

	public function _url()
		{ // the URL of the script we are currently running
		$rp=empty($_SERVER['HTTPS'])?443 : 80; // default remote port
		return (!empty($_SERVER['HTTPS'])?"https://":"http://").$_SERVER['SERVER_NAME'].($_SERVER['SERVER_PORT'] != $rp ? ":".$_SERVER['SERVER_PORT'] : "").$_SERVER['REQUEST_URI'];
		}

	public function delegate() { return $this->delegate; }
	public function setDelegate(NSObject $d=null) { $this->delegate=$d; }
	public function mainWindow() { return $this->mainWindow; }
	public function setMainWindow(NSWindow $w) { $this->mainWindow=$w; }
	public function mainMenu() { return $this->mainMenu; }
	public function setMainMenu(NSMenu $m=null) { $this->mainMenu=$m; }

	public function queueEvent(NSEvent $event)
		{
		NSLog("queueEvent: ".$event->description());
		$this->queuedEvent=$event;
		}

	public function openSettings(NSResponder $sender)
	{
		$this->open("settings.app");
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

		$this->mainMenu=new NSMenuView(true);	// create horizontal menu bar
		
		// we should either load or extend that

		$item=new NSMenuItemView("System");
		$submenu=new NSMenuView();
		$item->setSubMenu($submenu);
		$this->mainMenu->addMenuItem($item);
		$submenu->addMenuItemWithTitleAndAction("About", "orderFrontAboutPanel", $this);
		$submenu->addMenuItemWithTitleAndAction("Settings", "openSettings", $this);
		$submenu->addMenuItemSeparator();
		// make this switch between Login... // Logout...
		$ud=NSUserDefaults::standardUserDefaults();
		if(isset($ud))
			$submenu->addMenuItemWithTitleAndAction("Logout", "logout", $this);
		else
			$submenu->addMenuItemWithTitleAndAction("Login...", "login", $this);

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

	public function open($app, $args=array())
		{ // switch to a different app
		$bundle=NSWorkspace::fullPathForApplication($app);
		if(!is_null($bundle))
			{
			NSLog("open: ".$bundle->description());
// ask $bundle->executablePath;
			$executablePath=NSHTMLGraphicsContext::currentContext()->externalURLForPath($bundle->executablePath());
//			$executablePath="https://".$_SERVER['HTTP_HOST']."/$bundle/Contents/php/executable.php";
			$delim='?';
			foreach($args as $key => $value)
				{ // append arguments - if specified
				$executablePath.=$delim.rawurlencode($key)."=".rawurlencode($value);
				$delim='&';
				}
// how can we pass arbitrary parameters to their NSApplication $argv???
			header("location: ".$executablePath);	// how to handle special characters here? rawurlencode?
			exit;
			}
		NSLog("$app not found");
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
	public function run()
		{
		if(isset($_GET['RESOURCE']))
			{ // serve some resource file
			NSBundle::mainBundle();
			NSBundle::bundleForClass($this->classString());
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
			$noopen=$noopen || !NSFileManager::defaultManager()->fileExistsAtPath($path);
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
			$file=file_get_contents(NSFileManager::defaultManager()->fileSystemRepresentationWithPath($path));
			echo $file;	// provide requested contents to browser
			exit;
			}
		do
			{
// _NSLog($_POST);
			$targetId=_persist('NSEvent', null);
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
			if(isset($this->queuedEvent))
				$this->mainWindow->sendEvent($this->queuedEvent);
			$this->mainWindow->display();
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
	public function __construct()
		{ // must explicitly call!
		parent::__construct();
		}
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
	public function setTag($val) { $this->tag=$val; }
	public function tag() { return $this; }
	}

class NSMatrix extends NSControl
	{ // matrix of several buttons - radio buttons are grouped
	// make click on a radio button tribber our action+target
	}

class NSButton extends NSControl
	{
	protected $title;
	protected $altTitle;
	protected $state;
	protected $buttonType;
	public function __construct($newtitle = "NSButton", $type="Button")
		{
		parent::__construct();
//		NSLog("NSButton $newtitle ".$this->elementId);
		$this->title=$newtitle;
		$this->buttonType=$type;
		$this->state=$this->_persist("selected", 0);
		if(!is_null($this->_persist("ck", null)))
			{
			global $NSApp;
			$this->_persist("ck", "", "");	// unset
			NSLog($this->classString());
			switch($type)
				{
				case "CheckBox":
				case "Radio":
					$this->state=true;
					break;	// don't assume a button that has been clicked
			// FIXME: multiple buttons may have -ck set (the button pressed and several checkboxes)
			// => use ck only for checkboxes? and not as "click"???
		//	if($this->action)	// FIXME: action is never set here!!!
				default:
					$NSApp->queueEvent(new NSEvent($this, 'NSMouseDown')); // queue a mouseDown event for us
				}
			}
		}
	public function isSelected()
		{
		return $this->state;
		}
	public function setSelected($value)
		{
		if($value == $this->state)
			return;
		$this->state=$this->_persist("selected", $value);
		$this->setNeedsDisplay();
		}
	public function description() { return parent::description()." ".$this->title; }
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
	public function state() { return $this->isSelected(); }
	public function setState($s) { $this->setSelected($s); }
	public function setButtonType($type) { $this->buttonType=$type; $this->setNeedsDisplay(); }
	public function mouseDown(NSEvent $event)
	{ // this button may have been pressed
		// NSLog($event);
		// NSLog($this);
		// if radio button or checkbox, watch for value
		$this->sendAction();
	}
	public function draw()
		{
		html("<input");
		parameter("id", $this->elementId);
// FIXME: if default button (shortcut "\r"): invert the selected state
		parameter("class", "NSButton ".($this->isSelected()?"NSOnState":"NSOffState"));
		switch($this->buttonType)
			{
				case "Radio":
					parameter("type", "radio");
		// if Radio Button take elementId of parent so that radio buttons are grouped correctly!
					parameter("name", $this->elementId."-ck");
					break;
				case "CheckBox":
					parameter("type", "checkbox");
					parameter("name", $this->elementId."-ck");
					break;
				default:
					parameter("type", "submit");
					parameter("name", $this->elementId."-ck");
					parameter("value", _htmlentities($this->title));
					if(isset($this->altTitle))
						{ // use CSS or JS to change contents on hover
						}
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
		parent::__construct("");
		$this->menu=array();
		$this->selectedItemIndex=$this->_persist("selectedIndex", -1);
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
	public function indexOfSelectedItem() { return $this->selectedItemIndex; }
	public function titleOfSelectedItem() { return $this->selectedItemIndex < 0 ? null : $this->menu[$this->selectedItemIndex]; }
	public function selectItemAtIndex($index) { $this->selectedItemIndex=$this->_persist("selectedIndex", $index); $this->setNeedsDisplay(); }
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
		for($idx=0; $idx<count($this->menu); $idx++)
			if($this->menu[$idx] == $title)
				return $idx;
		return null;
		}

		public function draw()
			{
			NSGraphicsContext::currentContext()->text($this->title);
			html("<select");
			parameter("id", $this->elementId);
			parameter("class", "NSPopUpButton");
			parameter("name", $this->elementId);
// FIXME: handle selection
			parameter("onclick", "e('".$this->elementId."');s()");
			parameter("size", 1);	// make a popup not a combo-box
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
	protected $url;
	protected $name;
	protected $width=32;
	protected $height=32;
	public function size()
		{
		// load and analyse if needed
		return array('width' => $width, 'height' => $height);
		}
	public function setSize($array)
		{
		$width=$array['width'];
		$height=$array['height'];
		$this->setNeedsDisplay();
		}
	public static function imageNamed($name)
		{
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
		parameter("src", _htmlentities($this->url));
		if(isset($this->name))
			{
			parameter("name", _htmlentities($this->name));
			parameter("alt", _htmlentities($this->name));
			}
		else
			parameter("alt", _htmlentities("unnamed image"));
		parameter("style", "{ width:"._htmlentities($this->width).", height:"._htmlentities($this->height)."}");
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
		$url=NSHTMLGraphicsContext::currentContext()->externalURLForPath($path);
		if(!is_null($url))
			return $this->initByReferencingURL($url);
		// FIXME: could try to use data: scheme
		// or we could simply store the file path so that we can process the image in memory
		// and create data: only during composite()
		return null;	// don't know how to reference externally
		}
}

class NSImageView extends NSControl
{
	protected $image;
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
	public function draw()
		{
//		NSLog($this->image);
		if(isset($this->image))
			$this->image->composite();
		}
}

class NSCollectionView extends NSControl
{
	protected $colums=1;
	protected $border=0;
	protected $width="100%";
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

	public function __construct($cols=1, $objects=null)
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
		html("<table");
		parameter("class", "NSCollectionView");
		parameter("id", $this->elementId);
		parameter("border", $this->border);
		parameter("width", $this->width);
		html(">\n");
		$col=1;
		foreach($this->subviews as $item)
			{
			if($col == 1)
				html("<tr>");
			html("<td");
			parameter("class", "NSCollectionViewItem");
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
		if($col > 1)
			{ // handle missing colums
				html("</tr>\n");
			}
		html("</table>\n");
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
	protected $label;
	protected $view;
	public function label() { return $this->label; }
	public function view() { return $this->view; }
	public function setLabel($label) { $this->label=$label; }
	public function setView(NSView $view) { $this->view=$view; }
	public function __construct($label, NSView $view)
		{
//		parent::__construct();
		$this->label=$label;
		$this->view=$view;
		}
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
	public function selectTabViewItemAtIndex($index)
		{
		if($index < 0 || $index >= count($this->tabViewItems))
			return;	// ignore (or could rise an exception)
		NSLog("selectTabViewItemAtIndex $index");
		if(method_exists($this->delegate, "tabViewShouldSelectTabViewItem"))
			if(!$this->delegate->tabViewShouldSelectTabViewItem($this, $this->tabViewItems[index]))
				return;	// don't select
		if(method_exists($this->delegate, "tabViewWillSelectTabViewItem"))
			$this->delegate->tabViewWillSelectTabViewItem($this, $this->tabViewItems[index]);
		$this->selectedIndex=$this->_persist("selectedIndex", 0, $index);
		if(method_exists($this->delegate, "tabViewDidSelectTabViewItem"))
			$this->delegate->tabViewDidSelectTabViewItem($this, $this->tabViewItems[$index]);
		NSLog("selectTabViewItemAtIndex $index done");
		$this->setNeedsDisplay();
		}
	public function setBorder($border) { $this->border=0+$border; $this->setNeedsDisplay(); }
	public function mouseDown(NSEvent $event)
		{
		NSLog("tabview item ".$this->clickedItemIndex." was clicked: ".$event->description());
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
// FIXME: buttons must be able to change state!
// i.e. these buttons should be made in a way that calling their action
// will make selectTabViewItemAtIndex being called
// FIXME: use NSButton or NSMenuItem?
			html("<input");
			parameter("id", $this->elementId."-".$index);
			parameter("class", "NSTabViewItemsButton ".($item == $this->selectedTabViewItem()?"NSOnState":"NSOffState"));
			parameter("type", "submit");
			parameter("name", $this->elementId."-".$index);
			parameter("value", _htmlentities($item->label()));
			html(">\n");
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
			$selectedItem->view()->display();	// draw current tab
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
	protected $isHidden=false;
	protected $align="";
	// could have a data cell...
	// allow to define colspan and rowspan values
	public function title() { return $this->title; }
	public function setTitle($title) { $this->title=$title; }
	public function identifier() { return $this->identifier; }
	public function setIdentifier($identifier) { $this->identifier=$identifier; }
	public function isHidden() { return $this->isHidden; }
	public function setHidden($flag) { $this->isHidden=$flag; }
	public function isEditable() { return $this->isEditable; }
	public function setEditable($flag) { $this->isEditable=$flag; }
	public function align() { return $this->align; }
	public function setAlign($align) { $this->align=$align; }
	public function width() { return $this->width; }
	public function setWidth($width) { $this->width=$width; }
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
		$this->visibleRows=$visibleRows;
		$this->selectedRow=$this->_persist("selectedRow", -1);
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
	public function selectRow($row, $extend=false)
		{
		NSLog("selectRow $row extend ".($extend?"yes":"no"));
		// if ! extend -> delete previous otherwise merge into set
		$this->selectedRow=$this->_persist("selectedRow", -1, $row);
		$this->setNeedsDisplay();
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
			if($column->isHidden())
				continue;
			html("<tr");
			parameter("id", $this->elementId."-".$row);
			parameter("class", "NSTableRow");
			// add id="even"/"odd" so that we can define bgcolor by CSS?
			html(">\n");
			foreach($this->columns as $index => $column)
				{
				html("<td");
				parameter("id", $this->elementId."-".$row."-".$index);
				parameter("name", $column->identifier());
				parameter("class", "NSTableCell ".($row == $this->selectedRow?"NSSelected":"NSUnselected")." ".($row%2 == 0?"NSEven":"NSOdd"));
				parameter("onclick", "e('".$this->elementId."');"."r($row);"."c($index)".";s()");
				parameter("align", $column->align());
				parameter("width", $column->width());
				html(">\n");
				if($row < $rows)
					{ // ask delegate for the value to show
					$item=$this->dataSource->tableView_objectValueForTableColumn_row($this, $column, $row);
					// we should insert that into the $column->cell
					// $item->draw();
					html(_htmlentities($item));
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
	public function setStringValue($str) { $this->stringValue=$str; $this->htmlValue=htmlentities($str, ENT_COMPAT | ENT_SUBSTITUTE, NSHTMLGraphicsContext::encoding); $this->setNeedsDisplay(); }
	// should be used for static text fields
	public function setAttributedStringValue($astr) { $this->htmlValue=$astr; $this->isEditable=false; $this->wraps=true; $this->setNeedsDisplay(); }
	public function isEditable() { return $this->isEditable; }
	public function setEditable($flag) { $this->isEditable=$flag; $this->setNeedsDisplay(); }
	public function placeholderString() { return $this->placeholder; }
	public function setPlaceholderString($str) { $this->placeholder=$str; $this->setNeedsDisplay(); }
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
	public function display()
		{
		if($this->isHidden())
			{ // persist stringValue even if text field is currently hidden
			if($this->isEditable && $this->type != "password")
				_persist($this->name, $this->stringValue);
			return;
			}
		parent::display();
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
			if($this->placeholder)
				parameter("placeholder", $this->placeholder);
			parameter("size", $this->width);
			// FIXME: _setName should allow to set a global name, e.g. "username" or "password"
			parameter("name", $this->name);
			if($this->type != "password")
				parameter("value", _htmlentities($this->stringValue));	// password is always shown cleared/empty
			switch($this->type)
				{ // special types
				case "search":
					parameter("onsearch", "e('".$this->elementId."');s()");
					break;
				case "search":
					parameter("onchange", "e('".$this->elementId."');s()");
					break;
				case "range":
					parameter("oninput", "e('".$this->elementId."');s()");
					break;
				}
			html("/>\n");
			_persist($this->name, "", "");	// remove from persistence store (because we have our own <input>)
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
		$this->_persist("string", "", "");	// remove from persistence store
		}
}

// NSClipView? with different overflow-setting?

class NSScrollView extends NSView
{
	public function draw()
		{
		if($this->hidden)
			return;
		html("<div");
		parameter("style", "width: ".NSWidth($this->frame)."; height: ".NSHeight($this->frame)."; overflow: scroll");
		html(">");
		foreach($this->subviews as $item)
			$item->display();
		html("</div>");
		}
}

class NSWindow extends NSResponder
{
	protected $title;
	protected $contentView;
	protected $heads="";
	public function contentView() { return $this->contentView; }
	public function setContentView(NSView $view) { $this->contentView=$view; $view->setWindow($this); }
	public function title() { return $this->title; }
	public function setTitle($title) { $this->title=$title; }
	public function _addToHead($line) { $this->heads.=$line."\n"; }

	public function __construct()
		{
		global $NSApp;
		parent::__construct();
		$this->setContentView(new NSView());
		if($NSApp->mainWindow() == null)
			$NSApp->setMainWindow($this);
// NSLog($NSApp);
		}
	public function sendEvent(NSEvent $event)
		{
		NSLog("sendEvent: ".$event->description());
		// here we would run hitTest - but we know the target object already
		// $target=$event->window->hitTest($event);
		$target=$event->target();
		$target->mouseDown($event);
		}
	public function display() 
		{
		global $NSApp;
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
		$r=NSBundle::bundleForClass($this->classString())->pathForResourceOfType("AppKit", "css");
		if(isset($r))
			{
			$r=NSHTMLGraphicsContext::currentContext()->externalURLforPath($r);
			if(!is_null($r))
				{
				html("<link");
				parameter("rel", "stylesheet");
				parameter("href", $r);
				parameter("type", "text/css");
				html(">\n");
				}
			}
		// onclick handlers should only be used if necessary since they require JavaScript enabled
		html("<script>");
		html("function e(v){document.forms[0].NSEvent.value=v;};");
		html("function r(v){document.forms[0].clickedRow.value=v;};");
		html("function c(v){document.forms[0].clickedColumn.value=v;}");
		html("function s(){document.forms[0].submit();}");
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
		$mm=$NSApp->mainMenu();
		if(isset($mm))
			$mm->display();	// draw main menu before content view
		// add App-Icon, menu/status bar
		$this->contentView->display();
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
// should we filter by specific user's permissions defined in the Info.plist?
					$privs=$b->objectForInfoDictionaryKey("Privileges");
					if(!is_null($privs))
						{ // requires any of some privileges
						$ok=false;
						foreach(explode(',', $privs) as $priv)
							{
							// check if current user has $priv
							$ok=true;
							break;
							}
						if(!$ok)
							continue;	// user does not have sufficient privileges to "see" this bundle
						}
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
			{
			$bundle=NSBundle::bundleWithPath($path);
			$icon=$bundle->objectForInfoDictionaryKey('CFBundleIconFile');
//_NSLog("$icon for $path");
			if(is_null($icon))
				return NSImage::imageNamed("NSApplication");	// entry wasn't found
			$file=$bundle->pathForResourceOfType($icon, "");
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
	public function openFile($file)
		{ // locate application and open with passing the $file
		$pi=pathinfo($file);
		if(!isset($pi['extension']))
			$ext="";
		else
			$ext=$pi['extension'];
		if(!isset(self::$knownSuffixes[$ext]))
			return false;	// unknown suffix
		$app=self::$knownSuffixes[$ext];
		// somehow launch $app
		return true;
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
