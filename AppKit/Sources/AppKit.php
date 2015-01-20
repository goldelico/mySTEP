<?php
/*
 * AppKit.framework
 * (C) Golden Delicious Computers GmbH&Co. KG, 2012
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

function parameter($name, $value)
{
	NSGraphicsContext::currentContext()->html(" $name=\"".$value."\"");
}

function html($html)
{
	NSGraphicsContext::currentContext()->html($html);
}

function _htmlentities($string)
{
	return htmlentities($string, ENT_COMPAT | ENT_SUBSTITUTE, NSHTMLGraphicsContext::encoding);
}

/*
 * persistence is achieved by posting object->value relations through hidden <input> fields
 * so that they are available on next refresh of the page through $_POST;
 * a variable should be persisted
 * - if it belongs to the view state of the current window (model state should be persisted through CoreDataBase and NSUserDefaults)
 * - if it needs to survive the display (run) loop
*/

$persist=array();

class NSGraphicsContext extends NSObject
	{
	protected static $currentContext;
	public static function setCurrentContext($context) { self::$currentContext=$context; }
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
	public function flushGraphics()
		{
			flush();
		}
	public function _value($name, $value)
		{
		return " $name=\"".htmlentities($value, ENT_COMPAT | ENT_SUBSTITUTE, self::encoding)."\"";
		}
	public function _linkval($name, $url)
		{
		return " $name=\"".rawurlencode($url)."\"";
		}
	public function _tag($tag, $contents, $args="")
		{
		return "<$tag$args>".$contents."</$tag>";
		}
	public function bold($contents)
		{
		return _tag("b", $contents);
		}
	// write output objects
	public function header()
		{
		$this->html(_tag("html"));
		}
	public function footer()
		{
		
		}
	public function text($contents)
		{
		$this->html(htmlentities($contents, ENT_COMPAT | ENT_SUBSTITUTE, self::encoding));
		}
	public function link($url, $contents)
		{
		$this->html($this->_tag("a", $contents, $this->_linkval("src", $url)));
		}
	public function img($url)
		{
		$this->html($this->_tag("img", "", $this->_linkval("src", $url)));
		}
	public function input($size, $value)
		{
		$this->html($this->_tag("input", "", $this->_value("size", $size).$this->_value("value", $value)));
		}
	public function textarea($size, $value)
		{
		$this->html($this->_tag("textarea", $value, $this->_value("size", $size)));
		}
	/* we need this to convert file system paths into an external URL */
	/* hm, here we have a fundamental problem:
	 * we don't know where the framework/bundle requesting the path can be accessed from extern!
	 * because that is very very installation dependent (mapping from external URLs through links to local file paths)
	 */
	public function externalURLforPath($path)
		{
		// enable read (only) access to file (if not yet possible)
		// NSLog("path: $path");
		$path=str_replace("/Users/hns/Documents/Projects", "", $path);
		$path="http://localhost".$path;
		// strip off: /Users/hns/Documents/Projects
//		NSLog("__FILE__: ".$__FILE__);
//		NSLog($_SERVER);
		
		// NSLog("URL: $path");
		return $path;
		}
	
	}

class _NSHTMLGraphicsContextStore extends NSGraphicsContext
{ // collect html in a string
	protected $string="";
	public function string() { return $this->string; }
	public function html($html) { $string.=$html; }
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
	public function setDelegate($d) { $this->delegate=$d; }
	public function mainWindow() { return $this->mainWindow; }
	public function setMainWindow($w) { $this->mainWindow=$w; }
	public function mainMenu() { return $this->mainMenu; }
	public function setMainMenu($m) { $this->mainMenu=$m; }

	public function queueEvent(NSEvent $event)
		{
		NSLog("queueEvent: ".$event->description());
		$this->queuedEvent=$event;
		}

