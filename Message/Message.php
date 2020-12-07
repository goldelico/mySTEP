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

	private static $sender;

	public static function setSender($mail)
	{
		self::$sender=$mail;
	}

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

	public static function deliverMessageSubjectTo($body, $subject, $to, $bcc=null)
	{
		$headers=array('Subject' => $subject, 'To' => $to);
		if(!is_null($bcc))
			$headers['bcc']=$bcc;
		// FIXME: convert $body to attributed string (w/o any attributes)
		return self::deliverMessageHeadersFormatProtocol($body, $headers, self::NSASCIIMailFormat, null);
	}

// to send to multiple recipients, provide $headers['To'] as an array
// to send MIME with attachments, use an attributed string as $body
// or an array as $body
/*
	example for sending mail with attachment
	$headers=array('Subject' => "Here is your PDF attached", 'To' => "somebody@yourdomain.com");
	$msg[]="Here is some PDF:";
	$msg[]=(new PDFDocument())->initWithURL("https://server/file.pdf");
	$msg[]="Hope your find it good.";
	NSMailDelivery::deliverMessageHeadersFormatProtocol($msg, $headers, NSMailDelivery::NSMIMEMailFormat);
*/

	/*
	 * $body must be a string for NSASCIIMailFormat
	 * $body must be an array for NSMIMEMailFormat
	 */

	public static function deliverMessageHeadersFormatProtocol(/*NSAttributedString*/$body, array $headers, $format, $protocol=null)
	{
		if(is_null($protocol)) $protocol=self::NSSMTPDeliveryProtocol;
		if($protocol != self::NSSMTPDeliveryProtocol)
			return false;
		$hdrs="";
		// should check if sender isValid
		if(isset(self::$sender) && self::$sender != "")
			$hdrs.="From: ".self::$sender."\r\n";
		foreach($headers as $key => $value)
			{ // translate into mail headers
			if(is_array($value))
				$headers[$key]=$value=implode(',', $value);	// merge into list
			if($key == 'To' || $key == 'Subject')
				continue;	// skip
			// should check if To, Bcc, CC, Reply-To: are isValid
			$hdrs.="$key: $value\r\n";	// convert
			}
		if(!is_array($body) && $format == self::NSASCIIMailFormat)
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
			// or check for NSAttributedString
			if(count($body) > 1)
				{
				// specify MIME version 1.0
				$hdrs .= "Mime-Version: 1.0\n";

				// unique boundary
				$boundary = uniqid("QuantumSTEP");

				// tell e-mail client this e-mail contains alternate versions
				$hdrs .= "Content-Type: multipart/mixed" . "; boundary=$boundary\n\n";

				$msg="";

				foreach($body as $part)
					{
					$msg .= "--$boundary\n";

					if(is_object($part))
						{
						// must implement dataRepresentation() - like PDFDocument does
						// and potentially some other methods to control the content type
						// may also take NSData arguments...
						$msg .= "Content-Transfer-Encoding: base64\n";
						// FIXME: how do we known pdf? - at the moment we simply assume
						$msg .= "Content-Type: application/pdf; charset=UTF-8\n";
						$msg .= "Content-Disposition: attachment; somefile.pdf\n";
						$msg .= "\n";
						$msg .= chunk_split(base64_encode($part->dataRepresentation()), 76, "\n");
						$msg .= "\n";
						}
					else
						{ // string
						$msg .= "Content-Transfer-Encoding: quoted-printable\n";
						$msg .= "Content-Type: text/plain; charset=ISO-8859-1\n";
						$msg .= "\n";
						$msg .= $part;
						$msg .= "\n";
						}
						// get from attachment infos and type from $body

					$msg .= "\n";
					}
				$msg .= "\n--$boundary--";	// final boundary
				}
			else
				$msg=$body[0];
			}
// get error: error_get_last()['message']
		return mail($headers['To'], $headers['Subject'], $msg, $hdrs);
	}

}

// EOF
?>
