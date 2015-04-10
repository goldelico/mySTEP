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
	echo "<h1>Not Found</h1>";
	echo "<p>The requested URL ";
	echo $_SERVER['PHP_SELF'];
	if($_SERVER['QUERY_STRING'])
		echo "?".$_SERVER['QUERY_STRING'];
	echo " was not found on this server.</p>";
// FIXME: optionally notify someone?
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
			if(substr($path, 0, strlen($res)) == $res)
				{ // we have found a bundle where this file is stored as a resource!
				$path=substr($path, strlen($res));	// strip off path prefix
				$url="?RESOURCE=".rawurlencode($path);
				if($bundle != NSBundle::mainBundle())
					$url.="&BUNDLE=".rawurlencode($bundle->bundleIdentifier());
				return $url;
				}
			}
//		_NSLog("can't publish $path");
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
	public function __construct(NSResponder $target, $type)
	{
		parent::__construct();
		$this->type=$type;
		$this->target=$target;
	}
	public function description() { return "NSEvent: ".$this->type." -> ".$this->target->description(); }
	public function type() { return $this->type; }
	public function target() { return $this->target; }
}

global $NSApp;

class NSResponder extends NSObject
{
	public function __construct()
	{
		parent::__construct();
	}
}

class NSApplication extends NSResponder
{
	// FIXME: part of this belongs to NSWorkspace!?!
	protected $name;
	protected $argv;	// arguments (?)
	protected $delegate;
	protected $mainWindow;
	protected $mainMenu;
	protected $queuedEvent;

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
	
	public function __construct($name)
		{
		global $NSApp;
		parent::__construct();
		if(isset($NSApp))
			{
			NSLog("NSApplication is already defined (".($NSApp->name).")");
			exit;
			}
		$NSApp=$this;
		$this->name=$name;
		$NSApp->mainMenu=new NSMenuView(true);	// create horizontal menu bar
		
		// we should either load or extend that

		$item=new NSMenuItemView("System");
		$submenu=new NSMenuView();
		$item->setSubMenu($submenu);
		$NSApp->mainMenu->addMenuItem($item);
		$submenu->addMenuItemWithTitleAndAction("About", "orderFrontAboutPanel", $NSApp);
		$submenu->addMenuItemWithTitleAndAction("Settings", "openSettings", $NSApp);
		$submenu->addMenuItemSeparator();
		// make this switch between Login... // Logout...
		$ud=NSUserDefaults::standardUserDefaults();
		if(isset($ud))
			$submenu->addMenuItemWithTitleAndAction("Logout", "logout", $NSApp);
		else
			$submenu->addMenuItemWithTitleAndAction("Login...", "login", $NSApp);

		$item=new NSMenuItemView($this->name);
		$submenu=new NSMenuView();
		$item->setSubMenu($submenu);
		$NSApp->mainMenu->addMenuItem($item);
		$submenu->addMenuItemWithTitleAndAction("Quit", "terminate", $NSApp);

		$item=new NSMenuItemView("File");
		$submenu=new NSMenuView();
		$item->setSubMenu($submenu);
		$NSApp->mainMenu->addMenuItem($item);
		$submenu->addMenuItemWithTitleAndAction("New", "newDocument", $NSApp);
		$submenu->addMenuItemWithTitleAndAction("Open", "openDocument", $NSApp);
		$submenu->addMenuItemSeparator();
		$submenu->addMenuItemWithTitleAndAction("Save", "saveDocument", $NSApp);

		$item=new NSMenuItemView("Edit");
		$submenu=new NSMenuView();
		$item->setSubMenu($submenu);
		$NSApp->mainMenu->addMenuItem($item);
		$submenu->addMenuItemWithTitleAndAction("Undo", "undo", $NSApp);

		$item=new NSMenuItemView("View");
		$submenu=new NSMenuView();
		$item->setSubMenu($submenu);
		$NSApp->mainMenu->addMenuItem($item);
		$submenu->addMenuItemWithTitleAndAction("View", "undo", $NSApp);

		$item=new NSMenuItemView("Window");
		$submenu=new NSMenuView();
		$item->setSubMenu($submenu);
		$NSApp->mainMenu->addMenuItem($item);
		$submenu->addMenuItemWithTitleAndAction("Window", "undo", $NSApp);

		$item=new NSMenuItemView("Help");
		$submenu=new NSMenuView();
		$item->setSubMenu($submenu);
		$NSApp->mainMenu->addMenuItem($item);
		$submenu->addMenuItemWithTitleAndAction("Help", "help", $NSApp);
		
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
		if($this->name == "Palmtop")
			$this->open("loginwindow.app");
		else
			$this->open("Palmtop.app");
		}
	public function sendActionToTarget(NSResponder $from, $action, $target)
		{
		if(!isset($target))
			{
NSLog("sendAction $action to first responder");
			$target=null;	// it $target does not exist -> take first responder
			}
// echo "printr--";
// print_r($target); echo "--print_r"; flush();
NSLog("sendAction $action to ".$target->description());
		// FIXME: if method does not exist -> ignore or warn
		$target->$action($from);
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
NSLog($bundle);
			$noopen= is_null($bundle);	// bundle not found
NSLog("noopen: $noopen\n");
			if(!$noopen)
				$path=$bundle->resourcePath()."/".$_GET['RESOURCE'];	// relative to Resources
			else
				$path="?";
NSLog("path: $path\n");
			$noopen= $noopen || strpos("/".$path."/", "/../") !== FALSE;	// if someone tries ..
NSLog("noopen: $noopen\n");
			$noopen= $noopen || !NSFileManager::defaultManager()->fileExistsAtPath($path);
NSLog("noopen: $noopen after fileExistsAtPath $path\n");
			if(!$noopen)
				{ // check if valid extension
				$extensions=array("png", "jpg", "jpeg", "gif", "css", "js");
				$pi=pathinfo($path);
NSLog("extensions:");
NSLog($extensions);
NSLog($pi);
				$noopen = !isset($pi['extension']) || !in_array($pi['extension'], $extensions);
				}
			if($noopen)
				_404();	// simulate 404 error
			header("Content-Type: image/".$pi['extension']);
NSLog($path);
			$file=file_get_contents(NSFileManager::defaultManager()->fileSystemRepresentationWithPath($path));
			echo $file;	// provide requested contents to browser
			exit;
			}
		do
			{
			if(isset($this->queuedEvent))
				$this->mainWindow->sendEvent($this->queuedEvent);
			$this->mainWindow->display();
			// could we run an AJAX loop here?
			} while(false);
		}
}
	
