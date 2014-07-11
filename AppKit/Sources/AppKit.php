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

if($_SERVER['SERVER_PORT']!=443)
{ // reload page as https
	if($_SERVER['REQUEST_URI'] == "" || $_SERVER['REQUEST_URI'] == "/")
		header("location: https://".$_SERVER['HTTP_HOST']."/");
	else
		header("location: https://".$_SERVER['HTTP_HOST']."/".$_SERVER['REQUEST_URI']);
	exit;
}

global $ROOT;	// must be set by some .app
require_once "$ROOT/System/Library/Frameworks/Foundation.framework/Versions/Current/php/Foundation.php";

function parameter($name, $value)
{
	echo " $name=\"".$value."\"";
}
// check if login is required to run the App

	
global $NSApp;

class NSApplication
{
	// FIXME: part of this belongs to NSWorkspace!?!
	public $name;
	public $argv;	// arguments (?)
	public $delegate;
	public $mainWindow;
	public $mainMenu;

	function logout($sender)
	{
		setcookie("login", "", 24*3600);
		setcookie("passcode", "", 24*3600);
		$this->open("loginwindow.app");
	}
	function openSettings($sender)
	{
		$this->open("settings.app");
	}
	
	public function NSApplication($name)
		{
		global $NSApp;
		$NSApp=$this;
		$this->name=$name;
		$NSApp->mainMenu=new NSMenuView();	// create menu bar
		$NSApp->mainMenu->isHorizontal=true;
		
		// we should either load or extend that

		$item=new NSMenuItemView("System");
		$submenu=new NSMenuView();
		$item->setSubMenu($submenu);
		$NSApp->mainMenu->addMenuItem($item);
		$submenu->addMenuItemWithTitleAndAction("About", "orderFrontAboutPanel", $NSApp);
		$submenu->addMenuItemWithTitleAndAction("Settings", "openSettings", $NSApp);
		$submenu->addMenuItemSeparator();
		$submenu->addMenuItemWithTitleAndAction("Logout", "logout", $NSApp);

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
			$executablePath="https://".$_SERVER['HTTP_HOST']."/$bundle/Contents/php/executable.php";
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
		$defaults=NSUserDefaults::standardUserDefaults();	// try to read
		print_r($defaults);
		if($defaults->user == "")
			echo "Login failed!";
//			$this->open("loginwindow.app");	// go back to login
		
// FIXME: wir mŸssen die View-Hierarchie zweimal durchlaufen!
// zuerst die neuen $_POST-Werte in die NSTextFields Ÿbernehmen
// und dann erst den NSButton-action aufrufen
// sonst hŠngt es davon ab wo der NSButton in der Hierarchie steht ob die Felder Werte haben oder nicht
		
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
	$NSApp->delegate=new AppController;	// this should come from the NIB file!
	if(method_exists($NSApp->delegate, "awakeFromNib"))
		$NSApp->delegate->awakeFromNib();
	if(method_exists($NSApp->delegate, "didFinishLoading"))
		$NSApp->delegate->didFinishLoading();
	$NSApp->run();
}

class NSColor
	{
	public $rgb;
	public function name() { }
	public static function systemColorWithName($name)
		{
//		NSBundle::bundleForClass($this);
		// get system colors
		}
	}

class NSView
{ // semi-abstract superclass
	public $elementName;
	public $subviews = array();
	public $autoResizing;
	public function subviews() { return $this->subviews; }
	public function addSubview($view) { $this->subviews[]=$view; }
	public function NSView()
		{
		static $elementNumber;	// unique number
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
	public function sendAction($action, $target)
		{
		global $NSApp;
		$NSApp->sendActionToTarget($this, $action, $target);
		}
}

class NSMenuItemView extends NSView
	{	
		public $label;
		public $icon;
		public $shortcut;
		public $subMenuView;
		public $action;
		public $target;
		public $isSelected;
		public function NSMenuItemView($label)
			{
			parent::__construct();
			$this->label=$label;
			}
		public function setActionAndTarget($action, $target)
			{
			$this->action=$action;
			$this->target=$target;
			}
		public function setSubmenu($submenu)
			{
			$submenu->isHorizontal=false;
			$this->subMenuView=$submenu;
			}
		public function draw($superview="")
			{
			// FXIME: use <style>
			// if no action -> grey out
			echo htmlentities($this->label);
			if(isset($this->subMenuView))
				{
// for this to work correctly we must know our superview!	if(!$superview->isHorizontal)
					echo htmlentities(" >");
				if($this->isSelected)
					{
					echo "<br>";
					$this->subMenuView->draw();	// draw submenu (vertical)
					}
				}
			else if(isset($this->shortcut))
				echo htmlentities(" ".$this->shortcut);
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

class NSMenuView extends NSView
	{
	public $border=1;
	public $width="100%";
	public $isHorizontal;
	public $menuItems;
	public $selectedItem=-1;
	public function NSMenuItemView()
		{
		parent::__construct();
		$menuItems=array();
		}
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
			$item->isSelected=($this->selectedItem == $index);
			$item->draw();
			echo "</td>";
			$index++;
		}
		echo "</tr>\n";
		echo "</table>\n";		
		}
	}

