<?php
	
	// Debug
	//if (preg_match('@127\.0\.0\.1@', $_SERVER['SERVER_ADDR'])) {
		define('DEBUG', false);
		define('DEBUG_EXT', false);
	//}
	
	// Database settings
	define('MARKET_DB_HOST', 'localhost');
	define('MARKET_DB_USER', 'root');
	define('MARKET_DB_PASS', '');
	define('MARKET_DB_DATABASE', 'virtual-city-market');
	// define('MARKET_DB_EXT', 'mysqli');	// Force mysql or mysqli extension. Leave as-is for auto detection
	
	// Language
	define('MARKET_DEFAULT_LANG', 'en');
	define('MARKET_LANG_DIR', MARKET_ROOT_DIR . '/lang');
	// define('MARKET_LANG_AVAILABLE', 'a:1:{i:0;s:2:"en";}'); // Serialized array of languages otherwise MARKET_LANG_DIR is scanned
	
	// Other settings
	define('MARKET_INCLUDE_DIR', MARKET_ROOT_DIR . '/php');
	define('MARKET_TEMPLATE_DIR', MARKET_ROOT_DIR . '/templates');
	
	// Google Maps
	define('GMAP_API_KEY', ''); // Enter your api key. Get one from https://code.google.com/apis/console
	// Change these with your own map center
	define('GMAP_CENTER_LAT', '40.54469');
	define('GMAP_CENTER_LNG', '23.04345');
	define('GMAP_CENTER_ZOOM', '13');

	// Settings with defaults
	// define('MARKET_TIMEZONE', 'Europe/Athens');
	// define('MARKET_SESSION_NAME', 'market_sid');
	
?>