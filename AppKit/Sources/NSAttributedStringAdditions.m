/* 
   NSAttributedStringAdditions.m

   Extentions to NSAttributedString 

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    Oct 2001
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <AppKit/AppKit.h>

NSString *NSCharacterShapeAttributeName=@"CharacterShape";
NSString *NSGlyphInfoAttributeName=@"GlyphInfo";

NSString *NSPaperSizeDocumentAttribute=@"PaperSize";
NSString *NSLeftMarginDocumentAttribute=@"LeftMargin";
NSString *NSRightMarginDocumentAttribute=@"RightMargin";
NSString *NSTopMarginDocumentAttribute=@"TopMargin";
NSString *NSBottomMarginDocumentAttribute=@"BottomMargin";
NSString *NSHyphenationFactorDocumentAttribute=@"HyphenationFactor";
NSString *NSDocumentTypeDocumentAttribute=@"DocumentType";
NSString *NSCharacterEncodingDocumentAttribute=@"CharacterEncoding";
NSString *NSViewSizeDocumentAttribute=@"ViewSize";
NSString *NSViewZoomDocumentAttribute=@"ViewZoom";
NSString *NSViewModeDocumentAttribute=@"ViewMode";
NSString *NSBackgroundColorDocumentAttribute=@"BackgroundColor";
NSString *NSCocoaVersionDocumentAttribute=@"CocoaVersion";
NSString *NSReadOnlyDocumentAttribute=@"ReadOnly";
NSString *NSConvertedDocumentAttribute=@"Converted";
NSString *NSDefaultTabIntervalDocumentAttribute=@"DefaultTabInterval";
NSString *NSTitleDocumentAttribute=@"Title";
NSString *NSCompanyDocumentAttribute=@"Company";
NSString *NSCopyrightDocumentAttribute=@"Copyright";
NSString *NSSubjectDocumentAttribute=@"Subject";
NSString *NSAuthorDocumentAttribute=@"Author";
NSString *NSKeywordsDocumentAttribute=@"Keywords";
NSString *NSCommentDocumentAttribute=@"Comment";
NSString *NSEditorDocumentAttribute=@"Editor";
NSString *NSCreationTimeDocumentAttribute=@"CreationTime";
NSString *NSModificationTimeDocumentAttribute=@"ModificationTime";

const unsigned NSUnderlineByWordMask=0x01;

NSString *NSPlainTextDocumentType=@"PlainText";
NSString *NSRTFTextDocumentType=@"RTF";
NSString *NSRTFDTextDocumentType=@"RTFD";
NSString *NSMacSimpleTextDocumentType=@"SimpleText";
NSString *NSHTMLTextDocumentType=@"HTML";
NSString *NSDocFormatTextDocumentType=@"Doc";
NSString *NSWordMLTextDocumentType=@"WordML";

NSString *NSExcludedElementsDocumentAttribute=@"ExcludedElements";
NSString *NSTextEncodingNameDocumentAttribute=@"TextEncoding";
NSString *NSPrefixSpacesDocumentAttribute=@"PrefixSpaces";

NSString *NSBaseURLDocumentOption=@"BaseURL";
NSString *NSCharacterEncodingDocumentOption=@"CharacterEncoding";
NSString *NSDefaultAttributesDocumentOption=@"DefaultAttributes";
NSString *NSDocumentTypeDocumentOption=@"DocumentType";
NSString *NSTextEncodingNameDocumentOption=@"TextEncoding";
NSString *NSTextSizeMultiplierDocumentOption=@"TextSizeMultiplier";
NSString *NSTimeoutDocumentOption=@"Timeout";
NSString *NSWebPreferencesDocumentOption=@"WebPreferences";
NSString *NSWebResourceLoadDelegateDocumentOption=@"WebResourceLoadDelegate";

// class variables
static char *__buf = NULL;
static int __rtf_stack_depth = 0;

// interface to dynamically loaded WebView for parsing HTML

@protocol WebDocumentText
- (NSAttributedString *) attributedString;
@end

@interface WebFrameView : NSView
- (NSView <WebDocumentText> *) documentView;
@end

@interface WebDataSource : NSObject
- (NSString *) pageTitle;
- (NSString *) textEncodingName;
@end

@interface WebFrame : NSObject
- (WebFrameView *) frameView;
- (void) loadData:(NSData *) data MIMEType:(NSString *) mime textEncodingName:(NSString *) encoding baseURL:(NSURL *) url;
- (WebDataSource *) dataSource;
@end

@interface WebView : NSView
- (WebFrame *) mainFrame;
- (void) setFrameLoadDelegate:(id) delegate;
@end

// RTF parser error codes

#define ecOK 0                      // Everything's fine!
#define ecStackUnderflow    1       // Unmatched '}'
#define ecStackOverflow     2       // Too many '{' -- memory exhausted
#define ecUnmatchedBrace    3       // RTF ended during an open group.
#define ecInvalidHex        4       // invalid hex character found in data
#define ecBadTable          5       // RTF table (sym or prop) invalid
#define ecAssertion         6       // Assertion failure
#define ecEndOfFile         7       // End of file reached while reading RTF

typedef struct char_prop
{
    char fBold;
    char fUnderline;
    char fItalic;
} CHP;                  // CHaracter Properties

typedef enum {justL, justR, justC, justF } JUST;

typedef struct para_prop
{
    int xaLeft;                 // left indent in twips
    int xaRight;                // right indent in twips
    int xaFirst;                // first line indent in twips
    JUST just;                  // justification
} PAP;                  // PAragraph Properties

typedef enum {sbkNon, sbkCol, sbkEvn, sbkOdd, sbkPg} SBK;
typedef enum {pgDec, pgURom, pgLRom, pgULtr, pgLLtr} PGN;

typedef struct sect_prop
{
    int cCols;                  // number of columns
    SBK sbk;                    // section break type
    int xaPgn;                  // x position of page number in twips
    int yaPgn;                  // y position of page number in twips
    PGN pgnFormat;              // how the page number is formatted
} SEP;                  // SEction Properties

typedef struct doc_prop
{
    int xaPage;                 // page width in twips
    int yaPage;                 // page height in twips
    int xaLeft;                 // left margin in twips
    int yaTop;                  // top margin in twips
    int xaRight;                // right margin in twips
    int yaBottom;               // bottom margin in twips
    int pgnStart;               // starting page number in twips
    char fFacingp;              // facing pages enabled?
    char fLandscape;            // landscape or portrait??
} DOP;                  // DOcument Properties

typedef enum { rdsNorm, rdsSkip } RDS;              // Rtf Destination State
typedef enum { risNorm, risBin, risHex } RIS;       // Rtf Internal State

typedef struct save             // property save structure
{
    struct save *pNext;         // next save
    CHP chp;
    PAP pap;
    SEP sep;
    DOP dop;
    RDS rds;
    RIS ris;
} SAVE;

// What types of properties are there?
typedef enum {ipropBold,	ipropItalic,	ipropUnderline,	ipropLeftInd,
              ipropRightInd,ipropFirstInd,	ipropCols,		ipropPgnX,
              ipropPgnY,	ipropXaPage,	ipropYaPage,	ipropXaLeft,
              ipropXaRight,	ipropYaTop,		ipropYaBottom,	ipropPgnStart,
              ipropSbk,		ipropPgnFormat, ipropFacingp,	ipropLandscape,
              ipropJust,	ipropPard,		ipropPlain,		ipropSectd,
              ipropMax } IPROP;

typedef enum {actnSpec, actnByte, actnWord} ACTN;
typedef enum {propChp, propPap, propSep, propDop} PROPTYPE;

typedef struct propmod
{
    ACTN actn;              // size of value
    PROPTYPE prop;          // structure containing value
    int offset;				// offset of value from base of structure
} PROP;

typedef enum {ipfnBin, ipfnHex, ipfnSkipDest } IPFN;
typedef enum {idestPict, idestSkip } IDEST;
typedef enum {kwdChar, kwdDest, kwdProp, kwdSpec} KWD;

typedef struct symbol
{
    char *szKeyword;        // RTF keyword
    int dflt;				// default value to use
    BOOL fPassDflt;         // true to use default value from this table
    KWD kwd;				// base action to take
    int idx;				// index into property table if kwd == kwdProp
                            // index into destination table if kwd == kwdDest
} SYM;						// character to print if kwd == kwdChar

static BOOL fSkipDestIfUnk;
static long cbBin;
static long lParam;

static RDS rds;
static RIS ris;

static CHP chp;
static PAP pap;
static SEP sep;
static DOP dop;

static SAVE *__rtf_state;

// RTF parser tables

#ifndef offsetof
#define offsetof(TYPE, COMPONENT) (unsigned int)(&(((TYPE *) (0))->COMPONENT))
#endif

// Property descriptions
static PROP rgprop [ipropMax] = {
    { actnByte,   propChp,    offsetof(CHP, fBold) },       // ipropBold
    { actnByte,   propChp,    offsetof(CHP, fItalic) },     // ipropItalic
    { actnByte,   propChp,    offsetof(CHP, fUnderline) },  // ipropUnderline
    { actnWord,   propPap,    offsetof(PAP, xaLeft) },      // ipropLeftInd
    { actnWord,   propPap,    offsetof(PAP, xaRight) },     // ipropRightInd
    { actnWord,   propPap,    offsetof(PAP, xaFirst) },     // ipropFirstInd
    { actnWord,   propSep,    offsetof(SEP, cCols) },       // ipropCols
    { actnWord,   propSep,    offsetof(SEP, xaPgn) },       // ipropPgnX
    { actnWord,   propSep,    offsetof(SEP, yaPgn) },       // ipropPgnY
    { actnWord,   propDop,    offsetof(DOP, xaPage) },      // ipropXaPage
    { actnWord,   propDop,    offsetof(DOP, yaPage) },      // ipropYaPage
    { actnWord,   propDop,    offsetof(DOP, xaLeft) },      // ipropXaLeft
    { actnWord,   propDop,    offsetof(DOP, xaRight) },     // ipropXaRight
    { actnWord,   propDop,    offsetof(DOP, yaTop) },       // ipropYaTop
    { actnWord,   propDop,    offsetof(DOP, yaBottom) },    // ipropYaBottom
    { actnWord,   propDop,    offsetof(DOP, pgnStart) },    // ipropPgnStart
    { actnByte,   propSep,    offsetof(SEP, sbk) },         // ipropSbk
    { actnByte,   propSep,    offsetof(SEP, pgnFormat) },   // ipropPgnFormat
    { actnByte,   propDop,    offsetof(DOP, fFacingp) },    // ipropFacingp
    { actnByte,   propDop,    offsetof(DOP, fLandscape) },  // ipropLandscape
    { actnByte,   propPap,    offsetof(PAP, just) },        // ipropJust
	{ actnSpec,   propPap,    0 },                          // ipropPard
	{ actnSpec,   propChp,    0 },                          // ipropPlain
	{ actnSpec,   propSep,    0 },                          // ipropSectd
};

// Keyword descriptions
static SYM rgsymRtf[] = {
//  keyword     dflt    fPassDflt   kwd         idx
	{ "b",        1,      NO,			kwdProp,    ipropBold },
    { "u",        1,      NO,			kwdProp,    ipropUnderline },
    { "i",        1,      NO,			kwdProp,    ipropItalic },
    { "li",       0,      NO,			kwdProp,    ipropLeftInd },
    { "ri",       0,      NO,			kwdProp,    ipropRightInd },
    { "fi",       0,      NO,			kwdProp,    ipropFirstInd },
    { "cols",     1,      NO,			kwdProp,    ipropCols },
    { "sbknone",  sbkNon, YES,		kwdProp,    ipropSbk },
    { "sbkcol",   sbkCol, YES,		kwdProp,    ipropSbk },
    { "sbkeven",  sbkEvn, YES,		kwdProp,    ipropSbk },
    { "sbkodd",   sbkOdd, YES,		kwdProp,    ipropSbk },
    { "sbkpage",  sbkPg,  YES,		kwdProp,    ipropSbk },
    { "pgnx",     0,      NO,			kwdProp,    ipropPgnX },
    { "pgny",     0,      NO,			kwdProp,    ipropPgnY },
    { "pgndec",   pgDec,  YES,		kwdProp,    ipropPgnFormat },
    { "pgnucrm",  pgURom, YES,		kwdProp,    ipropPgnFormat },
    { "pgnlcrm",  pgLRom, YES,		kwdProp,    ipropPgnFormat },
    { "pgnucltr", pgULtr, YES,		kwdProp,    ipropPgnFormat },
    { "pgnlcltr", pgLLtr, YES,		kwdProp,    ipropPgnFormat },
    { "qc",       justC,  YES,		kwdProp,    ipropJust },
    { "ql",       justL,  YES,		kwdProp,    ipropJust },
    { "qr",       justR,  YES,		kwdProp,    ipropJust },
    { "qj",       justF,  YES,		kwdProp,    ipropJust },
    { "paperw",   12240,  NO,			kwdProp,    ipropXaPage },
    { "paperh",   15480,  NO,			kwdProp,    ipropYaPage },
    { "margl",    1800,   NO,			kwdProp,    ipropXaLeft },
    { "margr",    1800,   NO,			kwdProp,    ipropXaRight },
    { "margt",    1440,   NO,			kwdProp,    ipropYaTop },
    { "margb",    1440,   NO,			kwdProp,    ipropYaBottom },
    { "pgnstart", 1,      YES,		kwdProp,    ipropPgnStart },
    { "facingp",  1,      YES,		kwdProp,    ipropFacingp },
    { "landscape",1,      YES,		kwdProp,    ipropLandscape },
    { "par",      0,      NO,			kwdChar,    0x0a },	// use NSParagraphSeparatorCharacter 0x2029?
    { "\0x0a",    0,      NO,			kwdChar,    '\n' },
    { "\n",    	0,      NO,			kwdChar,    '\n' },
    { "\0x0d",    0,      NO,			kwdChar,    '\r' },
    { "tab",      0,      NO,			kwdChar,    '\t' },
    { "ldblquote",0,      NO,			kwdChar,    '"' },	// use unicode quotes??
    { "rdblquote",0,      NO,			kwdChar,    '"' },
    { "bin",      0,      NO,			kwdSpec,    ipfnBin },
    { "*",        0,      NO,			kwdSpec,    ipfnSkipDest },
    { "'",        0,      NO,			kwdSpec,    ipfnHex },
    { "author",   0,      NO,			kwdDest,    idestSkip },
    { "buptim",   0,      NO,			kwdDest,    idestSkip },
    { "colortbl", 0,      NO,			kwdDest,    idestSkip },
    { "comment",  0,      NO,			kwdDest,    idestSkip },
    { "creatim",  0,      NO,			kwdDest,    idestSkip },
    { "doccomm",  0,      NO,			kwdDest,    idestSkip },
    { "fonttbl",  0,      NO,			kwdDest,    idestSkip },
    { "footer",   0,      NO,			kwdDest,    idestSkip },
    { "footerf",  0,      NO,			kwdDest,    idestSkip },
    { "footerl",  0,      NO,			kwdDest,    idestSkip },
    { "footerr",  0,      NO,			kwdDest,    idestSkip },
    { "footnote", 0,      NO,			kwdDest,    idestSkip },
    { "ftncn",    0,      NO,			kwdDest,    idestSkip },
    { "ftnsep",   0,      NO,			kwdDest,    idestSkip },
    { "ftnsepc",  0,      NO,			kwdDest,    idestSkip },
    { "header",   0,      NO,			kwdDest,    idestSkip },
    { "headerf",  0,      NO,			kwdDest,    idestSkip },
    { "headerl",  0,      NO,			kwdDest,    idestSkip },
    { "headerr",  0,      NO,			kwdDest,    idestSkip },
    { "info",     0,      NO,			kwdDest,    idestSkip },
    { "keywords", 0,      NO,			kwdDest,    idestSkip },
    { "operator", 0,      NO,			kwdDest,    idestSkip },
    { "pict",     0,      NO,			kwdDest,    idestSkip },
    { "printim",  0,      NO,			kwdDest,    idestSkip },
    { "private1", 0,      NO,			kwdDest,    idestSkip },
    { "revtim",   0,      NO,			kwdDest,    idestSkip },
    { "rxe",      0,      NO,			kwdDest,    idestSkip },
    { "stylesheet",0,     NO,			kwdDest,    idestSkip },
    { "subject",  0,      NO,			kwdDest,    idestSkip },
    { "tc",       0,      NO,			kwdDest,    idestSkip },
    { "title",    0,      NO,			kwdDest,    idestSkip },
    { "txe",      0,      NO,			kwdDest,    idestSkip },
    { "xe",       0,      NO,			kwdDest,    idestSkip },
    { "{ ",        0,      NO,			kwdChar,    '{' },
    { "}",        0,      NO,			kwdChar,    '}' },
    { "\\",       0,      NO,			kwdChar,    '\\' }
    };
static int isymMax = sizeof(rgsymRtf) / sizeof(SYM);

// declare function headers

static int GSParseSpecialRTFKeyword(IPFN ipfn);

// define functions

static void GSRouteParsedRTFChar(int ch)			// Route the character to the 
{										// appropriate destination stream
    if (ris == risBin && --cbBin <= 0)
        ris = risNorm;

    switch (rds)
		{
		case rdsNorm:	// Output char. Properties are valid at this point.
			{
			int len = strlen(__buf);
			__buf[len++] = ch;
			__buf[len] = '\0';
			}
//    		putchar(ch);

		case rdsSkip:					// Toss this character.
		default:						// handle other destinations
			break;
		}
}

//
//	GSSetRTFProperty
//
//	Set the property identified by _iprop_ to the value _val_.
//

static int GSSetRTFProperty(IPROP iprop, int val)
{
	char *pb;

    if (rds == rdsSkip)                 // If we're skipping text,
        return ecOK;                    // don't do anything.

    switch (rgprop[iprop].prop)
		{
		case propDop:	pb = (char *)&dop;	break;
		case propSep:	pb = (char *)&sep;	break;
		case propPap:	pb = (char *)&pap;	break;
		case propChp:	pb = (char *)&chp;	break;
		default:
			if (rgprop[iprop].actn != actnSpec)
				return ecBadTable;
			return ecBadTable;
			// FIXME: pb may be used uninitialized below!!!
			break;
		}

    switch (rgprop[iprop].actn)
		{
		case actnByte:
			pb[rgprop[iprop].offset] = (unsigned char) val;
			break;
		case actnWord:
			(*(int *) (pb+rgprop[iprop].offset)) = val;
			break;
		case actnSpec:					// Set a property that requires
			switch (iprop)				// code to evaluate
				{
				case ipropPard:		memset(&pap, 0, sizeof(pap));	break;
				case ipropPlain:	memset(&chp, 0, sizeof(chp));	break;
				case ipropSectd:	memset(&sep, 0, sizeof(sep));	break;
				default:			
					return ecBadTable;
				}
			break;
		default:
			return ecBadTable;
		}

    return ecOK;
}

//
//	GSTranslateRTFKeyword.
//
//	Step 3.
//	Search rgsymRtf for szKeyword and evaluate it appropriately.
//
//	Inputs:
//	szKeyword:	The RTF control to evaluate.
//	param:		The parameter of the RTF control.
//	fParam:		YES if control had a parameter; (that is, if param is valid)
//              NO if it did not.
//

static int GSTranslateRTFKeyword(char *szKeyword, int param, BOOL fParam)
{
int isym;							// search for szKeyword in rgsymRtf

    for (isym = 0; isym < isymMax; isym++)
        if (strcmp(szKeyword, rgsymRtf[isym].szKeyword) == 0)
            break;

    if (isym == isymMax)            // control word not found
    	{
        if (fSkipDestIfUnk)         // if this is a new destination
            rds = rdsSkip;          // skip the destination
                                    // else just discard it
        fSkipDestIfUnk = NO;
        return ecOK;
    	}
									// found it!  use kwd and idx to determine 
    fSkipDestIfUnk = NO;			// what to do with it.
    switch (rgsymRtf[isym].kwd)
		{
		case kwdProp:
			if (rgsymRtf[isym].fPassDflt || !fParam)
				param = rgsymRtf[isym].dflt;
			return GSSetRTFProperty(rgsymRtf[isym].idx, param);
		case kwdChar:
			GSRouteParsedRTFChar(rgsymRtf[isym].idx);
			return ecOK;
		case kwdDest:
			if (rds != rdsSkip)					// if not skipping text
				switch (rgsymRtf[isym].idx)		// Switch output destination
					{
					default:
						rds = rdsSkip;			// when in doubt, skip it...
						break;
					}
			
			return ecOK;

		case kwdSpec:
			return GSParseSpecialRTFKeyword(rgsymRtf[isym].idx);
		default:
			return ecBadTable;
		}

    return ecBadTable;
}

//
//	GSParseSpecialRTFKeyword
//
//	Evaluate an RTF control that needs special processing.
//

static int GSParseSpecialRTFKeyword(IPFN ipfn)
{
    if (rds == rdsSkip && ipfn != ipfnBin)  // if we're skipping, and it's not
        return ecOK;                        // the \bin keyword, ignore it.

    switch (ipfn)
		{
		case ipfnBin:
			ris = risBin;
			cbBin = lParam;
			break;
		case ipfnSkipDest:
			fSkipDestIfUnk = YES;
			break;
		case ipfnHex:
			ris = risHex;
			break;
		default:
			return ecBadTable;
		}

    return ecOK;
}

static void	GSPushRTFState(void)	// Save RTF info into a linked list stack of SAVE structures
{
SAVE *psaveNew = malloc(sizeof(*psaveNew));

    if (!psaveNew)
		[NSException raise: NSMallocException format:@"malloc failed"];

    psaveNew->pNext = __rtf_state;
    psaveNew->chp = chp;
    psaveNew->pap = pap;
    psaveNew->sep = sep;
    psaveNew->dop = dop;
    psaveNew->rds = rds;
    psaveNew->ris = ris;
    ris = risNorm;
    __rtf_state = psaveNew;
    __rtf_stack_depth++;
}

static void GSPopRTFState(void)		// Pop RTF doc info from top of SAVE list stack if ending a destination
{
SAVE *psaveOld;

    if (!__rtf_state)
		[NSException raise: NSGenericException format:@"RTF stack underflow"];

//  if (rds != __rtf_state->rds)		// destination specified by rds is
										// about to close. cleanup if needed
    chp = __rtf_state->chp;
    pap = __rtf_state->pap;
    sep = __rtf_state->sep;
    dop = __rtf_state->dop;
    rds = __rtf_state->rds;
    ris = __rtf_state->ris;

    psaveOld = __rtf_state;
    __rtf_state = __rtf_state->pNext;
    __rtf_stack_depth--;
    free(psaveOld);
}

//
//	GSParseRTFKeyword
//
//	Step 2:
//	get a control word (and its associated value) and
//	call GSTranslateRTFKeyword to dispatch the control.
//

static const char *GSParseRTFKeyword (const char *f)
{
int ch, ec, param = 0;
char fParam = NO, fNeg = NO;
char *pch;
char szKeyword[30] = "";
char szParameter[20] = "";

    if (!*f || (ch = *f++) == '\0')
		{
		[NSException raise: NSGenericException format:@"RTF unexpected EOF"];
		return NULL;
		}
    if (!isalpha(ch))           				// control symbol; no delimiter
		{
        szKeyword[0] = (char) ch;
        szKeyword[1] = '\0';
		}
	else
		{
		for (pch = szKeyword; *f && isalpha(ch); (ch = *f++))
			*pch++ = (char) ch;
		*pch = '\0';
		if (ch == '-')
			{
			fNeg  = YES;
			if (!*f || (ch = *f++) == '\0')
				[NSException raise: NSGenericException
							 format:@"RTF unexpected EOF"];
			}
		if (isdigit(ch))
			{								// a digit after the control means 
			fParam = YES;					// we have a parameter
			for (pch = szParameter; *f && isdigit(ch); (ch = *f++))
				*pch++ = (char) ch;
			*pch = '\0';
			param = atoi(szParameter);
			if (fNeg)
				param = -param;
			lParam = atol(szParameter);
			if (fNeg)
				param = -param;
			}
		if (ch != ' ')
			f--;
		}

	if ((ec = GSTranslateRTFKeyword(szKeyword, param, fParam)) != ecOK)
		[NSException raise: NSGenericException 
					 format: @"GSParseRTFKeyword() failed: %d\n", ec];
    return f;
}

//
//	GSParseRTF
//
//	Step 1:
//	Isolate RTF keywords and send them to GSParseRTFKeyword;
//	Push and pop state at the start and end of RTF groups;
//	Send text to GSRouteParsedRTFChar for further processing.
//

static int GSParseRTF (const char *f)
{
int ch, cNibble = 2, b = 0;

	while(*f)
    	{
		ch = *f++;
        if (__rtf_stack_depth < 0)
            return ecStackUnderflow;

        if (ris == risBin)						// if we're parsing binary 
			GSRouteParsedRTFChar(ch);			// data, handle it directly
        else
			{
            switch (ch)
				{
				case '{':	GSPushRTFState();			break;
				case '}':	GSPopRTFState();			break;
				case '\\':	f = GSParseRTFKeyword(f);	break;

				default:
					if (ris == risNorm)
						GSRouteParsedRTFChar(ch);
					else
						{               		// parsing hex data
						if (ris != risHex)
							return ecAssertion;
						b = b << 4;
						if (isdigit(ch))
							b += (char) ch - '0';
						else
							{
							if (islower(ch))
								{
								if (ch < 'a' || ch > 'f')
									return ecInvalidHex;
								b += (char) ch - 'a';
								}
							else
								{
								if (ch < 'A' || ch > 'F')
									return ecInvalidHex;
								b += (char) ch - 'A';
							}	}

						cNibble--;
						if (!cNibble)
							{
							GSRouteParsedRTFChar(ch);
							cNibble = 2;
							b = 0;
							ris = risNorm;
						}	}

				case '\n':
				case '\r':          			// cr and lf are noise chars
					break;
    	}	}	}

    if (__rtf_stack_depth < 0)
        return ecStackUnderflow;
    if (__rtf_stack_depth > 0)
        return ecUnmatchedBrace;

    return ecOK;
}

@implementation NSAttributedString (NSAttributedStringAdditions)

#define TWIPSperPOINT	20.0		// points are 20 twips
#define POINTperMETER	2660.0

// some useful unit converters

+ (float) _pt2mm:(float) val
{
	return val*(POINTperMETER/1000.0);
}

+ (float) _mm2pt:(float) val
{ // 1pt = 1m/2660
	return val*(1000.0/POINTperMETER);
}

+ (float) _twips2mm:(int) twips
{ // convert twips to mm
	return twips*(POINTperMETER/(1000.0*TWIPSperPOINT));
}

+ (int) _mm2twips:(float) mm
{ // convert mm to twips
	return mm*(1000.0/POINTperMETER*TWIPSperPOINT);
}

- (id) initWithData:(NSData *)d options:(NSDictionary *)options documentAttributes:(NSDictionary **)dict error:(NSError **)error;
{ // you should pass [NSDictionary dictionaryWithObject:url forKey:NSBaseURLDocumentOption] if you did load NSData from a file or URL and it can be HTML
	id o;
	if(!d)
		{ // no data
		[self release];
		return nil;
		}
	// what to do with options?
	// we should also be more intelligent to decide about document format since simply trying to load as HTML and failing is really heavy
	o=[self initWithRTF:d documentAttributes:dict];			// try RTF
	if(!o)
		o=[self initWithDocFormat:d documentAttributes:dict];		// no, try MS Word
	if(!o)
		o=[self initWithHTML:d options:options documentAttributes:dict];	// no, try HTML
	if(!o)
		o=[self initWithRTFD:d documentAttributes:dict];	// no, finally try RTFD
	if(!o)
		{
		NSLog(@"file does not exist or can not be interpreted.");
		[self release];
		}
	return o;
}

- (id) initWithURL:(NSURL *)url options:(NSDictionary *)options documentAttributes:(NSDictionary **)dict error:(NSError **)error;
{
	NSData *data=[NSData dataWithContentsOfURL:url options:0 error:error];
	if(!data)
			{
				[self release];
				return nil;	// can't read
			}
	return [self initWithData:data options:options documentAttributes:dict error:error];
}

- (id) initWithURL:(NSURL *)url documentAttributes:(NSDictionary **)dict;
{
	return [self initWithURL:url options:0 documentAttributes:dict error:NULL];
}

- (id) initWithPath:(NSString *)path documentAttributes:(NSDictionary **)dict;
{
	return [self initWithURL:[NSURL fileURLWithPath:path] documentAttributes:dict];
}

// FIXME: currently just extracts the main text as a NSCString - no handling of attributes or Unicode

- (id) initWithRTF:(NSData *)data documentAttributes:(NSDictionary **)dict
{
	const void *bytes = [data bytes];
	int len = [data length];
	__buf = objc_calloc(len , sizeof(__buf)+1);
	if ((GSParseRTF(bytes)) != ecOK)
		// FIXME: should do more specific error handling
		NSLog(@"error parsing RTF");
	return [[NSString alloc] initWithCStringNoCopy:__buf 
											length:strlen(__buf)
									  freeWhenDone:YES];
}

- (id) initWithRTFD:(NSData *)data documentAttributes:(NSDictionary **)dict
{
	NSFileWrapper *w = [[[NSFileWrapper alloc] initWithSerializedRepresentation:data] autorelease];
	if(!w)
			{
				[self release];
				return nil;
			}
	return [self initWithRTFDFileWrapper:w documentAttributes:dict];
}

- (id) initWithRTFDFileWrapper:(NSFileWrapper *)wrapper 
			documentAttributes:(NSDictionary **)dict
{
	id o;
	if([wrapper isRegularFile])
		{
		o=[self initWithRTF:[wrapper regularFileContents] documentAttributes:dict];
		if(o)
			return o;	// was a plain RTF file
		}
	NIMP;	// FIXME
	return self;
}

- (id) initWithHTML:(NSData *)data documentAttributes:(NSDictionary **)dict;
{
	return [self initWithHTML:data options:nil documentAttributes:dict];
}

- (id) initWithHTML:(NSData *)data baseURL:(NSURL *)url documentAttributes:(NSDictionary **)dict;
{
	return [self initWithHTML:data options:[NSDictionary dictionaryWithObject:url forKey:NSBaseURLDocumentOption] documentAttributes:dict];
}

// reuse (this is not at all thread safe!)
static BOOL didLoadWebKit;
static WebView *webView;
static BOOL done;

- (void) webView:(WebView *)sender didFinishLoadForFrame:(WebFrame*) frame
{
	NSLog(@"did finish loading main frame");
	if(frame == [sender mainFrame])
		done=YES;
}

- (id) initWithHTML:(NSData *)data options:(NSDictionary *)options documentAttributes:(NSDictionary **)dict;
{
	// check if header looks reasonable like HTML or XHTML before even trying
	if(!didLoadWebKit)
		[[NSBundle bundleWithPath:@"/System/Library/Frameworks/WebKit.framework"] load], didLoadWebKit=YES;	// dynamically load
	// CHECKME: do we really need to create a WebView or is creating a webFrame sufficient?
	if(!webView)
		{
		webView=[[NSClassFromString(@"WebView") alloc] initWithFrame:NSMakeRect(0.0, 0.0, 100.0, 100.0)];
		if(!webView)
				{
			[self release];
			return nil;	// can't initialize
				}
		}
	[[webView mainFrame] loadData:data MIMEType:@"text/html" textEncodingName:@"utf-8" baseURL:[options objectForKey:NSBaseURLDocumentOption]];
	[webView setFrameLoadDelegate:self];
	done=NO;
	while(!done)
		{ // loading is not yet done
		[NSApp nextEventMatchingMask:NSAnyEventMask untilDate:[NSDate dateWithTimeIntervalSinceNow:0.05] inMode:NSDefaultRunLoopMode dequeue:NO];	// process events
		}
	if(dict)
		*dict=[NSDictionary dictionaryWithObjectsAndKeys:
			NSHTMLTextDocumentType, NSDocumentTypeDocumentAttribute,
			[[[webView mainFrame] dataSource] textEncodingName], NSCharacterEncodingDocumentAttribute,	// may be nil?
			[[[webView mainFrame] dataSource] pageTitle], NSTitleDocumentAttribute,	// title may be nil!!!
			nil];
	return [self initWithAttributedString:[[[[webView mainFrame] frameView] documentView] attributedString]];
}

- (id) initWithDocFormat:(NSData *)data documentAttributes:(NSDictionary **)dict;
{
	return [self initWithString:@"Can't read DOC format yet"];
}

// RTF/D create methods which can take an optional dict
// describing doc wide attributes to write out.  Current
// attributes are @"PaperSize",@"LeftMargin",@"RightMargin"
// @"TopMargin", @"BottomMargin", and @"HyphenationFactor".
// First is NSSize (NSValue) others are floats (NSNumber).

- (NSData *) RTFFromRange:(NSRange)range documentAttributes:(NSDictionary *)d
{
	NSMutableString *rtf=[NSMutableString stringWithCapacity:[self length]+100];
	id o;
	unsigned i, cnt=[self length];
	NSMutableArray *fonts=[NSMutableArray array];	// font table
	NSMutableArray *colors=[NSMutableArray array];	// color table
	NSArray *colorAttributes=[NSArray arrayWithObjects:
		NSBackgroundColorAttributeName,
		NSForegroundColorAttributeName,
		NSStrokeColorAttributeName,
		NSUnderlineColorAttributeName,
		NSStrikethroughColorAttributeName,
		nil];
	[rtf appendString:@"{\\rtf1\\mac\\ansi\\ansicpg10000\\cocoartf102\\deff0"];
	if((o=[d objectForKey:@"CocoaRTFVersion"]))
		[rtf appendFormat:@"\\cocoartf%d", [o intValue]];	// convert NS size values to RTF units
	if((o=[d objectForKey:@"PaperSize"]))
		[rtf appendFormat:@"\\paperw%d\\paperh%d", (int)([o sizeValue].width*TWIPSperPOINT), (int)([o sizeValue].height*TWIPSperPOINT)];	// convert NS size values to RTF units
	if((o=[d objectForKey:@"LeftMargin"]))
		[rtf appendFormat:@"\\margl%d", (int)([o floatValue]*TWIPSperPOINT)];	// convert NS size values to RTF units (twips)
	if((o=[d objectForKey:@"RightMargin"]))
		[rtf appendFormat:@"\\margr%d", (int)([o floatValue]*TWIPSperPOINT)];	// convert NS size values to RTF units
	if((o=[d objectForKey:@"TopMargin"]))
		[rtf appendFormat:@"\\margt%d", (int)([o floatValue]*TWIPSperPOINT)];	// convert NS size values to RTF units
	if((o=[d objectForKey:@"BottomMargin"]))
		[rtf appendFormat:@"\\margb%d", (int)([o floatValue]*TWIPSperPOINT)];	// convert NS size values to RTF units
	if((o=[d objectForKey:@"HyphenationFactor"]))
		[rtf appendFormat:@"\\hyphen%d", (int)([o floatValue]*TWIPSperPOINT)];	// convert NS size values to RTF units
	// write some other document wide attributes
	[rtf appendString:@"\n"];
	for(i=0; i<cnt; )
		{ // first pass: collect and write fonts and collect colors
		NSRange rng;
		NSDictionary *attr=[self attributesAtIndex:i longestEffectiveRange:&rng inRange:NSMakeRange(i, cnt-i)];
		NSFont *font=[attr objectForKey:NSFontAttributeName];
		NSEnumerator *e=[colorAttributes objectEnumerator];
		NSString *attrib;
		if(![fonts containsObject:[font fontName]])
			{ // fonttbl example: {\fonttbl\f0\fswiss\fcharset77 Helvetica-Bold;\f1\fswiss\fcharset77 Helvetica;\f2\fnil\fcharset77 Monaco;}
			if([fonts count] == 0)
				[rtf appendString:@"{\fonttbl"];	// first font
			[rtf appendFormat:@"\f%d", [fonts count]];	// unique number
														//// what does \fswiss resp. \fnil mean?
														// write \fcharset
			[rtf appendFormat:@" %@;", [font fontName]];	// e.g. Helvetica-Bold
			[fonts addObject:[font fontName]];	// register font name and encode
			}
		while((attrib=[e nextObject]))
			{
			NSColor *color=[attr objectForKey:attrib];
			if(color && ![colors containsObject:color])
				[colors addObject:color];	// new color found
			}
		i+=rng.length;
		}
	if([fonts count])
		[rtf appendString:@"}\n"];	// close font table
	// filetbl - optional
	if([colors count])
		{ // colortbl example: {\colortbl;\red255\green255\blue255;\red118\green15\blue80;}
		int c, ccnt=[colors count];
		[rtf appendString:@"{\\colortbl;\n"];	// open color table
		for(c=0; c<ccnt; i++)
			{
			NSColor *co=[colors objectAtIndex:i];
			[rtf appendFormat:@"\\red%u\\green%u\\blue%u;\n",
				(unsigned)(255*[co redComponent]+0.5),
				(unsigned)(255*[co greenComponent]+0.5),
				(unsigned)(255*[co blueComponent]+0.5)];	// color table entry
			}
		[rtf appendString:@"};\n"];	// close color table
		}
	// stylesheet (paragraph formats) - optional
	// ...
	// listtable - optional
	// ...
	// revtbl - optional
	// ...
	for(i=0; i<cnt; )
		{ // second pass: write contents
		NSRange rng;
		NSDictionary *attr=[self attributesAtIndex:i longestEffectiveRange:&rng inRange:NSMakeRange(i, cnt-i)];
		NSFont *font=[attr objectForKey:NSFontAttributeName];
		unichar c;
		[rtf appendFormat:@"\f%d\fs%d", [fonts indexOfObject:[font fontName]], [font pointSize]*TWIPSperPOINT];	// select font
		// FIXME: encode other attributes like colors
		while(rng.length-- > 0)
			{
			c=[[self string] characterAtIndex:i++];	// get character
			switch(c)
				{
				case '\n':
					[rtf appendString:@"\\\n"];	// write backslash and newline
					break;
				case '\\':
					[rtf appendString:@"\\\\"];	// write double backslash
					break;
				default:
					if(c >= 0x7f || c < ' ')
						{
						// FIXME: handle code page switches/hex escapes etc.
						[rtf appendFormat:@"\\'%02x", c];
						}
					else
						[rtf appendFormat:@"%C", c];	// copy character which should be plain 7 bit ASCII now
				}
			}
		}
	[rtf appendString:@"}\n"];
	return [rtf dataUsingEncoding:NSASCIIStringEncoding];	// encode
}

- (NSData *) RTFDFromRange:(NSRange)range documentAttributes:(NSDictionary *)d
{
	return [[self RTFDFileWrapperFromRange:range documentAttributes:d] serializedRepresentation];
}

- (NSFileWrapper *) RTFDFileWrapperFromRange:(NSRange)range 
						  documentAttributes:(NSDictionary *)dict
{
	return NIMP;
}

- (NSData *) dataFromRange:(NSRange) range
		documentAttributes:(NSDictionary *) dict
					 error:(NSError **) error
{
	NSString *fmt=[dict objectForKey:NSDocumentTypeDocumentAttribute];
	if([fmt isEqualToString:NSRTFTextDocumentType])
		return [self RTFFromRange:range documentAttributes:dict];
	if([fmt isEqualToString:NSRTFDTextDocumentType])
		return [self RTFDFromRange:range documentAttributes:dict];
	if([fmt isEqualToString:NSPlainTextDocumentType])
		return NIMP;	// return plain text as encoded NSData
	if([fmt isEqualToString:NSHTMLTextDocumentType])
		{
		// encode as HTML by using and filtering with attributes
		return NIMP;
		}
/*
		NSMacSimpleTextDocumentType
		NSDocFormatTextDocumentType
		NSWordMLTextDocumentType
		NSWebArchiveTextDocumentType
		*/
		return NIMP;
}