	// FIXME: shouldn't we separate between NSImage and NSImageView?

class NSImage extends NSObject
{
	public static $images=array();
	public $url;
	public $name;
	public $width=32;
	public $height=32;
	public function size
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
	public function NSImage()
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
		$this->setURL("https://".$_SERVER['HTTP_HOST']."/$path");
		}
}

class NSImageView extends NSView
{
	public $image;
	public function NSImageView()
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
		parameter("src", htmlentities($image->url));
		parameter("name", htmlentities($image->name));
		parameter("style", "{ width:".htmlentities($image->width).", height:".htmlentities($image->height)."}");
		echo ">\n";
		}
}

class NSCollectionView extends NSView
{
	public $colums=5;
	public $border=0;
	public $width="100%";
	public $content;
	public function content() { return $this->content; }
	public function setContent($array) { $this->content=$array; }
	// FIXME: we should decide which method we prefer!
	public function addSubview($item) { $this->addCollectionViewItem($item); }
	public function addCollectionViewItem($item) { $this->content[]=$item; }
	public function setBorder($border) { $this->border=0+$border; }

// allow to define colspan and rowspan objects
// allow to modify alignment

	public function NSCollectionView($cols=5, $items=array())
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

class NSTabViewItem
	{
	public $label;
	public $view;
	public function NSTabViewItem($label, $view)
		{
		$this->label=$label;
		$this->view=$view;
		}
	}

class NSTabView extends NSView
	{
	public $border=1;
	public $width="100%";
	public $tabViewItems;
	public $selectedIndex=0;
	public $delegate;
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
	public function NSTabView($items=array())
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
			$selectedItem->view->sendEvent($event);
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
			parameter("value", htmlentities($item->label));
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
			$selectedItem->view->draw();	// draw current tab
		else
			echo htmlentities("No tab at index ".$this->selectedIndex);
		echo "</td>";
		echo "</tr>\n";
		echo "</table>\n";
		}
	}
	
class NSTableView extends NSView
	{
	public $headers;
	public $border=0;
	public $width="100%";
	public $dataSource;
	public $visibleRows=20;
	public $selectedRow=-1;
	public function setDataSource($source) { $this->dataSource=$source; }
	public function setHeaders($headers) { $this->headers=$headers; }
	public function setBorder($border) { $this->border=0+$border; }
	public function numberOfRows() { return $this->dataSource->numberOfRowsInTableView($this); }
	public function numberOfColumns() { return count($this->headers); }
	
	// allow to define colspan and rowspan objects
	// allow to modify alignment
	
	public function NSTableView($headers=array("Column1"), $visibleRows=20)
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
			echo htmlentities($header);
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
					echo htmlentities($item);
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
	
class NSButton extends NSView
{
	public $title;
	public $target;	// object
	public $action;	// function name
	public function NSButton($newtitle = "NSButton")
		{
       		parent::__construct();
// echo "NSButton $newtitle<br>";
		$this->title=$newtitle;
		}
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
		echo "<input";
		parameter("class", "NSButton");
		parameter("type", "submit");
		parameter("name", $this->elementName);
		parameter("value", htmlentities($this->title));
		echo "\"/>\n";
		}
}

