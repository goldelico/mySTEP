<?php
	/*
	 * PDFKit.framework
	 * (C) Golden Delicious Computers GmbH&Co. KG, 2012
	 * All rights reserved.
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

function cm2pt($cm)
{
	return $cm*72/2.54;
}

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
		super::init();
		$this->bounds=array();
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
		// here we have neither a document() nor a pageRef()
		$this->drawImageInRect($image, $rect);
		return $this;
	}

	public function document() { return $this->document; }
	public function _setDocument(PDFDocument $doc) { $this->document=$doc; }

	public function label() { return $this->label; }
	public function setLabel($label) { $this->label=$label; }

	const kPDFDisplayBoxMediaBox=0;
	const kPDFDisplayBoxCropBox=1;
	const kPDFDisplayBoxBleedBox=2;
	const kPDFDisplayBoxTrimBox=3;
	const kPDFDisplayBoxArtBox=4;

	public function boundsForBox($box)
	{
		return $this->bounds[$box];
	}

	public function setBoundsForBox($box, /*NSRect*/ $bounds)
	{
		$this->bounds[$box]=$bounds;
	}

	public function dataRepresentation()
	{
		// FIXME: should return only this page!
		return $this->document()->dataRepresentation();
	}

	public function pageRef()
	{
		return $this->document->_ezpdf();
	}

	/* non-standard drawing methods */
	/* a page must be added to a PDFDocument right after init to use these functions */

	function setFontSize($fontSize=12.0)
	{
		$this->pageRef()->fontSize=$fontSize;
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
		$this->pageRef()->selectFont($fpath, array(/*"encoding"=>"StandardEncoding",*/ "differences" => array((int)eur => "Euro")));
	}

	function setColor(NSColor $color)
	{
		$this->pageRef()->setColor($color->r(), $color->g(), $color->b());
	}

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

	function widthOfText($text)
	{
		return $this->pageRef()->getTextWidth($this->pageRef()->fontSize, $text);
	}

	// handle attributed strings to define line spacing, fonts etc.

	function drawTextInRect($text, &$rect /* , $attributes */)
	{ // draw limited to rect (which may specify <=0 width or height for 'unlimited') and return new $y position by reference
// _NSLog("drawTextAtPoint: $text");
// _NSLog($rect);
		// FIXME: EUR symbol?
		$text=iconv("UTF-8", "CP1252", $text);
		$width=NSWidth($rect);
		$height=NSHeight($rect);
		if($width <= 0.0) $width=99999999.9;	// no limitations
		if($height <= 0.0) $height=99999999.9;
		$lines=explode("\n", $text);
		$x=NSMinX($rect);
		$y=NSMaxY($rect);	// start point
//		$py=NSHeight($this->boundsForBox(PDFPage::kPDFDisplayBoxMediaBox);
//		$y=$py-$y;	// flip coordinates: take (0,0) as top left corner of paper
		$ymin=$y-$height;
		for($i=0; $i<count($lines); $i++)
			{
			$line=$lines[$i];
			while(true)
				{
// _NSLog(($y-$this->pageRef()->fontSize)." ".($ymin-$height));
				if($y-$this->pageRef()->fontSize < $ymin)
					{ // no room for another line
					$lines[$i]=$line;	// what is not printed on this line
					break;
					}
// _NSLog("addTextWrap x=$x y=$y w=$width s=$this->pageRef()->fontSize l=$line j=$this->justification a=$this->angle");
				$line=$this->pageRef()->addTextWrap($x, $y-$this->pageRef()->fontSize, $width, $this->pageRef()->fontSize, $line, $this->justification, $this->angle);
				$y -= $this->lineSpacing*$this->pageRef()->fontSize;
				if($line == "")
					break;	// done with this line
				}
			}
		if(NSHeight($rect) > 0)
			$rect['height']-=$y-NSMinY($rect);	// reduce rect by amount we have printed
//		$y=$py-$y;	// flip coordinates: take (0,0) as top left corner of paper
		$rect['y']=$y;	// where next line can start
		return implode("\n", array_slice($lines, $i));	// return any text that has not been processed
	}

	function drawImageInRect(NSImage $image, $rect)
	{
		$data=$image->_gd();	// GD reference
		$size=$image->size();
		$width=NSWidth($rect);
		if($width <= 0.0) $width=NSWidth($image->size());
		$height=NSHeight($rect);
		if($height <= 0.0) $height=NSHeight($image->size());
		$x=NSMinX($rect);
		$y=NSMinY($rect);
//		$py=NSHeight($this->boundsForBox(PDFPage::kPDFDisplayBoxMediaBox);
//		$y=$py-$y;	// flip coordinates: take (0,0) as top left corner of paper
		$this->pageRef()->addImage($data, $x, $y-$height, $width, $height);
	}

	/* more ideas
		addLink
		addInternalLink
		setEncryption
	*/
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

	public function _ezpdf()
	{
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
		if($this->data)
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
		if(isset($this->ezpdf))
			{ // sould collect from pages
			return $this->ezpdf->output();
			}
		return $this->data;
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
		$this->load();
		$this->pages->insertObjectAtIndex($page, $index);
		$page->_setDocument($this);	// set backlink
		if(!isset($this->ezpdf))
			{ // first page - defines page size for all
			$ps=$page->boundsForBox(PDFPage::kPDFDisplayBoxMediaBox);
			$this->ezpdf=new Cpdf(array(NSMinX($ps), NSMinY($ps), NSWidth($ps), NSHeight($ps)));
			$page->setFont('Helvetica');
			}
		else
			// there is an optional $insert=0,$id=0,$pos='after' parameter if we do not append
			$this->ezpdf->newPage();
			// can we change page size on the fly?
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
