<?php
/*
 * AppKit.framework
 * (C) Golden Delicious Computers GmbH&Co. KG, 2012
 * All rights reserved.
 *
 * defines (simple) classes for NSWindow, NSView, NSButton, NSTextField, NSSecureTextField, NSForm, NSImage, NSTable, NSPopUpButton
 * draw method generates HTML and CSS output
 *
 * hitTest, sendEvent and mouseDown are called when button is clicked or something modified
 */

// echo "loading AppKit<br>";

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

// replace by NSGraphicsContext::currentContext->method

function parameter($name, $value)
{
	echo " $name=\"".$value."\"";
}
// check if login is required to run the App

function _htmlentities($string)
{
	return htmlentities($string, ENT_COMPAT | ENT_SUBSTITUTE, NSHTMLGraphicsContext::encoding);
}

class NSGraphicsContext extends NSObject
	{
	protected static $currentContext;
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
	// FIXME: make more useful commands that allow to flush
	// html primitives
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
		echo _tag("html");
		}
	public function footer()
		{
		
		}
	public function text($contents)
		{
		echo htmlentities($string, ENT_COMPAT | ENT_SUBSTITUTE, self::encoding);
		}
	public function link($url, $contents)
		{
		echo $this->_tag("a", $contents, $this->_linkval("src", $url));
		}
	public function img($url)
		{
		echo $this->_tag("img", "", $this->_linkval("src", $url));
		}
	public function input($size, $value)
		{
		echo $this->_tag("input", "", $this->_value("size", $size).$this->_value("value", $value));
		}
	public function textarea($size, $value)
		{
		echo $this->_tag("textarea", $value, $this->_value("size", $size));
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
//		print_r($_SERVER);
		
		// NSLog("URL: $path");
		return $path;
		}
	
	}

global $NSApp;

