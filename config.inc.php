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
	
	// Mail
	define('SUPPORT_EMAIL', 'support@localhost'); // Used in email templates
	define('MARKET_SMTP_HOST', 'localhost'); // Outgoing server
	define('MARKET_SMTP_FROM', 'noreply@localhost'); // Return path
	define('MARKET_SMTP_FROM_NAME', 'Virtual city market');
	//define('MARKET_SMTP_USER', '');
	//define('MARKET_SMTP_PASS', '');
	
	// Google Analytics
	define('ANALYTICS_TRACKING_CODE', ''); // Enter your Google Analytics tracking code (UA-XXXXXXXX-X)
	
	// Google Maps
	define('GMAP_API_KEY', ''); // Enter your api key. Get one from https://code.google.com/apis/console
	// Change these with your own map center
	define('GMAP_CENTER_LAT', '40.54469');
	define('GMAP_CENTER_LNG', '23.04345');
	define('GMAP_CENTER_ZOOM', '13');
	
	// Google Fusion Table Layer
	define('FUSION_TABLE_LAYER', ''); // Enter the tableId of a public shared google fusion table. Read the tutorial at https://support.google.com/fusiontables/answer/2527132
	
	// reCAPTCHA (Get your keys from https://www.google.com/recaptcha/admin/create)
	define('RECAPTCHA_PRIVATE_KEY', ''); // Enter your reCAPTCHA private key.
	define('RECAPTCHA_PUBLIC_KEY', '');  // Enter your reCAPTCHA public key.
	
	// Settings with defaults
	//define('MARKET_TIMEZONE', 'Europe/Athens');
	//define('MARKET_SESSION_NAME', 'market_sid');
	
	// More settings
	define('MARKET_CITIES_MENU', true);
	
?>