#if example_how_to_use_this_class_for_great_things

- (NSString *) attributedStringToHTML:(NSAttributedString*)aString
{
	NSArray *excluded = [NSArray arrayWithObjects: @"doctype", @"html",  
		@"head", @"body", @"xml", @"p", nil];
	NSDictionary *attr = [NSDictionary dictionaryWithObjectsAndKeys:
		NSHTMLTextDocumentType, NSDocumentTypeDocumentAttribute,
		//aTitle, NSTitleDocumentAttribute,
		excluded, NSExcludedElementsDocumentAttribute,
		[NSNumber numberWithInt: NSASCIIStringEncoding], NSCharacterEncodingDocumentAttribute,
		nil];
	NSData * tdata = [aString dataFromRange: NSMakeRange(0, [aString length])  
						 documentAttributes: attr error: nil];
	
	NSString * tString = [[NSString alloc] initWithData:tdata encoding:NSASCIIStringEncoding];	
	return tString;
}

#endif

- (NSDictionary *) fontAttributesInRange:(NSRange)range
{ // get font attributes for character at range.location
	NSDictionary *d;
	NSMutableDictionary *e;
	if(NSMaxRange(range) > [self length])
		[NSException raise:NSRangeException format:@"range out of bounds"];
	d=[self attributesAtIndex:range.location effectiveRange:NULL];
	e=[d mutableCopy];
	[e removeObjectForKey:NSLinkAttributeName];
	[e removeObjectForKey:NSParagraphStyleAttributeName];
	[e removeObjectForKey:NSAttachmentAttributeName];
	return [e autorelease];
}

