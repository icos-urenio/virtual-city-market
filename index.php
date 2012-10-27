<?php
/**
 * @version     1.0a
 * @package     virtualCityMarket
 * @copyright   Copyright (C) 2012 Logotech S.A.. All rights reserved.
 * @license     GNU Affero General Public License version 3 or later; see LICENSE.txt
 * @author      Dimitrios Mitzias for Logotech S.A.
 */
 
	define('IN_MARKET', true);
	define('MARKET_ROOT_DIR', preg_replace('@\\\@', '/', dirname(__FILE__)));
	define('MARKET_WEB_DIR', preg_replace('@\\\@', '/', substr(MARKET_ROOT_DIR, strlen($_SERVER['DOCUMENT_ROOT']))));
	
	$config = MARKET_ROOT_DIR . '/config.inc.php';
	if (@is_file($config) && @is_readable($config)) {
		require($config);
	}
	else {
		fatalError(
			'Cannot find the global configuration file...',
			__FILE__, __LINE__
		);
	}
	
	require(MARKET_INCLUDE_DIR . '/MARKET.class.php');
	
	$market = new MARKET();
	$market->printPage();
	
	function fatalError($error, $filename = '', $line = '')
	{
		die (
			'<!DOCTYPE html>' .
			'<html>' .
			'    <head>' .
			'        <title>Fatal error</title>' .
			'        <link href="' . MARKET_WEB_DIR . '/bootstrap/css/bootstrap.min.css" rel="stylesheet" type="text/css">' .
			'    </head>' .
			'    <body style="background-color: #888;">' .
			'        <div style="position: relative; top: 40px; left: auto; margin: 0 auto; z-index: 1; max-width: 100%;" class="modal">' .
			'            <div class="modal-header">' .
			'                <h3>Fatal error</h3>' .
			'            </div>' .
			'            <div class="modal-body">' .
							(($filename && $line && DEBUG) ? '<p class="muted pull-right">(in ' . basename($filename) . ' on line ' . $line . ')</p>' : '') .
			'                <p>' . $error . '</p>' . 
			'            </div>' .
			'            <div class="modal-footer">' .
			'                <a class="btn btn-primary" href="">Retry</a>' .
			'            </div>' .
			'        </div>' .
			'    </body>' .
			'</html>'
		);
	}
	
?>