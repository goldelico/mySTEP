//
//  CFString.h
//  CoreFoundation
//
//  Created by H. Nikolaus Schaller on 03.10.08.
//  Copyright 2008 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#ifndef _mySTEP_H_CFString
#define _mySTEP_H_CFString

#import <CoreFoundation/CFBase.h>

/*
 #import <CoreFoundation/CFLocale.h>
#import <CoreFoundation/CFArray.h>
#import <CoreFoundation/CFData.h>
*/

#ifndef _mySTEP_H_CFBase
typedef NSString *CFStringRef;
#endif

typedef CFOptionFlags CFStringCompareFlags;
typedef UInt32 CFStringEncoding;
typedef CFIndex CFStringEncodings;

// typedef NSComparisonResult CFComparisonResult;

// CFStringRef CFSTR(const char *str) { return (CFStringRef) [[[NSString alloc] initWithCString:str] autorelease]; }
// formally, the CFSTR generated strings should be the same if the constant is already known and should be immune against retain/release problems

#define CFSTR(str) (CFStringRef) [[[NSString alloc] initWithCString:(str)] autorelease]


#define CFStringCompare (s1, s2, opt) [(s1) compare:(s2) options:(opt)]
#define CFStringCompareWithOptions (s1, s2, rng, opt) [(s1) compare:(s2) range:(rng) options:(opt)]
#define CFStringCompareWithOptionsAndLocale (s1, s2, rng, opt, loc) [(s1) compare:(s2) range:(rng) options:(opt) locale:(loc)]

#define CFStringConvertEncodingToNSStringEncoding(enc) (enc)
#define CFStringConvertNSStringEncodingToEncoding(enc) (enc)

#define CFStringCreateArrayBySeparatingStrings (alloc, str, sep) [(str) componentsSeparatedByString:(sep)]	// allocator is ignored
#define CFStringCreateByCombiningStrings (alloc, array, sep) [(array) componentsJoinedByString:(sep)]	// allocator is ignored

#define CFStringCreateCopy (alloc, str) [(str) copy]

#define CFStringCreateExternalRepresentation (alloc, str, enc, lossByte) [(str) dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(enc)]

#define CFStringCreateWithBytes (alloc, bytes, n, enc, irep) [[NSString alloc] initWithBytes:(bytes) length:(n)]



enum
{
#define kCFStringEncoding(x) kCFStringEncoding##x
	kCFStringEncoding(UNDEFINED) = 0,
	kCFStringEncoding(MacRoman),
    kCFStringEncoding(MacJapanese),
    kCFStringEncoding(MacChineseTrad),
    kCFStringEncoding(MacKorean),
    kCFStringEncoding(MacArabic),
    kCFStringEncoding(MacHebrew),
    kCFStringEncoding(MacGreek),
    kCFStringEncoding(MacCyrillic),
    kCFStringEncoding(MacDevanagari),
    kCFStringEncoding(MacGurmukhi),
    kCFStringEncoding(MacGujarati),
    kCFStringEncoding(MacOriya),
    kCFStringEncoding(MacBengali),
    kCFStringEncoding(MacTamil),
    kCFStringEncoding(MacTelugu),
    kCFStringEncoding(MacKannada),
    kCFStringEncoding(MacMalayalam),
    kCFStringEncoding(MacSinhalese),
    kCFStringEncoding(MacBurmese),
    kCFStringEncoding(MacKhmer),
    kCFStringEncoding(MacThai),
    kCFStringEncoding(MacLaotian),
    kCFStringEncoding(MacGeorgian),
    kCFStringEncoding(MacArmenian),
    kCFStringEncoding(MacChineseSimp),
    kCFStringEncoding(MacTibetan),
    kCFStringEncoding(MacMongolian),
    kCFStringEncoding(MacEthiopic),
    kCFStringEncoding(MacCentralEurRoman),
    kCFStringEncoding(MacVietnamese),
    kCFStringEncoding(MacExtArabic),
    /* The following use script code 0, smRoman */
    kCFStringEncoding(MacSymbol),
    kCFStringEncoding(MacDingbats),
    kCFStringEncoding(MacTurkish),
    kCFStringEncoding(MacCroatian),
    kCFStringEncoding(MacIcelandic),
    kCFStringEncoding(MacRomanian),
    kCFStringEncoding(MacCeltic),
    kCFStringEncoding(MacGaelic),
    /* The following use script code 4, smArabic */
    kCFStringEncoding(MacFarsi),	/* Like MacArabic but uses Farsi digits */
    /* The following use script code 7, smCyrillic */
    kCFStringEncoding(MacUkrainian),
    /* The following use script code 32, smUnimplemented */
    kCFStringEncoding(MacInuit),
    kCFStringEncoding(MacVT100),	/* VT100/102 font from Comm Toolbox: Latin-1 repertoire + box drawing etc */
    /* Special Mac OS encodings*/
	kCFStringEncoding(MacHFS),	/* Meta-value, should never appear in a table */
	
