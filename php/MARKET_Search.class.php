<?php
/**
 * @version     1.0a
 * @package     virtualCityMarket
 * @copyright   Copyright (C) 2012 Logotech S.A.. All rights reserved.
 * @license     GNU Affero General Public License version 3 or later; see LICENSE.txt
 * @author      Dimitrios Mitzias for Logotech S.A.
 */
 
	require_once('MARKET_Base.class.php');
	
	
	class MARKET_Search extends MARKET_Base {
		
		var $cmd        = '';
		var $search_for = array();
		var $search_in  = array();
		var $search_as  = array();
		
		
		function MARKET_Search ()
		{
			// Dummy
		}
		
		
		function searchFor($keywords, $cmd, $search_as, $mode = 'single', $part = 'FULL')
		{
			$this->search_for = array();
			$this->search_as = $search_as;
			$this->parseKeywords(trim($keywords));
			$this->parseCmd($cmd);
			return $this->getSql($mode, $part);
		}
		
		
		function parseKeywords($keywords)
		{
			if ($keywords) {
				$keywords = mb_split('\-\|\|\-', $keywords); // Split multiple keywords at -||-
				foreach ($keywords as $keyword) {
					
					$j = 0;
					$tokens = array();
					$in_quoted_string = false;
					
					$params = preg_split('@\s+@u', $keyword);
					
					$counti = count($params);
					for ($i = 0; $i < $counti; $i++) {
						
						if (!isset($tokens[$j])) {
							$tokens[$j]['token'] = '';
							$tokens[$j]['logic'] = 'AND';
						}
						
						if (!$in_quoted_string) {
							if ($params[$i] != '-' && preg_match('@^\-@', $params[$i])) {
								$tokens[$j]['logic'] = 'NOT';
								$params[$i] = substr($params[$i], 1);
							}
						}
						
						if (preg_match('@^\"@', $params[$i])) {
							$in_quoted_string = true;
							$params[$i] = substr($params[$i], 1);
						}
						
						if ($in_quoted_string) {
							$tokens[$j]['token'] .= $params[$i] . ' ';
						}
						else {
							$tokens[$j]['token'] = trim($params[$i]);
							if ($tokens[$j]['token']) $j++;
						}
						
						if (preg_match('@\"$@', $params[$i])) {
							$in_quoted_string = false;
							$tokens[$j]['token'] = trim(substr($tokens[$j]['token'], 0, -2));
							if ($tokens[$j]['token']) $j++;
						}
						
					}
					
					$this->search_for[] = $tokens;
					
				}
			}
		}
		
		
		function parseCmd($cmd)
		{
			// Clear all
			$this->cmd = array();
			
			$keywords = "SEARCH IN|OF|WHERE|RETURN|GROUP BY|ORDER BY";
			while (preg_match('@(' . $keywords . ')@', $cmd, $matched_keyword)) {
				preg_match('@^(.*)' . $matched_keyword[1] . '(.*)@', $cmd, $matches);
				if ($current_keyword) $this->cmd[$current_keyword] = trim($matches[1]);
				$current_keyword = $matched_keyword[1];
				$cmd = trim($matches[2]);
			}
			// One more time please
			$this->cmd[$current_keyword] = $cmd;
			if (!$this->cmd['WHERE']) $this->cmd['WHERE'] = 1;
		}
		
		
		function getSql($mode, $part)
		{
			switch ($part) {
				case 'FULL':
					$sql = 'SELECT ' . $this->cmd['RETURN'] . ' FROM ' . $this->cmd['OF'] . ' WHERE ' . $this->cmd['WHERE'] . ' AND (';
				break;
				case 'WHERE':
					$sql = ' AND (';
				break;
				
			}
			
			$tokens = $this->search_for;
			if (preg_match('@^CONCAT@', $this->cmd['SEARCH IN'])) {
				$search_in = array(trim($this->cmd['SEARCH IN']));
			}
			else {
				$search_in = $this->arrayTrim(explode(',', $this->cmd['SEARCH IN']));
			}
			$search_as = $this->arrayTrim(explode(',', $this->search_as));
			
			if ($mode == 'multiple') {
				$counti = count($tokens);
				for ($i = 0; $i < $counti; $i++) {
					$in[$i][] = $search_in[$i];
					$as[$i][] = $search_as[$i];
				}
			}
			else {
				$in[0] = $search_in;
				$as[0] = $search_as;
			}
			$counti = count($tokens);
			for ($i = 0; $i < $counti; $i++) {
				$sql .= "(";
				$countk = count($in[$i]);
				for ($k = 0; $k < $countk; $k++) {
					$countj = count($tokens[$i]);
					for ($j = 0; $j < $countj; $j++) {
						if (preg_match('@\*@', $tokens[$i][$j]['token'])) {
							$tokens[$i][$j]['token'] = preg_replace('@\*@', '%', $tokens[$i][$j]['token']);
						}
						/*
						if (preg_match('@(.+)_ids$@', $search_in[$j], $matches)) {
							$keyword_sql = "SELECT $matches[1].id FROM $matches[1] WHERE title='$tokens[0][$i]'";
							$sqp =& $this->getRef('Sql_Parser');
							$sqp->parseSQL($keyword_sql);
							$keyword_sql = $sqp->getSQL();
							if (sqlQuery($keyword_sql, $res)) {
								$token = ',' . sqlResult($res, 0) . ',';
							}
							else {
								$token = $tokens[0][$i];
							}
						}
						else {
							$token = $tokens[$i][$j];
						}
						*/
						if ($tokens[$i][$j]['logic'] == 'NOT') {
							$token = $tokens[$i][$j]['token'];
							$equal = '<>';
							$like  = 'NOT LIKE';
							$and   = 'AND';
						}
						else {
							$token = preg_replace('@^\+@', '', $tokens[$i][$j]['token']);
							$equal = '=';
							$like  = 'LIKE';
							if ($mode == 'multiple') {
								$and   = 'OR';
							}
							else if ($mode == 'allwords') {
								$and   = 'OR';
							}
							else {
								$and   = 'AND';
							}
						}
						
						if (preg_match('@\%@', $token)) {
							$search_as = 'nochange';
						}
						else {
							$search_as = $as[$i][$k];
						}
						switch ($search_as) {
							case 'exact':
								$sql .= $in[$i][$k] . " $like '" . sqlEscape($token) . "'";
							break;
							case 'nochange':
								$sql .= $in[$i][$k] . " $like '" . sqlEscape($token) . "'";
							break;
							case 'start':
								$sql .= $in[$i][$k] . " $like '" . sqlEscape($token) . "%'";
							break;
							case 'end':
								$sql .= $in[$i][$k] . " $like '%" . sqlEscape($token) . "'";
							break;
							case 'both':
							default:
								$sql .= $in[$i][$k] . " $like '%" . sqlEscape($token) . "%'";
						}
						if ($j < $countj - 1) {
							$sql .= " $and ";
						}
					}
					if ($k < $countk - 1) {
						$sql .= ') OR (';
					}
					else {
						$sql .= ')';
					}
				}
				if ($i < $counti - 1) {
					$sql .= ') AND (';
				}
				else {
					$sql .= ')';
				}
			}
			
			if ($part == 'FULL') {
				if ($this->cmd['GROUP BY']) $sql .= ' GROUP BY ' . $this->cmd['GROUP BY'];
				if ($this->cmd['ORDER BY']) $sql .= ' ORDER BY ' . $this->cmd['ORDER BY'];
			}
			
			return $sql;
		}
		
		
	}
	
?>