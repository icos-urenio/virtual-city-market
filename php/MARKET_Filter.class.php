<?php
/**
 * @version     1.0a
 * @package     virtualCityMarket
 * @copyright   Copyright (C) 2012 Logotech S.A.. All rights reserved.
 * @license     GNU Affero General Public License version 3 or later; see LICENSE.txt
 * @author      Dimitrios Mitzias for Logotech S.A.
 */

	ini_set('max_execution_time', 0);
	
	class MARKET_Filter {
		
		
		function MARKET_Filter()
		{
			// Dummy function
		}
		
		
		function createThumbnail($image, $size, $complete_tag = false, $alt = 'alt=""')
		{
			// Parse size parameter
			if (preg_match('@^(\d+)x(\d+)$@', $size, $matches)) {
				$width = $matches[1];
				$height = $matches[2];
			}
			else if (preg_match('@^(\d+)$@', $size)) {
				$width = $size;
				$height = $size;
			}
			else {
				MARKET_Base::raiseError(MARKET_ERROR_RETURN,
					__FUNCTION__ . '(): Size "' . htmlspecialchars($size) . '" is not acceptable.',
					__FILE__, __LINE__
				);
				return MARKET_Filter::_defaultThumbnail();
			}
			
			$type = strtolower(substr(strrchr($image, '.'), 1));
			$out = '/cache/' . dirname($image) . '/' . substr(basename($image), 0, strrpos(basename($image), '.')) . '.' . $width . 'x' . $height . '.' . $type;
			if (@is_file(MARKET_ROOT_DIR . '/' . $out) && @is_readable(MARKET_ROOT_DIR . '/' . $out)) {
				// Do nothing
			}
			else {
				// Create thumbnail
				// Requires GD
				if (extension_loaded('gd')) {
					$gd_info = gd_info();
					$in = MARKET_ROOT_DIR . '/' . $image;
					if (@is_file($in) && @is_readable($in)) {
						if (!list($w, $h) = getimagesize($in)) {
							MARKET_Base::raiseError(MARKET_ERROR_RETURN,
								__FUNCTION__ . '(): Image "' . htmlspecialchars($image) . '" is not supported',
								__FILE__, __LINE__
							);
							return MARKET_Filter::_defaultThumbnail();
						}

						if ($type == 'jpeg') $type = 'jpg';
						switch ($type) {
							case 'bmp': $img = imagecreatefromwbmp($in); break;
							case 'gif': $img = imagecreatefromgif($in); break;
							case 'jpg': $img = imagecreatefromjpeg($in); break;
							case 'png': $img = imagecreatefrompng($in); break;
							default : 
								MARKET_Base::raiseError(MARKET_ERROR_RETURN,
									__FUNCTION__ . '(): Image "' . htmlspecialchars($image) . '" is not supported',
									__FILE__, __LINE__
								);
								return MARKET_Filter::_defaultThumbnail();
						}
						
						// Resize and crop
						
						$sratio = $w / $h;
						$dratio = $width / $height;
						if ($sratio > $dratio) {
							$temp_width = (int)($h * $dratio);
							$temp_height = $h;
							$x = (int)(($w - $temp_width) / 2);
							$y = 0; 
						}
						else {
							$temp_width = $w;
							$temp_height = (int)($w / $dratio);
							$x = 0;
							$y = (int)(($h - $temp_height) / 2); 
						}
						$source_width = $temp_width;
						$source_height = $temp_height;
						
						$dst = imagecreatetruecolor($width, $height);
						
						// Preserve transparency
						if ($type == 'gif' || $type == 'png') {
							imagecolortransparent($dst, imagecolorallocatealpha($dst, 0, 0, 0, 127));
							imagealphablending($dst, false);
							imagesavealpha($dst, true);
						}
						
						imagecopyresampled($dst, $img, 0, 0, $x, $y, $width, $height, $source_width, $source_height);
						
						// Create dir
						MARKET_Base::makeDir(dirname(MARKET_ROOT_DIR . $out));
						
						switch ($type) {
							case 'bmp': imagewbmp($dst, MARKET_ROOT_DIR . $out); break;
							case 'gif': imagegif($dst, MARKET_ROOT_DIR . $out); break;
							case 'jpg': imagejpeg($dst, MARKET_ROOT_DIR . $out); break;
							case 'png': imagepng($dst, MARKET_ROOT_DIR . $out); break;
						}
						
					}
					else {
						MARKET_Base::raiseError(MARKET_ERROR_WARNING,
							__FUNCTION__ . '(): Image "' . htmlspecialchars($image) . '" not found or not readable',
							__FILE__, __LINE__
						);
						return MARKET_Filter::_defaultThumbnail('', $width, $height, $complete_tag, $alt);
					}
				}
				else {
					MARKET_Base::raiseError(MARKET_ERROR_WARNING,
						__FUNCTION__ . '(): The GD extension is not loaded',
						__FILE__, __LINE__
					);
					return MARKET_Filter::_defaultThumbnail($image, $width, $height, $complete_tag, $alt);
				}
			}
			
			if ($complete_tag) {
				return '<img src="' . MARKET_WEB_DIR . $out . '" width="' . $width . '" height="' . $height . '" ' . $alt . ' />';
			}
			else {
				return MARKET_WEB_DIR . '/' . $out;
			}
		}
		
		private function _defaultThumbnail($image = '', $width = '', $height = '', $complete_tag = false, $alt = 'alt=""')
		{
			if (!$image) $image = 'lib/default_image.png';
			if (!$width) $width = '120';
			if (!$height) $height = '120';
			
			/*
			$in = MARKET_ROOT_DIR . '' . $image;
			if (@is_file($in) && @is_readable($in)) {
				return MARKET_Filter::createThumbnail($image, $width . 'x' . $height, $complete_tag, $alt);
			}
			*/
			if ($complete_tag) {
				return '<img src="' . MARKET_WEB_DIR . '/' . $image . '" width="' . $width . '" height="' . $height . '" ' . $alt . ' />';
			}
			else {
				return MARKET_WEB_DIR . '/' . $image;
			}
		}
		
		
		function b2KB($bytes, $base = 1024, $decimals = 2, $dec_point = ',', $thousands_sep = '.')
		{
			$units = array('b', 'KB', 'MB', 'GB', 'TB', 'PB');
			$i = 0;
			while ($bytes > $base) {
				$bytes = $bytes / $base;
				$i++;
			}
			return number_format($bytes, $decimals, $dec_point, $thousands_sep) . $units[$i];
		}
		
		
		function marketDate($date, $format)
		{
			// Datetime
			if (preg_match('@([0-9]{2,4})-([0-9]{1,2})-([0-9]{1,2}) ([0-9]{2}):([0-9]{2}):([0-9]{2})@', $date, $matches)) {
				$date = date($format, mktime($matches[4], $matches[5], $matches[6], $matches[2], $matches[3], $matches[1]));
			}
			else if (preg_match('@([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})@', $date, $matches)) {
				$date = date($format, mktime($matches[4], $matches[5], $matches[6], $matches[2], $matches[3], $matches[1]));
			}
			else if (preg_match('@([0-9]{2,4})-([0-9]{1,2})-([0-9]{1,2})@', $date, $matches)) {
				$date = date($format, mktime(0, 0, 0, $matches[2], $matches[3], $matches[1]));
			}
			$lng =& MARKET_Base::getRef('Lang');
			$parts = explode(' ', $date);
			$date = '';
			foreach ($parts as $part) {
				$match = preg_replace('@[^\w]+@i', '', $part);
				if ($match && !preg_match('@^\d+$@', $match) && $lng->strs['DATE'][$match]) {
					$date .= preg_replace('@\w+@i', $lng->strs['DATE'][$match], $part) . ' ';
				}
				else {
					$date .= $part . ' ';
				}
			}
			return substr($date, 0, -1);
		}
		
		
		function marketNumber($number, $decimal_places = 0)
		{
			$lng =& MARKET_Base::getRef('Lang');
			return number_format($number, $decimal_places, $lng->strs['MATH']['Decimal_Point'], $lng->strs['MATH']['Thousands_Separator']);
		}
		
		
		function marketTime($secs)
		{
			$str = '';
			if ($secs > 3600) {
				$str = floor($secs / 3600) . 'h ';
				$secs = $secs % 3600;
				$str .= sprintf('%02d', floor($secs / 60)) . "' " . sprintf('%02d', $secs % 60) . "''";
			}
			else if ($secs > 60) {
				$str = sprintf('%02d', floor($secs / 60)) . "' " . sprintf('%02d', $secs % 60) . "''";
			}
			else {
				$str = "00' " . sprintf('%02d', $secs) . "''";
			}
			return $str;
		}
		
		
		function noSpamAdvanced($email) {
			$str = '';
			if (preg_match_all('@(.{1,2})@', $email, $matches)) {
				$foo = "'" . implode("'+'", $matches[1]) . "'";
			}
			$str =  "<script type=\"text/javascript\">document.write(unescape('%3C')+'a h'+'ref='+'\"'+'ma'+'il'+'to:'+" . $foo . "+'\"'+unescape('%3E')+" . $foo . "+''+unescape('%3C')+'/a'+unescape('%3E'));</script>";
//			$str .= '<noscript><a href="{MARKET.WebDir}/nospam.html?a=' . urlencode($foo) . '"><img src="{MARKET.WebDir}/nospam.html?a=' . urlencode($foo) . '&b=.png" border="0" alt="{LANG.ClickToSendEmail}" title="{LANG.ClickToSendEmail}" /></a></noscript>';
			$str .= '<noscript><img src="{MARKET.WebDir}/nospam.html?a=' . urlencode($foo) . '&b=.png" border="0" align="absmiddle" /></noscript>';
			return $str;
		}
		
		
		function makePassword()
		{
			$words = array('alpha', 'bravo', 'charlie', 'delta', 'echo', 'foxtrot', 'golf', 'hotel', 'india', 'juliet', 'kilo', 'lima', 'mike', 'november', 'oscar', 'papa', 'quebec', 'romeo', 'sierra', 'tango', 'uniform', 'victor', 'whiskey', 'xray', 'yankee', 'zulu');
			$seed = (double)microtime() * 1000000;
			srand($seed);
			$str = $words[mt_rand(0,25)];
			$str .= substr(uniqid($seed), 0, 4);
			return $str;
		}
		
		function marketQRCode($data, $errorCorrectionLevel = 'L', $matrixPointSize = 4)
		{
			
			require_once(MARKET_ROOT_DIR . '/redist/phpqrcode/qrlib.php');
			
			$code = md5($data . '|' . $errorCorrectionLevel . '|' . $matrixPointSize);
			$code_dir = substr($code, 0, 2);
			
			$filename = MARKET_ROOT_DIR . '/cache/qrcode/' . $code_dir . '/' . md5($data . '|' . $errorCorrectionLevel . '|' . $matrixPointSize) . '.png';
			
			if (!@is_file($filename)) {
				MARKET_Base::makeDir(dirname($filename));
				QRcode::png($data, $filename, $errorCorrectionLevel, $matrixPointSize, 2);
			}
			
			return MARKET_WEB_DIR . '/cache/qrcode/' . $code_dir . '/' . basename($filename);
			
		}
		
		function marketSummary($str, $length = 175) {
			
			$delimiter = mb_strpos($str, '<!--break-->');
			if ($delimiter !== false) {
				return mb_substr($str, 0, $delimiter);
			}
			
			if (mb_strlen($str) <= $length) {
				return $str;
			}
			
			$summary = mb_substr($str, 0, $length);
			
			$max_rpos = mb_strlen($summary);
			
			$min_rpos = $max_rpos;
			
			$reversed = mb_strrev($summary);
			
			$break_points = array();
			$break_points[] = array('</p>' => 0);
			
			$line_breaks = array(
				'<br />' => 6,
				'<br>'   => 4
			);
			$break_points[] = $line_breaks;
			
			$break_points[] = array(
				'. ' => 1,
				', ' => 0,
				'! ' => 1,
				'? ' => 1,
				' '  => 0
			);
			
			foreach ($break_points as $points) {
				foreach ($points as $point => $offset) {
					$rpos = mb_strpos($reversed, mb_strrev($point));
					if ($rpos !== false) {
						$min_rpos = min($rpos + $offset, $min_rpos);
					}
				}
				if ($min_rpos !== $max_rpos) {
					$summary = ($min_rpos === 0) ? $summary : mb_substr($summary, 0, 0 - $min_rpos) . '...';
					break;
				}
			}
			
			return $summary;
		}
		
		function autolink($text) {
			$pattern = "/(((http[s]?:\/\/)|(www\.))(([a-z][-a-z0-9]+\.)?[a-z][-a-z0-9]+\.[a-z]+(\.[a-z]{2,2})?)\/?[a-z0-9.,_\/~#&=;%+?-]+[a-z0-9\/#=?]{1,1})/is";
			$text = preg_replace($pattern, "<a href='$1'>$1</a>", $text);
			// fix URLs without protocols
			$text = preg_replace("/href='www/", "href='http://www", $text);
			return $text;
		}
		
		
	}

?>
