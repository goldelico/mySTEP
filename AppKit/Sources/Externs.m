/* 
   Externs.m

   External data

   Copyright (C) 1997 Free Software Foundation, Inc.

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import<Foundation/NSString.h>
#import <AppKit/NSEvent.h>

// Global strings
NSString *NSModalPanelRunLoopMode= @"ModalPanelMode";
NSString *NSEventTrackingRunLoopMode= @"EventTrackingMode";
NSString *NSApplicationIcon= @"NSApplicationIcon";
NSString *NSApplicationPath= @"NSApplicationPath";
NSString *NSApplicationName= @"NSApplicationName";
NSString *NSApplicationProcessIdentifier= @"NSApplicationProcessIdentifier";

//
// Global Exception Strings
//
NSString *NSAbortModalException= @"AbortModal";
NSString *NSAbortPrintingException= @"AbortPrinting";
NSString *NSAppKitIgnoredException= @"AppKitIgnored";
NSString *NSAppKitVirtualMemoryException= @"AppKitVirtualMemory";
NSString *NSBadBitmapParametersException= @"BadBitmapParameters";
NSString *NSBadComparisonException= @"BadComparison";
NSString *NSBadRTFColorTableException= @"BadRTFColorTable";
NSString *NSBadRTFDirectiveException= @"BadRTFDirective";
NSString *NSBadRTFFontTableException= @"BadRTFFontTable";
NSString *NSBadRTFStyleSheetException= @"BadRTFStyleSheet";
NSString *NSBrowserIllegalDelegateException= @"BrowserIllegalDelegate";
NSString *NSColorListIOException= @"ColorListIO";
NSString *NSColorListNotEditableException= @"ColorListNotEditable";
NSString *NSDraggingException= @"Draggin";
NSString *NSFontUnavailableException= @"FontUnavailable";
NSString *NSIllegalSelectorException= @"IllegalSelector";
NSString *NSImageCacheException= @"ImageCache";
NSString *NSNibLoadingException= @"NibLoading";
NSString *NSPPDIncludeNotFoundException= @"PPDIncludeNotFound";
NSString *NSPPDIncludeStackOverflowException= @"PPDIncludeStackOverflow";
NSString *NSPPDIncludeStackUnderflowException= @"PPDIncludeStackUnderflow";
NSString *NSPPDParseException= @"PPDParse";
NSString *NSPrintOperationExistsException= @"PrintOperationExists";
NSString *NSPrintPackageException= @"PrintPackage";
NSString *NSPrintingCommunicationException= @"PrintingCommunication";
NSString *NSRTFPropertyStackOverflowException= @"RTFPropertyStackOverflow";
NSString *NSTIFFException= @"TIFF";
NSString *NSTextLineTooLongException= @"TextLineTooLong";
NSString *NSTextNoSelectionException= @"TextNoSelection";
NSString *NSTextReadException= @"TextRead";
NSString *NSTextWriteException= @"TextWrite";
NSString *NSTypedStreamVersionException= @"TypedStreamVersion";
NSString *NSWindowManagerException= @"WindowManager";
NSString *NSWordTablesReadException= @"WordTablesRead";
NSString *NSWordTablesWriteException= @"WordTablesWrite";

// NSColor Global strings
NSString *NSCalibratedWhiteColorSpace= @"NSCalibratedWhiteColorSpace";
NSString *NSCalibratedBlackColorSpace= @"NSCalibratedBlackColorSpace";
NSString *NSCalibratedRGBColorSpace= @"NSCalibratedRGBColorSpace";
NSString *NSDeviceWhiteColorSpace= @"NSDeviceWhiteColorSpace";
NSString *NSDeviceBlackColorSpace= @"NSDeviceBlackColorSpace";
NSString *NSDeviceRGBColorSpace= @"NSDeviceRGBColorSpace";
NSString *NSDeviceCMYKColorSpace= @"NSDeviceCMYKColorSpace";
NSString *NSNamedColorSpace= @"NSNamedColorSpace";
NSString *NSPatternImageColorSpace= @"NSPatternImageColorSpace";
NSString *NSCustomColorSpace= @"NSCustomColorSpace";

// NSColor Global gray values
const float NSBlack		= 0;
const float NSDarkGray	= 0.333;
const float NSGray		= 0.5;
const float NSLightGray	= 0.667;
const float NSWhite		= 1;

// NSDataLink global strings
NSString *NSDataLinkFileNameExtension= @"dlf";

// NSScreen Global device dictionary key strings
NSString *NSDeviceResolution= @"Resolution";
NSString *NSDeviceColorSpaceName= @"ColorSpaceName";
NSString *NSDeviceBitsPerSample= @"BitsPerSample";
NSString *NSDeviceIsScreen= @"IsScreen";
NSString *NSDeviceIsPrinter= @"IsPrinter";
NSString *NSDeviceSize= @"Size";
// NSString *NSUserSpaceScaleFactor;	// not public
// NSString *NSScreenNumber;	// not public

// Pasteboard Type Globals 
NSString *NSStringPboardType		= @"NSStringPboardType";
NSString *NSColorPboardType			= @"NSColorPboardType";
NSString *NSFileContentsPboardType	= @"NSFileContentsPboardType";
NSString *NSFilenamesPboardType		= @"NSFilenamesPboardType";
NSString *NSFontPboardType			= @"NSFontPboardType";
NSString *NSRulerPboardType			= @"NSRulerPboardType";
NSString *NSPostScriptPboardType	= @"NSPostScriptPboardType";
NSString *NSTabularTextPboardType	= @"NSTabularTextPboardType";
NSString *NSRTFPboardType			= @"NSRTFPboardType";
NSString *NSRTFDPboardType			= @"NSRTFDPboardType";
NSString *NSTIFFPboardType			= @"NSTIFFPboardType";
NSString *NSDataLinkPboardType		= @"NSDataLinkPboardType";
NSString *NSGeneralPboardType		= @"NSGeneralPboardType";

// Pasteboard Name Globals 
NSString *NSDragPboard				= @"NSDragPboard";
NSString *NSFindPboard				= @"NSFindPboard";
NSString *NSFontPboard				= @"NSFontPboard";
NSString *NSGeneralPboard			= @"NSGeneralPboard";
NSString *NSRulerPboard				= @"NSRulerPboard";

// Pasteboard Exceptions
NSString *NSPasteboardCommunicationException=
		@"NSPasteboardCommunicationException";

// Printing Information Dictionary Keys 
NSString *NSPrintAllPages= @"PrintAllPages";
NSString *NSPrintBottomMargin= @"PrintBottomMargin";
NSString *NSPrintCopies= @"PrintCopies";
NSString *NSPrintFaxCoverSheetName= @"PrintFaxCoverSheetName";
NSString *NSPrintFaxHighResolution= @"PrintFaxHighResolution";
NSString *NSPrintFaxModem= @"PrintFaxModem";
NSString *NSPrintFaxReceiverNames= @"PrintFaxReceiverNames";
NSString *NSPrintFaxReceiverNumbers= @"PrintFaxReceiverNumbers";
NSString *NSPrintFaxReturnReceipt= @"PrintFaxReturnReceipt";
NSString *NSPrintFaxSendTime= @"PrintFaxSendTime";
NSString *NSPrintFaxTrimPageEnds= @"PrintFaxTrimPageEnds";
NSString *NSPrintFaxUseCoverSheet= @"PrintFaxUseCoverSheet";
NSString *NSPrintFirstPage= @"PrintFirstPage";
NSString *NSPrintHorizonalPagination= @"PrintHorizonalPagination";
NSString *NSPrintHorizontallyCentered= @"PrintHorizontallyCentered";
NSString *NSPrintJobDisposition= @"PrintJobDisposition";
NSString *NSPrintJobFeatures= @"PrintJobFeatures";
NSString *NSPrintLastPage= @"PrintLastPage";
NSString *NSPrintLeftMargin= @"PrintLeftMargin";
NSString *NSPrintManualFeed= @"PrintManualFeed";
NSString *NSPrintOrientation= @"PrintOrientation";
NSString *NSPrintPagesPerSheet= @"PrintPagesPerSheet";
NSString *NSPrintPaperFeed= @"PrintPaperFeed";
NSString *NSPrintPaperName= @"PrintPaperName";
NSString *NSPrintPaperSize= @"PrintPaperSize";
NSString *NSPrintPrinter= @"PrintPrinter";
NSString *NSPrintReversePageOrder= @"PrintReversePageOrder";
NSString *NSPrintRightMargin= @"PrintRightMargin";
NSString *NSPrintSavePath= @"PrintSavePath";
NSString *NSPrintScalingFactor= @"PrintScalingFactor";
NSString *NSPrintTopMargin= @"PrintTopMargin";
NSString *NSPrintHorizontalPagination= @"PrintHorizontalPagination";
NSString *NSPrintVerticalPagination= @"PrintVerticalPagination";
NSString *NSPrintVerticallyCentered= @"PrintVerticallyCentered";

// Print Job Disposition Values 
NSString *NSPrintCancelJob 	= @"PrintCancelJob";
NSString *NSPrintFaxJob 	= @"PrintFaxJob";
NSString *NSPrintPreviewJob= @"PrintPreviewJob";
NSString *NSPrintSaveJob 	= @"PrintSaveJob";
NSString *NSPrintSpoolJob 	= @"PrintSpoolJob";

//
// Notifications
//
#define NOTE(name) NSString *NS##name##Notification

// NSApplication notifications
NOTE(ApplicationDidBecomeActive)		= @"ApplicationDidBecomeActive";
NOTE(ApplicationDidFinishLaunching)		= @"ApplicationDidFinishLaunching";
NOTE(ApplicationDidHide)				= @"ApplicationDidHide";
NOTE(ApplicationDidResignActive)		= @"ApplicationDidResignActive";
NOTE(ApplicationDidUnhide)				= @"ApplicationDidUnhide";
NOTE(ApplicationDidUpdate)				= @"ApplicationDidUpdate";
NOTE(ApplicationWillBecomeActive)		= @"ApplicationWillBecomeActive";
NOTE(ApplicationWillFinishLaunching)	= @"ApplicationWillFinishLaunching";
NOTE(ApplicationWillTerminate)			= @"ApplicationWillTerminate";
NOTE(ApplicationWillHide)				= @"ApplicationWillHide";
NOTE(ApplicationWillResignActive)		= @"ApplicationWillResignActive";
NOTE(ApplicationWillUnhide)				= @"ApplicationWillUnhide";
NOTE(ApplicationWillUpdate)				= @"ApplicationWillUpdate";

// NSColorList notifications
NOTE(ColorListChanged)					= @"ColorListChanged";

// NSColorPanel notifications
NOTE(ColorPanelColorChanged)			= @"ColorPanelColorChanged";

// NSComboBox notifications
NOTE(ComboBoxWillPopUp)					= @"ComboBoxWillPopUp";
NOTE(ComboBoxWillDismiss)				= @"ComboBoxWillDismiss";
NOTE(ComboBoxSelectionDidChange)		= @"ComboBoxSelectionDidChange";
NOTE(ComboBoxSelectionIsChanging)		= @"ComboBoxSelectionIsChanging";

// NSControl notifications
NOTE(ControlTextDidBeginEditing)		= @"ControlTextDidBeginEditing";
NOTE(ControlTextDidEndEditing)			= @"ControlTextDidEndEditing";
NOTE(ControlTextDidChange)				= @"ControlTextDidChange";

// NSImageRep notifications
NOTE(ImageRepRegistryChanged)			= @"ImageRepRegistryChanged";

// NSSplitView notifications
NOTE(SplitViewDidResizeSubviews)		= @"SplitViewDidResizeSubviews";
NOTE(SplitViewWillResizeSubviews)		= @"SplitViewWillResizeSubviews";

// NSTableView notifications
NOTE(TableViewSelectionDidChange)		= @"TableViewSelectionDidChange";
NOTE(TableViewSelectionIsChanging)		= @"TableViewSelectionIsChanging";
NOTE(TableViewColumnDidResize)			= @"TableViewColumnDidResize";
NOTE(TableViewColumnDidMove)			= @"TableViewColumnDidMove";

// NSOutlineView notifications
NOTE(OutlineViewColumnDidMove)			= @"OutlineViewColumnDidMove";
NOTE(OutlineViewColumnDidResize)		= @"OutlineViewColumnDidResize";
NOTE(OutlineViewSelectionDidChange)		= @"OutlineViewSelectionDidChange";
NOTE(OutlineViewSelectionIsChanging)	= @"OutlineViewSelectionIsChanging";
NOTE(OutlineViewItemDidExpand)			= @"OutlineViewItemDidExpand";
NOTE(OutlineViewItemDidCollapse)		= @"OutlineViewItemDidCollapse";
NOTE(OutlineViewItemWillExpand)			= @"OutlineViewItemWillExpand";
NOTE(OutlineViewItemWillCollapse)		= @"OutlineViewItemWillCollapse";

// NSText notifications
NOTE(TextDidBeginEditing)				= @"TextDidBeginEditing";
NOTE(TextDidEndEditing)					= @"TextDidEndEditing";
NOTE(TextDidChange)						= @"TextDidChange";
NOTE(TextViewDidChangeSelection)		= @"TextViewDidChangeSelection";
NOTE(TextViewWillChangeNotifyingTextView)	= @"NSTextViewWillChangeNotifyingTextView";
NOTE(TextViewDidChangeTypingAttributes)		= @"NSTextViewDidChangeTypingAttributes";

// NSView notifications
NOTE(ViewFocusDidChange)				= @"ViewFocusDidChange";
NOTE(ViewFrameDidChange)				= @"ViewFrameDidChange";
NOTE(ViewBoundsDidChange)				= @"ViewBoundsDidChange";

// NSWindow notifications
NOTE(WindowDidBecomeKey)				= @"WindowDidBecomeKey";
NOTE(WindowDidBecomeMain)				= @"WindowDidBecomeMain";
NOTE(WindowDidChangeScreen)				= @"WindowDidChangeScreen";
NOTE(WindowDidChangeScreenProfile)		= @"WindowDidChangeScreenProfile";
NOTE(WindowDidDeminiaturize)			= @"WindowDidDeminiaturize";
NOTE(WindowDidExpose)					= @"WindowDidExpose";
NOTE(WindowDidMiniaturize)				= @"WindowDidMiniaturize";
NOTE(WindowDidMove)						= @"WindowDidMove";
NOTE(WindowDidResignKey)				= @"WindowDidResignKey";
NOTE(WindowDidResignMain)				= @"WindowDidResignMain";
NOTE(WindowDidResize)					= @"WindowDidResize";
NOTE(WindowDidUpdate)					= @"WindowDidUpdate";
NOTE(WindowWillClose)					= @"WindowWillClose";
NOTE(WindowWillMiniaturize)				= @"WindowWillMiniaturize";
NOTE(WindowWillMove)					= @"WindowWillMove";

NOTE(ScreenDidChangeProfile)			= @"ScreenDidChangeProfile";

// NSWorkspace notifications
NOTE(WorkspaceDidLaunchApplication)		= @"WorkspaceDidLaunchApplication";
NOTE(WorkspaceDidMount)					= @"WorkspaceDidMount";
NOTE(WorkspaceDidPerformFileOperation)	= @"WorkspaceDidPerformFileOperation";
NOTE(WorkspaceDidTerminateApplication)	= @"WorkspaceDidTerminateApplication";
NOTE(WorkspaceDidUnmount)				= @"WorkspaceDidUnmount";
NOTE(WorkspaceWillLaunchApplication)	= @"WorkspaceWillLaunchApplication";
NOTE(WorkspaceWillPowerOff)				= @"WorkspaceWillPowerOff";
NOTE(WorkspaceWillUnmount)				= @"WorkspaceWillUnmount";

// Workspace File Type Globals 
NSString *NSPlainFileType 				= @"NSPlainFileType";
NSString *NSDirectoryFileType 			= @"NSDirectoryFileType";
NSString *NSApplicationFileType 		= @"NSApplicationFileType";
NSString *NSFilesystemFileType 			= @"NSFilesystemFileType";
NSString *NSShellCommandFileType 		= @"NSShellCommandFileType";

// Workspace File Operation Globals 
NSString *NSWorkspaceCompressOperation 	= @"NSWorkspaceCompressOperation";
NSString *NSWorkspaceCopyOperation 		= @"NSWorkspaceCopyOperation";
NSString *NSWorkspaceDecompressOperation= @"NSWorkspaceDecompressOperation";
NSString *NSWorkspaceDecryptOperation 	= @"NSWorkspaceDecryptOperation";
NSString *NSWorkspaceDestroyOperation 	= @"NSWorkspaceDestroyOperation";
NSString *NSWorkspaceDuplicateOperation	= @"NSWorkspaceDuplicateOperation";
NSString *NSWorkspaceEncryptOperation 	= @"NSWorkspaceEncryptOperation";
NSString *NSWorkspaceLinkOperation 		= @"NSWorkspaceLinkOperation";
NSString *NSWorkspaceMoveOperation 		= @"NSWorkspaceMoveOperation";
NSString *NSWorkspaceRecycleOperation 	= @"NSWorkspaceRecycleOperation";

// NSStringDrawing & NSAttributedString Additions
NSString *NSAttachmentAttributeName		= @"NSAttachment";
NSString *NSBackgroundColorAttributeName= @"NSBackgroundColor";
NSString *NSBaselineOffsetAttributeName	= @"NSBaselineOffset";
NSString *NSCursorAttributeName			= @"NSCursor";
NSString *NSExpansionAttributeName		= @"NSExpansion";
NSString *NSFontAttributeName			= @"NSFont";
NSString *NSForegroundColorAttributeName= @"NSColor";
NSString *NSKernAttributeName 			= @"NSKern";
NSString *NSLigatureAttributeName		= @"NSLigature";
NSString *NSLinkAttributeName			= @"NSLink";
NSString *NSObliquenessAttributeName	= @"NSObliqueness";
NSString *NSParagraphStyleAttributeName = @"NSParagraphStyle";
NSString *NSShadowAttributeName			= @"NSShadow";
NSString *NSStrikethroughColorAttributeName	= @"NSStrikethroughColor";
NSString *NSStrikethroughStyleAttributeName	= @"NSStrikethroughStyle";
NSString *NSStrokeColorAttributeName	= @"NSStrokeColor";
NSString *NSStrokeWidthAttributeName	= @"NSStrokeWidth";
NSString *NSSuperscriptAttributeName 	= @"NSSuperscript";
NSString *NSToolTipAttributeName		= @"NSToolTip";
NSString *NSUnderlineColorAttributeName	= @"NSUnderlineColor";
NSString *NSUnderlineStyleAttributeName	= @"NSUnderlineStyle";

NSString *NSImageColorSyncProfileData	= @"NSImageColorSyncProfileData";
NSString *NSImageCompressionFactor		= @"NSImageCompressionFactor";
NSString *NSImageCompressionMethod		= @"NSImageCompressionMethod";
NSString *NSImageCurrentFrame			= @"NSImageCurrentFrame";
NSString *NSImageCurrentFrameDuration	= @"NSImageCurrentFrameDuration";
NSString *NSImageDitherTransparency		= @"NSImageDitherTransparency";
NSString *NSImageEXIFData				= @"NSImageEXIFData";
NSString *NSImageFrameCount				= @"NSImageFrameCount";
NSString *NSImageGamma					= @"NSImageGamma";
NSString *NSImageInterlaced				= @"NSImageInterlaced";
NSString *NSImageLoopCount				= @"NSImageLoopCount";
NSString *NSImageProgressive			= @"NSImageProgressive";
NSString *NSImageRGBColorTable			= @"NSImageRGBColorTable";

// compatibility with Apple AppKit so that we can debug using Xcode 8.2.1
NSString *NSAccessibilityCloseButtonSubrole			= @"NSAccessibilityCloseButtonSubrole";
NSString *NSAccessibilityFullScreenButtonSubrole	= @"NSAccessibilityFullScreenButtonSubrole";
NSString *NSAccessibilityMinimizeButtonSubrole		= @"NSAccessibilityMinimizeButtonSubrole";
NSString *NSAccessibilityZoomButtonSubrole			= @"NSAccessibilityZoomButtonSubrole";