class NSResponder extends NSObject
{
	public function __construct()
	{
		// parent::__construct();
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

	public function delegate() { return $this->delegate; }
	public function setDelegate($d) { $this->delegate=$d; }
	public function mainWindow() { return $this->mainWindow; }
	public function setMainWindow($w) { $this->mainWindow=$w; }
	public function mainMenu() { return $this->mainMenu; }
	public function setMainMenu($m) { $this->mainMenu=$m; }
	function logout($sender)
	{
		setcookie("login", "", 24*3600);
		setcookie("passcode", "", 24*3600);
		$this->open("loginwindow.app");
	}
	public function openSettings($sender)
	{
		$this->open("settings.app");
	}
	
	public function __construct($name)
		{
		global $NSApp;
		// parent::__construct();
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
//			print_r($bundle);
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
echo "sendAction $action to";
print_r($target);
echo "<br>";
*/
		if(!isset($target))
			return;	// it $target does not exist -> take first responder
		// if method does not exist -> ignore
		$target->$action($from);
		}
	public function run()
		{

// FIXME: wir müssen die View-Hierarchie zweimal durchlaufen!
// zuerst die neuen $_POST-Werte in die NSTextFields übernehmen
// und dann erst den NSButton-action aufrufen
// sonst hängt es davon ab wo der NSButton in der Hierarchie steht ob die Felder Werte haben oder nicht
		
		$this->mainWindow->sendEvent($_POST);
		$this->mainWindow->display();
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
	protected $subviews = array();
	protected $autoResizing;
	public function subviews() { return $this->subviews; }
	public function addSubview($view) { $this->subviews[]=$view; }
	public function __construct()
		{
		static $elementNumber;	// unique number
		parent::__construct();
		$this->elementName="NSView-".(++$elementNumber);
		}
	public function draw()
		{
//		echo "<!-- ".$this->elementName." -->\n";
		foreach($this->subviews as $view)
			$view->draw();
		}
	public function sendEvent($event)
		{
		foreach($this->subviews as $view)
			$view->sendEvent($event);
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
		return true;
		}
	public function __construct($newtitle = "NSButton", $type="Button")
		{
		parent::__construct();
		// echo "NSButton $newtitle<br>";
		$this->title=$newtitle;
		$this->buttonType=$type;
		}
	public function title() { return $this->title; }
	public function setTitle($title) { $this->title=$title; }
	public function state() { return $this->state; }
	public function setState($s) { $this->state=$s; }
	public function sendEvent($event)
	{ // this button may have been pressed
		// print_r($event);
		// print_r($this);
		if(isset($event[$this->elementName]) && $event[$this->elementName] == $this->title)
			$this->sendAction($this->action, $this->target);
	}
	public function draw()
		{
		parent::draw();
		// checkbox, radiobutton
		echo "<input";
		parameter("class", "NSButton");
		switch($buttonType)
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
		if($item == $this->isSelected())
			{
			parameter("checked", "checked");
			parameter("style", "color=green;");
			}
		else
			parameter("style", "color=red;");
		echo "\"/>\n";
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
		public function setSelected($sel) { $this->isSelected=$sel; }
		public function __construct($label)
			{
			parent::__construct($label);
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
			echo _htmlentities($this->title);
			if(isset($this->subMenuView))
				{
				echo "<select";
				parameter("class", "NSMenuItemView");
				parameter("name", $this->elementName);
				parameter("size", 1);	// make a popup not a combo-box
				echo ">\n";
				$index=0;
				foreach($this->subMenuView->menuItems() as $item)
				{ // add menu buttons and switching logic
					echo "<option";
					parameter("class", "NSMenuItem");
					if($this->selectedItem == $index)
						parameter("selected", "selected");	// mark menu title as selected
					echo ">";
					$item->draw();	// draws the title
					echo "</option>\n";
					$index++;
				}
				echo "</select>\n";
				}
			else if(isset($this->shortcut))
				echo _htmlentities(" ".$this->shortcut);
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
			echo "<hr>\n";
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
//		echo $this->isHorizontal?"horizontal":"vertical";
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
			echo "<input";
			parameter("type", "hidden");
			parameter("name", $this->elementName."-selectedIndex");
			parameter("value", $this->selectedItem);
			echo ">\n";
			echo "<table";
			parameter("border", $this->border);
			if($this->isHorizontal)
				parameter("width", $this->width);
			echo "\">\n";
			echo "<tr";
			parameter("class", "NSMenuItemView");
			//		parameter("bgcolor", "LightSteelBlue");
			echo ">\n";
			$index=0;
			foreach($this->menuItems as $item)
			{ // add menu buttons and switching logic
				echo "<td";
				parameter("class", "NSMenuItem");
				parameter("bgcolor", $this->selectedItem == $index?"blue":"white");
				echo ">\n";
				$item->setSelected($this->selectedItem == $index);
				$item->draw();
				echo "</td>\n";
				$index++;
			}
			echo "</tr>\n";
			echo "</table>\n";
			}
		else
			{ // show menu as popup items
				// HTML5 hat <menu> und <menuitem> tags!
				if($this->isHorizontal)
					{ // draw all submenus because we are top-level
						echo "<div";
						parameter("class", "NSMenuView");
						echo ">\n";
						foreach($this->menuItems as $item)
						{ // add menu buttons and switching logic
							$item->draw();
						}
						echo "</div>\n";
					}
				else
					{
					echo "vertical menu on top level";
					// will be drawn by NSMenuItemView
					}
			}
		}
	}

class NSComboBox extends NSControl
	{
	// use <select size > 1>
	}

// FIXME: shouldn't we separate between NSImage and NSImageView?

class NSImage extends NSObject
{
	protected static $images=array();
	protected $url;
	protected $name;
	protected $width=32;
	protected $height=32;
	public function size()
		{
		return array($width, $height);
		}
	public static function imageNamed($name)
		{
		$img=self::$images[$name];
		if(isset($img))
			return $img;	// known
		return new NSImage($name);	// create
		}
	public function __construct()
		{
		parent::__construct();
		}
	public function setName($name)
		{
		if($this->name != "")
			unset(self::$images[$this->name]);
		if($name != "")
			{
			self::$images[$name]=$this;
			$this->name=$name;
			if(!isset($this->url))
				{
				// search in main bundle
				$this->setFilePath("images/".$name.".png");	// set default name				
				}
			}
		}
	public function initByReferencingURL($url)
		{
		$this->url=$url;
		// $this->setName(basename($path)) - ohne Suffix
		}
	public function initByReferencingFile($path)
		{
		NSHTMLGraphicsContext::currentContext()->externalURLforPath($path);
		$this->initByReferencingURL($url);
//		$this->seinitByReferencingURLURL("https://".$_SERVER['HTTP_HOST']."/$path");
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
		return $image;
		}
	public function setImage($img)
		{
		$image=$img;
		$this->setNeedsDisplay();
		}
	public function draw()
		{
		parent::draw();
		echo "<img";
		parameter("src", _htmlentities($image->url));
		parameter("name", _htmlentities($image->name));
		parameter("style", "{ width:"._htmlentities($image->width).", height:"._htmlentities($image->height)."}");
		echo ">\n";
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
// echo "NSCollectionView $cols<br>";
		}
	public function sendEvent($event)
		{
		foreach($this->content as $item)
			$item->sendEvent($event);
		}
	public function draw()
		{
		parent::draw();
		echo "<table";
		parameter("border", $this->border);
		parameter("width", $this->width);
		echo "\">\n";
		$col=1;
		foreach($this->content as $item)
			{
			if($col == 1)
				echo "<tr>";
			echo "<td>\n";
			$item->draw();
			echo "</td>";
			$col++;
			if($col > $this->columns)
				{
				echo "</tr>\n";
				$col=1;
				}
			}
		if($col > 1)
			{ // handle missing colums
				echo "</tr>\n";
			}
		echo "</table>\n";
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
	protected $delegate;
	protected $segmentedControl;
	public function delegate() { return $this->delegate; }
	public function setDelegate($d) { $this->delegate=$d; }
	public function tabViewItems() { return $this->tabViewItems; }
	public function addTabViewItem($item) { $this->tabViewItems[]=$item; }
	public function selectedTabViewItem() {	return $this->tabViewItems[$this->selectedIndex]; }
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
	public function indexOfSelectedTabViewItem() { return $this->selectedIndex; }
	public function selectTabViewItemAtIndex($index)
		{
		if(method_exists($this->delegate, "tabViewShouldSelectTabViewItem"))
			if(!$this->delegate->tabViewShouldSelectTabViewItem($this, $this->tabViewItems[index]))
				return;	// don't select
		if(method_exists($this->delegate, "tabViewWillSelectTabViewItem"))
			$this->delegate->tabViewWillSelectTabViewItem($this, $this->tabViewItems[index]);
		$this->selectedIndex=$index;
		if(method_exists($this->delegate, "tabViewDidSelectTabViewItem"))
			$this->delegate->tabViewDidSelectTabViewItem($this, $this->tabViewItems[$index]);
		}
	public function setBorder($border) { $this->border=0+$border; }
	public function __construct($items=array())
		{
       		parent::__construct();
			$this->tabViewItems=$items;
		// echo "NSTabView $cols<br>";
		}
	public function sendEvent($event)
		{ // forward to selected item
		if(isset($event[$this->elementName."-selectedIndex"]))
			$this->selectedIndex=$event[$this->elementName."-selectedIndex"];	// get default
// print_r($selectedIndex);
		for($index=0; $index < count($this->tabViewItems); $index++)
			{
			$element=$this->elementName."-".$index;
// print_r($element);
			if(isset($event[$element]) && $event[$element] != "")
				$this->selectTabViewItemAtIndex($index);	// some tab button was pressed
			}
		$selectedItem=$this->selectedTabViewItem();
		if(isset($selectedItem))
			$selectedItem->view()->sendEvent($event);
		}
	public function draw()
		{
		parent::draw();
		echo "<input";
		parameter("type", "hidden");
		parameter("name", $this->elementName."-selectedIndex");
		parameter("value", $this->selectedIndex);
		echo ">\n";
		echo "<table";
		parameter("border", $this->border);
		parameter("width", $this->width);
		echo "\">\n";
		echo "<tr>";
		echo "<td";
		parameter("class", "NSTabViewItemsBar");
		parameter("bgcolor", "LightSteelBlue");
		echo ">\n";
		$index=0;
		foreach($this->tabViewItems as $item)
			{ // add tab buttons and switching logic
			echo "<input";
			parameter("class", "NSTabViewItemsButton");
			parameter("type", "submit");
			parameter("name", $this->elementName."-".$index++);
			parameter("value", _htmlentities($item->label()));
			if($item == $this->selectedTabViewItem())
				parameter("style", "color=green;");
			else
				parameter("style", "color=red;");
			echo ">\n";
			}
		echo "</td>";
		echo "</tr>\n";
		echo "<tr>";
		echo "<td";
		parameter("align", "center");
		echo ">\n";
		$selectedItem=$this->selectedTabViewItem();
		if(isset($selectedItem))
			$selectedItem->view()->draw();	// draw current tab
		else
			echo _htmlentities("No tab for index ".$this->selectedIndex);
		echo "</td>";
		echo "</tr>\n";
		echo "</table>\n";
		}
	}
	
class NSTableView extends NSControl
	{
	protected $headers;
	protected $border=0;
	protected $width="100%";
	protected $delegate;
	protected $dataSource;
	protected $visibleRows=20;
	protected $selectedRow=-1;
	public function delegate() { return $this->delegate; }
	public function setDelegate($d) { $this->delegate=$d; }
	public function setDataSource($source) { $this->dataSource=$source; }
	public function setHeaders($headers) { $this->headers=$headers; }
	public function setBorder($border) { $this->border=0+$border; }
	public function numberOfRows() { return $this->dataSource->numberOfRowsInTableView($this); }
	public function numberOfColumns() { return count($this->headers); }
	
	// allow to define colspan and rowspan objects
	// allow to modify alignment
	
	public function __construct($headers=array("Column1"), $visibleRows=20)
		{
       		parent::__construct();
		$this->visibleRows=$visibleRows;
		$this->headers=$headers;
		}
	public function sendEvent($event)
		{
		if(isset($event[$this->elementName."-selectedRow"]))
			$this->selectedRow=$event[$this->elementName."-selectedRow"];	// get default
/* handle row selection
		for($index=0; $index < count($this->tabViewItems); $index++)
			{
			$element=$this->elementName."-".$index;
// print_r($element);
			if(isset($event[$element]) && $event[$element] != "")
				$this->selectTabViewItemAtIndex($index);	// some tab button was pressed
			}
*/
		}
	public function draw()
		{
		parent::draw();
		echo "<input";
		parameter("type", "hidden");
		parameter("name", $this->elementName."-selectedRow");
		parameter("value", $this->selectedRow);
		echo ">\n";
		echo "<table";
		parameter("border", $this->border);
		parameter("width", $this->width);
		echo "\">\n";
		echo "<tr";
		parameter("class", "NSHeaderView");
		parameter("bgcolor", "LightSteelBlue");
		echo ">\n";
		// columns should be NSTableColumn objects that define alignment, identifier, title, sorting etc.
		foreach($this->headers as $header)
			{
			echo "<th";
			parameter("class", "NSTableHeaderCell");
			parameter("bgcolor", "LightSteelBlue");
			echo ">\n";
			echo _htmlentities($header);
			echo "</th>\n";
			}
		echo "</tr>\n";
		$rows=$this->numberOfRows();
		for($row=0; $row<$this->visibleRows; $row++)
			{
			echo "<tr>";
			foreach($this->headers as $column)
				{
				echo "<td";
				parameter("class", "NSTableCell");
				parameter("bgcolor", ($row%2 == 0)?"white":"PaleTurquoise");	// alternating colors
				echo ">\n";
				if($row < $rows)
					{ // ask delegate for the item to draw
					$item=$this->dataSource->tableView_objectValueForTableColumn_row($this, $column, $row);
					// we should insert that into the $column->cell
				//	$item->draw();					
					echo _htmlentities($item);
					}
				else
					echo "&nbsp;";	// add empty rows
				echo "</td>";
				}
			echo "</tr>\n";
			}
		echo "</table>\n";
		}
	}
	
class NSTextField extends NSControl
{
// FIXME: should we use cookies to store values when switching apps???
	protected $stringValue;
	protected $backgroundColor;
	protected $align;
	protected $type="text";
	protected $width;
	public function stringValue() { return $this->stringValue; }
	public function __construct($width=30, $stringValue = "")
	{
       		parent::__construct();
		$this->stringValue=$stringValue;
		$this->width=$width;
	}
	public function sendEvent($event)
		{ // some button has been pressed
		if(isset($event[$this->elementName]))
			$this->stringValue=$event[$this->elementName];	// get our value when posted
		}
	public function draw()
		{
		parent::draw();
		echo "<input";
		parameter("class", "NSTextField");
		parameter("type", $this->type);
		parameter("size", $this->width);
		parameter("name", $this->elementName);
		parameter("value", _htmlentities($this->stringValue));
		echo "\"/>\n";
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

class NSStaticTextField extends NSControl
{
	protected $stringValue;
	public function __construct($stringValue = "")
	{
       		parent::__construct();
		$this->stringValue=$stringValue;
	}
	public function draw()
		{
		parent::draw();
		echo _htmlentities($this->stringValue);
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
		}
	public function sendEvent($event)
		{ // some button has been pressed
		if(isset($event[$this->elementName]))
			$this->stringValue=$event[$this->elementName];	// get our value when posted
		}
	public function draw()
		{
		parent::draw();
		echo "<textarea";
		parameter("width", $this->width);
		parameter("height", $this->height);
		parameter("name", $this->elementName);
		echo "\">";
		echo _htmlentities($this->stringValue);
		echo "</textarea>\n";
		}
}

class NSWindow extends NSResponder
{
	protected $title;
	protected $contentView;
	public function contentView() { return $this->contentView; }
	public function setContentView($view) { $this->contentView=$view; }
	public function __construct($newtitle = "QuantumSTEP Cloud")
		{
		global $NSApp;
		parent::__construct();
// echo "NSWindow $newtitle<br>";
		$this->title=$newtitle;
		$this->setContentView(new NSView());
		if($NSApp->mainWindow() == NULL)
			$NSApp->setMainWindow($this);
// print_r($NSApp);
		}
	public function sendEvent($event)
		{
// print_r($event);
		$this->contentView->sendEvent($event);
		}
	public function display() 
		{
		// FIXME: use HTML class and CSS
		global $NSApp;
		echo "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">\n";
		echo "<html>\n";
		echo "<head>\n";
		echo "<meta";
		parameter("http-equiv", "content-type");
		parameter("content", "text/html; charset=".NSHTMLGraphicsContext::encoding);
		echo ">\n";
		$r=NSBundle::bundleForClass($this->class_())->pathForResourceOfType("AppKit", "css");
		if(isset($r))
		   {
		   echo "<link";
		   parameter("rel", "stylesheet");
		   parameter("href", NSHTMLGraphicsContext::currentContext()->externalURLforPath($r));
		   parameter("type", "text/css");
		   echo ">\n";
		   }
		$r=NSBundle::bundleForClass($this->class_())->pathForResourceOfType("AppKit", "js");
		if(isset($r))
		   {
		   echo "<script";
		   parameter("src", NSHTMLGraphicsContext::currentContext()->externalURLforPath($r));
		   parameter("type", "text/javascript");
		   echo ">\n";
		   echo "</script>\n";
		   echo "<noscript>Your browser does not support JavaScript!</noscript>\n";
		   }
		echo "<title>"._htmlentities($this->title)."</title>\n";
		echo "</head>\n";
		echo "<body>\n";
		echo "<form";
		parameter("name", "NSWindow");
		parameter("class", "NSWindow");
		parameter("accept_charset", NSHTMLGraphicsContext::encoding);
		parameter("method", "POST");	// a window is a big form to handle all input/output through POST (and GET)
		echo ">\n";
		$mm=$NSApp->mainMenu();
		if(isset($mm))
			$mm->draw();	// draw main menu before content view
		// add App-Icon, menu/status bar
		$this->contentView->draw();
		// add footer (Impressum, Version etc.)
		echo "</form>\n";
		echo "</body>\n";
		echo "</html>\n";
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
//			echo "$ROOT/$dir<br>";
			$f=opendir("$ROOT/$dir");
			if($f)
				{
				while($bundle=readdir($f))
					{
					#
//					echo "$dir/$bundle<br>";
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
//		print_r($knownApplications);
		return self::$knownApplications;
		}
	public function fullPathForApplication($name)
		{
		NSWorkspace::knownApplications();	// update list
//		echo "$name<br>";
		$app=self::$knownApplications[$name];
		if(isset($app))
			return $app["NSApplicationPath"];
		echo "fullPathForApplication:$app not found<br>";
		print_r(self::$knownApplications);
		return $app;
		}
	public function iconForFile($path)
		{
		return NSImageView::imageNamed("NSApplication");	// default
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

// EOF
?>