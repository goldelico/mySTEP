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
// how can we pass arbitrary parameters to their NSApplication $argv???
		header("location: https://".$_SERVER['HTTP_HOST']."/$app/Contents/php/executable.php");
		exit;
		}
	public function terminate()
		{
		$this->open("Cloudtop.app");
		}
	public function run()
		{
		// dispatch event(s)
// print_r($this);
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
{ // abstract superclass
	public $subviews = array();
	public $autoResizing;
	public function subviews() { return $this->subviews; }
	public function addSubview($view) { $this->subviews[]=$view; }
	public function draw()
		{
		foreach($this->subviews as $view)
			$view->draw();
		}
}

class NSImageView extends NSView
{
	public $name;
	public $width=32;
	public $height=32;
	public function NSImageView($name)
		{
		$this->name="images/".$name.".png";	// default name
		}
	public function setName($name) { $this->name=$name; }
	public function draw()
		{
		parent::draw();
		echo "<img src=\"";
		echo htmlentities($this->name);
		echo "\" style=\"{ width:".htmlentities($this->width).", height:".htmlentities($this->height)."}\">\n";
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
		$this->columns=$cols;
		$this->content=$items;
// echo "NSCollectionView $cols<br>";
		}
	public function draw()
		{
		parent::draw();
		echo "<table border=\"";
		echo $this->border;
		echo "\" width=\"";
		echo $this->width;
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
	public $border=0;
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
		$this->tabViewItems=$items;
		// echo "NSTabView $cols<br>";
		}
	public function draw()
		{
		parent::draw();
		echo "<table border=\"";
		echo $this->border;
		echo "\" width=\"";
		echo $this->width;
		echo "\">\n";
		echo "<tr>";
		echo "<td>";
		foreach($this->tabViewItems as $item)
			{ // add tab buttons and switching logic
			if($item == $this->selectedTabViewItem())
				echo "<span color=green>";
			else
				echo "<span color=red>";
			echo htmlentities($item->label);
			echo "<span> ";
			}
		echo "</td>";
		echo "</tr>";
		echo "<tr>";
		echo "<td align=\"center\">\n";
		$selectedItem=$this->tabViewItems[$this->selectedIndex];
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
	public function setDataSource($source) { $this->dataSource=$source; }
	public function setHeaders($headers) { $this->headers=$headers; }
	public function setBorder($border) { $this->border=0+$border; }
	
	// allow to define colspan and rowspan objects
	// allow to modify alignment
	
	public function NSTableView($headers=array())
		{
		$this->headers=$headers;
		}
	public function draw()
		{
		parent::draw();
		echo "<table border=\"";
		echo $this->border;
		echo "\" width=\"";
		echo $this->width;
		echo "\">\n";
		echo "<tr>";
		// columns should be NSTableColumn objects that define alignment, identifier, title, sorting etc.
		foreach($this->headers as $header)
			{
			echo "<th>";
			echo htmlentities($header);
			echo "</th>\n";
			}
		echo "</tr>\n";
		$rows=$this->dataSource->numberOfRows();
		for($row=0; $row<$visibleRows; $row++)
			{
			echo "<tr>";
			foreach($this->headers as $column)
				{
				// handle alternating colors
				echo "<td>\n";
				if($row < $rows)
					{ // ask delegate for the item to draw
					$item=$this->dataSource->tableView_objectValueForTableColumn_row($this, $column, $row);
					$item->draw();					
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
// echo "NSButton $newtitle<br>";
	$this->title=$newtitle;
		}
	public function draw()
		{
		parent::draw();
		echo "<input type=\"submit\" name=\"";
		echo rawurlencode("name");
		echo "\" value=\"";
		echo htmlentities($this->title);
		echo "\">\n";
		}
}

// checkbox, radiobutton

class NSTextField extends NSView
{
	public $stringValue;
	public $backgroundColor;
	public $align;
	public $type="text";
	public $width;
// get current value from stored cookie
	public function NSTextField($width=30, $stringValue = "")
	{
	$this->stringValue=$stringValue;
	$this->width=$width;
	}
	public function draw()
		{
		parent::draw();
		echo "<input type=\"".$this->type."\" size=\"".$this->width."\" name=\"";
		echo rawurlencode("name");
		echo "\" value=\"";
		echo htmlentities($this->stringValue);
		echo "\">\n";
		}
}

class NSSecureTextField extends NSTextField
{
	public function NSSecureTextField($width=30)
	{
	parent::NSTextField($width);
	$this->type="password";
	}

}

class NSStaticTextField extends NSView
{
	public $stringValue;
	public function NSStaticTextField($stringValue = "")
	{
	$this->stringValue=$stringValue;
	}
	public function draw()
		{
		parent::draw();
		echo htmlentities($this->stringValue);
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

// EOF
?>