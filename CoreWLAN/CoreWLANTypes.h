//
//  CoreWLANTypes.h
//  CoreWLAN
//
//  Created by H. Nikolaus Schaller on 03.10.10.
//  Copyright 2010 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum CWChannelBand {
	kCWChannelBandUnknown=0,
	kCWChannelBand2GHz=1,
	kCWChannelBand5GHz=2,
} CWChannelBand;

typedef enum CWChannelWidth {
	kCWChannelWidthUnknown=0,
	kCWChannelWidth20MHz=1,
	kCWChannelWidth40MHz=2,
	kCWChannelWidth80MHz=3,
	kCWChannelWidth160MHz=4,
} CWChannelWidth;

typedef enum CWCipherKeyFlags {
	kCWCipherKeyFlagsNone=0,
	kCWCipherKeyFlagsUnicast=0x2,
	kCWCipherKeyFlagsMulticast=0x4,
	kCWCipherKeyFlagsTx=0x8,
	kCWCipherKeyFlagsRx=0x10,
} CWCipherKeyFlags;

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

typedef enum _CWIBSSModeSecurity {
	kCWIBSSModeSecurityNone=0,
	kCWIBSSModeSecurityWEP40=1,
	kCWIBSSModeSecurityWEP104=2,
} _CWIBSSModeSecurity;

typedef enum _CWInterfaceState
{
	kCWInterfaceStateInactive=0,
	kCWInterfaceStateScanning,
	kCWInterfaceStateAuthenticating,
	kCWInterfaceStateAssociating,
	kCWInterfaceStateRunning
} CWInterfaceState;

/* may be deprecated - doc is no consistent */
typedef enum _CWOpMode
{
	kCWOpModeStation=0,
	kCWOpModeIBSS,
	kCWOpModeMonitorMode,
	kCWOpModeHostAP
} CWOpMode;

typedef enum _CWInterfaceMode
{
	kCWInterfaceModeStation=0,
	kCWInterfaceModeIBSS,
	kCWInterfaceModeMonitorMode,
	kCWInterfaceModeHostAP
} CWInterfaceMode;

typedef enum _CWPHYMode
{
	kCWPHYModeNone=0,
	kCWPHYMode11a,
	kCWPHYMode11b,
	kCWPHYMode11g,
	kCWPHYMode11n,
	kCWPHYMode11ac,
	kCWPHYMode11ax,
} CWPHYMode;

typedef enum _CWScanType
{
	kCWScanTypeActive=0,
	kCWScanTypePassive,
	kCWScanTypeFast
} CWScanType;

typedef enum CWSecurity {
	kCWSecurityNone=0,
	kCWSecurityWEP,
	kCWSecurityWPAPersonal,
	kCWSecurityWPAPersonalMixed,
	kCWSecurityWPA2Personal,
	kCWSecurityPersonal,
	kCWSecurityDynamicWEP,
	kCWSecurityWPAEnterprise,
	kCWSecurityWPAEnterpriseMixed,
	kCWSecurityWPA2Enterprise,
	kCWSecurityEnterprise,
	kCWSecurityWPA3Personal,
	kCWSecurityWPA3Enterprise,
	kCWSecurityWPA3Transition,
	kCWSecurityOWE,
	kCWSecurityOWETransition,
	kCWSecurityUnknown=NSIntegerMax
} CWSecurity;

typedef enum _CWSecurityMode
{
	kCWSecurityModeOpen=0,
	kCWSecurityModeWEP,
	kCWSecurityModeWPA_PSK,
	kCWSecurityModeWPA2_PSK,
	kCWSecurityModeDynamicWEP,
	kCWSecurityModeWPA_Enterprise,
	kCWSecurityModeWPA2_Enterprise,
	kCWSecurityModeWPS,
} CWSecurityMode;

typedef enum _kCWParamErr {
	/* reversed definition */
	kCWInvalidParameterErr=kCWParamErr,
	kCWNoMemoryErr=kCWNoMemErr,
	kCWUnknownErr=kCWUknownErr,
	kCWInvalidFormatErr=kCWFormatErr,
	kCWAuthenticationAlgorithmUnsupportedErr=kCWAuthAlgUnsupportedErr,
	kCWInvalidAuthenticationSequenceNumberErr=kCWInvalidAuthSeqNumErr,
	kCWInvalidInformationElementErr=kCWInvalidInfoElementErr,
	kCWHTFeaturesNotSupportedErr=kCWHTFeaturesNotSupported,
	kCWPCOTransitionTimeNotSupportedErr=kCWPCOTransitionTimeNotSupported,
	kCWReferenceNotBoundErr=kCWRefNotBoundErr,
	kCWIPCFailureErr=kCWIPCError,
	kCWOperationNotPermittedErr=kCWOpNotPermitted,
	kCWErr=kCWError,
} _kCWParamErr;

typedef enum CWEventType {
	CWEventTypeNone=0,
	CWEventTypePowerDidChange,
	CWEventTypeSSIDDidChange,
	CWEventTypeBSSIDDidChange,
	CWEventTypeCountryCodeDidChange,
	CWEventTypeLinkDidChange,
	CWEventTypeLinkQualityDidChange,
	CWEventTypeModeDidChange,
	CWEventTypeScanCacheUpdated,
	CWEventTypeBtCoexStats,
	CWEventTypeUnknown=NSIntegerMax
} CWEventType;