	public function openSettings($sender)
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
	public function open($app)
		{ // switch to a different app
		$bundle=NSWorkspace::fullPathForApplication($app);
//		NSLog("open: ".$bundle->description());
		if(isset($bundle))
			{
// ask $bundle->executablePath;
			$executablePath=NSHTMLGraphicsContext::currentContext()->externalURLForPath($bundle->executablePath());
//			$executablePath="https://".$_SERVER['HTTP_HOST']."/$bundle/Contents/php/executable.php";
// how can we pass arbitrary parameters to their NSApplication $argv???
			header("location: ".$executablePath);	// how to handle special characters here? rawurlencode?
			exit;
			}
		}
	public function terminate()
		{
		if($this->name == "Palmtop")
			$this->open("loginwindow.app");
		else
			$this->open("Palmtop.app");
		}
	public function sendActionToTarget($from, $action, $target)
		{
/*
NSLog("sendAction $action to ".$target->description());
*/
		if(!isset($target))
			return;	// it $target does not exist -> take first responder
		// if method does not exist -> ignore or warn
		$target->$action($from);
		}
	public function run()
		{
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
NSLog("_POST:");
NSLog($_POST);
	if($GLOBALS['debug']) echo "<h1>NSApplicationMain($name)</h1>";
	new NSApplication($name);
	$NSApp->setDelegate(new AppController);	// this should come from the NIB file!
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
//		NSBundle::bundleForClass($this);
		// get system colors
		}
	}

class NSView extends NSResponder
{ // semi-abstract superclass
	protected $elementName;
	protected $subviews=array();
	protected $superview;
	protected $autoResizing;
	protected $needsDisplay;
	protected $window;
	public function __construct()
		{
		static $elementNumber;	// unique number
		parent::__construct();
		// if we ever get problems with this numbering, we should derive the name from
		// the subview tree index, e.g. 0-2-3
		$this->elementName="NSView-".(++$elementNumber);
		}
	public function persist($object, $default, $value=null)
		{
		global $persist;	// will come back as $_POST[] next time (+ values from <input>)
		$object=$this->elementName."-".$object;	// add namespace for this view
		if(is_null($value))
			{ // query
NSLog("query persist $object");
			if(isset($_POST[$object]))
				$value=$_POST[$object];
			else
				$value=$default;
			}
		if($value === $default)
			{
NSLog("unset persist $object");
			unset($persist[$object]);	// default values need not waste http bandwidth
			unset($_POST[$object]);		// if we want to read back again this will return $default
			}
		else
			{
NSLog("set persist $object = $value");
			$persist[$object]=$value;	// store (new/non-default value) until we draw
			$_POST[$object]=$value;		// store if we overwrite and want to read back again
			}
		return $value;
		}
	public function window() { return $this->window; }
	public function setWindow($window)
		{
//		NSLog("setWindow ".$window->description()." for ".$this->description());
		$this->window=$window;
		foreach($this->subviews as $view)
			$view->setWindow($window);
		}
	public function superview() { return $this->superview; }
	public function _setSuperView($superview)
		{
		$this->superview=$superview;
		}
	public function subviews() { return $this->subviews; }
	public function addSubview($view)
		{
		$this->subviews[]=$view;
		$view->_setSuperView($this);
		$view->setWindow($this->window);
		}
	public function _removeSubView($view)
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
//		NSLog("<!-- ".$this->elementName." -->");
		foreach($this->subviews as $view)
			$view->display();
		$this->draw();
		}
	public function draw()
		{ // draw our own contents
		}
	public function mouseDown(NSEvent $event)
		{ // nothing by default
		}
}

class NSControl extends NSView
	{
	public function sendAction($action, $target)
		{
		global $NSApp;
		$NSApp->sendActionToTarget($this, $action, $target);
		}
	}

