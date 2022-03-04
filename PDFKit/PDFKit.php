<?php
/*
 * PDFKit.framework
 * (C) Golden Delicious Computers GmbH&Co. KG, 2012-2022
 * All rights reserved.
 *
 * Notes:
 *   (0, 0) is the bottom left corner
 *   $rect for a text box defines the bottom left corner althogh text drawing starts at top
 *   all coordinates are in pt (Point = 1/72 inch)
 */

global $ROOT;	// must be set by some .app
require_once "$ROOT/System/Library/Frameworks/AppKit.framework/Versions/Current/php/AppKit.php";

// there may be newer version e.g. at https://github.com/rospdf - but compatibility is not clear
require_once "$ROOT/Internal/Frameworks/EzPDF.framework/Versions/Current/php/class.Cpdf.php";
// require_once "$ROOT/Internal/Frameworks/EzPDF.framework/Versions/Current/php/class.ezpdf.php";

if($GLOBALS['debug']) echo "<h1>PDFKit.framework</h1>";

// FIXME: properly handle Unicode translation!

const para="\247";	// paragraph
const ae="\344";
const oe="\366";
const ue="\374";
const ss="\337";
const AE="\304";
const OE="\326";
const UE="\334";
const eur="\200"; // there is no EUR symbol in ISO Latin-1

// _NSLog(function_exists('set_magic_quotes_runtime')?"set_magic_quotes_runtime exists":"set_magic_quotes_runtime missing");
if (!function_exists('set_magic_quotes_runtime')) {
function set_magic_quotes_runtime($flag)
{ // function has been deprecated in 5.3 removed in PHP 7.0
//	_NSLog("deprecated set_magic_quotes_runtime() ".($flag?"true":"false"));
}
}

function cm2pt($cm)
{
	return $cm*72/2.54;
}

// this is effectively a mix of PDFPage and NSGraphicsContext...

class PDFPage extends NSObject
{
	private $document;	// reference to owning document
	private $angle=0.0;
	private $justification='left';
	private $lineSpacing=1.1;
	private $bounds;
	private $label;

	public function init()
	{
// _NSLog("init");
//		parent::init();
		$this->bounds=array();
		// we can't set defaults here because we have no document
		return $this;
	}

	public function initWithDocument(PDFDocument $document)
	{ // override to add background for all pages
		$this->init();
		$document->insertPageAtIndex($this, $document->pageCount());	// append
		return $this;
	}

	public function initWithImage(NSImage $image)
	{ // override to add background for all pages
		$this->init();
		// here we have neither a document() nor a pageRef()!
		// what is the $rect???
		$this->drawImageInRect($image, $rect);
		return $this;
	}

	public function document() { return $this->document; }
	public function _setDocument(PDFDocument $doc) { $this->document=$doc; }

	public function label() { return $this->label; }
	public function setLabel($label) { $this->label=$label; }

	/* access modifiers only for PHP 7.1ff
	/*public*/ const kPDFDisplayBoxMediaBox=0;
	/*public*/ const kPDFDisplayBoxCropBox=1;
	/*public*/ const kPDFDisplayBoxBleedBox=2;
	/*public*/ const kPDFDisplayBoxTrimBox=3;
	/*public*/ const kPDFDisplayBoxArtBox=4;

	public function boundsForBox($box)
	{
// _NSLog("boundsForBox $box");
		switch($box)
			{
			case PDFPage::kPDFDisplayBoxBleedBox:
			case PDFPage::kPDFDisplayBoxTrimBox:
			case PDFPage::kPDFDisplayBoxArtBox:
				if(isset($this->bounds[$box]))
					return $this->bounds[$box];	// FIXME: interset with MediaBox
			case PDFPage::kPDFDisplayBoxCropBox:
				if(isset($this->bounds[PDFPage::kPDFDisplayBoxCropBox]))
					return $this->bounds[kPDFDisplayBoxCropBox];	// FIXME: intersect with MediaBox
			case PDFPage::kPDFDisplayBoxMediaBox:
				return $this->bounds[PDFPage::kPDFDisplayBoxMediaBox];
			}
		// raise exception;
		return null;
	}

	public function setBoundsForBox($box, /*NSRect*/ $bounds)
	{
// _NSLog("setBoundsForBox $box");
		$this->bounds[$box]=$bounds;
		if($box == PDFPage::kPDFDisplayBoxMediaBox)
			{ // now we can create an ezpdf backend
// _NSLog("init 1");
			$this->setFont();
// _NSLog("init");
			$this->setFontSize();
// _NSLog("init");
			$this->setLineStyle();
// _NSLog("init");
			$this->setJustification();
// _NSLog("init");
//			$this->setColor(NSColor::systemColorWithName("black"));
// _NSLog("init");

			}
	}