- (NSDictionary *) rulerAttributesInRange:(NSRange)range
{
	NSDictionary *d;
	if(NSMaxRange(range) > [self length])
		[NSException raise:NSRangeException format:@"range out of bounds"];
	d=[self attributesAtIndex:range.location effectiveRange:NULL];
	return [NSDictionary dictionaryWithObjectsAndKeys:[d objectForKey:NSParagraphStyleAttributeName], NSParagraphStyleAttributeName, nil];
}

- (BOOL) containsAttachments
{
	NIMP;
	return NO;	// look for attachment character(s)
}

// FIXME: this and e.g. nextWordFromIndex: should be used in the string drawing algorithm to determine line breaks and wrapping!

- (unsigned) lineBreakBeforeIndex:(unsigned)location
					  withinRange:(NSRange)aRange
{
	// return first char to go on the next line or NSNotFound
	// if the speciefied range does not contain a line break	
	unsigned len=[self length];
	NSString *s=[self string];
	static NSCharacterSet *c;
	if(!c)
		c=[[NSCharacterSet characterSetWithCharactersInString:@"\n"] retain];
	if(aRange.location+aRange.length > len || location > len)
		[NSException raise:NSRangeException format:@"Invalid location %u and range %@", location, NSStringFromRange(aRange)];	// raise exception
	while(aRange.length-- > 0 && aRange.location < len && aRange.location < location)
		{
		if([c characterIsMember:[s characterAtIndex:aRange.location]])
			return aRange.location;
		aRange.location++;
		}
	return NSNotFound;
}