class NSButton extends NSControl
	{
	protected $title;
	protected $target;	// object
	protected $action;	// function name
	protected $state;
	protected $buttonType;
	public function isSelected()
		{
		return $this->state;
		}
	public function setSelected($value)
		{
		$this->state=$this->persist("selected", $value);
		}
	public function __construct($newtitle = "NSButton", $type="Button")
		{
		global $NSApp;
		parent::__construct();
		NSLog("NSButton $newtitle ".$this->elementName);
		$this->title=$newtitle;
		$this->buttonType=$type;
		$this->state=$this->persist("selected", 0);
		if(isset($_POST[$this->elementName]))
			{
			global $NSApp;
			NSLog($this->classString());
			$NSApp->queueEvent(new NSEvent($this, 'NSMouseDown')); // queue a mouseDown event for us
			}
		}
	public function title() { return $this->title; }
	public function setTitle($title) { $this->title=$title; }
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
		// checkbox, radiobutton
		html("<input");
		parameter("class", "NSButton");
		switch($this->buttonType)
			{
				case "CheckBox":
					parameter("type", "checkbox");
				break;
				case "Radio":
					parameter("type", "radio");
				break;
				default:
					parameter("type", "submit");
			}
		parameter("type", "submit");
		parameter("name", $this->elementName);
		parameter("value", _htmlentities($this->title));
		if($this->isSelected())
			{
			parameter("checked", "checked");
			parameter("style", "color=green;");
			}
		else
			parameter("style", "color=red;");
		html("\"/>\n");
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
		public function setSelected($sel) { $this->isSelected=$this->persist("isSelected", 0, $sel); }
		public function __construct($label)
			{
			parent::__construct($label);
			$this->isSelected=$this->persist("isSelected", 0);
			}
		public function setActionAndTarget($action, $target)
			{
			$this->action=$action;
			$this->target=$target;
			}
		public function setSubmenu($submenu)
			{
			$this->subMenuView=$submenu;
			}
		public function draw($superview="")
			{
			// FXIME: use <style>
			// if no action -> grey out
			NSGraphicsContext::currentContext()->text($this->title);
			if(isset($this->subMenuView))
				{
				html("<select");
				parameter("class", "NSMenuItemView");
				parameter("name", $this->elementName);
				parameter("onclick", "e('".$this->elementName."');s()");
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

class NSMenuView extends NSControl
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
		$this->selectedItem=$this->persist("selectedIndex", -1);
		$menuItems=array();
		}
	public function menuItems() { return $this->menuItems; }
	public function menuItemAtIndex($index) { return $this->menuItems[$index]; }
	public function addMenuItem($item) { $this->menuItems[]=$item; }
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
			$this->persist("-selectedIndex", -1, $this->selectedItem);
			html("<table");
			parameter("border", $this->border);
			if($this->isHorizontal)
				parameter("width", $this->width);
			html("\">\n");
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
	public static function imageNamed($name)
		{
		if(isset(self::$images[$name]))
			return self::$images[$name];	// known
		$image=new NSImage();	// create
		$image->setName($name);
		return $image;
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
		parameter("src", _htmlentities($this->url));
		parameter("name", _htmlentities($this->name));
		parameter("style", "{ width:"._htmlentities($this->width).", height:"._htmlentities($this->height)."}");
		html(">\n");
		}
	public function setName($name)
		{
		if($this->name != "")
			unset(self::$images[$this->name]);
		if($name != "")
			{
			$this->name=$name;
			self::$images[$this->name]=$this;
			if(!isset($this->url))
				{
				// search in main bundle
				// or in AppKit bundle
				$this->url="images/".$name.".png";	// set default name
				}
			}
		}
	public function initByReferencingURL($url)
		{
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
		NSHTMLGraphicsContext::currentContext()->externalURLforPath($path);
		$this->initByReferencingURL($url);
//		$this->initByReferencingURLURL("https://".$_SERVER['HTTP_HOST']."/$path");
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
	public function setImage($img)
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
	protected $content;
	public function content() { return $this->content; }
	public function setContent($array) { $this->content=$array; }
	// FIXME: we should decide which method we prefer!
	public function addSubview($item) { $this->addCollectionViewItem($item); }
	public function addCollectionViewItem($item) { $this->content[]=$item; }
	public function setBorder($border) { $this->border=0+$border; }

// allow to define colspan and rowspan objects
// allow to modify alignment

	public function __construct($cols=5, $items=array())
		{
		parent::__construct();
		$this->columns=$cols;
		$this->content=$items;
// NSLog("NSCollectionView $cols");
		}
	public function mouseDown(NSEvent $event)
		{
		}
	public function draw()
		{
// FIXME: this is not yet very systematic...
// we call display from draw which should itself be called from display only
		html("<table");
		parameter("class", "NSCollectionView");
		parameter("border", $this->border);
		parameter("width", $this->width);
		html("\">\n");
		$col=1;
		foreach($this->content as $item)
			{
			if($col == 1)
				html("<tr>");
			html("<td");
			parameter("class", "NSCollectionViewItem");
			html("\">\n");
//NSLog($item);
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
	public function __construct($label, $view)
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
	protected $tabViewItems;
	protected $selectedIndex=0;
	protected $clickedItemIndex=-1;
	protected $delegate;
	protected $segmentedControl;
	public function __construct($items=array())
		{
		parent::__construct();
		foreach($items as $item)
			$this->addTabViewItem($item);	// may have been clicked
		$this->selectTabViewItemAtIndex($this->persist("selectedIndex", 0));
		}
	public function delegate() { return $this->delegate; }
	public function setDelegate($d) { $this->delegate=$d; }
	public function tabViewItems() { return $this->tabViewItems; }
	public function addTabViewItem($item)
		{
		if(isset($_POST[$this->elementName."-".count($this->tabViewItems)]))
			{ // this index was clicked
			global $NSApp;
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
	public function indexOfTabViewItem($item)
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
		NSLog("selectTabViewItemAtIndex $index");
		if(method_exists($this->delegate, "tabViewShouldSelectTabViewItem"))
			if(!$this->delegate->tabViewShouldSelectTabViewItem($this, $this->tabViewItems[index]))
				return;	// don't select
		if(method_exists($this->delegate, "tabViewWillSelectTabViewItem"))
			$this->delegate->tabViewWillSelectTabViewItem($this, $this->tabViewItems[index]);
		$this->selectedIndex=$this->persist("selectedIndex", 0, $index);
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
	public function draw()
		{
		html("<table");
		parameter("border", $this->border);
		parameter("width", $this->width);
		parameter("name", $this->elementName);
		html("\">\n");
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
			html("<input");
			parameter("class", "NSTabViewItemsButton");
			parameter("type", "submit");
			parameter("name", $this->elementName."-".$index++);
			parameter("value", _htmlentities($item->label()));
			if($item == $this->selectedTabViewItem())
				parameter("style", "color:green;");
			else
				parameter("style", "color:red;");
			html(">\n");
			}
		html("</td>");
		html("</tr>\n");
		html("<tr>");
		html("<td");
		parameter("align", "center");
		html(">\n");
		$selectedItem=$this->selectedTabViewItem();
		if(isset($selectedItem))
			$selectedItem->view()->draw();	// draw current tab
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
	public function setDelegate($d) { $this->delegate=$d; }
	public function setDataSource($source) { $this->dataSource=$source; }
	public function setHeaders($headers) { $this->headers=$headers; }
	public function setBorder($border) { $this->border=0+$border; }
	public function numberOfRows() { return $this->dataSource->numberOfRowsInTableView($this); }
	public function numberOfColumns() { return count($this->headers); }
	public function __construct($headers=array("Column1"), $visibleRows=0)
		{
       		parent::__construct();
		$this->visibleRows=$visibleRows;
		$this->selectedRow=$this->persist("selectedRow", -1);
		// FIXME: create array of NSTableColumn objects and set column title (value) + identifier (key) defaults from $headers array
		$this->headers=$headers;
		if(isset($_POST['NSEvent']) && $_POST['NSEvent'] == $this->elementName)
			{ // click into table
			global $NSApp;
			$this->clickedRow=$_POST['clickedRow'];
			$this->clickedColumn=$_POST['clickedColumn'];
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
		$this->selectedRow=$this->persist("selectedRow", -1, $row);
		}
	public function mouseDown(NSEvent $event)
		{
		if(false && $this->clickedRow == -1)
			; // select column
		$this->selectRow($this->clickedRow);
		}
	public function draw()
		{
		$rows=$this->numberOfRows();	// may trigger a callback that changes something
		NSLog("numberOfRows: $rows");
		html("<table");
		parameter("border", $this->border);
		parameter("width", $this->width);
		html("\">\n");
		html("<tr");
		parameter("class", "NSHeaderView");
		parameter("bgcolor", "LightSteelBlue");
		html(">\n");
		// columns should be NSTableColumn objects that define alignment, identifier, title, sorting etc.
		foreach($this->headers as $header)
			{
			$index=key($this->headers);
			html("<th");
			parameter("class", "NSTableHeaderCell");
			parameter("bgcolor", "LightSteelBlue");
			parameter("name", $this->elementName."-".$index);
			parameter("onclick", "e('".$this->elementName."');"."r(-1);"."c($index)".";s()");
			html(">\n");
			html(_htmlentities($header));
			html("</th>\n");
			}
		html("</tr>\n");
		$row=$this->firstVisibleRow;
		while(($this->visibleRows == 0 && $row<$rows) || $row<$this->firstVisibleRow+$this->visibleRows)
			{
			html("<tr");
			parameter("class", "NSTableRow");
			// add id="even"/"odd" so that we can define bgcolor by CSS?
			parameter("name", $this->elementName."-".$row);
			html(">\n");
			foreach($this->headers as $column)
				{
				$index=key($this->headers);
				html("<td");
				parameter("class", "NSTableCell");
				if($row == $this->selectedRow)
					parameter("bgcolor", "LightSteelBlue");	// selected
				else
					parameter("bgcolor", ($row%2 == 0)?"white":"PaleTurquoise");	// alternating colors
				parameter("name", $this->elementName."-".$row."-".$index);
				parameter("onclick", "e('".$this->elementName."');"."r($row);"."c($index)".";s()");
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
	protected $stringValue="";	// should this be a property of NSControl?
	protected $backgroundColor;
	protected $align;
	protected $type="text";
	protected $width;
	protected $isEditable=true;
	protected $textColor;
	protected $wraps=true;
	public function stringValue() { return $this->stringValue; }
	public function setStringValue($str) { $this->stringValue=$str; }
	public function isEditable() { return $this->isEditable; }
	public function setEditable($flag) { $this->isEditable=$flag; }
	public function __construct($width=30, $stringValue = "")
	{
       		parent::__construct();
		if(isset($_POST[$this->elementName."-stringValue"]))
			$this->stringValue=$_POST[$this->elementName."-stringValue"];
		if($stringValue)
			$this->stringValue=$stringValue;
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
			parameter("class", "NSTextField");
			parameter("type", $this->type);
			parameter("size", $this->width);
			parameter("name", $this->elementName."-stringValue");
			parameter("value", _htmlentities($this->stringValue));
			html("\"/>\n");
			}
		else
			{
			if($this->wraps)
				html(nl2br(_htmlentities($this->stringValue)));
			else
				html(_htmlentities($this->stringValue));
			}
		}
}

class NSSecureTextField extends NSTextField
{
	public function __construct($width=30)
	{
       		parent::__construct($width);
	//	parent::NSTextField($width);
		$this->type="password";
	}

}

class NSTextView extends NSControl
{
	protected $string="";
	protected $width;
	protected $height;
	public function __construct($width = 80, $height = 20)
		{
       		parent::__construct();
		$this->width=$width;
		$this->height=$height;
		if(isset($_POST[$this->elementName."-stringValue"]))
			$this->string=$_POST[$this->elementName."-stringValue"];
		}
	public function setStringValue($string)
		{
		$this->stringValue=$this->persist("stringValue", "", $string);
		}
	public function mouseDown(NSEvent $event)
		{ // some button has been pressed
		}
	public function draw()
		{
		html("<textarea");
		parameter("width", $this->width);
		parameter("height", $this->height);
		parameter("name", $this->elementName."-stringValue");
		html("\">");
		html(_htmlentities($this->stringValue));
		html("</textarea>\n");
		}
}

class NSWindow extends NSResponder
{
	protected $title;
	protected $contentView;
	public function contentView() { return $this->contentView; }
	public function setContentView($view) { $this->contentView=$view; $view->setWindow($this); }
	public function title() { return $this->title; }
	public function setTitle($title) { $this->title=$title; }

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
		html("<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">\n");
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
			html("<link");
			parameter("rel", "stylesheet");
			parameter("href", NSHTMLGraphicsContext::currentContext()->externalURLforPath($r));
			parameter("type", "text/css");
			html(">\n");
			}
		$r=NSBundle::bundleForClass($this->classString())->pathForResourceOfType("AppKit", "js");
		// onlclick handlers should only be used if necessary since they require JavaScript enabled
		html("<script>");
		html("function e(v){document.forms[0].NSEvent.value=v;};");
		html("function r(v){document.forms[0].clickedRow.value=v;};");
		html("function c(v){document.forms[0].clickedColumn.value=v;}");
		html("function s(){document.forms[0].submit();}");
		html("</script>");
		if(isset($r))
			{
			html("<script");
			parameter("src", NSHTMLGraphicsContext::currentContext()->externalURLforPath($r));
			parameter("type", "text/javascript");
			html(">\n");
			html("</script>\n");
			}
		html("<noscript>Your browser does not support JavaScript!</noscript>\n");
		if(isset($this->title))
			html("<title>"._htmlentities($this->title)."</title>\n");
		html("</head>\n");
		html("<body>\n");
		html("<form");
		parameter("name", "NSWindow");
		parameter("class", "NSWindow");
		parameter("accept_charset", NSHTMLGraphicsContext::encoding);
		parameter("method", "POST");	// a window is a big form to handle all persistence and mouse events through POST - and goes back to the same
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
		$app=self::$knownApplications[$name];
		if(isset($app))
			return $app["NSApplicationPath"];
		NSLog("fullPathForApplication:$app not found");
		NSLog(self::$knownApplications);
		return $app;
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
		html("\">");
		NSGraphicsContext::currentContext()->text("your browser does not support iframes. Please use this link".$this->url);
		html("</iframe>");
		}

}

// EOF
?>
