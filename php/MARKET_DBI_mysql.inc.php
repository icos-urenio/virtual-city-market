<?php
/**
 * @version     1.0a
 * @package     virtualCityMarket
 * @copyright   Copyright (C) 2012 Logotech S.A.. All rights reserved.
 * @license     GNU Affero General Public License version 3 or later; see LICENSE.txt
 * @author      Dimitrios Mitzias for Logotech S.A.
 */
 
	function sqlQuery($sql, &$res, $log = true)
	{
		global $MARKET_db_conn;
		
		// Connect to database
		if (!is_resource($MARKET_db_conn)) {
			$MARKET_db_conn = @mysql_connect(MARKET_DB_HOST, MARKET_DB_USER, MARKET_DB_PASS)
				or	MARKET_Base::raiseError(MARKET_ERROR_DIE,
						'sql_connect(): Cannot connect to "' . MARKET_DB_HOST . '" SQL Server',
						__FILE__, __LINE__
					);
			@mysql_select_db(MARKET_DB_DATABASE)
				or	MARKET_Base::raiseError(MARKET_ERROR_DIE,
					'sql_select_db(): Cannot select database "' . MARKET_DB_DATABASE . '"',
					__FILE__, __LINE__
				);
			if (defined('MARKET_DB_COLLATION')) {
				@mysql_query("SET NAMES '" . MARKET_DB_COLLATION . "'");
			}
			else {
				@mysql_query("SET NAMES 'utf8' COLLATE 'utf8_unicode_ci'");
			}
		}
		
		if (DEBUG && $log) {
			$dbg =& MARKET_Base::getRef('Debug');
			$dbg->add('sql', $sql);
			$prf =& MARKET_Base::getRef('Profiler');
			$prf->startTimer('sqlQuery', $sql);
		}
		
		$res = @mysql_query($sql, $MARKET_db_conn);
		
		if (DEBUG && $log) $prf->stopTimer('sqlQuery');
		
		if ($res) {
			if (preg_match('@^(SELECT|SHOW)(?! CREATE)@', $sql) && ($found = @mysql_num_rows($res))) {
				if (DEBUG && $log) $dbg->add('info', 'MySQL Results: ' . $found);
				return $found;
			}
			else if (preg_match('@^EXPLAIN@', $sql) && ($found = @mysql_num_rows($res))) {
				return true;
			}
			else if (preg_match('@^INSERT@', $sql)) {
				$sql = "SELECT LAST_INSERT_ID()";
				$res = @mysql_query($sql, $MARKET_db_conn);
				
				$insert_id = @mysql_result($res, 0);
				$insert_id = ($insert_id) ? $insert_id : -1;
				if (DEBUG && $log) $dbg->add('info', 'MySQL Insert ID: ' . $insert_id);
				return $insert_id;
			}
			else if (preg_match('@^(UPDATE|DELETE|REPLACE)@', $sql)) {
				$affected_rows = @mysql_affected_rows($MARKET_db_conn);
				if (DEBUG && $log) $dbg->add('info', 'MySQL Affected Rows: ' . $affected_rows);
				return $affected_rows;
			}
			else if (preg_match('@^CREATE@', $sql)) {
				if (DEBUG && $log) $dbg->add('info', 'MySQL Results: Table creation');
				return true;
			}
			else if (preg_match('@^SHOW CREATE@', $sql)) {
				if (DEBUG && $log) $dbg->add('info', 'MySQL Results: Table creation SQL');
				return true;
			}
			else {
				if (DEBUG && $log) $dbg->add('info', 'MySQL Results: Unknown');
			}
		}
		else if (DEBUG && $log) {
			$dbg->add('info', 'MySQL Error: ' . sqlError());
		}
		return false;
	}
	
	
	function sqlResult(&$res, $row, $col = 0)
	{
		return @mysql_result($res, $row, $col);
	}
	
	
	function sqlFreeResult(&$res)
	{
		@mysql_free_result($res);
	}
	
	
	function sqlFetchArray(&$res)
	{
		return @mysql_fetch_array($res);
	}
	
	
	function sqlFetchAssoc(&$res)
	{
		return @mysql_fetch_assoc($res);
	}
	
	
	function sqlFetchField(&$res)
	{
		return @mysql_fetch_field($res);
	}
	
	
	function sqlError()
	{
		return @mysql_error();
	}
	
	
	function sqlInsertId()
	{
		return @mysql_insert_id();
	}
	
	function sqlNumRows(&$res)
	{
		return @mysql_num_rows($res);
	}
	
	function sqlEscape($str = '')
	{
		return @mysql_real_escape_string($str);
	}
	
	function sqlSelectDb($db)
	{
		return @mysql_select_db($db);
	}

?>
