<?php
/**
 * @version     1.0a
 * @package     virtualCityMarket
 * @copyright   Copyright (C) 2012 Logotech S.A.. All rights reserved.
 * @license     GNU Affero General Public License version 3 or later; see LICENSE.txt
 * @author      Dimitrios Mitzias for Logotech S.A.
 */

	require_once('MARKET_Debug.class.php');
	
	
	class MARKET_Profiler extends MARKET_Debug {
		
		var $timers = array();
		var $trace = array();
		
		function MARKET_Profiler()
		{
			// dummy function
		}
		
		
		function startTimer($name, $description = '')
		{
			$counti = count($this->timers[$name]);
			$this->timers[$name][$counti]['name']         = $name;
			$this->timers[$name][$counti]['description']  = $description;
			$this->timers[$name][$counti]['start']        = $this->getCurrentTime();
		}
		
		
		function stopTimer($name)
		{
			if ($this->timers[$name]) {
				$counti = count($this->timers[$name]) - 1;
				$this->timers[$name][$counti]['elapsed'] = $this->getElapsedTime($this->timers[$name][$counti]['start'], 6);
				$this->trace[] = $this->timers[$name][$counti];
				array_pop($this->timers[$name]);
			}
			else {
				$this->raiseError(MARKET_ERROR_WARNING,
					'stopTimer(): Timer "' . $name . '" not started',
					__FILE__, __LINE__
				);
			}
		}
		
		
		function getLastTimer()
		{
			return $this->trace[count($this->trace) - 1]['elapsed'];
		}
		
		
	}
	
	

?>