    /* Unicode & ISO UCS encodings begin at 0x100 */
    /* We don't use Unicode variations defined in TextEncoding; use the ones in CFString.h, instead. */
	
    /* ISO 8-bit and 7-bit encodings begin at 0x200 */
	kCFStringEncoding(ISOLatin1) = 0x200, /* defined in CoreFoundation/CFString.h */
	kCFStringEncoding(ISOLatin2),	/* ISO 8859-2 */
    kCFStringEncoding(ISOLatin3),	/* ISO 8859-3 */
    kCFStringEncoding(ISOLatin4),	/* ISO 8859-4 */
    kCFStringEncoding(ISOLatinCyrillic),	/* ISO 8859-5 */
    kCFStringEncoding(ISOLatinArabic),	/* ISO 8859-6, =ASMO 708, =DOS CP 708 */
    kCFStringEncoding(ISOLatinGreek),	/* ISO 8859-7 */
    kCFStringEncoding(ISOLatinHebrew),	/* ISO 8859-8 */
    kCFStringEncoding(ISOLatin5),	/* ISO 8859-9 */
    kCFStringEncoding(ISOLatin6),	/* ISO 8859-10 */
    kCFStringEncoding(ISOLatinThai),	/* ISO 8859-11 */
    kCFStringEncoding(ISOLatin7),	/* ISO 8859-13 */
    kCFStringEncoding(ISOLatin8),	/* ISO 8859-14 */
    kCFStringEncoding(ISOLatin9),	/* ISO 8859-15 */
	
    /* MS-DOS & Windows encodings begin at 0x400 */
    kCFStringEncoding(DOSLatinUS) = 437,	/* code page 437 */
    kCFStringEncoding(DOSGreek) = 737,		/* code page 737 (formerly code page 437G) */
    kCFStringEncoding(DOSBalticRim) = 775,	/* code page 775 */
    kCFStringEncoding(DOSLatin1) = 850,	/* code page 850, "Multilingual" */
    kCFStringEncoding(DOSGreek1) = 851,	/* code page 851 */
    kCFStringEncoding(DOSLatin2) = 852,	/* code page 852, Slavic */
    kCFStringEncoding(DOSCyrillic) = 855,	/* code page 855, IBM Cyrillic */
    kCFStringEncoding(DOSTurkish) = 857,	/* code page 857, IBM Turkish */
    kCFStringEncoding(DOSPortuguese) = 860,	/* code page 860 */
    kCFStringEncoding(DOSIcelandic) = 861,	/* code page 861 */
    kCFStringEncoding(DOSHebrew) = 862,	/* code page 862 */
    kCFStringEncoding(DOSCanadianFrench) = 863, /* code page 863 */
    kCFStringEncoding(DOSArabic) = 864,	/* code page 864 */
    kCFStringEncoding(DOSNordic) = 865,	/* code page 865 */
    kCFStringEncoding(DOSRussian) = 866,	/* code page 866 */
    kCFStringEncoding(DOSGreek2) = 869,	/* code page 869, IBM Modern Greek */
    kCFStringEncoding(DOSThai) = 874,		/* code page 874, also for Windows */
    kCFStringEncoding(DOSJapanese) = 932,	/* code page 932, also for Windows */
    kCFStringEncoding(DOSChineseSimplif) = 936, /* code page 936, also for Windows */
    kCFStringEncoding(DOSKorean) = 949,	/* code page 949, also for Windows; Unified Hangul Code */
    kCFStringEncoding(DOSChineseTrad) = 950,	/* code page 950, also for Windows */
	kCFStringEncoding(WindowsLatin1),
    kCFStringEncoding(WindowsLatin2) = 1250,	/* code page 1250, Central Europe */
    kCFStringEncoding(WindowsCyrillic) = 1251,	/* code page 1251, Slavic Cyrillic */
    kCFStringEncoding(WindowsGreek) = 1253,	/* code page 1253 */
    kCFStringEncoding(WindowsLatin5) = 1254,	/* code page 1254, Turkish */
    kCFStringEncoding(WindowsHebrew) = 1255,	/* code page 1255 */
    kCFStringEncoding(WindowsArabic) = 1256,	/* code page 1256 */
    kCFStringEncoding(WindowsBalticRim) = 1257,	/* code page 1257 */
    kCFStringEncoding(WindowsKoreanJohab) = 1361, /* code page 1361, for Windows NT */
    kCFStringEncoding(WindowsVietnamese) = 1258, /* code page 1258 */
	