- (unsigned) lineBreakByHyphenatingBeforeIndex:(unsigned)location
											withinRange:(NSRange)aRange
{
	// we should know about hyphenation rules and a language attribute
	return [self lineBreakBeforeIndex:location withinRange:aRange];
}

- (NSRange) doubleClickAtIndex:(unsigned)location
{ // FIXME: should be linguistically correct
	NSRange rng;
	rng.location=[self nextWordFromIndex:location forward:NO];
	rng.length=[self nextWordFromIndex:location forward:YES]-rng.location;
#if 1
	NSLog(@"doubleClickAtIndex:%u -> %@", location, NSStringFromRange(rng));
#endif
	return rng;
}

- (unsigned) nextWordFromIndex:(unsigned)location forward:(BOOL)flag
{
	unsigned len=[self length];
	NSString *s=[self string];
	static NSCharacterSet *c;
	NSRange r;
#if 1
	NSLog(@"nextWordFromIndex:%u forward:%d", location, flag);
#endif
	if(!c)
		c=[[[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet] retain];
	if(location > len || (location == len && flag) || (location == 0 && !flag))
		[NSException raise:NSRangeException format:@"Invalid location %u", location];	// raise exception
	if(flag)
		r=[s rangeOfCharacterFromSet:c options:0 range:NSMakeRange(location+1, len-location-1)];
	else
		r=[s rangeOfCharacterFromSet:c options:NSBackwardsSearch range:NSMakeRange(0, location-1)];
	if(r.location != NSNotFound)
		return r.location;	// location of first whitespace
	return location;	// unchanged
}

- (NSData *) docFormatFromRange:(NSRange) range documentAttributes:(NSDictionary *) attrs;
{ // convert to Word DOC format
	return NIMP;
}

- (NSFileWrapper *) fileWrapperFromRange:(NSRange) range documentAttributes:(NSDictionary *) attrs error:(NSError **) error;
{
	return NIMP;
}

- (NSRange) itemNumberInTextList:(NSTextList *) textList atIndex:(unsigned) loc;
{
	NSRange rng;
	NSParagraphStyle *p=[self attribute:NSParagraphStyleAttributeName atIndex:loc longestEffectiveRange:&rng inRange:(NSRange){ 0, [self length] }];
	[p textLists];
	return rng;
}

- (NSRange) rangeOfTextBlock:(NSTextBlock *) textBlock atIndex:(unsigned) loc;
{
	NSRange rng;
	NSParagraphStyle *p=[self attribute:NSParagraphStyleAttributeName atIndex:loc longestEffectiveRange:&rng inRange:(NSRange){ 0, [self length] }];
	[p textBlocks];
	return rng;
}

- (NSRange) rangeOfTextList:(NSTextList *) textList atIndex:(unsigned) loc;
{
	NSRange rng;
	NSParagraphStyle *p=[self attribute:NSParagraphStyleAttributeName atIndex:loc longestEffectiveRange:&rng inRange:(NSRange){ 0, [self length] }];
	[p textLists];
	return rng;
}

- (NSRange) rangeOfTextTable:(NSTextTable *) textTable atIndex:(unsigned) loc;
{
	NSRange rng;
	NSParagraphStyle *p=[self attribute:NSParagraphStyleAttributeName atIndex:loc longestEffectiveRange:&rng inRange:(NSRange){ 0, [self length] }];
	[p textBlocks];
	return rng;
}

- (NSURL *) URLAtIndex:(NSUInteger) loc effectiveRange:(NSRangePointer) range; 
{
	// check for URL Link attribute
	// or if not found, check for string that looks like an URL (scheme:something)
	return NIMP;
}

+ (NSAttributedString *) attributedStringWithAttachment:(NSTextAttachment *)attach; // Problem, parse error
{
	return [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%C", NSAttachmentCharacter]
										   attributes:[NSDictionary dictionaryWithObject:attach forKey:NSAttachmentAttributeName]] autorelease]; }

