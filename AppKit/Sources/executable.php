<?php
/*
 * AppKit.framework
 * (C) Golden Delicious Computers GmbH&Co. KG, 2012
 * All rights reserved.
 *
 * defines (simple) classes for NSWindow, NSView, NSButton, NSTextField, NSSecureTextField, NSForm, NSImage, NSTable, NSPopUpButton
 * draw method generates html output
 * hitTest, sendEvent and mouseDown called when button is clicked or something modified
 */

if($_SERVER['SERVER_PORT']!=443)
{ // reload page as https
	if($_SERVER['REQUEST_URI'] == "" || $_SERVER['REQUEST_URI'] == "/")
		header("location: https://".$_SERVER['HTTP_HOST']."/");
	else
		header("location: https://".$_SERVER['HTTP_HOST']."/".$_SERVER['REQUEST_URI']);
	exit;
}

require "$ROOT/System/Library/Frameworks/Foundation.framework/Versions/Current/php/executable.php";		

function parameter($name, $value)
{
	echo " $name=\"".$value."\"";
}
// check if login is required to run the App

class NSApplication
{
	public $name;
	public $argv;	// arguments (?)
	public $delegate;
	public $mainWindow;
	// FIXME: this belongs to NSWorkspace!?!
	public function open($app)
		{ // switch to a different app
		// search App in different locations
		$dir="System/Library/CoreServices";
// use NSBundle
		$bundle="$dir/$app";
// ask $bundle->executablePath;
		$executablePath="https://".$_SERVER['HTTP_HOST']."/$bundle/Contents/php/executable.php";
// how can we pass arbitrary parameters to their NSApplication $argv???
		header("location: ".$executablePath);	// how to handle special characters here? rawurlencode?
		exit;
		}
	public function terminate()
		{
		$this->open("Cloudtop.app");
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
// FIXME: wir mŸssen die View-Hierarchie zweimal durchlaufen!
// zuerst die neuen $_POST-Werte in die NSTextFields Ÿbernehmen
// und dann erst den NSButton-action aufrufen
// sonst hŠngt es davon ab wo der NSButton in der Hierarchie steht ob die Felder Werte haben oder nicht
		$this->mainWindow->sendEvent($_POST);
		$this->mainWindow->display();
		}
}

global $NSApp;
	
function NSApplicationMain($name)
{
	global $NSApp;
	$NSApp = new NSApplication;
	$NSApp->name=$name;
	// set $NSApp->argv
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
		global $elementNumber;	// unique number
		$this->elementName="NSView-".(++$elementNumber);
		}
	public function draw()
		{
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

class NSImageView extends NSView
{
	public $name;
	public $width=32;
	public $height=32;
	public function NSImageView($name)
		{
       		parent::__construct();
		$this->name="images/".$name.".png";	// default name
		}
	public function setName($name) { $this->name=$name; }
	public function draw()
		{
		parent::draw();
		echo "<img";
		parameter("src", htmlentities($this->name));
		parameter("style", "{ width:".htmlentities($this->width).", height:".htmlentities($this->height)."}");
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
	public $view;
	public $label;
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
	public function tabViewItems() { return $this->tabViewItems; }
	public function addTabViewItem($item) { $this->tabViewItems[]=$item; }
	public function selectedTabViewItem() {	return $this->tabViewItems[$this->selectedIndex]; }
	public function indexOfSelectedTabViewItem() { return $this->selectedIndex; }
	public function selectTabViewItemAtIndex($index) { $this->selectedIndex=$index; }
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
/*
			if($item == $this->selectedTabViewItem())
				echo "<span color=green>";
			else
				echo "<span color=red>";
			echo htmlentities($item->label);

			echo "</span> ";
			echo "</button>";
*/
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
		echo "<body>\n";
		// horizontal Menu bar
		// add QuantumSTEP-Icon for the system menu
		echo "<h2>".htmlentities($NSApp->name)."<font size=-1> | Files | Edit | Windows | Help</font>"."</h2>\n";
		echo "<form method=\"POST\">\n";	// a window is a big form to handle all input/output through POST (and GET)
		// add App-Icon, menu/status bar
		$this->contentView->draw();
		// add footer (Impressum, Version etc.)
		echo "</form>\n";
		echo "</body>\n";
		echo "</html>\n";
	}
}

class WebView extends NSView
{
	public $url;
	public function WebView($url = "https://www.quantumstep.eu")
		{
       		parent::__construct();
		$this->url=$url;
		}
// set URL, set stringValue,  setHTML
	public function draw()
		{
		parent::draw();
		echo "<iframe";
		paramter("src", rawurlencode($this->url));
		paramter("width", "100%");
		paramter("height", "100%");
		echo ">\n";
		echo "<a";
		parameter("href", rawurlencode($this->url));
		echo ">Link</a>";
		echo "<iframe>\n";
		}
}

// EOF
?>