function NSApplicationMain($name)
{
	global $NSApp;
	global $ROOT;
	if(!isset($ROOT))
		{
		echo '$ROOT is not set globally!';
		exit;
		}
// _NSLog("_POST:");
// _NSLog($_POST);
	if($GLOBALS['debug']) echo "<h1>NSApplicationMain($name)</h1>";
	new NSApplication($name);
	$NSApp->setDelegate(new AppController);	// this should be the principalClass from the NIB file!
	// FIXME: shouldn't we better implement some objc_sendMsg($NSApp->delegate() "awakeFromNib", args...)?
	if(method_exists($NSApp->delegate(), "awakeFromNib"))
		$NSApp->delegate()->awakeFromNib();
	if(method_exists($NSApp->delegate(), "didFinishLoading"))
		$NSApp->delegate()->didFinishLoading();
	$NSApp->run();
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
	protected $elementId;
	protected $subviews=array();
	protected $superview;
	protected $autoResizing;
	protected $needsDisplay;
	protected $window;
	protected $tooltip;
	public function __construct()
		{
		static $elementNumber;	// unique number
		parent::__construct();
		// if we ever get problems with this numbering, we should derive the name from
		// the subview tree index, e.g. 0-2-3
		$this->elementId=++$elementNumber;
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
		}
	public function superview() { return $this->superview; }
	public function _setSuperView(NSView $superview=null)
		{
		$this->superview=$superview;
		}
	public function subviews() { return $this->subviews; }
	public function addSubview(NSView $view)
		{
		$this->subviews[]=$view;
		$view->_setSuperView($this);
		$view->setWindow($this->window);
		}
	public function _removeSubView(NSView $view)
		{
		$view->setWindow(null);
		$view->_setSuperView(null);
		if(($key = array_search($view, $this->subviews, true)) !== false)
			$this->subviews($array[$key]);
		}
	public function removeFromSuperview()
		{
		$this->superview()->_removeSubView($this);
		}
	public function setNeedsDisplay()
		{
		$this->needsDisplay=true;
		}
	public function needsDisplay()
		{
		return $this->needsDisplay;
		}
	public function display()
		{ // draw subviews first
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
		}
	public function mouseDown(NSEvent $event)
		{ // nothing by default
		}
}

