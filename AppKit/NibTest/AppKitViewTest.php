<?php

$GLOBALS['debug']=isset($_GET['DEBUG']) && (strcasecmp($_GET['DEBUG'], "yes") == 0);

// don't touch
global $ROOT;
$ROOT=preg_replace('|(.*/)(QuantumSTEP/)(.*)|i', '$1$2', __FILE__);

require_once "$ROOT/System/Library/Frameworks/AppKit.framework/Versions/Current/php/AppKit.php";
require_once "$ROOT/System/Library/Frameworks/Message.framework/Versions/Current/php/Message.php";

class AppController extends NSObject
{
	public $mainWindow;
	public $to;
	public $subject;
	public $body;
	public $status;
	public $tableInTab;

	public function checkAddress(NSObject $sender)
		{
		$status=NSMailDelivery::isEmailValid($this->to->stringValue());
		$this->status->setStringValue($status?"Address Valid":"Address Not Valid");
		}

	public function sendTheMail(NSObject $sender)
		{
		$status=NSMailDelivery::deliverMessageSubjectTo($this->body->string(), $this->subject->stringValue(), $this->to->stringValue());
		$this->status->setStringValue($status?"Mail Sent":"Mail Not Sent");
		}

	public function buttonPressed(NSObject $sender)
		{
// _NSLog("button pressed: ".$sender->classString()." title=".$sender->title());
		$this->status->setStringValue($sender->title());
		}

	public function matrixPressed(NSMatrix $sender)
		{
		$this->status->setStringValue("Matrix ".$sender->selectedRow()." / ".$sender->selectedColumn());
		}

	public function numberOfRowsInTableView(NSTableView $table)
		{
		if($table == $this->tableInTab)
			return 6;
		return 5;
		}

	public function tableView_objectValueForTableColumn_row(NSTableView $table, NSTableColumn $column, $row)
		{
		if($table == $this->tableInTab)
			{
			switch($column->identifier())
				{
				case "a":
					$values=NSUserDefaults::standardUserDefaults()->objectForKey("values");
					if(!is_null($values) && isset($values[$row]))
						return $values[$row];
					break;
				case "b":
					break;
				case "c":
					return ($row%2) == 0?"1":"0";
				}
			}
		return $column->identifier()." ".$row;
		}

	public function tableView_setObjectValue_forTableColumn_row(NSTableView $table, $value, NSTableColumn $column, $row)
		{
		if($table == $this->tableInTab)
			{
			}
		$values=NSUserDefaults::standardUserDefaults()->objectForKey("values");
		if(is_null($values))
			$values=array();
		$values[$row]=$value;
		NSUserDefaults::standardUserDefaults()->setObjectForKey("values", $values);
		}

	public function tableViewSelectionDidChange(NSTableView $tableView)
		{
		$this->status->setStringValue("Table selection: ".$tableView->selectedColumn()." / ".$tableView->selectedRow());
		}

