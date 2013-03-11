<?php
/**
 * @version     1.0a
 * @package     virtualCityMarket
 * @copyright   Copyright (C) 2012 Logotech S.A.. All rights reserved.
 * @license     GNU Affero General Public License version 3 or later; see LICENSE.txt
 * @author      Dimitrios Mitzias for Logotech S.A.
 */
 
	require_once('MARKET_Base.class.php');
	
	// Load database abstraction layer
	if (defined('MARKET_DB_EXT')) {
		if (extension_loaded(MARKET_DB_EXT)) {
			require_once('MARKET_DBI_' . MARKET_DB_EXT . '.inc.php');
		}
		else {
			MARKET_Base::raiseError(MARKET_ERROR_DIE,
				'Cannot load "' . MARKET_DB_EXT . '" extension. Cannot interact with the database.',
				__FILE__, __LINE__
			);
		}
	}
	else {
		if (extension_loaded('mysqli')) {
			define('MARKET_DB_EXT', 'mysqli');
			require_once('MARKET_DBI_mysqli.inc.php');
		}
		else if (extension_loaded('mysql')) {
			define('MARKET_DB_EXT', 'mysql');
			require_once('MARKET_DBI_mysql.inc.php');
		}
		else {
			MARKET_Base::raiseError(MARKET_ERROR_DIE,
				'No mysql extension is loaded. Cannot interact with the database.',
				__FILE__, __LINE__
			);
		}
	}
	
	// Some functions
	if (!function_exists('mb_ucfirst')) {
		function mb_ucfirst($str, $encoding = "UTF-8", $lower_str_end = false) {
			$first_letter = mb_strtoupper(mb_substr($str, 0, 1, $encoding), $encoding);
			$str_end = "";
			if ($lower_str_end) {
				$str_end = mb_strtolower(mb_substr($str, 1, mb_strlen($str, $encoding), $encoding), $encoding);
			}
			else {
				$str_end = mb_substr($str, 1, mb_strlen($str, $encoding), $encoding);
			}
			$str = $first_letter . $str_end;
			return $str;
		}
	}
		
	if (!function_exists('mb_lcfirst')) {
		function mb_lcfirst($str, $encoding = "UTF-8", $lower_str_end = false) {
			$first_letter = mb_strtolower(mb_substr($str, 0, 1, $encoding), $encoding);
			$str_end = "";
			if ($lower_str_end) {
				$str_end = mb_strtolower(mb_substr($str, 1, mb_strlen($str, $encoding), $encoding), $encoding);
			}
			else {
				$str_end = mb_substr($str, 1, mb_strlen($str, $encoding), $encoding);
			}
			$str = $first_letter . $str_end;
			return $str;
		}
	}
	
	if (!function_exists('mb_strrev')) {
		function mb_strrev($str) {
			return join('', array_reverse(preg_split('@@u', $str)));
		}
	}
	
	function __($str) {
		$lng = MARKET_Base::getRef('Lang');
		return $lng->translate($str);
	}
	
	class MARKET extends MARKET_Base {
		
		function MARKET()
		{
			// Debugging
			if (defined('DEBUG') && DEBUG) {
				// Error Reporting
				error_reporting(E_ALL & ~E_NOTICE & ~E_STRICT & ~E_DEPRECATED);
				ini_set('display_errors', '1');
				
				// Start debugging
				$this->getRef('Debug');
			}
			
			// Timezone settings
			if (defined('MARKET_TIMEZONE')) {
				date_default_timezone_set(MARKET_TIMEZONE);
			}
			else {
				date_default_timezone_set('UTC');
			}
			
			// Internal encoding for multi-byte string manipulation
			if (extension_loaded('mbstring')) {
				mb_internal_encoding('UTF-8');
				mb_regex_encoding('UTF-8');
			}
			else {
				MARKET_Base::raiseError(MARKET_ERROR_DIE,
					'The "mbstring" extension is not loaded. Please see the README file.',
					__FILE__, __LINE__
				);
			}
			
			// Parse the request
			$this->getRef('Request');
		}
		
		
		function printPage()
		{
			print $this->getPage();
		}
		
		
		function getPage()
		{
			global $MARKET_mode;
			
			$auth =& $this->getRef('Auth');
			$tpl =& $this->getRef('Template');
			
			$TEMPLATE = $tpl->main_template;
			$VAR = strtoupper($TEMPLATE);
			
			switch ($MARKET_mode) {
				
				case 'admin':
					$auth->checkPermissions('admin');
					
				case 'edit':
					$auth->checkPermissions('registered');
				
				case 'public':
					$req =& $this->getRef('Request');
					// noSpam
					if ($req->params[0] == 'nospam') {
						$tpl->getNoSpamImage($_GET['a'], $_GET['b']); // This function will exit
					}
					if ($tname = $tpl->loadPage($req->url)) {
						if ($tpl->loadTemplate($tname)) {
							// Check Permissions and redirect to login screen if necessary
							if ($tpl->permissions != 'public') {
								$auth =& $this->getRef('Auth');
								if ($auth->checkPermissions($tpl->permissions)) {
									$tpl->parseTemplate($VAR, $TEMPLATE);
								}
								else {
									$req->httpError(403); // Access Denied
								}
							}
							else {
								$tpl->parseTemplate($VAR, $TEMPLATE);
							}
						}
						else {
							$req->httpError(404); // Not Found
						}
					}
					else {
						$req->httpError(404); // Not Found
					}
					
				break;
				
			}
			
			if (defined('DEBUG') && DEBUG) {
				$dbg  =& $this->getRef('Debug');
				$dbg->analyzePage();
				$tpl->vars['global'][$VAR] .= '<debug>{PAGE.Debug}</debug>';
			}
			return $tpl->getFinalTemplate($VAR);
		}
		
	}
	
?>