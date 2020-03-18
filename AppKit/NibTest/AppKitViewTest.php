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

	public function numberOfRowsInTableView(NSTableView $table)
		{
		return 5;
		}

	public function tableView_objectValueForTableColumn_row(NSTableView $table, NSTableColumn $column, $row)
		{
		return $column->identifier()." ".$row;
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
//	$this->subject->setName("subject");
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
	$v->setAllowsColumnSelection(true);
	foreach($v->columns() as $column)
		$column->setEditable(false);
	$grid->addSubview($v);
	}
}

NSApplicationMain("Zeiterfassung");

// EOF
?>