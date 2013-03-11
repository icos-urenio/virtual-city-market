<?php
	
	function myCheckDNSRR($hostName, $recType = '')	{
		if (!empty($hostName)) {
			if( $recType == '' ) $recType = "MX";
			exec("nslookup -type=$recType $hostName", $result);
			// check each line to find the one that starts with the host
			// name. If it exists then the function succeeded.
			foreach ($result as $line) {
				if (preg_match("@^$hostName@i", $line)) {
					return true;
				}
			}
			// otherwise there was no mail handler for the domain
			return false;
		}
		return false;
	}
	
	function validEmail($email)	{
		$isValid = true;
		$atIndex = strrpos($email, "@");
		if (is_bool($atIndex) && !$atIndex) {
			$isValid = false;
		}
		else {
			$domain = substr($email, $atIndex + 1);
			$local = substr($email, 0, $atIndex);
			$localLen = strlen($local);
			$domainLen = strlen($domain);
			if ($localLen < 1 || $localLen > 64) {
				// local part length exceeded
				$isValid = false;
			}
			else if ($domainLen < 1 || $domainLen > 255) {
				// domain part length exceeded
				$isValid = false;
			}
			else if ($local[0] == '.' || $local[$localLen - 1] == '.') {
				// local part starts or ends with '.'
				$isValid = false;
			}
			else if (preg_match('/^www\./', $local)) {
				// local part starts with www.
				$isValid = false;
			}
			else if (preg_match('/\\.\\./', $local)) {
				// local part has two consecutive dots
				$isValid = false;
			}
			else if (!preg_match('/^[A-Za-z0-9\\-\\.]+$/', $domain)) {
				// character not valid in domain part
				$isValid = false;
			}
			else if (preg_match('/\\.\\./', $domain)) {
				// domain part has two consecutive dots
				$isValid = false;
			}
			else if (!preg_match('/^(\\\\.|[A-Za-z0-9!#%&`_=\\/$\'*+?^{}|~.-])+$/', str_replace("\\\\", "", $local))) {
				// character not valid in local part unless 
				// local part is quoted
				if (!preg_match('/^"(\\\\"|[^"])+"$/', str_replace("\\\\", "", $local))) {
					$isValid = false;
				}
			}
			if (function_exists('checkdnsrr')) $func = 'checkdnsrr'; else $func = 'myCheckDNSRR';
			if ($isValid && !($func($domain, "MX") || $func($domain, "A"))) {
				// domain not found in DNS
				$isValid = false;
			}
		}
		return $isValid;
	}
	
	function logEvent($type, $str, $user_id = 0) {
		if (!$user_id) $user_id = $_SESSION['User']['user_id'];
		$sql = "INSERT INTO log (id, user_id, type, text, tstamp) VALUES ('', '" . sqlEscape($user_id) . "', '" . sqlEscape($type) . "', '" . sqlEscape($str) . "', NOW())";
		sqlQuery($sql, $res);
	}
	
?>