/*
+textFileTypes;
{
	return [NSArray arrayWithObjects:@"txt", @"rtf", @"rtfd", @"html", nil];
}

+textUnfilteredFileTypes;
{
	return [NSArray arrayWithObjects:@"txt", @"rtf", @"rtfd", @"html", nil];
}

+textPasteboardTypes' not found
{
	return [NSArray arrayWithObjects:NSHTMLPboardType, NSRTFPboardType, NSRTFDPboardType, NSStringPboardType, nil];
}

+textUnfilteredPasteboardTypes' not found
{
	return [NSArray arrayWithObjects:NSHTMLPboardType, NSRTFPboardType, NSRTFDPboardType, NSStringPboardType, nil];
}

-docFormatFromRange:documentAttributes:' not found
{
	// format as .doc
}

	 -fileWrapperFromRange:documentAttributes:error:' not found
{
	// format as specified by NSDocumentTypeDocumentAttribute and encapsulate in a fileWrapper
}

	 -itemNumberInTextList:atIndex:' not found
	 -lineBreakByHyphenatingBeforeIndex:withinRange:' not found
	 -rangeOfTextBlock:atIndex:' not found
	 -rangeOfTextList:atIndex:' not found
	 -rangeOfTextTable:atIndex:' not found
	 */ 
