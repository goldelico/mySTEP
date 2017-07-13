<?php

	/*
	 * CoreDataBaseGUI.framework
	 * (C) Golden Delicious Computers GmbH&Co. KG, 2013
	 * All rights reserved.
	 */

global $ROOT;	// must be set by some .app
require_once "$ROOT/System/Library/Frameworks/CoreDataBase.framework/Versions/Current/php/CoreDataBase.php";
require_once "$ROOT/System/Library/Frameworks/AppKit.framework/Versions/Current/php/AppKit.php";

if($GLOBALS['debug']) echo "<h1>CoreDataBaseGUI.framework</h1>";

class DBRecordView extends NSCollectionView
	{
	protected $db;
	protected $table;
	protected $key;
	protected $selectedRow;
	protected $data;
	protected $dirty=false;
	protected $columns=array();
	protected $views=array();
	protected $labels=array();

	function db() { return $this->db; }
	function table() { return $this->table; }
	function columns() { return $this->columns; }
	function key() { return $this->key; }
	function label($column) { return $this->labels[$column]; }
	function view($column) { return $this->views[$column]; }

	function __construct($db, $table, $key)
		{
		parent::_construct(3);
		$this->db=$db;
		$this->table=$table;
		$this->key=$key;
		}

	function addTextField($label, $column, $readonly=false)
		{
		$this->column =$column;
		$v=new NSTextField();
		$v->setStringValue($label);
		$this->addSubview($v);
		$this->labels[]=$v;
		$this->labels[$column]=$v;
		$v=new NSTextField(20);
		$v->setEditable(!$readonly);
		$this->addSubview($v);
		$this->views[]=$v;
		$this->views[$column]=$v;
		$this->columns[]=$column;
		$v=new NSTextField();
		$this->addSubview($v);
		}

	function addTextView($label, $column, $readonly=false)
		{
		$this->column =$column;
		$v=new NSTextField();
		$v->setStringValue($label);
		$this->addSubview($v);
		$this->labels[]=$v;
		$this->labels[$column]=$v;
		$v=new NSTextView(20);
		$v->setEditable(!$readonly);
		$this->addSubview($v);
		$this->views[]=$v;
		$this->views[$column]=$v;
		$this->columns[]=$column;
		$v=new NSTextField();
		$this->addSubview($v);
		}

	function addPopup($label, $column, $values, $readonly=false)
		{
		$this->column =$column;
		$v=new NSTextField(20);
		$v->setStringValue($label);
		$this->addSubview($v);
		$this->labels[]=$v;
		$this->labels[$column]=$v;
		$v=new NSPopupButton($values);
		$v->setEditable(!$readonly);
		$this->addSubview($v);
		$this->views[]=$v;
		$this->views[$column]=$v;
		$this->columns[]=$column;
		$v=new NSTextField();
		$this->addSubview($v);
		}

	function addDateField($label, $column)
		{
		}

	function addChangeButton()
		{ // adds Save button (must be last element added)
		$v=new NSButton();
		$v->setTitle("Save");
		$v->setActionAndTarget('save', $this);
		$this->addSubview($v);
		}

	function row($row)
		{ // if different row - switch and save before
		if(!isset($this->data) || $row != $this->selectedRow)
			{
			$this->save();	// save previous row
			$query="SELECT * FROM ".quoteIdent($this->table)." WHERE ".quoteIdent($this->key)." = ".quoteIdent($row);
			$db->query($query, $error);
			// get rowData
			$this->selectedRow=$row;
			}
		return $this->data;
		}

	function setValue($column, $value)
		{
		if($this->data[$column] === $value)
			return;	// no change
		$this->data[$column]=$value;
		$this->dirty=true;
		}

	function save(NSResponder $sender=null)
		{
		if($this->dirty)
			{
			// UPDATE/INSERT all rows
			$this->dirty=false;
			}
		}

	function selectRow($row)
		{
		if(isset($this->data))
			{
			foreach($this->columns as $column)
				{
				$this->data[$column]=$this->views[$column]->stringValue();	// fetch any GUI changes
				$this->dirty=true;			
				}
			$this->save(null);	// save any changes to previous row
			}
		$r=$this->row($row);	// fetch new row
		foreach($this->columns as $column)
			{
			$this->views[$column]->setStringValue($row);	// show values from selected row
			}
		}
	}

// use example
if(false)
	{
	$product=new DBRecordView($shop, "shop_products", "uuid");
	$product->addTextField("uuid", "uuid", true);
	$product->addTextField("SKU", "number");
	$product->addTextField("Product", "product");
	$product->addTextField("Vendor", "vendor");
	$product->addTextView("Description", "long_description");
	// more...
	$product->addSaveButton();

	$tabView->addTabViewItem();
	}

?>
