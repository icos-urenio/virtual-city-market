<?php
/**
 * @version     1.0a
 * @package     virtualCityMarket
 * @copyright   Copyright (C) 2012 Logotech S.A.. All rights reserved.
 * @license     GNU Affero General Public License version 3 or later; see LICENSE.txt
 * @author      Dimitrios Mitzias for Logotech S.A.
 */
 
	require_once('MARKET_Base.class.php');
	
	class MARKET_Request extends MARKET_Base {
		
		var $url = '';
		var $query_string = '';
		var $params = array();
		
		
		function MARKET_Request()
		{
			global $MARKET_mode, $MARKET_mod_rewrite;
			
			$url = '';
			if ((function_exists('apache_get_modules') && in_array('mod_rewrite', apache_get_modules())) ||  getenv('HTTP_MOD_REWRITE') == 'On') {
				$MARKET_mod_rewrite = true;
				
				if (array_key_exists('REQUEST_URI', $_SERVER)) {
					$url = substr($_SERVER['REQUEST_URI'], strlen(MARKET_WEB_DIR) + 1);
					$url = preg_replace('@\?.*@', '', $url);
				}
			}
			else {
				$MARKET_mod_rewrite = false;
				
				if (array_key_exists('PATH_INFO', $_SERVER)) {
					$url = substr($_SERVER['PATH_INFO'], 1);
				}
			}
			$query_string = $_SERVER['QUERY_STRING'];
			
			if (!$url || preg_match('@/$@', $url)) {
				$url .= 'index.html';
			}
			
			$params = explode('/', $url);
			
			// Language
			$lng =& $this->getRef('Lang');
			if ($lng->isLanguage($params[0])) {
				$lang = $params[0];
				$this->stripParams($params, $url);
				$lng->setLanguage($lang);
			}
			else {
				$lng->setLanguage('');
				if (count($lng->getAvailable()) > 1) {
					$this->redirectTo(MARKET_WEB_DIR . '/' . $lng->lang . '/' . $url . (($query_string) ? '?' . $query_string : ''));
				}
			}
			
			$this->request = $url . ($query_string ? '?' . $query_string : '');
			
			// MARKET Mode
			switch ($params[0]) {
				case 'admin':
					$MARKET_mode = 'admin';
					$this->stripParams($params, $url);
					$lng->loadStrings($lng->lang, false);
				break;
				case 'edit':
					$MARKET_mode = 'edit';
					$this->stripParams($params, $url);
					$lng->loadStrings($lng->lang, true);
				break;
				default:
					$MARKET_mode = 'public';
					$lng->loadStrings($lng->lang, true);
			}
			
			$last = count($params) - 1;
			$params[$last] = preg_replace('@\.html$@', '', $params[$last]);
			
			$this->url = $url;
			$this->query_string = $query_string;
			$this->params = $params;
			
		}
		
		
		function stripParams(&$params, &$url)
		{
			$url = preg_replace('@^' . $this->pregEscape($params[0]) . '/@', '', $url);
			array_shift($params);
		}
		
		
		function redirectTo($url)
		{
			if ($url) {
				$url = preg_replace('@&amp;@', '&', $url);
				header('Location: ' . $url);
				exit;
			}
			$this->raiseError(MARKET_ERROR_MAIL | MARKET_ERROR_DIE,
				'redirectTo(): Cannot redirect to an empty url',
				__FILE__, __LINE__
			);
		}
		
		
		function replaceInUrl($param, $val, $keep_name = false)
		{
			global $MARKET_mode;
			$query_string = $this->query_string;
			if (is_array($param)) {
				$counti = count($param);
				for ($i = 0; $i < $counti; $i++) {
					$query_string = $this->rIU($param[$i], $val[$i], $query_string, $keep_name);
				}
			}
			else {
				$query_string = $this->rIU($param, $val, $query_string, $keep_name);
			}
			
			if (preg_match('@^\?@', $query_string)) $query_string = substr($query_string, 1);
			$parts = explode('&', $query_string);
			$query_string = '';
			foreach ($parts as $part) {
				list($key, $val) = explode('=', $part);
				$query_string .= urlencode(urldecode($key)) . '=' . urlencode(urldecode($val)) . '&';
			}
			$query_string = substr($query_string, 0, -1);
			
			$query_string = preg_replace('@&@', '&amp;', $query_string);
			
			$query_string = ($query_string) ? '?' . $query_string : '';
			
			if ($MARKET_mode == 'admin') {
				return 'admin/' . $this->url . $query_string;
			}
			else {
				return $this->url . $query_string;
			}
		}
		
		
		function rIU($param, $val, $query_string, $keep_name = false)
		{
			if ($query_string) {
				// Helps regular expression matching
				$query_string = '&' . $query_string . '&';
				
				if (preg_match('@&' . $param . '=.*&(?!#\d+;)@U', $query_string)) {
					if ($val) {
						$query_string = preg_replace('@&' . $param . '=.*&(?!#\d+;)@U', '&' . $param . '=' . $val . '&', $query_string);
					}
					else if ($keep_name) {
						$query_string = preg_replace('@&' . $param . '=.*&(?!#\d+;)@U', '&' . $param . '=&', $query_string);
					}
					else {
						$query_string = preg_replace('@&' . $param . '=.*&(?!#\d+;)@U', '&', $query_string);
					}
				}
				else if ($val) {
					$query_string .= $param . '=' . $val . '&';
				}
				// Get rid of the ampersands introduced above
				$query_string = substr($query_string, 1, -1);
			}
			else {
				$query_string = $param . '=' . $val;
			}
			return $query_string;
		}
		
		
		function httpError($error_number)
		{
			if (preg_match('@^\d+$@', $error_number)) {
				$http_errors = file(MARKET_INCLUDE_DIR . '/http_errors.txt');
				foreach ($http_errors as $http_error) {
					if (preg_match('@^' . $error_number . '@', $http_error)) {
						
						$http_error = trim($http_error);
						list($error['number'], $error['title'], $error['description']) = preg_split("@\t@", $http_error, -1, PREG_SPLIT_NO_EMPTY);
						
						header ('HTTP/1.1 ' . $error[0] . ' ' . $error[1]);
						
						$tpl =& $this->getRef('Template');
						if ($tpl->loadTemplate($error_number) || $tpl->loadTemplate('http_error')) {
							
							$tpl->assignGlobal(array(
								'ERROR' => $error,
								'URL' => MARKET_WEB_DIR . '/' . $this->request,
								'REQUEST_METHOD' => $_SERVER['REQUEST_METHOD'],
								'ADDRESS' => str_replace('ADDRESS', 'address', $_SERVER['SERVER_SIGNATURE'])
							));
							$tpl->parseTemplate('HTTP_ERROR');
							
							if (defined('DEBUG') && DEBUG) {
								// Explicitly call the session close function in order to catch all SQL queries
								session_write_close();
								$dbg =& $this->getRef('Debug');
								$dbg->analyzePage();
								$tpl->vars['global']['HTTP_ERROR'] .= '<debug>{PAGE.Debug}</debug>';
							}

							$tpl->printTemplate('HTTP_ERROR');
						
						}
						else {
							
							$error['description'] = preg_replace('@\{URL\}@', MARKET_WEB_DIR . '/' . $this->request, $error['description']);
							$error['description'] = preg_replace('@\{REQUEST_METHOD\}@', $_SERVER['REQUEST_METHOD'], $error['description']);
							
							print '<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">' . "\n" .
									'<html>' . "\n" .
										'<head>' . "\n" .
											'<title>' . $error['number'] . ' ' . $error['title'] . '</title>' . "\n" .
										'</head>' . "\n" .
										'<body>' . "\n" .
											'<h1>' . $error['title'] . '</h1>' . "\n" .
											'<p>' . $error['description'] . '</p>' . "\n" .
											'<hr />' . "\n" .
											str_replace('ADDRESS', 'address', $_SERVER['SERVER_SIGNATURE']) . "\n" .
										'</body>' . "\n" .
									'</html>';
									
						}
						exit;
					}
				}
			}
			exit;
		}
		
		
	}

?>