class NSControl extends NSView
	{
	public function __construct()
		{ // must explicitly call!
		parent::__construct();
		}
	public function sendAction($action, NSObject $target=null)
		{
		global $NSApp;
NSLog($this->description()." sendAction $action");
		$NSApp->sendActionToTarget($this, $action, $target);
		}
	public function setActionAndTarget($action, NSObject $target=null)
		{
		$this->action=$action;
		$this->target=$target;
		}
	}

class NSMatrix extends NSControl
	{ // matrix of several buttons - radio buttons are grouped
	// make click on a radio button tribber our action+target
	}

class NSButton extends NSControl
	{
	protected $title;
	protected $altTitle;
	protected $action;	// function name
	protected $target;	// object
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
			$NSApp->queueEvent(new NSEvent($this, 'NSMouseDown')); // queue a mouseDown event for us
			}
		}
	public function isSelected()
		{
		return $this->state;
		}
	public function setSelected($value)
		{
		$this->state=$this->_persist("selected", $value);
		}
	public function description() { return parent::description()." ".$this->title; }
	public function title() { return $this->title; }
	public function setTitle($title) { $this->title=$title; }
	public function alternateTitle() { return $this->altTitle; }
	public function setAlternateTitle($title) { $this->altTitle=$title; }
	public function state() { return $this->state; }
	public function setState($s) { $this->state=$s; }
	public function mouseDown(NSEvent $event)
	{ // this button may have been pressed
		// NSLog($event);
		// NSLog($this);
		// if radio button or checkbox, watch for value
		$this->sendAction($this->action, $this->target);
	}
	public function draw()
		{
		html("<input");
		parameter("id", $this->elementId);
		parameter("class", "NSButton");
		switch($this->buttonType)
			{
				case "Radio":
					parameter("type", "radio");
					parameter("name", $this->elementId."-ck");
					break;
				case "CheckBox":
					parameter("type", "checkbox");
		// if Radio Button/Checkbox take elementId of parent so that radio buttons are grouped correctly!
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
// FIXME: if default button (shortcut "\r"): make it blue
		if($this->isSelected())
			{
			parameter("checked", "checked");
			parameter("style", "color:green;");
			}
		else
			parameter("style", "color:red;");
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

// FIXME: we currently do not separate between NSMenu/NSMenuItem and NSMenuView/NSMenuItemView

class NSMenuItemView extends NSButton
	{	
		protected $icon;
		protected $shortcut;
		protected $subMenuView;
		protected $action;
		protected $target;
		protected $isSelected;
		public function isSelected() { return $this->isSelected; }
		public function setSelected($sel) { $this->isSelected=$this->_persist("isSelected", 0, $sel); }
		public function __construct($label)
			{
			parent::__construct($label);
			$this->isSelected=$this->_persist("isSelected", 0);
			}
		public function setSubmenu(NSMenu $submenu)
			{
			$this->subMenuView=$submenu;
			}
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
	public function addMenuItem(NSMenuItemView $item) { $this->menuItems[]=$item; }
	public function addMenuItemWithTitleAndAction($title, $action, $target)
		{
		$item=new NSMenuItemView($title);
		$item->setActionAndTarget($action, $target);
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
			//		parameter("bgcolor", "LightSteelBlue");
			html(">\n");
			$index=0;
			foreach($this->menuItems as $item)
			{ // add menu buttons and switching logic
				html("<td");
				parameter("class", "NSMenuItem");
				parameter("bgcolor", $this->selectedItem == $index?"blue":"white");
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
		parameter("id", $this->elementId);
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
	protected $colums=5;
	protected $border=0;
	protected $width="100%";
	public function content() { return $this->subviews(); }
	public function setContent($items)
		{
		foreach($this->subviews() as $item)
			$item->removeFromSuperview();	// remove from hierarchy
		foreach($items as $item)
			$this->addSubview($item);
		}
	public function addCollectionViewItem($item)
		{ // alternate function name
			$this->addSubview($item);
		}
	public function setBorder($border) { $this->border=0+$border; }

// allow to define colspan and rowspan objects
// allow to modify alignment

	public function __construct($cols=5, $items=array())
		{
		parent::__construct();
		$this->columns=$cols;
		$this->setContent($items);
// NSLog("NSCollectionView cols=$cols rows=".(count($item)+$cols-1)/$cols);
		}
	public function mouseDown(NSEvent $event)
		{
		}
	public function display()
		{
		html("<table");
		parameter("class", "NSCollectionView");
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
		}
	public function setBorder($border) { $this->border=0+$border; }
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
		parameter("bgcolor", "LightSteelBlue");
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
			parameter("class", "NSTabViewItemsButton");
			parameter("type", "submit");
			parameter("name", $this->elementId."-".$index);
			parameter("value", _htmlentities($item->label()));
			if($item == $this->selectedTabViewItem())
				parameter("style", "color:green;");
			else
				parameter("style", "color:red;");
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
	protected $identifier;
	protected $width="*";
	protected $isEditable=false;
	// allow to define colspan and rowspan values
	// allow to modify alignment
	public function identifier() { return $this->identifier; }
	public function setIdentifier($identifier) { $this->identifier=$identifier; }
}

// IDEA:
// we can implement some firstVisibleRow and scrollToVisible
// through appending e.g. #31-5-0 to the URL (send modified "Location:" header instructing the browser to reload)

class NSTableView extends NSControl
	{
	protected $headers;
	protected $border=0;
	protected $width="100%";
	protected $delegate;
	protected $dataSource;
	protected $visibleRows=0;	// 0 = infinite
	protected $firstVisibleRow=0;
	protected $selectedRow=-1;
	protected $clickedRow;
	protected $clickedColumn;
	public function delegate() { return $this->delegate; }
	public function setDelegate(NSObject $d=null) { $this->delegate=$d; }
	public function setDataSource(NSObject $source=null) { $this->dataSource=$source; }
	public function setHeaders($headers) { $this->headers=$headers; }
	public function setBorder($border) { $this->border=0+$border; }
	public function numberOfRows() { if(!isset($this->dataSource)) return 1; return $this->dataSource->numberOfRowsInTableView($this); }
	public function numberOfColumns() { return count($this->headers); }
	public function __construct($headers=array("Column1"), $visibleRows=0)
		{
       		parent::__construct();
		$this->visibleRows=$visibleRows;
		$this->selectedRow=$this->_persist("selectedRow", -1);
		// FIXME: create array of NSTableColumn objects and set column title (value) + identifier (key) defaults from $headers array
		$this->headers=$headers;
		if(_persist('NSEvent', null) == $this->elementId)
			{ // click into table
			global $NSApp;
			_persist('NSEvent', "", "");	// reset
			$this->clickedRow=_persist('clickedRow', null);
			_persist('clickedRow', "", "");	// reset
			$this->clickedColumn=_persist('clickedColumn', null);
			_persist('clickedColumn', "", "");	// reset
			NSLog($this->classString());
			$NSApp->queueEvent(new NSEvent($this, 'NSMouseDown')); // queue a mouseDown event for us
			}
		}
	public function reloadData() { $this->setNeedsDisplay(); }
	public function columns()
		{
		return $this->headers;	// headers should be the headers of the columns...
		}
	public function setColumns($array)
		{
		if(is_null($array))
			return;
		NSLog("set columns");
		NSLog($array);
		$this->headers=$array;
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
		}
	public function mouseDown(NSEvent $event)
		{
		if(false && $this->clickedRow == -1)
			; // select column
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
		parameter("bgcolor", "LightSteelBlue");
		html(">\n");
		// columns should be NSTableColumn objects that define alignment, identifier, title, sorting etc.
		foreach($this->headers as $index => $header)
			{
			html("<th");
			parameter("id", $this->elementId."-".$index);
			parameter("class", "NSTableHeaderCell");
			parameter("bgcolor", "LightSteelBlue");
			parameter("onclick", "e('".$this->elementId."');"."r(-1);"."c($index)".";s()");
			html(">\n");
			html(_htmlentities($header));
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
			foreach($this->headers as $index => $column)
				{
				html("<td");
				parameter("id", $this->elementId."-".$row."-".$index);
				parameter("class", "NSTableCell");
				if($row == $this->selectedRow)
					parameter("bgcolor", "LightSteelBlue");	// selected
				else
					parameter("bgcolor", ($row%2 == 0)?"white":"PaleTurquoise");	// alternating colors
				parameter("onclick", "e('".$this->elementId."');"."r($row);"."c($index)".";s()");
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
	protected $htmlValue;
	protected $backgroundColor;
	protected $align;
	protected $type="text";
	protected $width;
	protected $isEditable=true;
	protected $textColor;
	protected $wraps=false;
	public function stringValue() { return $this->stringValue; }
	public function setStringValue($str) { $this->stringValue=$str; $this->htmlValue=htmlentities($str, ENT_COMPAT | ENT_SUBSTITUTE, NSHTMLGraphicsContext::encoding); }
	// should be used for static text fields
	public function setAttributedStringValue($astr) { $this->htmlValue=$astr; $this->isEditable=false; $this->wraps=true; }
	public function isEditable() { return $this->isEditable; }
	public function setEditable($flag) { $this->isEditable=$flag; }
	public function __construct($width=30, $stringValue = null)
	{
       		parent::__construct();
// _NSLog("__contruct NSTextField ".$this->elementId);
		$this->setStringValue($this->_persist("string", ""));
		// should be depreacted and be replaced by SetStringValue() ...
		if(!is_null($stringValue))
			$this->setStringValue($stringValue);	// overwrite
		// should be depreacted and replaced by setFrame() ...
		$this->width=$width;
	}
	public function mouseDown(NSEvent $event)
		{ // some button has been pressed

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
			parameter("name", $this->elementId."-string");
			if($this->type != "password")
				parameter("value", _htmlentities($this->stringValue));	// password is always shown cleared/empty
			html("/>\n");
			$this->_persist("string", "", "");	// remove from persistence store
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
	public function __construct($width=30)
	{
       		parent::__construct($width);
		$this->type="password";
	}

}

class NSSearchField extends NSTextField
{
	public function __construct($width=30)
	{
		parent::__construct($width);
		$this->type="search";
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
		// FIXME: doesn't this conflict with posting a changed string?
		$this->string=$this->_persist("string", "", $string);
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
		if($NSApp->mainWindow() == NULL)
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
		// FIXME: use HTML class and CSS
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
		// onlclick handlers should only be used if necessary since they require JavaScript enabled
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

class NSWorkspace
{
	protected static $sharedWorkspace;
	protected static $knownApplications;
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
		$appdirs=array("Applications", "Applications/Games", "Applications/Work", "Applications/Utilities", "System/Library/CoreServices");
		self::$knownApplications=array();
		foreach($appdirs as $dir)
			{
			global $ROOT;
//			NSLog("$ROOT/$dir");
			$f=opendir("$ROOT/$dir");
			if($f)
				{
				while($bundle=readdir($f))
					{
//					NSLog("knownApps check: $dir/$bundle");
					if(substr($bundle, -4) == ".app")
						{ // candidate
							// checks that the PHP executable exists
							if(!NSWorkspace::sharedWorkspace()->isFilePackageAtPath("$ROOT/$dir/$bundle"))
								continue;	// is not a bundle
							$name=substr($bundle, 0, strlen($bundle)-4);
							self::$knownApplications[$bundle]=array(
									"NSApplicationName" => $name,
									"NSApplicationPath" => "$dir/$bundle",
									"NSApplicationDomain" => $dir
							);
						// collect suffixes handled by this app
						}
					}
				closedir($f);
				}
			}
//		NSLog($knownApplications);
		return self::$knownApplications;
		}
	public function fullPathForApplication($name)
		{
		NSWorkspace::knownApplications();	// update list
//		NSLog("fullPathForApplication: $name)";
		if(isset(self::$knownApplications[$name]))
			return self::$knownApplications[$name]["NSApplicationPath"];
		NSLog("fullPathForApplication:$name not found");
		NSLog(self::$knownApplications);
		return null;
		}
	public function iconForFile($path)
		{
		return NSImage::imageNamed("NSApplication");	// default
		// check if that is a bundle -> get through Info.plist / bundle
		// $bundle->objectForInfoDictionaryKey('CFBundleIconFile');
		// else find application by suffix
		}
	public function openFile($file)
		{
		// locate application and open with passing the $file
		}
	public function isFilePackageAtPath($path)
		{
		$fm=NSFileManager::defaultManager();
		if($fm->fileExistsAtPathAndIsDirectory($path, $dir) && $dir && $fm->fileExistsAtPathAndIsDirectory($path."/Contents", $dir) && $dir)
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
		NSGraphicsContext::currentContext()->text("your browser does not support iframes. Please use this link".$this->url);
		html("</iframe>");
		}

}

// EOF
?>
