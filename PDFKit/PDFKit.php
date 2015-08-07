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
			{
			$ps=$document->pageSize();
			self::$ezpdf=new Cpdf(array(NSMinX($ps), NSMinY($ps), NSWidth($ps), NSHeight($ps)));
			$this->setFont('Helvetica');
			}
		else
			self::$ezpdf->newPage();
		return $this;
	}

	function setFontSize($fontSize=12.0)
	{
		$this->fontSize=$fontSize;
	}

	function setFont($fontName)
	{ // try to handle UNICODE encoding
		$b=NSBundle::bundleForClass('Cpdf');	// locate font description file in Ezpdf.framework bundle
		$fpath=$b->pathForResourceOfType("fonts/$fontName", "afm");
		if(!$fpath)
			{
			_NSLog("can't find font metrics: $fontName");
			return;
			}
// _NSLog("fpath $fpath");
		$fpath=NSFileManager::defaultManager()->fileSystemRepresentationWithPath($fpath);	// use internal representation
// _NSLog("fpath $fpath");
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

	function setLineSpacing($lineSpacing=1.1)
	{
		$this->lineSpacing=$lineSpacing;
	}

	function widthOfText($text)
	{
		return self::$ezpdf->getTextWidth($this->fontSize, $text);
	}

	// handle attributed strings to define line spacing, fonts etc.

	function drawTextAtPoint($text, &$rect /* , $attributes */)
	{ // draw limited to rect (which may specify <=0 width or height for 'unlimited') and return new $y position by reference
// _NSLog("drawTextAtPoint: $text");
// _NSLog($rect);
		$width=NSWidth($rect);
		$height=NSHeight($rect);
		if($width <= 0.0) $width=99999999.9;
		if($height <= 0.0) $height=99999999.9;
		$lines=explode("\n", $text);
		$py=NSHeight($this->document->pageSize());
		$x=NSMinX($rect);
		$ymin=$y=$py-NSMinY($rect);	// flip coordinates: take (0,0) as top left corner of paper
		for($i=0; $i<count($lines); $i++)
			{
			$line=$lines[$i];
			while(true)
				{
// _NSLog(($y-$this->fontSize)." ".($ymin-$height));
				if($y-$this->fontSize < $ymin-$height)
					{ // no room for another line
					$lines[$i]=$line;	// what is not printed on this line
					break;
					}
// _NSLog("addTextWrap x=$x y=$y w=$width s=$this->fontSize l=$line j=$this->justification a=$this->angle");
				$line=self::$ezpdf->addTextWrap($x, $y, $width, $this->fontSize, $line, $this->justification, $this->angle);
				$y -= $this->lineSpacing*$this->fontSize;
				if($line == "")
					break;	// done with this line
				}
			}
		if(NSHeight($rect) > 0)
			$rect['height']-=$y-NSMinY($rect);	// reduce by amount we have printed
		$rect['y']=$py-$y;	// where next line can start
		return implode("\n", array_slice($lines, $i));	// return text that has not been processed
	}

	function drawImageInRect(NSImage $image, $rect)
	{
		$data=$image->_gd();	// GD reference
		$size=$image->size();
		$width=NSWidth($rect);
		$height=NSHeight($rect);
		$py=NSHeight($this->document->pageSize());
		self::$ezpdf->addImage($data, NSMinX($rect), $py-NSMinY($rect), NSWidth($rect), NSHeight($rect), $width, $height);
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
		return $page;
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