@end


@implementation NSMutableAttributedString (NSMutableAttributedStringAdditions)

- (void) superscriptRange:(NSRange)range
{
	[self setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:NSSuperscriptAttributeName] range:range];
}

- (void) subscriptRange:(NSRange)range
{
	[self setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:-1] forKey:NSSuperscriptAttributeName] range:range];
}

- (void) unscriptRange:(NSRange)range
{ // Undo previous superscripting
	[self setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0] forKey:NSSuperscriptAttributeName] range:range];
}

- (void) applyFontTraits:(NSFontTraitMask)traitMask range:(NSRange)range
{
	NIMP;
}

- (void) setAlignment:(NSTextAlignment)alignment range:(NSRange)range
{
	NSParagraphStyle *style=nil;
	// get NSParagraphStyle of range
	if(!style)
		return;
	// make mutable
	// set alignment attribute for paragraph
	// define for full range
	NIMP;
	[self addAttribute:NSParagraphStyleAttributeName value:style range:range];
}

// Methods (NOT automagically called) to "fix" attributes
// after changes are made.  Range is specified in terms of 
// the final string.

- (void) fixAttributesInRange:(NSRange)range
{ // master fix method
	[self fixFontAttributeInRange:range];
	[self fixParagraphStyleAttributeInRange:range];
	[self fixAttachmentAttributeInRange:range];
}