    /* Various national standards begin at 0x600 */
	kCFStringEncoding(ASCII) = 0x0600,
    kCFStringEncoding(JIS_X0201_76),
    kCFStringEncoding(JIS_X0208_83),
    kCFStringEncoding(JIS_X0208_90),
    kCFStringEncoding(JIS_X0212_90),
    kCFStringEncoding(JIS_C6226_78),
    kCFStringEncoding(ShiftJIS_X0213_00), /* Shift-JIS format encoding of JIS X0213 planes 1 and 2*/
    kCFStringEncoding(GB_2312_80),
    kCFStringEncoding(GBK_95),		/* annex to GB 13000-93; for Windows 95 */
    kCFStringEncoding(GB_18030_2000),
    kCFStringEncoding(KSC_5601_87),	/* same as KSC 5601-92 without Johab annex */
    kCFStringEncoding(KSC_5601_92_Johab), /* KSC 5601-92 Johab annex */
    kCFStringEncoding(CNS_11643_92_P1),	/* CNS 11643-1992 plane 1 */
    kCFStringEncoding(CNS_11643_92_P2),	/* CNS 11643-1992 plane 2 */
    kCFStringEncoding(CNS_11643_92_P3),	/* CNS 11643-1992 plane 3 (was plane 14 in 1986 version) */
	
    /* ISO 2022 collections begin at 0x800 */
    kCFStringEncoding(ISO_2022_JP) = 0x800,
    kCFStringEncoding(ISO_2022_JP_2),
    kCFStringEncoding(ISO_2022_JP_1), /* RFC 2237*/
    kCFStringEncoding(ISO_2022_JP_3), /* JIS X0213*/
    kCFStringEncoding(ISO_2022_CN),
    kCFStringEncoding(ISO_2022_CN_EXT),
    kCFStringEncoding(ISO_2022_KR),
	
    /* EUC collections begin at 0x900 */
    kCFStringEncoding(EUC_JP) = 0x900,		/* ISO 646, 1-byte katakana, JIS 208, JIS 212 */
    kCFStringEncoding(EUC_CN),		/* ISO 646, GB 2312-80 */
    kCFStringEncoding(EUC_TW),		/* ISO 646, CNS 11643-1992 Planes 1-16 */
    kCFStringEncoding(EUC_KR),		/* ISO 646, KS C 5601-1987 */
	
    /* Misc standards begin at 0xA00 */
	//   kCFStringEncoding(ShiftJIS),		/* plain Shift-JIS */
    kCFStringEncoding(KOI8_R) = 0xa00,		/* Russian internet standard */
    kCFStringEncoding(Big5),		/* Big-5 (has variants) */
    kCFStringEncoding(MacRomanLatin1),	/* Mac OS Roman permuted to align with ISO Latin-1 */
    kCFStringEncoding(HZ_GB_2312),	/* HZ (RFC 1842, for Chinese mail & news) */
    kCFStringEncoding(Big5_HKSCS_1999), /* Big-5 with Hong Kong special char set supplement*/
	
    /* Other platform encodings*/
	kCFStringEncoding(NextStepLatin), /* defined in CoreFoundation/CFString.h */
	
    /* EBCDIC & IBM host encodings begin at 0xC00 */
    kCFStringEncoding(EBCDIC_US) = 0xc00,	/* basic EBCDIC-US */
    kCFStringEncoding(EBCDIC_CP037),	/* code page 037, extended EBCDIC (Latin-1 set) for US,Canada... */
};

#endif
