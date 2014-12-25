<?php
	/*
	 * PDFKit.framework
	 * (C) Golden Delicious Computers GmbH&Co. KG, 2012
	 * All rights reserved.
	 */

global $ROOT;	// must be set by some .app
require_once "$ROOT/System/Library/Frameworks/Foundation.framework/Versions/Current/php/Foundation.php";

if($GLOBALS['debug']) echo "<h1>PDFKit.framework</h1>";

// how can we draw into a PDFPage?

class PDFPage extends NSObject
{
	private $document;	// reference to owning document

	public function dataRepresentation()
	{
		return "data";
	}

}

class PDFDocument extends NSObject
{
	private $pages;

	// constructor/destructor($document)

	public function dataRepresentation()
	{
		// collect from all pages
		return "data";
	}

	public function exchangePageAtIndexWithPageAtIndex($i1, $i2)
	{
		$temp=$this->pages[$i1];
		$this->pages[$i1]=$this->pages[$i2];
		$this->pages[$i2]=$temp;
	}

	public function indexForPage($page)
	{
		// search
	}

	public function insertPageAtIndex:($page, $index)
	{
	}

	public function pageAtIndex($index)
	{
		return $this->pages[$index];
	}

	public function pageCount()
	{
		return count($this->pages);
	}

	function removePageAtIndex($index)
	{
	}

}

// EOF
?>