- (void) fixFontAttributeInRange:(NSRange)range
{
	unsigned i;
	unsigned cnt=[self length];
	for(i=0; i<cnt; i++)
		{
		// substitute illegal or missing fonts
		// i.e. if the font(s) don't support the character range, substitute a font
		}
}

- (void) fixParagraphStyleAttributeInRange:(NSRange)range
{
	NSRange lineRange=range;
	unsigned end=NSMaxRange(range);
	NSString *str=[self string];
//	NSLog(@"0 %@", NSStringFromRange(range));
	if(end > [self length])
		[NSException raise:NSRangeException format:@"range too long"];
	while(lineRange.location < end)
		{
		NSParagraphStyle *attrib;
		NSRange attribRange;
//		NSLog(@"a %@", NSStringFromRange(lineRange));
		lineRange=[str lineRangeForRange:lineRange];
//		NSLog(@"b %@", NSStringFromRange(lineRange));
		attrib=[self attribute:NSParagraphStyleAttributeName atIndex:lineRange.location longestEffectiveRange:&attribRange inRange:range];
//		NSLog(@"c %@ %@", NSStringFromRange(attribRange), attrib);
		attribRange.location=NSMaxRange(attribRange);	// start to update where attribRange ends
		attribRange=NSIntersectionRange(attribRange, lineRange);	// but not beyond line end
		attribRange=NSIntersectionRange(attribRange, range);	// but not beyond given range
//		NSLog(@"d %@", NSStringFromRange(attribRange));
		if(attribRange.length > 0)
			{ // only if there is something to fix
			NSLog(@"d %@", NSStringFromRange(attribRange));
			if(attrib)
				[self addAttribute:NSParagraphStyleAttributeName value:attrib range:attribRange];
			else
				[self removeAttribute:NSParagraphStyleAttributeName range:attribRange];
			}
//		NSLog(@"e %@", NSStringFromRange(lineRange)),
		lineRange.location=NSMaxRange(lineRange);	// go to next line
		}
}

