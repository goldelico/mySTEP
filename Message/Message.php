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
	const NSASCIIMailFormat="NSASCIIMailFormat";
	const NSMIMEMailFormat="NSMIMEMailFormat";
	const NSSMTPDeliveryProtocol="NSSMTPDeliveryProtocol";
	const NSSendmailDeliveryProtocol="NSSendmailDeliveryProtocol";	// not used

	public static function isEmailValid($mail)
	{
		if(filter_var($mail, FILTER_VALIDATE_EMAIL) == false)
			return false;
		list($user, $domain) = explode('@', $mail, 2);
		if(checkdnsrr($domain, 'MX'))
			return true;
// NSLog("no MX for $mail");
		if(checkdnsrr($domain, 'A'))
			return true;
// NSLog("no A for $mail");
		return false;

/* old - does not check existence; does not cover new tlds
	return ereg("^".
		"[a-zA-Z0-9_-]+".		// name
		"([.][a-zA-Z0-9_-]+)*".		// .name (multiple)
		"@".
		"([a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?[.])+".	// at least one domain.
		"([a-zA-Z]{2,4}|museum)".	// tld
		"$", $mail);
*/
	}

	public static function hasDeliveryClassBeenConfigured()
	{
		return true;
	}

	public static function deliverMessageSubjectTo($body, $subject, $to)
	{
		$headers=array('Subject' => $subject, 'To' => $to);
		// FIXME: convert $body to attributed string (w/o any attributes)
		return self::deliverMessageHeadersFormatProtocol($body, $headers, self::NSASCIIMailFormat, null);
	}

// to send to multiple recipients, provide $headers['To'] as an array
// to send MIME with attachments, use an attributed string

	public static function deliverMessageHeadersFormatProtocol(/*NSAttributedString*/$body, array $headers, $format, $protocol=null)
	{
		if(is_null($protocol)) $protocol=self::NSSMTPDeliveryProtocol;
		if($protocol != self::NSSMTPDeliveryProtocol)
			return false;
		// optionally define some default From: header...
		$hdrs="";
		foreach($headers as $key => $value)
			{ // translate into mail headers
			if(is_array($value))
				$headers[$key]=$value=implode(',', $value);	// merge into list
			if($key == 'To' || $key == 'Subject')
				continue;	// skip
			$hdrs.="$key: $value\r\n";	// convert
			}
		if($format == self::NSASCIIMailFormat)
			// FIXME: convert attributed string to ASCII
/* FIXME:
 * convert utf8 to 7-bit ascii
 * and specify encoding in the headers
 * reception on Apple Mail simply works because utf8 appears to be some default
 * we must also translate the Subject!
 */
			$msg=$body;
		else
			{
			// extract attachments from $body
			$msg=$body;
			// build additional MIME headers/sections

/*****

NOTE: this is now wrong with latest PHP. Only the first Content-Type: multipart/alternative can be in the headers
part. Everthing else must be in $body.

I.e. we scan the body for attachments and add them

		//add From: header
		$headers  = "From: service@$httpdomain\n";
		$headers .= "Bcc: sales@$httpdomain\n";	// make us always receive a copy...
		//	$headers .= "To: $dest\n";
		$headers .= "Reply-To: service@$httpdomain\n";
		//	$headers .= "Subject: $subject - $orderid\n";

		//specify MIME version 1.0
		$headers .= "Mime-Version: 1.0\n";

		//unique boundary
		$boundary = uniqid("HHLXSHOP");

		//tell e-mail client this e-mail contains//alternate versions
		$headers .= "Content-Type: multipart/alternative" . "; boundary=$boundary\n";
		$headers .= "Content-Transfer-Encoding: 8bit\n";
		$headers .= "\n";

		$b = "Dear ".$orow['Rechnungsname'].",\n".$body."\n\n";
		$b .= "To view the current and complete status of your order, please open your personal order link:\n  <$orderlink>\nWe recommend to bookmark this link.\n\n";
		$b .= "With kind regards,\nYour team from Golden Delicious Computers.\n\n";
		$b .= signature();
		$b .= "\n";
		$b=str_replace("\n\n", "\n \n", $b);

		// message to people with clients who don't understand MIME

		$headers .= $b;

		// plain text version of message
		$headers .= "--$boundary\n";
		$headers .= "Content-Type: text/plain; charset=ISO-8859-1\n";
		$headers .= "Content-Transfer-Encoding: 8bit\n";
		$headers .= "\n";
		$headers .= $b;

		// append order page
		if($addhtml)
			{ // add a HTML version of order page
// FIXME: we don't find shop.goldelico.com through the nameserver!
				$path=$httphome."/".orderlink($orderid)."&info=mail";
				$path="http://www.handheld-linux.com"."/".orderlink($orderid)."&info=mail";
				// echo htmlentities($path);
				$fd=@fopen($path, "r");	// get order page (through http! - for https we would have to provide authentication infos) - but it is local anyway
				if($fd)
					{
// echo "loading.";
					$headers .= "--$boundary\n" .
					"Content-Type: text/html; charset=ISO-8859-1\n" .
					"Content-Transfer-Encoding: 8bit\n";
					$headers .= "\n";
					while(!feof($fd))
						$headers .= fread($fd, 999999);
					fclose($fd);
					// split long lines at existing blank!
					$headers .= "\n--$boundary--";
					}
			}
		else
			$headers .= "\n--$boundary--";
		$headers .= "\n";

*****/
			}
		return mail($headers['To'], $headers['Subject'], $msg);
	}

}

// EOF
?>
