//
//  CWGlobals.h
//  CoreWLAN
//
//  Created by H. Nikolaus Schaller on 03.10.10.
//  Copyright 2010 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

@class NSString;

extern NSString * const kCWAssocKey8021XProfile;
extern NSString * const kCWAssocKeyPassphrase;
extern NSString * const kCWBSSIDDidChangeNotification;
extern NSString * const kCWCountryCodeDidChangeNotification;
extern NSString * const kCWErrorDomain;
extern NSString * const kCWIBSSKeyChannel;
extern NSString * const kCWIBSSKeyPassphrase;
extern NSString * const kCWIBSSKeySSID;
extern NSString * const kCWLinkDidChangeNotification;
extern NSString * const kCWModeDidChangeNotification;
extern NSString * const kCWPowerDidChangeNotification;
extern NSString * const kCWScanKeyBSSID;
extern NSString * const kCWScanKeyDwellTime;
extern NSString * const kCWScanKeyMerge;
extern NSString * const kCWScanKeyRestTime;
extern NSString * const kCWScanKeyScanType;
extern NSString * const kCWScanKeySSID;
extern NSString * const kCWSSIDDidChangeNotification;

typedef enum _CWErr
{
    kCWNoErr						= 0,
    kCWParamErr						= -3900,
    kCWNoMemErr						= -3901,
    kCWUknownErr					= -3902,
    kCWNotSupportedErr				= -3903,
    kCWFormatErr					= -3904,
    kCWTimeoutErr					= -3905,
    kCWUnspecifiedFailureErr		= -3906,
    kCWUnsupportedCapabilitiesErr	= -3907,
    kCWReassociationDeniedErr		= -3908,
    kCWAssociationDeniedErr			= -3909,
    kCWAuthAlgUnsupportedErr		= -3910,
    kCWInvalidAuthSeqNumErr			= -3911,
    kCWChallengeFailureErr			= -3912,
    kCWAPFullErr					= -3913,
    kCWUnsupportedRateSetErr		= -3914,
    kCWShortSlotUnsupportedErr		= -3915,
    kCWDSSSOFDMUnsupportedErr		= -3916,
    kCWInvalidInfoElementErr		= -3917,
    kCWInvalidGroupCipherErr		= -3918,
    kCWInvalidPairwiseCipherErr		= -3919,
    kCWInvalidAKMPErr				= -3920,
    kCWUnsupportedRSNVersionErr		= -3921,
    kCWInvalidRSNCapabilitiesErr	= -3922,
    kCWCipherSuiteRejectedErr		= -3923,
    kCWInvalidPMKErr				= -3924,
    kCWSupplicantTimeoutErr			= -3925,
    kCWHTFeaturesNotSupported		= -3926,
    kCWPCOTransitionTimeNotSupported= -3927,
    kCWRefNotBoundErr				= -3928,
    kCWIPCError						= -3929,
    kCWOpNotPermitted				= -3930,
    kCWError						= -3931,
} CWErr;

typedef enum _CWInterfaceState
{
    kCWInterfaceStateInactive=0,
    kCWInterfaceStateScanning,
    kCWInterfaceStateAuthenticating,
    kCWInterfaceStateAssociating,
    kCWInterfaceStateRunning
} CWInterfaceState;

typedef enum _CWOpMode
{
    kCWOpModeStation=0,
    kCWOpModeIBSS,
    kCWOpModeMonitorMode,
    kCWOpModeHostAP
} CWOpMode;

typedef enum _CWPHYMode
{
    kCWPHYMode11A=0,
    kCWPHYMode11B,
    kCWPHYMode11G,
    kCWPHYMode11N
} CWPHYMode;

typedef enum _CWScanType
{
    kCWScanTypeActive=0,
    kCWScanTypePassive,
    kCWScanTypeFast
} CWScanType;

typedef enum _CWSecurityMode
{
    kCWSecurityModeOpen=0,
    kCWSecurityModeWEP,
    kCWSecurityModeWPA_PSK,
    kCWSecurityModeWPA2_PSK,
    kCWSecurityModeWPA_Enterprise,
    kCWSecurityModeWPA2_Enterprise,
    kCWSecurityModeWPS,
    kCWSecurityModeDynamicWEP
} CWSecurityMode;