- (void) fixAttachmentAttributeInRange:(NSRange)range
{
	unsigned end=NSMaxRange(range);
	NSString *str=[self string];
	if(end > [self length])
		[NSException raise:NSRangeException format:@"range too long"];
	while(range.location < end)
		{
		NSRange aRange;
		NSTextAttachment *a=[self attribute:NSAttachmentAttributeName atIndex:range.location effectiveRange:&aRange];
//		NSLog(@"a %@", NSStringFromRange(aRange));
		if(a)
			{ // this range has an attachment attribute - remove at locations without attachment Character
				unsigned e=NSMaxRange(aRange);
				e=MIN(e, end);
				while(range.location < e)
					{
					if([str characterAtIndex:range.location] != NSAttachmentCharacter)
						{
						NSRange rng=range;
						while(range.location < e)
							if([str characterAtIndex:range.location] != NSAttachmentCharacter)
								range.location++;	// collect sequences of non-attachment characters
						rng.length=range.location-rng.location;
//						NSLog(@"b %@", NSStringFromRange(rng));
						if(rng.length > 0)
							[self removeAttribute:NSAttachmentAttributeName range:rng];	// remove attachments for non-attachment characters
						}
					range.location++;	// skip attachment characters
					}
			}
		range.location=NSMaxRange(aRange);	// loop over attributes
		}
}

- (void) setBaseWritingDirection:(NSWritingDirection) direction range:(NSRange) range;
{
	// FIXME: does this change all paragraph styles?
	[self addAttribute:@"BaseWritingDirection" value:[NSNumber numberWithInt:direction] range:range];
}

- (BOOL) readFromData:(NSData *) data options:(NSDictionary *) opts documentAttributes:(NSDictionary **) attrs;
{
	return [self readFromData:data options:opts documentAttributes:attrs error:NULL];
}

- (BOOL) readFromData:(NSData *) data options:(NSDictionary *) opts documentAttributes:(NSDictionary **) attrs error:(NSError **) error;
{
	NSAttributedString *a=[[NSAttributedString alloc] initWithData:data options:opts documentAttributes:attrs error:error];
	if(!a) return NO;
	[self setAttributedString:a];
	[a release];
	return YES;
}
						   
- (BOOL) readFromURL:(NSURL *) url options:(NSDictionary *) opts documentAttributes:(NSDictionary **) attrs;
{
	return [self readFromURL:url options:opts documentAttributes:attrs error:NULL];
}

- (BOOL) readFromURL:(NSURL *) url options:(NSDictionary *) opts documentAttributes:(NSDictionary **) attrs error:(NSError **) error;
{
	NSAttributedString *a=[[NSAttributedString alloc] initWithURL:url options:opts documentAttributes:attrs error:error];
	if(!a) return NO;
	[self setAttributedString:a];
	[a release];
	return YES;
}

@end
