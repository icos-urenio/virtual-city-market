<?php
/**
 * @version     1.0a
 * @package     virtualCityMarket
 * @copyright   Copyright (C) 2012 Logotech S.A.. All rights reserved.
 * @license     GNU Affero General Public License version 3 or later; see LICENSE.txt
 * @author      Dimitrios Mitzias for Logotech S.A.
 */
 
	require_once('MARKET_Base.class.php');
	
	class MARKET_Debug extends MARKET_Base {
		
		var $start = 0;
		
		var $errors   = array();
		var $warnings = array();
		var $vars	  = array();
		var $sqls     = array();
		var $infos    = array();
		
		
		function MARKET_Debug()
		{
			$this->resetTime();
		}
		
		
		function resetTime()
		{
			$this->start = $this->getCurrentTime();
		}
		
		
		function getCurrentTime()
		{
			$time = explode(' ', microtime());
			$usec = (double)$time[0];
			$sec  = (double)$time[1];
			return $sec + $usec;
		}
		
		
		function getElapsedTime($start = '', $resolution = 4)
		{
			if ($start) {
				$elapsed_time = $this->getCurrentTime() - $start;
			}
			else {
				$elapsed_time = $this->getCurrentTime() - $this->start;
			}
			return number_format($elapsed_time, $resolution);
		}
		
		
		function getMemoryUsage()
		{
			if (function_exists('memory_get_peak_usage')) {
				return memory_get_peak_usage(true);
			}
			else {
				return 'unknown';
			}
		}
		
		
		function add($type, $value, $variable = '')
		{
			if ($variable) {
				$this->{$type . 's'}[$variable] = print_r($value, true);
			}
			else if ($type == 'warning' || $type == 'error') {
				$this->errors[] = array($type, $value);
			}
			else {
				$this->{$type . 's'}[] = $value;
			}
		}
		
		
		function analyzePage()
		{
			
			// Get a reference to a template
			$tpl =& $this->getRef('Template');
			
			if ($tpl->loadTemplate('debug', MARKET_INDIRECT_CALL)) {
				
				// Elapsed Time
				$tpl->assignLocal('debug', 'ELAPSED_TIME', $this->getElapsedTime());
				
				// Memory
				$tpl->assignLocal('debug', 'MEMORY_USED', $this->getMemoryUsage());
				
				// Errors
				$counti = count($this->errors);
				if ($counti) {
					$tpl->assignLocal('debug', 'NUM_OF_ERRORS', $counti . ' ' . ($counti==1 ? 'error' : 'errors') . ' occured.');
					$vars = '';
					for ($i = 0; $i < $counti; $i++) {
						$vars .= 'type:`' . $this->errors[$i][0] . '`,value:`' . $this->errors[$i][1] . '`;';
					}
					$tpl->assignSource('error', $vars);
				}
				else {
					$tpl->assignLocal('debug', 'NUM_OF_ERRORS', 'No error.');
					$tpl->disableTemplate('errors_cnt');
				}
				
				// Variables
				$counti = count($this->vars);
				if ($counti) {
					$tpl->assignLocal('debug', 'NUM_OF_VARS', $counti . ' ' . ($counti==1 ? 'variable' : 'variables') . ' watched.');
					$vars = '';
					foreach ($this->vars as $avar => $value) {
						$vars .= 'variable:`'. $avar. '`,value:`' . $value."`;";
					}
					$tpl->assignSource('variable', $vars);
				}
				else {
					$tpl->assignLocal('debug', 'NUM_OF_VARS', 'No variables.');
					$tpl->disableTemplate('variables_cnt');
				}
				// SQLs
				$counti = count($this->sqls);
				if ($counti) {
					$tpl->assignLocal('debug', 'NUM_OF_SQLS', 'This page executed ' . $counti . ' ' . ($counti==1 ? 'query' : 'queries' ) . '.');
					$vars = '';
					for ($i = 0; $i < $counti; $i++) {
						$vars = "sql_query:`" . htmlspecialchars($this->sqls[$i]) . "`;";
						$tpl->assignSource('sql', $vars);
						$tpl->assignLocal('sql', 'SQL_INFO', '[' . $this->infos[$i] . ']');
						if (preg_match('@^SELECT@', $this->sqls[$i])) {
							if (sqlQuery('EXPLAIN ' . $this->sqls[$i], $res, false)) {
								$vars = '';
								while ($row = sqlFetchAssoc($res)) {
									foreach ($row as $key=>$val) {
										if (!$val) $val = '&nbsp;';
										$vars .= ucfirst($key) . ':`' . $val . '`,';
									}
									$vars = substr($vars, 0, -1) . ';';
								}
								if (preg_match('@^comment:`(.*)`@i', $vars, $match)) {
									$tpl->assignGlobal('SQL_CNT', '<br />[Comment: ' . $match[1] . ']');
									$tpl->disableTemplate('sql_cnt');
								}
								else {
									$tpl->assignSource('explain', $vars);
									$tpl->parseTemplate('EXPLAIN', 'explain', MARKET_DO_NOT_APPEND);
									$tpl->parseTemplate('SQL_CNT', 'sql_cnt', MARKET_DO_NOT_APPEND);
								}
							}
							else {
								$tpl->clearGlobal('SQL_CNT');
								$tpl->disableTemplate('sql_cnt');
							}
						}
						else {
							$tpl->clearGlobal('SQL_CNT');
							$tpl->disableTemplate('sql_cnt');
						}
						$tpl->parseTemplate('SQL', 'sql');
						$tpl->enableTemplate('sql_cnt');
					}
					$tpl->clearGlobal('SQL_CNT');
				}
				else {
					$tpl->assignLocal('debug', 'NUM_OF_SQLS', 'This page did not execute any query.');
					$tpl->disableTemplate('sql');
				}
				
				// Profiling data
				$prf =& $this->getRef('Profiler');
				$counti = count($prf->trace);
				if ($counti) {
					$tpl->assignLocal('debug', 'NUM_OF_TIMERS', $counti . ' ' . ($counti==1 ? 'timer' : 'timers') . '.');
					$vars = '';
					foreach ($prf->trace as $timer) {
						$vars .= 'timer:`' . $timer['name'] . '`,description:`' . $timer['description'] . '`,elapsed:`' . $timer['elapsed'] . ' secs`;';
					}
					$tpl->assignSource('profile', $vars);
				}
				else {
					$tpl->assignLocal('debug', 'NUM_OF_TIMERS', 'No timer set.');
					$tpl->disableTemplate('profiler_cnt');
				}
				
				// Cache Hits
				if (MARKET_ENABLE_CACHE) {
					$tpl->assignLocal('debug', 'NUM_OF_HITS', $tpl->cache_hits . ' ' . ($tpl->cache_hits==1 ? 'hit' : 'hits') . '.' );
				}
				else {
					$tpl->assignLocal('debug', 'NUM_OF_HITS', 'Disabled');
				}
				
				$tpl->parseTemplate('PAGE.Debug', 'debug');
			}
			else {
				$tpl->assignGlobal('PAGE.Debug', 'Elapsed time: ' . $this->getElapsedTime());
			}
			
			return $tpl->getVariable('global', 'PAGE.Debug');
		}
		
		
	}
	
	

?>