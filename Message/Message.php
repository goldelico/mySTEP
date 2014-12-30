<?php
	/*
	 * Message.framework
	 * (C) Golden Delicious Computers GmbH&Co. KG, 2012
	 * All rights reserved.
	 */

global $ROOT;	// must be set by some .app
require_once "$ROOT/System/Library/Frameworks/Foundation.framework/Versions/Current/php/Foundation.php";

if($GLOBALS['debug']) echo "<h1>Message.framework</h1>";

class NSMailDelivery extends NSObject
{
	public static function deliverMessageSubjectDestination($body, $subject, $email)
	{
	// wrapper for sendmail()
	}

	public static function deliverMessageHeadersFormatProtocol($body, array $headers, $format, $protocol)
	{
		// depending on Format the body may be HTML
		// how to get the subject? the email?
	}

}

// EOF
?>
