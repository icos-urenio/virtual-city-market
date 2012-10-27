<?php
/**
 * @version     1.0a
 * @package     virtualCityMarket
 * @copyright   Copyright (C) 2012 Logotech S.A.. All rights reserved.
 * @license     GNU Affero General Public License version 3 or later; see LICENSE.txt
 * @author      Dimitrios Mitzias for Logotech S.A.
 */
 
	define('MARKET_ERROR_WARNING', 1);
	define('MARKET_ERROR_RETURN',  2);
	define('MARKET_ERROR_PRINT',   4);
	define('MARKET_ERROR_MAIL',    8);
	define('MARKET_ERROR_DIE',    16);
	
	define('MARKET_INDIRECT_CALL', false);
	define('MARKET_DO_NOT_APPEND', false);
	
	class MARKET_Base {
		
		function MARKET_Base()
		{
		}
		
		
		function readTag(&$lines, &$i, &$counti)
		{
			$tag = '';
			while (!preg_match('@>\s*$@', $lines[$i]) && $i<$counti) {
				$tag .= trim($lines[$i++]) . ' ';
			}
			// One more time please
			$tag .= trim($lines[$i]);
			return $tag;
		}
		
		
		function parseAttributes($str)
		{
			$attributes = array();
			if (preg_match_all('@ ([^= ]*)="(.+)"@U', $str, $matches)) {
				$counti = count($matches[0]);
				for ($i = 0; $i < $counti; $i++) {
					$attributes[$matches[1][$i]] = $matches[2][$i];
				}
			}
			return $attributes;
		}
		
		
		function &getRef($oname)
		{
			$cname = 'MARKET_' . $oname;
			if (!isset($GLOBALS[$cname])) {
				$fname = MARKET_INCLUDE_DIR . '/' . $cname . '.class.php';
				if (@is_file($fname) && @is_readable($fname)) {
					require_once($fname);
					$GLOBALS[$cname] = new $cname();
				}
			}
			return $GLOBALS[$cname];
		}
		
		
		function parseProperties($properties)
		{
			$pairs = $this->explodeString(';', $properties);
			if (is_array($pairs)) {
				foreach ($pairs as $pair) {
					list($var, $val) = $this->explodeString(':', $pair, 2);
					$vals = $this->explodeString(',', $val);
					if ($number_of = count($vals)) {
						if ($number_of == 1 && !strstr($vals[0], '-}')) {
							list($key, $val) = $this->getProperty($var, $vals[0]);
							$ret[$key] = $val;
						}
						else {
							unset($arr);
							$i = 0;
							foreach ($vals as $val) {
								list($key, $val) = $this->getProperty($i, $val);
								$arr[$key] = $val;
								$i++;
							}
							$ret[$var] = $arr;
						}
					}
				}
			}
			return $ret;
			
		}
		
		
		function getProperty($key, $val)
		{
			// Remove backquotes if any
			$val = preg_replace('@`@', '', $val);
			if (strstr($val, '-}')) {
				list($key, $val) = explode('-}', $val, 2);
			}
			return array(trim($key), trim($val));
		}
		
		
		function setProperty($var, $val = '')
		{
			if (is_array($var)) {
				foreach ($var as $key => $val) {
					$this->$key = $val;
				}
			}
			else {
				$this->$var = $val;
			}
		}
		
		
		function explodeString($delimiter, $string, $parts = 0)
		{
			// Init
			$string = trim($string);
			$str_length = strlen($string);
			$char = '';
			$string_start = '';
			$in_string = false;
			
			for ($i = 0; $i < $str_length; $i++) {
				$char = $string[$i];
				// We are in a string, check for not escaped end of strings except for
				// backquotes that can't be escaped
				if ($in_string) {
					while ($i < $str_length) {
						$i = strpos($string, $string_start, $i);
						// No end of string found -> add the current substring to the
						// returned array
						if (!$i) {
							$ret[] = $string;
							return $ret;
						}
						// Backquotes or no backslashes before quotes: it's indeed the
						// end of the string -> exit the loop
						else if ($string_start == '`' || $string[$i-1] != '\\') {
							$string_start = '';
							$in_string = false;
							break;
						}
						// one or more backslashes before the presumed end of string...
						else {
							// ... first check for escaped backslashes
							$j = 2;
							$escaped_backslash = false;
							while ($i-$j > 0 && $string[$i-$j] == '\\') {
								$escaped_backslash = !$escaped_backslash;
								$j++;
							}
							// ... if escaped backslashes: it's really the end of the
							// string -> exit the loop
							if ($escaped_backslash) {
								$string_start = '';
								$in_string = false;
								break;
							}
							// ... else loop
							else {
								$i++;
							}
						}
					}
				}
				// We are not in a string, first check for delimiter...
				else if ($char == $delimiter) {
					// if delimiter found, add the parsed part to the returned array
					$ret[] = substr($string, 0, $i);
					$string = ltrim(substr($string, min($i + 1, $str_length)));
					$str_length = strlen($string);
					// Asked for a particular number of parts. Should we return?
					if ($parts && $parts == count($ret) + 1) {
						// Add the remainder and return
						$ret[] = $string;
						return $ret;
					}
					else {
						if ($str_length) {
							$i = -1;
						}
						else {
							// The string ends here
							return $ret;
						}
					}
				}
				// ... then check for start of a string,...
				else if (($char == '"') || ($char == '\'') || ($char == '`')) {
					$in_string = true;
					$string_start = $char;
				}
			}
			// add any rest to the returned array
			if (!empty($string) && preg_match('@[^\s]+@', $string)) {
				$ret[] = $string;
			}
			return $ret;
		}
		
		
		function pregEscape($str)
		{
			return preg_replace('@([^A-z0-9_-]|[\\\[\]])@u', "\\\\\\1", $str);
		}
		
		
		function pregAddslashes($str) {
			return preg_quote($str, '@');
		}
		
		
		function arrayFunc($arr, $func)
		{
			if (is_array($arr)) {
				foreach($arr as $key => $val) {
					$arr[$key] = $func($val);
				}
				return $arr;
			}
			return false;
		}
		
		
		function arrayAddSlashes($arr)
		{
			return $this->arrayFunc($arr, 'addslashes');
		}
		
		
		function arrayStripSlashes($arr)
		{
			return $this->arrayFunc($arr, 'stripslashes');
		}
		
		
		function arrayTrim($arr)
		{
			if (is_array($arr)) {
				foreach ($arr as $key=>$value) {
					if (!is_array($value)) {
						$arr[$key] = trim($value);
					}
				}
			}
			return $arr;
		}
		
		
		function arrayLower($arr)
		{
			return $this->arrayFunc($arr, 'strtolower');
		}
		
		
		function raiseError($level, $error, $file, $line)
		{
			
			global $MARKET_ERROR;
			
			if (defined('DEBUG') && DEBUG) $dbg =& MARKET_Base::getRef('Debug');
			
			$MARKET_ERROR = preg_replace('@^(.*):@U', '<b>$1:</b>', sprintf('%s [file %s, line %d]', $error, basename($file), $line));
			
			// Warning
			if ($level & MARKET_ERROR_WARNING) {
				if (defined('DEBUG') && DEBUG) $dbg->add('warning', $MARKET_ERROR);
			}
			
			// Just return
			if ($level & MARKET_ERROR_RETURN) {
				if (defined('DEBUG') && DEBUG) $dbg->add('error', $MARKET_ERROR);
			}
			
			// Print this error
			if ($level & MARKET_ERROR_PRINT) {
				if (defined('DEBUG') && DEBUG) $dbg->add('error', $MARKET_ERROR);
				$this->user_errors[] = '<i>' . $error . '</i>';
			}
			
			// Fatal Error
			if ($level & MARKET_ERROR_DIE) {
				fatalError($error, $file, $line); // This function will exit
			}
		}
		
		
		function makeDir($dir, $mode = 'O777')
		{
			if (preg_match('@^//([^/]+)/(.*)$@', $dir, $matches)) { // Network Share
				$folders = explode('/', $matches[2]);
				$dir = '//' . $matches[1] . '/';
			}
			else {
				$folders = explode('/', $dir);
				$dir = '';
			}
			foreach ($folders as $folder) {
				$dir .= $folder . '/';
				if (!@is_dir($dir)) {
					if (!@mkdir($dir)) {
						$this->raiseError(MARKET_ERROR_WARNING,
							__FUNCTION__ . '(): Cannot create directory "' . $dir . '"',
							__FILE__, __LINE__
						);
					}
				}
			}
			return true;
		}
	}
	
	

?>