// checkbox, radiobutton

class NSTextField extends NSView
{
// FIXME: should we use cookies to store values when switching apps???
	public $stringValue;
	public $backgroundColor;
	public $align;
	public $type="text";
	public $width;
	public function stringValue() { return $this->stringValue; }
	public function NSTextField($width=30, $stringValue = "")
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
		parameter("value", htmlentities($this->stringValue));
		echo "\"/>\n";
		}
}

class NSSecureTextField extends NSTextField
{
	public function NSSecureTextField($width=30)
	{
       		parent::__construct($width);
	//	parent::NSTextField($width);
		$this->type="password";
	}

}

class NSStaticTextField extends NSView
{
	public $stringValue;
	public function NSStaticTextField($stringValue = "")
	{
       		parent::__construct();
		$this->stringValue=$stringValue;
	}
	public function draw()
		{
		parent::draw();
		echo htmlentities($this->stringValue);
		}
}

class NSTextView extends NSView
{
	public $string="";
	public $width;
	public $height;
	public function NSTextView($width = 80, $height = 20)
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
		echo htmlentities($this->stringValue);
		echo "</textarea>\n";
		}
}

class NSWindow
{
	public $title;
	public $contentView;
	public function contentView() { return $this->contentView; }
	public function setContentView($view) { $this->contentView=$view; }
	public function NSWindow($newtitle = "QuantumSTEP Cloud")
		{
		global $NSApp;
// echo "NSWindow $newtitle<br>";
		$this->title=$newtitle;
		$this->setContentView(new NSView());
		if(!$NSApp->mainWindow)
			$NSApp->mainWindow=$this;
// print_r($NSApp);
		}
	public function sendEvent($event)
		{
// print_r($event);
		$this->contentView->sendEvent($event);
		}
	public function display() 
		{
		global $NSApp;
		echo "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">\n";
		echo "<html>\n";
		echo "<head>\n";
		echo "<meta http-equiv=\"content-type\" content=\"text/html; charset=ISO-8859-1\">\n";	// sollte UTF8 sein!
		// meta content generator...
		echo "<title>".htmlentities($this->title)."</title>\n";
		echo "</head>\n";
		echo "<body";
//		parameter("bgcolor", "grey");
		echo ">\n";
		if(isset($NSApp->mainMenu))
			$NSApp->mainMenu->draw();
		echo "<form method=\"POST\">\n";	// a window is a big form to handle all input/output through POST (and GET)
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
	public static $knownApplications;
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
//					echo "$dir/$bundle<br>";
					if(substr($bundle, -4) == ".app")
						{ // candidate
						// check for bundle
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
	public static function fullPathForApplication($name)
		{
		NSWorkspace::knownApplications();
//		echo "$name<br>";
		$app=self::$knownApplications[$name];
		if(isset($app))
			return $app["NSApplicationPath"];
		echo "fullPathForApplication:$app not found<br>";
		print_r(self::$knownApplications);
		return $app;
		}
	public static function iconForFile($path)
		{
		return NSImageView::imageNamed("NSApplication");	// default
		// check if that is a bundle -> get through Info.plist / bundle
		// $bundle->objectForInfoDictionaryKey('CFBundleIconFile');
		// else find application by suffix
		}
	public static function openFile($file)
		{
		}
}

// EOF
?>