	public function dataRepresentation()
	{
		// FIXME: should return only this page!
		return $this->document()->dataRepresentation();
	}

	public function pageRef()
	{
		if(!isset($this->document))
			NSLog("no document set");
		return $this->document()->pageRef();
	}

/*
 * basically we should have a draw:withContext method
 * that allows to format a single page by drawing into some NSGraphicsContext
 * all the following functions belong there
 */

	/* non-standard drawing methods */
	/* a page must be added to a PDFDocument right after init to use these functions */

	function setFontSize($fontSize=12.0)
	{
		$this->pageRef()->fontSize=$fontSize;
	}

	function fontSize()
	{
		return $this->pageRef()->fontSize;
	}

	function setFont($fontName="Helvetica")
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
		$this->pageRef()->selectFont($fpath, array(/*"encoding"=>"StandardEncoding",*/ "differences" => array((int)eur => "Euro")));
		$this->font=$fontName;
	}

	function font()
	{
		return $this->font;
	}

	function setColor(NSColor $color)
	{
		$this->pageRef()->setColor($color->r(), $color->g(), $color->b());
	}

	// setFillColor?

	function setStrokeColor(NSColor $color)
	{
		$this->pageRef()->setStrokeColor($color->r(), $color->g(), $color->b());
	}

	// we could implement NSBezierPath to store control points and line styles
	// and use curve($x0,$y0,$x1,$y1,$x2,$y2,$x3,$y3)


	function strokeLine($start, $end)	// NSPoints
	{
		$this->pageRef()->line(NSMinX($start), NSMinY($start), NSMinX($end), NSMinY($end));
	}

	function strokeRect($rect)
	{
		$this->strokeLine(NSMakePoint(NSMinX($rect), NSMinY($rect)), NSMakePoint(NSMaxX($rect), NSMinY($rect)));
		$this->strokeLine(NSMakePoint(NSMaxX($rect), NSMinY($rect)), NSMakePoint(NSMaxX($rect), NSMaxY($rect)));
		$this->strokeLine(NSMakePoint(NSMaxX($rect), NSMaxY($rect)), NSMakePoint(NSMinX($rect), NSMaxY($rect)));
		$this->strokeLine(NSMakePoint(NSMinX($rect), NSMaxY($rect)), NSMakePoint(NSMinX($rect), NSMinY($rect)));
	}

	function setLineStyle($width=1, $cap='', $join='', $dash='', $phase=0)
	{
		$this->pageRef()->setLineStyle($width, $cap, $join, $dash, $phase);
	}

	function getFontHeight()
	{
		return $this->pageRef()->getFontHeight(1.0);
	}

	function getFontDecender()
	{
		return $this->pageRef()->getFontDecender(1.0);
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

	function lineSpacing()
	{
		return $this->lineSpacing;
	}

	function widthOfText($text)
	{
		return $this->pageRef()->getTextWidth($this->pageRef()->fontSize, $text);
	}

	// handle attributed strings to define line spacing, fonts etc.

	function drawTextInRect($text, &$rect, $attributes=null)
	{ // draw limited to rect (which may specify <=0 width or height for 'unlimited') and return new $y position by reference
// _NSLog("drawTextInRect: $text");
// _NSLog($rect);
		// FIXME: EUR symbol?
		$text=iconv("UTF-8", "CP1252", $text);
		$width=NSWidth($rect);
		$height=NSHeight($rect);
		if($width <= 0.0) $width=99999999.9;	// no limitations
		if($height <= 0.0) $height=99999999.9;
		$lines=explode("\n", $text);
		$x=NSMinX($rect);
		$y=NSMaxY($rect);	// starting point is at top of box
		$ymin=$y-$height;
		for($i=0; $i<count($lines); $i++)
			{
			$line=$lines[$i];
			while(true)
				{
// _NSLog(($y-$this->pageRef()->fontSize)." <=> ".$ymin);
				if($y-$this->pageRef()->fontSize < $ymin)
					{ // no room for another line
					$lines[$i]=$line;	// what is not printed on this line
					break;
					}
// _NSLog("addTextWrap x=$x y=$y w=$width s=".($this->pageRef()->fontSize)." l=$line j=$this->justification a=$this->angle");
				$line=$this->pageRef()->addTextWrap($x, $y-$this->pageRef()->fontSize, $width, $this->pageRef()->fontSize, $line, $this->justification, $this->angle);
				$y -= $this->lineSpacing*$this->pageRef()->fontSize;
				if($line == "")
					break;	// done with this line
				}
			}
		if(NSHeight($rect) > 0)
			$rect['height']-=NSMaxY($rect)-$y;	// reduce $rect by amount we have printed (so that we can draw the next box below)
		return implode("\n", array_slice($lines, $i));	// return any text that has not been processed fitting into the original rect
	}

	function drawTextAtPoint($text, $point, $attributes=null)
	{ // draw unlimited
		$this->drawTextInRect($text, NSMakeRect($point['x'], $point['y'], -1, -1), $attributes);
	}

	function drawImageInRect(NSImage $image, $rect)
	{
		$data=$image->_gd();	// GD reference i.e. "the image" loaded from file or whereever
// print_r($data);
		$size=$image->size();
		$width=NSWidth($rect);
		if($width <= 0.0) $width=NSWidth($size);
		$height=NSHeight($rect);
		if($height <= 0.0) $height=NSHeight($size);
		$x=NSMinX($rect);
		$y=NSMaxY($rect);
// _NSLog("image size ".strlen($jpeg));
// _NSLog("x:$x y:".($y-$height)."w:$width h:$height");
		// note: this calls set_magic_quotes_runtime() inside its implementation which was removed in PHP 7.0
		$this->pageRef()->addImage($data, $x, $y-$height, $width, $height);	// ezpdf will convert to JPEG!
	}

	/* more ideas
		addLink
		addInternalLink
		setEncryption
	*/

	function saveGraphicsState()
	{
	}

	function restoreGraphicsState()
	{
	}
}

