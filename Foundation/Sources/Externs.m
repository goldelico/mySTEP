
#include <Foundation/NSString.h>
#include <Foundation/NSException.h>

//	Global lock to be used by classes when operating on any global
//	data that invoke other methods which also access global; thus,
//	creating the potential for deadlock.
//
NSRecursiveLock *mstep_global_lock = nil;
unsigned long __NSAllocatedObjects;		// counter for object allocation

													// NSThread Notifications
NSString *NSWillBecomeMultiThreadedNotification = @"NSWillBecomeMultiThreadedNotification";
NSString *NSThreadWillExitNotification = @"NSThreadWillExitNotification";
															// RunLoop modes 
NSString *NSConnectionReplyMode = @"NSConnectionReplyMode";
															// Exceptions
NSString *NSInconsistentArchiveException = @"NSInconsistentArchiveException";
NSString *NSGenericException = @"NSGenericException";
NSString *NSInternalInconsistencyException=@"NSInternalInconsistencyException";
NSString *NSInvalidArgumentException = @"NSInvalidArgumentException";
NSString *NSUndefinedKeyException = @"NSUndefinedKeyException";
NSString *NSMallocException = @"NSMallocException";
NSString *NSRangeException = @"NSRangeException";
NSString *NSCharacterConversionException = @"NSCharacterConversionException";

NSUncaughtExceptionHandler *_NSUncaughtExceptionHandler;
																	// NSBundle
NSString *NSBundleDidLoadNotification = @"NSBundleDidLoadNotification";
NSString *NSLoadedClasses = @"NSLoadedClasses";
																	// Stream 
NSString *StreamException = @"StreamException";
															// File Attributes
NSString *NSFileAppendOnly = @"NSFileAppendOnly";
NSString *NSFileBusy = @"NSFileBusy";
NSString *NSFileCreationDate = @"NSFileCreationDate";
NSString *NSFileDeviceIdentifier = @"NSFileDeviceIdentifier";
NSString *NSFileExtensionHidden = @"NSFileExtensionHidden";
NSString *NSFileGroupOwnerAccountID = @"NSFileGroupOwnerAccountID";
NSString *NSFileGroupOwnerAccountName = @"NSFileGroupOwnerAccountName";
NSString *NSFileHFSCreatorCode = @"NSFileHFSCreatorCode";
NSString *NSFileHFSTypeCode = @"NSFileHFSTypeCode";
NSString *NSFileImmutable = @"NSFileImmutable";
NSString *NSFileModificationDate = @"NSFileModificationDate";
NSString *NSFileOwnerAccountID = @"NSFileOwnerAccountID";
NSString *NSFileOwnerAccountName = @"NSFileOwnerAccountName";
NSString *NSFilePosixPermissions = @"NSFilePosixPermissions";
NSString *NSFileReferenceCount = @"NSFileReferenceCount";
NSString *NSFileSize = @"NSFileSize";
NSString *NSFileSystemFileNumber = @"NSFileSystemFileNumber";
NSString *NSFileType = @"NSFileType";
															// File Types 
NSString *NSFileTypeDirectory = @"NSFileTypeDirectory";
NSString *NSFileTypeRegular = @"NSFileTypeRegular";
NSString *NSFileTypeSymbolicLink = @"NSFileTypeSymbolicLink";
NSString *NSFileTypeSocket = @"NSFileTypeSocket";
NSString *NSFileTypeFifo = @"NSFileTypeFifo";
NSString *NSFileTypeCharacterSpecial = @"NSFileTypeCharacterSpecial";
NSString *NSFileTypeBlockSpecial = @"NSFileTypeBlockSpecial";
NSString *NSFileTypeUnknown = @"NSFileTypeUnknown";
													// FileSystem Attributes 
NSString *NSFileSystemSize		= @"NSFileSystemSize";
NSString *NSFileSystemFreeSize	= @"NSFileSystemFreeSize";
NSString *NSFileSystemNodes 	= @"NSFileSystemNodes";
NSString *NSFileSystemFreeNodes = @"NSFileSystemFreeNodes";
NSString *NSFileSystemNumber 	= @"NSFileSystemNumber";

													// Standard domains
NSString *NSArgumentDomain 	   = @"NSArgumentDomain";
NSString *NSGlobalDomain 	   = @"NSGlobalDomain";
NSString *NSRegistrationDomain = @"NSRegistrationDomain";
													// Public notification
NSString *NSUserDefaultsDidChangeNotification = 
		@"NSUserDefaultsDidChangeNotification";
								// Keys for language-dependent information 
NSString *NSWeekDayNameArray = @"NSWeekDayNameArray";
NSString *NSShortWeekDayNameArray = @"NSShortWeekDayNameArray";
NSString *NSMonthNameArray = @"NSMonthNameArray";
NSString *NSShortMonthNameArray = @"NSShortMonthNameArray";
NSString *NSTimeFormatString = @"NSTimeFormatString";
NSString *NSDateFormatString = @"NSDateFormatString";
NSString *NSTimeDateFormatString = @"NSTimeDateFormatString";
NSString *NSShortTimeDateFormatString = @"NSShortTimeDateFormatString";
NSString *NSCurrencySymbol = @"NSCurrencySymbol";
NSString *NSDecimalSeparator = @"NSDecimalSeparator";
NSString *NSThousandsSeparator = @"NSThousandsSeparator";
NSString *NSInternationalCurrencyString = @"NSInternationalCurrencyString";
NSString *NSCurrencyString = @"NSCurrencyString";
NSString *NSDecimalDigits = @"NSDecimalDigits";
NSString *NSAMPMDesignation = @"NSAMPMDesignation";

// EOF