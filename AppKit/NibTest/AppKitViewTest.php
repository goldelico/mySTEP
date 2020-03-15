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
_NSLog("button pressed: ".$sender->classString()." title=".$sender->title());
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
	$tf=new NSTextField();
	$tf->setAttributedStringValue("To:");
	$grid->addSubview($tf);
	$this->to=new NSTextField();
	$grid->addSubview($this->to);

	$tf=new NSTextField();
	$tf->setAttributedStringValue("Subject:");
	$grid->addSubview($tf);
	$this->subject=new NSTextField();
	$grid->addSubview($this->subject);

	$tf=new NSTextField();
	$tf->setAttributedStringValue("Message:");
	$grid->addSubview($tf);
	$this->body=new NSTextView();
	$grid->addSubview($this->body);

	$this->mainWindow->contentView()->addSubview($grid);

	$grid=new NSCollectionView(3);

	$button=new NSButton();
	$button->setTitle("Check Address");
	$button->setActionAndTarget('checkAddress', $this);
	$grid->addSubview($button);

	$button=new NSButton();
	$button->setTitle("Send Mail");
	$button->setActionAndTarget('sendTheMail', $this);
	$grid->addSubview($button);

	$this->status=new NSTextField();
	$this->status->setAttributedStringValue("New Mail");
	$grid->addSubview($this->status);

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

	$v=new NSPopUpButton();
	$grid->addSubview($v);
	$v->addItemWithTitle("item 1");
	$v->addItemWithTitle("item 2");
	$v->addItemWithTitle("item 3");
	$v->setActionAndTarget('buttonPressed', $this);

	$v=new NSTabView();
	$grid->addSubview($v);
	$c=new NSButton();
	$c->setTitle("first Button");
	$c->setActionAndTarget('buttonPressed', $this);
	$v->addTabViewItem(new NSTabViewItem("1", $c));
	$c=new NSButton();
	$c->setTitle("second Button");
	$c->setActionAndTarget('buttonPressed', $this);
	$v->addTabViewItem(new NSTabViewItem("2", $c));

	$v=new NSPopUpButton();
	$grid->addSubview($v);
	$v->addItemWithTitle("right 1");
	$v->addItemWithTitle("right 2");
	$v->addItemWithTitle("right 3");
	$v->addItemWithTitle("right 4");
	$v->setActionAndTarget('buttonPressed', $this);

	$button=new NSTextField();
	$button->setAttributedStringValue("");
	$grid->addSubview($button);

	$v=new NSTableView(array("first", "second", "third"));
	$v->setDataSource($this);
	foreach($v->columns() as $column)
		$column->setEditable(false);
	$grid->addSubview($v);

	$this->mainWindow->contentView()->addSubview($grid);

	}
}

NSApplicationMain("Zeiterfassung");

// EOF
?>