class PDFDocument extends NSObject
{
	private $pages;
	private $size;
	private $url;
	private $data;

	private $ezpdf;

	public function __construct()
	{
		parent::__construct();
		$this->pages=new NSMutableArray();
	}

	public function __destruct()
	{
		parent::__destruct();
	}

	function pageRef()
	{
// _NSLog("create ezpdf");
		if(!isset($this->ezpdf))
			{ // first call - defines page size for all - limitation of class Cpdf
// _NSLog($this->pages);
			$first=$this->pages->objectAtIndex(0);
// _NSLog($first);
			$ps=$first->boundsForBox(PDFPage::kPDFDisplayBoxMediaBox);
// _NSLog($ps);
			$this->ezpdf=new Cpdf(array(NSMinX($ps), NSMinY($ps), NSWidth($ps), NSHeight($ps)));
			}
// _NSLog($this->ezpdf);
		return $this->ezpdf;
	}

	public function initWithData($data)
	{
		if(substr($data, 0, 4) != "%PDF")
			NSLog("Is not PDF: ".substr($this->data, 0, 20));
		else
			$this->data=$data;
		return $this;
	}

	private function load()
	{
		if(isset($this->data))
			{
			// parse PDFPpages from $this->data
			}
	}

	public function initWithURL($url)
	{
		$this->url=$url;
		$fd=@fopen($this->url, "r");
		$data="";
		if($fd)
			{
			while(!feof($fd))
				$data .= fread($fd, 999999);
			fclose($fd);
			return $this->initWithData($data);
			}
		NSLog("Could not receive data from ".$this->url);
		return null;
	}

	public function documentURL()
	{
		return $this->url;
	}

	public function majorVersion()
	{
		return 1;
	}

	public function minorVersion()
	{
		return 0;
	}

	public function documentAttributes()
	{
		$this->load();
		return $this->attributes;
	}

	public function dataRepresentationWithOptions($options)
	{
		if(isset($this->data))
			return $this->data;
		return $this->pageRef()->output();
	}

	public function dataRepresentation()
	{
		return $this->dataRepresentationWithOptions(0);
	}

	public function string()
	{
	}

	// writeToFile/URL+withOptions

	public function exchangePageAtIndexWithPageAtIndex($i1, $i2)
	{
		$this->load();
		$this->pages->exchangeObjectAtIndexWithObjectAtIndex($i1, $i2);
	}

	public function indexForPage(PDFPage $page)
	{
		$this->load();
		return $this->pages->indexForObject($page);
	}

	public function insertPageAtIndex(PDFPage $page, $index)
	{
// _NSLog("insertPageAtIndex $index");
		$this->load();
		$this->pages->insertObjectAtIndex($page, $index);
		$page->_setDocument($this);	// set backlink
		if($this->pages->count() > 1)
			{ // second page
			// there is an optional $insert=0,$id=0,$pos='after' parameter if we do not append
// _NSLog("new page");
			$this->pageRef()->newPage();	// add a page break
			// can we change page size on the fly?
			}
// _NSLog($this->pages);
	}

	public function pageAtIndex($index)
	{
		$this->load();
		return $this->pages->objectAtIndex($index);
	}

	public function pageCount()
	{
		$this->load();
		return $this->pages->count();
	}

	public function removePageAtIndex($index)
	{
		$this->load();
		$page->_setDocument(null);
		return $this->pages->removeObjectAtIndex($index);
	}

	public function pageClass()
	{
		return "PDFPage";
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
