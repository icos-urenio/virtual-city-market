<?php
/**
 * @version     1.0a
 * @package     virtualCityMarket
 * @copyright   Copyright (C) 2012 Logotech S.A.. All rights reserved.
 * @license     GNU Affero General Public License version 3 or later; see LICENSE.txt
 * @author      Dimitrios Mitzias for Logotech S.A.
 */
 
	require_once('MARKET_Base.class.php');
	
	
	class MARKET_Sql_Parser extends MARKET_Base {
		
		var $sql = array();
		var $sql_type = '';
		
		var $db_tables = array();
		
		var $join = array();
		var $should_join = array();
		
		
		function MARKET_SQL_Parser()
		{
			
			// Dummy function
			
		}
		
		
		function analyseSQL($sql, $lang = '')
		{
			if (!$lang) $lang = MARKET_LANG;
			$this->parseSQL($sql);
			return $this->getSQL($lang);
		}
		
		
		function parseSQL($sql)
		{
			
			// Clear all
			$this->sql = array();
			$this->should_join = array();
			
			$sql = str_replace("\r", '', $sql);
			$sql = str_replace("\n", ' ', $sql);
			
			// Get rid of backticks. Probably a security breach. Todo:
			$sql = preg_replace('@`@', '', $sql);
			
			if ($sql) {
				$this->sql_type = '';
				
				// UNION SELECT patch
				// Works only for our grouping
				if (preg_match('/UNION SELECT (.*)$/', $sql, $matches)) {
					$sql = "SELECT " . $matches[1];
				}
				
				// SELECTs
				if (preg_match('/^(SELECT DISTINCT|SELECT) (.*)/', $sql, $matches)) {
					$this->sql_type = 'SELECT';
					$keywords = array('FROM', 'WHERE' , 'GROUP BY' , 'ORDER BY', 'LIMIT');
					// Force the order of sql components in array
					$this->sql = array($matches[1] => '', 'FROM' => '', 'WHERE' => '', 'GROUP BY' => '', 'ORDER BY' => '', 'LIMIT' => '');
				}
				
				// INSERTs
				else if (preg_match('/^(INSERT INTO) (.*)/', $sql, $matches)) {
					$this->sql_type = 'INSERT';
					$keywords = array('VALUES', 'WHERE');
				}
				
				// UPDATEs
				else if (preg_match('/^(UPDATE) (.*)/', $sql, $matches)) {
					$this->sql_type = 'UPDATE';
					$keywords = array('WHERE');
				}
				
				// DELETEs
				else if (preg_match('/^(DELETE) (.*)/', $sql, $matches)) {
					$this->sql_type = 'DELETE';
					$keywords = array('FROM', 'WHERE');
				}
				
				$current_keyword = $matches[1];
				$rest = trim($matches[2]);
				
				if ($this->sql_type) { // Matched
					foreach ($keywords as $keyword) {
						if (preg_match("@$keyword@", $rest)) {
							preg_match("@^(.*?)$keyword (.*)@", $rest, $matches);
							$this->sql[$current_keyword] = trim($matches[1]);
							$current_keyword = $keyword;
							$rest = trim($matches[2]);
						}
					}
					// One more time please
					$this->sql[$current_keyword] = $rest;
					
					if (!$this->sql['WHERE']) $this->sql['WHERE'] = 1;
					
				}
			}
			
		}
		
		
		function getSQL($lang = '')
		{
			if (!$lang) $lang = MARKET_LANG;
			switch ($this->sql_type) {
				case 'SELECT':
					$tables = $this->extractTables($this->sql['FROM']);
					if (is_array($tables)) {
						$fields = $this->extractFields($this->sql['SELECT'], $tables);
						foreach ($tables as $table) {
							$features = $this->getFeatures($table);
							if ($features['versioning']) {
								$this->prepareVsSQL($table, $lang);
							}
							else {
								if ($features['workflow']     && in_array($table . '_ps', $this->should_join)) $this->prepareWkSQL($table);
								if ($features['multilingual'] && in_array($table . '_ml', $this->should_join)) $this->prepareMlSQL($table, $lang);
							}
						}
					}
					$sql = '';
					foreach ($this->sql as $key=>$val) {
						if ($val) {
							//if (!($key == 'WHERE' && $val == '1')) {
								$sql .= $key . ' ' . $val . ' ';
							//}
						}
					}
					return $sql;
				break;
				case 'DELETE':
					$sql = "SELECT " . $table . ".id " . $sql;
					if (sqlQuery($sql, $res)) {
						while ($row = sqlFetchAssoc($res)) {
							$sqls[] = "DELETE FROM " . $table . " WHERE id='" . $row['id'] . "'";
							if ($features['workflow']) {
								$sqls[] = "DELETE FROM " . $table . "_ps WHERE id='" . $row['id'] . "'";
							}
						}
						return $sqls;
					}
					else {
						return false;
					}
				break;
			}
		}
		
		
		function prepareMlSQL($table, $lang)
		{
			switch ($this->sql_type) {
				case 'SELECT':
					$this->sql['FROM'] = preg_replace('@\b' . $table . '\b@', $table . ' STRAIGHT_JOIN ' . $table . '_ml', $this->sql['FROM']);
					$this->sql['WHERE'] .= " AND " . $table . ".id=" . $table . "_ml.id";
					if ($_GET['version_history']) {
						$this->sql['WHERE'] .= " AND " . $table . ".version=" . $table . "_ml.version";
					}
					// Add language constraint only once
					if (!preg_match('@' . $table . '_ml\.lang=\'' . $lang . '\'@', $this->sql['WHERE'])) {
						$this->sql['WHERE'] .= " AND " . $table . "_ml.lang='" . $lang . "'";
					}
				break;
			}
		}
		
		
		function prepareWkSQL($table)
		{
			global $MARKET_mode;
			switch ($this->sql_type) {
				case 'SELECT':
					$this->sql['FROM'] = preg_replace('@\b' . $table . '\b@', $table . ' STRAIGHT_JOIN ' . $table . '_ps', $this->sql['FROM']);
					$this->sql['WHERE'] .= " AND " . $table . ".id=" . $table . "_ps.id";
					if ($MARKET_mode == MARKET_MODE_PUBLIC) {
						$this->sql['WHERE'] .= " AND publish='1'";
					}
					else {
						$this->sql['WHERE'] .= " AND ('".$_SESSION['User']['Role']."'='1' OR (${table}_ps.owner='".$_SESSION['User']['Id']."' AND ${table}_ps.ups & 4) OR (${table}_ps.role='".$_SESSION['User']['Role']."' AND ${table}_ps.gps & 4) OR (${table}_ps.wps & 4) OR (${table}_ps.forward_ids LIKE '%,u" . $_SESSION['User']['Id'] . ",%') OR (${table}_ps.forward_ids LIKE '%,r" . $_SESSION['User']['Role'] . ",%'))";
					}
				break;
				case 'DELETE':
					$this->sql['FROM'] = preg_replace('@\b' . $table . '\b@', $table . ' LEFT JOIN ' . $table . '_ps USING (id)', $this->sql['FROM']);
					$this->sql['WHERE'] .= " AND ('".$_SESSION['User']['Role']."'='1' OR (${table}_ps.owner='".$_SESSION['User']['Id']."' AND ${table}_ps.ups & 4) OR (${table}_ps.role='".$_SESSION['User']['Role']."' AND ${table}_ps.gps & 4) OR (${table}_ps.wps & 4))";
				break;
			}
			
		}
		
		
		function prepareVsSQL($table, $lang)
		{
			switch ($this->sql_type) {
				case 'SELECT':
					$this->sql['FROM'] = preg_replace('@\b' . $table . '\b@', $table . '_vs', $this->sql['FROM']);
					$this->sql['WHERE'] .= " AND active='1'";
					// Add language constraint only once
					if (!preg_match('@' . $table . '_ml\.lang=\'' . $lang . '\'@', $this->sql['WHERE'])) {
						$this->sql['WHERE'] .= " AND " . $table . "_vs.lang='" . $lang . "'";
					}
				break;
			}
		}
		
		
		function extractTables($str)
		{
			$tables = array();
			if ($str) {
				while (preg_match("@(,|STRAIGHT_JOIN|LEFT JOIN|ON|USING)@", $str, $matched_keyword)) {
					switch ($matched_keyword[1]) {
						case 'ON':
							preg_match("@^(\w+) ON .+=.+(.*)@U", $str, $matches);
						break;
						case 'USING':
							preg_match("@^(\w+) USING \(.+\)(.*)@U", $str, $matches);
						break;
						default:
							preg_match("@^(\w+)\s*$matched_keyword[1] (.*)@", $str, $matches);
					}
					$matches  = $this->arrayTrim($matches);
					$tables[] = $matches[1];
					$str      = $matches[2];
				}
				$str = trim($str);
				if ($str) {
					// One more time please
					$tables[] = $str;
				}
			}
			return $tables;
		}
		
		
		function extractFields($str, $tables)
		{
			if ($str) {
				$i = 0;
				$rest = '';
				$myfields = $this->arrayTrim($this->explodeString(',', $str));
				foreach ($myfields as $myfield) {
					if (preg_match('@^([a-z_\.]+) AS ([a-z_]+)$@i', $myfield, $matches)) {
						if (preg_match('@^([a-z_]+)\.([a-z_\*]+)$@i', $matches[1], $matches1)) {
							$fields[$i]['table'] = $matches1[1];
							$fields[$i]['name']  = $matches1[2];
						}
						else {
							$fields[$i]['name']  = $matches[1];
						}
						$fields[$i]['alias']  = $matches[2];
					}
					else if (preg_match('@^([a-z_]+)\.([a-z_\*]+)$@i', $myfield, $matches)) {
						$fields[$i]['table'] = $matches[1];
						$fields[$i]['name']  = $matches[2];
					}
					else if (preg_match('@^([a-z_\*]+)$@i', $myfield)) {
						$fields[$i]['name'] = $myfield;
					}
					else {
						$rest .= $myfield . ', '; // functions
					}
					$i++;
				}
			}
			if ($rest) {
				$j = 0;
				if (preg_match_all('@^[A-Z_]+\((.*)\) AS ([a-z_]+),$@Ui', trim($rest), $matches)) {
					foreach($matches[0] as $key => $match) {
						$fields[$i]['expr'] = substr($matches[0][$key], 0, -1);
						$fields[$i]['alias'] = $matches[2][$key];
						$myfields = $this->arrayTrim($this->explodeString(',', $matches[1][$key]));
						foreach ($myfields as $myfield) {
							if (preg_match('@^([a-z_]+)\.([a-z_]+)$@i', $myfield, $matches1)) {
								$fields[$i]['table'][$j] = $matches1[1];
								$fields[$i]['name'][$j] = $matches1[2];
							}
							else if (preg_match('@^([a-z_]+)$@i', $myfield)) {
								$fields[$i]['name'][$j] = $myfield;
							}
							$j++;
						}
						$i++;
					}
				}
			}
			
			// Now find the tables for the fields that do not have one
			// Include market tables (Permissions, Multilingual)
			$myfields = array();
			$dbi =& $this->getRef('Database_Info');
			$extensions = array('', '_ps', '_ml');
			foreach ($tables as $table) {
				foreach ($extensions as $extension) {
					if ($tablefields = $dbi->getFields(MARKET_DB_DATABASE, $table . $extension)) {
						foreach ($tablefields AS $tablefield) {
							$myfields[$tablefield['Field']] = $table . $extension;
						}
					}
				}
			}
			if (is_array($fields)) {
				foreach ($fields as $i => $field) {
					if (is_array($field['name'])) {
						foreach ($field['name'] as $j => $val) {
							if (!$fields[$i]['table'][$j]) {
								$fields[$i]['table'][$j] = $myfields[$fields[$i]['name'][$j]];
								if (!in_array($fields[$i]['table'][$j], $tables)
									&& !in_array($fields[$i]['table'][$j], $this->should_join)) {
										$this->should_join[] = $fields[$i]['table'][$j];
								}
							}
						}
					}
					else {
						if (!$field['table']) {
							$fields[$i]['table'] = $myfields[$field['name']];
						}
						if (!in_array($fields[$i]['table'], $tables)
							&& !in_array($fields[$i]['table'], $this->should_join)) {
								$this->should_join[] = $fields[$i]['table'];
						}
					}
				}
			}
			return $fields;
		}
		
		
		function getFeatures($table)
		{
			if (!$this->db_tables) {
				
				// Get Database Info
				$dbi =& $this->getRef('Database_Info');
				$db_tables = $dbi->getTables(MARKET_DB_DATABASE);
				foreach ($db_tables as $db_table) {
					if (preg_match('@^(.+)_ml$@', $db_table, $matches)) {
						$this->db_tables[$matches[1]]['multilingual'] = 1;
					}
					else if (preg_match('@^(.+)_ps$@', $db_table, $matches)) {
						$this->db_tables[$matches[1]]['workflow'] = 1;
					}
					else if (preg_match('@^(.+)_vs$@', $db_table, $matches)) {
						//$this->db_tables[$matches[1]]['versioning'] = 1;
					}
				}
			}
			return $this->db_tables[$table];
		}
		
		
	}

?>