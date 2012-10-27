<?php
/**
 * @version     1.0a
 * @package     virtualCityMarket
 * @copyright   Copyright (C) 2012 Logotech S.A.. All rights reserved.
 * @license     GNU Affero General Public License version 3 or later; see LICENSE.txt
 * @author      Dimitrios Mitzias for Logotech S.A.
 */
 
	class MARKET_Session {
		
		var $session_name = 'market_sid';
		var $web_dir = '';
		
		function MARKET_Session()
		{
			$this->session_name = defined('MARKET_SESSION_NAME') ? MARKET_SESSION_NAME : $this->session_name;
			$this->web_dir      = defined('MARKET_WEB_DIR')      ? MARKET_WEB_DIR      : $this->web_dir;
			
			$this->startSession();
		}
		
		
		function startSession()
		{
			ini_set('session.save_handler', 'user');
			ini_set('session.use_trans_sid', 0);
			
			session_name($this->session_name);
			session_cache_limiter('no-cache');
			session_set_cookie_params(0, $this->web_dir . '/' );
			
			// Initiate functions for manipulating data associated with a user session.
			session_set_save_handler(
				array($this, 'sessionOpen'),
				array($this, 'sessionClose'),
				array($this, 'sessionRead'),
				array($this, 'sessionWrite'),
				array($this, 'sessionDestroy'),
				array($this, 'sessionGc')
			);
			
			session_start();
		}
		
		
		function sessionOpen($save_path, $name)
		{
			return true;
		}
		
		
		function sessionClose()
		{
			return true;
		}
		
		
		function sessionRead($session_id)
		{
			$sql = "SELECT data FROM market_session WHERE session_id='" . $session_id . "'";
			if (sqlQuery($sql, $res, EXT_DEBUG)) {
				return sqlResult($res, 0);
			}
			return '';
		}
		
		
		function sessionWrite($session_id, $data)
		{
  			$expires = time() + get_cfg_var('session.gc_maxlifetime');
			$sql = "UPDATE market_session SET expires='" . $expires . "', data='" . $data . "' WHERE session_id = '" . $session_id . "'";
			if (!sqlQuery($sql, $res, EXT_DEBUG)) {
				$sql = "INSERT INTO market_session (session_id, expires, data) VALUES ('" . $session_id . "', '" . $expires . "', '" . $data . "')";
				sqlQuery($sql, $res, EXT_DEBUG);
				if (!$res) {
					return false;
				}
			}
			return true;
		}
		
		
		function sessionDestroy($session_id)
		{
			$sql = "DELETE FROM market_session WHERE session_id = '" . $session_id . "'";
			return sqlQuery($sql, $res, EXT_DEBUG);
		}
		
		
		function sessionGc($gc_maxlifetime)
		{
			$sql = "DELETE FROM market_session WHERE expires<'" . time() . "'";
			return sqlQuery($sql, $res, EXT_DEBUG);
		}
		
	}
	
?>