	function didFinishLoading()
		{

		$GLOBALS['NSApp']->setMainMenu(null);	// no main menu

		$this->mainWindow=new NSWindow("Mail");

		$grid=new NSCollectionView(2);
		$this->mainWindow->contentView()->addSubview($grid);

		/* editable text field with specific name */
		$tf=new NSTextField();
		$tf->setAttributedStringValue("To:");
		$grid->addSubview($tf);
		$this->to=new NSTextField();
		$this->to->setName("to");
		$grid->addSubview($this->to);

		/* editable text field without specific name */
		$tf=new NSTextField();
		$tf->setAttributedStringValue("Subject:");
		$grid->addSubview($tf);
		$this->subject=new NSTextField();
//		$this->subject->setName("subject");
		$grid->addSubview($this->subject);

		/* editable multi-line text view */
		$tf=new NSTextField();
		$tf->setAttributedStringValue("Message:");
		$grid->addSubview($tf);
		$this->body=new NSTextView();
		$grid->addSubview($this->body);

		$grid=new NSCollectionView(3);
		$this->mainWindow->contentView()->addSubview($grid);

		/* buttons for handling mail */
		$button=new NSButton();
		$button->setTitle("Check Address");
		$button->setActionAndTarget('checkAddress', $this);
		$grid->addSubview($button);

		$button=new NSButton();
		$button->setTitle("Send Mail");
		$button->setActionAndTarget('sendTheMail', $this);
		$grid->addSubview($button);

		/* non-editable status field - updated by buttons */
		$this->status=new NSTextField();
		$this->status->setAttributedStringValue("New Mail");
		$grid->addSubview($this->status);

		/* radio buttons and checkboxes */
		$button=new NSButton();
		$button->setButtonType("Radio");
		$button->setTitle("Radio");
		$button->setActionAndTarget('buttonPressed', $this);
		$grid->addSubview($button);

		$button=new NSButton();
		$button->setButtonType("CheckBox");
		$button->setTitle("CheckBox");
		$button->setActionAndTarget('buttonPressed', $this);
		$grid->addSubview($button);

		$button=new NSButton();
		$button->setButtonType("CheckBox");
		$button->setTitle("Mixed");
		$button->setAllowsMixedState(true);
		$button->setActionAndTarget('buttonPressed', $this);
		$grid->addSubview($button);

		/* buttons with actions and/or links */
		$button=new NSButton();
		$button->setTitle("Local");
		$button->setActionAndTarget('buttonPressed', $this);
		$grid->addSubview($button);

		$button=new NSButton();
		$button->setTitle("No target");
		$button->setActionAndTarget('buttonPressed', null);
		$grid->addSubview($button);

		$button=new NSButton();
		$button->setTitle("Link");
		$button->setActionAndTarget('index.html', 'http://www.goldelico.com');
		$grid->addSubview($button);

		/* popupbutton */
		$v=new NSPopUpButton();
		$grid->addSubview($v);
		$v->addItemWithTitle("item 1");
		$v->addItemWithTitle("item 2");
		$v->addItemWithTitle("item 3");
		$v->setActionAndTarget('buttonPressed', $this);

		/* tab view */
		$v=new NSTabView();
		$grid->addSubview($v);
		/* embedded action buttons - are the actions sent correctly? */
		$c=new NSButton();
		$c->setTitle("first Button");
		$c->setActionAndTarget('buttonPressed', $this);
		$v->addTabViewItem(new NSTabViewItem("1", $c));
		$c=new NSButton();
		$c->setTitle("second Button");
		$c->setActionAndTarget('buttonPressed', $this);
		$v->addTabViewItem(new NSTabViewItem("2", $c));
		/* embedded popupbutton - does it persist if hidden? */
		$c=new NSPopUpButton();
		$c->setActionAndTarget('buttonPressed', $this);
		$c->addItemWithTitle("tab item 1");
		$c->addItemWithTitle("tab item 2");
		$c->addItemWithTitle("tab item 3");
		$v->addTabViewItem(new NSTabViewItem("3", $c));
		/* embedded text field - does it persist if hidden? */
		$c=new NSTextField();
		$v->addTabViewItem(new NSTabViewItem("4", $c));
		/* embed a table */
		$c=new NSTableView(array("a", "b", "c"));
		$this->tableInTab=$c;
		$c->setDataSource($this);
		$c->setDelegate($this);
		$c->setAllowsColumnSelection(true);
		foreach($c->columns() as $column)
			$column->setEditable(false);
		$c->columns()[0]->setEditable(true);	// make first column editable
		$c->columns()[2]->setDataCell(new NSButton("value", "CheckBox"));	// make checkbox
		$v->addTabViewItem(new NSTabViewItem("5", $c));
		/* embedded Matrix with Radio Buttons */
		$c=new NSMatrix(2);
		$c->setMode("NSRadioModeMatrix");
		$c->setActionAndTarget('matrixPressed', $this);
		for($row=0; $row<2; $row++)
			for($col=0; $col<2; $col++)
				{
				$button=new NSButton("radio $row/$col", "Radio");
				$c->addSubview($button);
				}
		$v->addTabViewItem(new NSTabViewItem("6", $c));
		/* embedded Matrix with Checkboxes */
		$c=new NSMatrix(2);
		$c->setActionAndTarget('matrixPressed', $this);
		for($row=0; $row<2; $row++)
			for($col=0; $col<2; $col++)
				{
				$button=new NSButton("check $row/$col", "CheckBox");
				$c->addSubview($button);
				}
		$v->addTabViewItem(new NSTabViewItem("7", $c));

		/* another popupbutton to check if they act independently */
		$v=new NSPopUpButton();
		$grid->addSubview($v);
		$v->addItemWithTitle("right 1");
		$v->addItemWithTitle("right 2");
		$v->addItemWithTitle("right 3");
		$v->addItemWithTitle("right 4");
		$v->setActionAndTarget('buttonPressed', $this);

		/* invisible text field */
		$button=new NSTextField();
		$button->setAttributedStringValue("");
		$grid->addSubview($button);

		/* a table which allows column selection */
		$v=new NSTableView(array("first", "second", "third"));
		$v->setDataSource($this);
		$v->setDelegate($this);
		$v->setAllowsColumnSelection(true);
		foreach($v->columns() as $column)
			$column->setEditable(false);
		$grid->addSubview($v);
		}
	}

NSApplicationMain("AppKitViewTest");

// EOF
?>