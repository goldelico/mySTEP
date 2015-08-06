<?php
	/*
	 * PDFKit.framework
	 * (C) Golden Delicious Computers GmbH&Co. KG, 2012
	 * All rights reserved.
	 */

global $ROOT;	// must be set by some .app
require_once "$ROOT/System/Library/Frameworks/AppKit.framework/Versions/Current/php/AppKit.php";
require_once "$ROOT/Internal/Frameworks/EzPDF.framework/Versions/Current/php/class.Cpdf.php";
// require_once "$ROOT/Internal/Frameworks/EzPDF.framework/Versions/Current/php/class.ezpdf.php";

if($GLOBALS['debug']) echo "<h1>PDFKit.framework</h1>";

// FIXME: handle Unicode translation

const para="\247";	// paragraph
const ae="\344";
const oe="\366";
const ue="\374";
const ss="\337";
const AE="\304";
const OE="\326";
const UE="\334";
// const eur="\200"; // there is no EUR symbol in ISO Latin-1
const eur="EUR";

class PDFPage extends NSObject
{
	private static $ezpdf;
	private $document;	// reference to owning document
	private $angle=0.0;
	private $fontSize=12.0;
	private $justification='left';
	private $lineSpacing=1.1;

	public function document() { return $this->document; }

	public function initWithDocument(PDFDocument $document)
	{ // override to add background for all pages
		$this->document=$document;
		if(!isset(self::$ezpdf))
			self::$ezpdf=new Cpdf($document->pageSize());
		else
			self::$ezpdf->newPage();
		return $this;
	}

	function selectFont($fontName)
	{ // try to handle UNICODE encoding
		$b=NSBundle::bundleForClass('Cpdf');	// locate font description file in Ezpdf.framework bundle
		$fpath=$b->pathForResourceOfType($fontName, "afm");
		if(is_null($fpath))
			{
			_NSLog("can't find font metrics: $fontName");
			return;
			}
		$fpath=NSFileManager::defaultManager()->stringWithFileSystemRepresentation($fpath);	// use internal representation
		self::$ezpdf->selectFont($fpath, array(/*"encoding"=>"StandardEncoding",*/ "differences" => array((eur+0) => "Euro")));
	}

	function setColor(NSColor $color)
	{
		self::$ezpdf->setColor($color->r(), $color->g(), $color->b());
	}

	function setStrokeColor(NSColor $color)
	{
		self::$ezpdf->setStrokeColor($color->r(), $color->g(), $color->b());
	}

	// we could implement NSBezierPath to store control points and line styles

	function strokeLine($start, $end)	// NSPoints
	{
		self::$ezpdf->line(NSMinX($start), NSMinY($start), NSMinX($end), NSMinY($end));
	}

	function setLineStyle($width=1, $cap='', $join='', $dash='', $phase=0)
	{
		self::$ezpdf->setLineStyle($width, $cap, $join, $dash, $phase);
	}

	function getFontHeight()
	{
		return self::$ezpdf->getFontHeight(1.0);
	}

	function getFontDecender()
	{
		return self::$ezpdf->getFontDecender(1.0);
	}

	function setAngle($angle=0.0)
	{
		$this->angle=$angle;
	}

	function setJustification($justification='left')
	{
		$this->justification=$justification;
	}

	function setFontSize($fontSize=12.0)
	{
		$this->fontSize=$fontSize;
	}

	function setLineSpacing($lineSpacing=1.1)
	{
		$this->lineSpacing=$lineSpacing;
	}

	function widthOfText($text)
	{
		return self::$ezpdf->getTextWidth($this->fontSize, $text);
	}

	// handle attributed strings to define line spacing, fonts etc.

	function drawTextAtPoint($text, $rect /* , $attributes */)
	{ // draw limited to rect (which may specify <=0 width or height for 'unlimited') and return new $y position
		// FIXME: can we return still unprinted text if height limit is reached?
		// can we simply modify the returned rect to show the still available subrect?
		$width=NSWidth($rect);
		$height=NSHeight($rect);
		if($width <= 0.0) $width=99999999.9;
		if($height <= 0.0) $height=99999999.9;
		$lines=explode("\n", $text);
		$y=NSMinY($point);
		for($i=0; $i<count($lines); $i++)
			{
			$line=$lines[$i];
			while(true)
				{
				if($y >= NSMinY($point)+$height)
					{ // no room
					$lines[$i]=$line;	// what is not printed on this line
					break;
					}
				$line=$pdf->addTextWrap(NSMinX($point), $y, $width, $this->fontSize, $line, 0.0);
				$y -= $this->lineSpacing*$this->fontSize;
				if(!$line)
					break;	// done
				}
			}
		if(NSHeight($rect) > 0)
			$rect['height']-=$y-NSMinY($rect);	// reduce by amount we have printed
		$rect['y']=$y;	// next line
		return implode("\n", array_slice($lines, $i));	// return what has not been processed
	}

	function drawImageInRect(NSImage $image, $rect)
	{
		$data=$image->_gd();	// GD reference
		$size=$image->size();
		$width=NSWidth($rect);
		$height=NSHeight($rect);
		self::$ezpdf->addImage($data, NSMinX($rect), NSMinY($rect), NSWidth($rect), NSHeight($rect), $width, $height);
	}

	public static function dataRepresentation()
	{
// _NSLog(self::$ezpdf);
		return self::$ezpdf->output();
	}
}

function cm2pt($cm)
{
	return $cm*72/2.54;
}

class PDFDocument extends NSObject
{
	private $pages;
	private $size;

	public function __construct()
	{
		parent::__construct();
		$this->pages=new NSMutableArray();
	}

	public function __destruct()
	{
		parent::__destruct();
	}

	public function dataRepresentation()
	{
		return PDFPage::dataRepresentation();
	}

	public function exchangePageAtIndexWithPageAtIndex($i1, $i2)
	{
		$this->pages->exchangeObjectAtIndexWithObjectAtIndex($i1, $i2);
	}

	public function indexForPage(PDFPage $page)
	{
		return $this->pages->indexForObject($page);
	}

	public function insertPageAtIndex(PDFPage $page, $index)
	{
		$this->pages->insertObjectAtIndex($page, $index);
	}

	public function pageAtIndex($index)
	{
		return $this->pages->objectAtIndex($index);
	}

	public function pageCount()
	{
		return $this->pages->count();
	}

	function removePageAtIndex($index)
	{
		return $this->pages->removeObjectAtIndex($index);
	}

	function pageClass()
	{
		return "PDFPage";
	}

// PDF generator

	function startNewPage()
	{
		$pclass=$this->pageClass();
		$page=new $pclass;
		$page=$page->initWithDocument($this);
		$this->insertPageAtIndex($page, $this->pageCount());	// append new page
	}

	function pageSize()
	{
		return $this->pageSize;
	}

	function setPageSize($size)
	{
		return $this->pageSize=$size;
	}

}

class PDFView extends NSView
{ // FIXME: do we really need this class to view a single PDF page?
	protected $document;
	protected $currentPage;

	public function document() { return $this->document; }
	public function setDocument(PDFDocument $doc) { $this->document=$doc; }
}

// EOF
?>
