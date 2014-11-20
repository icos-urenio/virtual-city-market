<?php
/**
 * @version     1.0a
 * @package     virtualCityMarket
 * @copyright   Copyright (C) 2012 Logotech S.A.. All rights reserved.
 * @license     GNU Affero General Public License version 3 or later; see LICENSE.txt
 * @author      Dimitrios Mitzias for Logotech S.A.
 */
 
	require_once('MARKET_Base.class.php');
	
	class MARKET_Auth extends MARKET_Base {
		
		
		function MARKET_Auth()
		{
			if (!session_id()) {
				// Start session
				$this->getRef('Session');
			}
		}
		
		
		function checkPermissions($permissions)
		{
			if ($permissions == 'public') {
				// Nothing else is needed
			}
			// Not only do we have to make sure that the user is logged in
			else if (!$_SESSION['User']['is_loggedin']) {
				$req =& $this->getRef('Request');
				$req->redirectTo(MARKET_WEB_DIR . '/login.html?redirect=' . urlencode($req->request));
			}
			else if ($permissions == 'registered') {
				// Nothing else is needed
			}
			else if ($permissions == 'admin') {
				// We also should make sure that he is an administrator
				if (!$_SESSION['User']['is_admin']) {
					return false;
				}
			}
			return true;
		}
		
		
		function userLogin($sql)
		{
			if (sqlQuery($sql, $res, EXT_DEBUG)) {
				$_SESSION['User'] = sqlFetchAssoc($res);
				$_SESSION['User']['data'] = unserialize($_SESSION['User']['data']);
				$_SESSION['User']['is_loggedin'] = true;
				return true;
			}
			return false;
		}
		
		
		function userLogout()
		{
			unset($_SESSION['User']);
		}
		
		
		function saveUserData($var, $val)
		{
			if ($_SESSION['User']['is_loggedin']) {
				if ($val) {
					$_SESSION['User']['data'][$var] = $val;
				}
				else {
					unset($_SESSION['User']['data'][$var]);
				}
				$sql = "UPDATE market_user SET data='" . sqlEscape(serialize($_SESSION['User']['data'])) . "' WHERE user_id='" . $_SESSION['User']['user_id'] . "'";
				sqlQuery($sql, $res, EXT_DEBUG);
				return true;
			}
			return false;
		}
	}

?>