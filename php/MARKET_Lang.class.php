<?php
/**
 * @version     1.0a
 * @package     virtualCityMarket
 * @copyright   Copyright (C) 2012 Logotech S.A.. All rights reserved.
 * @license     GNU Affero General Public License version 3 or later; see LICENSE.txt
 * @author      Dimitrios Mitzias for Logotech S.A.
 */
 
	class MARKET_Lang {
		
		var $lang = '';
		var $languages = array();
		
		var $charset = '';
		var $strs = array();
		
		
		function MARKET_Lang()
		{
			$this->languages = $this->getAvailable();
		}
		
		function translate($str) {
			if (isset($this->strs[$str])) $str = $this->strs[$str];
			return $str;
		}
		
		function getAvailable()
		{
			
			if (defined('MARKET_LANG_AVAILABLE')) return unserialize(MARKET_LANG_AVAILABLE);
			
			$languages = array();
			if ($dirh = @opendir(MARKET_LANG_DIR)) {
				while ($file = readdir($dirh)) {
					if (!preg_match('@^\.@', $file)) {
						$dir = MARKET_LANG_DIR . '/' . $file;
						if (@is_dir($dir) && @is_readable($dir)) {
							$languages[] = $file;
						}
					}
				}
				closedir($dirh);
			}
			else if (defined('MARKET_DEFAULT_LANG') && MARKET_DEFAULT_LANG) {
				$languages[] = MARKET_DEFAULT_LANG;
			}
			return $languages;
			
		}
		
		
		function isLanguage($lang)
		{
			if (in_array($lang, $this->languages)) {
				return true;
			}
			return false;
		}
		
		
		function setLanguage($lang)
		{
			if ($lang && $this->isLanguage($lang)) {
				$this->lang = $lang;
			}
			else if ($_COOKIE['lang'] && $this->isLanguage($_COOKIE['lang'])) {
				$this->lang = $_COOKIE['lang'];
			}
			else if (MARKET_HONOR_USER_LANG && $langs = $this->get_languages('data')) {
				$this->lang = MARKET_DEFAULT_LANG;
				foreach ($langs as $val) {
					if ($this->isLanguage($val[1])) {
						$this->lang = $val[1];
						break;
					}
				}
			}
			else {
				$this->lang = MARKET_DEFAULT_LANG;
			}
			
			if ((!$lang && !$_COOKIE['lang']) || ($_COOKIE['lang'] && $_COOKIE['lang'] != $this->lang)) {
				setcookie('lang', $this->lang, mktime(0, 0, 0, date("m"), date("d"), date("Y") + 1), MARKET_WEB_DIR . '/'); // Expire in one year
			}
			
			// Define MARKET language
			define('MARKET_LANG', $this->lang);
			
			// Define locale
			setlocale(LC_TIME, $this->locale);
		}
		
		
		/**
		 * Load language strings
		 * 
		 *  * - *
		 * 
		 * @param	string	language
		 * @return	string	template source
		 * @access	public
		 */
		function loadStrings($lang, $all)
		{
			// Load default language file
			if ($lang != MARKET_DEFAULT_LANG) {
				// Admin strings
				$fname = $_SERVER['DOCUMENT_ROOT'] . MARKET_RESOURCE_DIR . '/lang/' . MARKET_DEFAULT_LANG . '/Strings.inc.php';
				if (@is_file($fname) && @is_readable($fname)) {
					include_once($fname);
				}
				if ($all) {
					$fname = MARKET_LANG_DIR . '/' . MARKET_DEFAULT_LANG . '/Strings.inc.php';
					if (@is_file($fname) && @is_readable($fname)) {
						include_once($fname);
					}
				}
			}
			// Admin strings
			$fname = $_SERVER['DOCUMENT_ROOT'] . MARKET_RESOURCE_DIR . '/lang/' . $lang . '/Strings.inc.php';
			if (@is_file($fname) && @is_readable($fname)) {
				include_once($fname);
			}
			if ($all) {
				// Load language file
				$fname = MARKET_LANG_DIR . '/' . $lang . '/Strings.inc.php';
				if (@is_file($fname) && @is_readable($fname)) {
					include_once($fname);
				}
			}
		}
		
		
		/**
		 * Get available languages
		 * 
		 *  * - *
		 * 
		 * @return	string	template source
		 * @access	public
		 */
		function getLanguagesSource()
		{
			return $this->getOther();
		}
		
		
		/**
		 * Get other available languages
		 * 
		 *  * - *
		 * 
		 * @param	string	language
		 * @return	string	template source
		 * @access	public
		 */
		function getOther($lang = '')
		{
			$str = '';
			$counti = count($this->languages);
			for ($i = 0; $i < $counti; $i++) {
				if ($this->languages[$i] != $lang) {
					$str .= 'LANG:`' . $this->languages[$i] . '`;';
				}
			}
			return $str;
		}
		
		
		function get_languages($feature, $spare='')
		{
			// get the languages
			$a_languages = $this->a_languages();
			$index = '';
			$complete = '';
			$found = false; // set to default value
			//prepare user language array
			$user_languages = array();

			//check to see if language is set
			if (isset( $_SERVER["HTTP_ACCEPT_LANGUAGE"])) {
				$languages = strtolower($_SERVER["HTTP_ACCEPT_LANGUAGE"]);
				// need to remove spaces from strings to avoid error
				$languages = str_replace(' ', '', $languages);
				$languages = explode(",", $languages);

				foreach ($languages as $language_list) {
					// pull out the language, place languages into array of full and primary
					// string structure:
					$temp_array = array();
					// slice out the part before ; on first step, the part before - on second, place into array
					$temp_array[0] = substr( $language_list, 0, strcspn( $language_list, ';' ) );//full language
					$temp_array[1] = substr( $language_list, 0, 2 );// cut out primary language
					//place this array into main $user_languages language array
					$user_languages[] = $temp_array;
				}

				//start going through each one
				for ( $i = 0; $i < count( $user_languages ); $i++ ) {
					foreach ( $a_languages as $index => $complete ) {
						if ( $index == $user_languages[$i][0] ) {
							// complete language, like english (canada)
							$user_languages[$i][2] = $complete;
							// extract working language, like english
							$user_languages[$i][3] = substr( $complete, 0, strcspn( $complete, ' (' ) );
						}
					}
				}
			}
			else { //if no languages found
				$user_languages[0] = array( '','','','' ); //return blank array.
			}
			if ( $feature == 'data' ) {
				return $user_languages;
			}

			// this is just a sample, replace target language and file names with your own.
			elseif ($feature == 'header') {
			}
		}
		

		function a_languages()
		{
			$a_languages = array(
				'af' => 'Afrikaans',
				'sq' => 'Albanian',
				'ar-dz' => 'Arabic (Algeria)',
				'ar-bh' => 'Arabic (Bahrain)',
				'ar-eg' => 'Arabic (Egypt)',
				'ar-iq' => 'Arabic (Iraq)',
				'ar-jo' => 'Arabic (Jordan)',
				'ar-kw' => 'Arabic (Kuwait)',
				'ar-lb' => 'Arabic (Lebanon)',
				'ar-ly' => 'Arabic (libya)',
				'ar-ma' => 'Arabic (Morocco)',
				'ar-om' => 'Arabic (Oman)',
				'ar-qa' => 'Arabic (Qatar)',
				'ar-sa' => 'Arabic (Saudi Arabia)',
				'ar-sy' => 'Arabic (Syria)',
				'ar-tn' => 'Arabic (Tunisia)',
				'ar-ae' => 'Arabic (U.A.E.)',
				'ar-ye' => 'Arabic (Yemen)',
				'ar' => 'Arabic',
				'hy' => 'Armenian',
				'as' => 'Assamese',
				'az' => 'Azeri',
				'eu' => 'Basque',
				'be' => 'Belarusian',
				'bn' => 'Bengali',
				'bg' => 'Bulgarian',
				'ca' => 'Catalan',
				'zh-cn' => 'Chinese (China)',
				'zh-hk' => 'Chinese (Hong Kong SAR)',
				'zh-mo' => 'Chinese (Macau SAR)',
				'zh-sg' => 'Chinese (Singapore)',
				'zh-tw' => 'Chinese (Taiwan)',
				'zh' => 'Chinese',
				'hr' => 'Croatian',
				'cs' => 'Czech',
				'da' => 'Danish',
				'div' => 'Divehi',
				'nl-be' => 'Dutch (Belgium)',
				'nl' => 'Dutch (Netherlands)',
				'en-au' => 'English (Australia)',
				'en-bz' => 'English (Belize)',
				'en-ca' => 'English (Canada)',
				'en-ie' => 'English (Ireland)',
				'en-jm' => 'English (Jamaica)',
				'en-nz' => 'English (New Zealand)',
				'en-ph' => 'English (Philippines)',
				'en-za' => 'English (South Africa)',
				'en-tt' => 'English (Trinidad)',
				'en-gb' => 'English (United Kingdom)',
				'en-us' => 'English (United States)',
				'en-zw' => 'English (Zimbabwe)',
				'en' => 'English',
				'us' => 'English (United States)',
				'et' => 'Estonian',
				'fo' => 'Faeroese',
				'fa' => 'Farsi',
				'fi' => 'Finnish',
				'fr-be' => 'French (Belgium)',
				'fr-ca' => 'French (Canada)',
				'fr-lu' => 'French (Luxembourg)',
				'fr-mc' => 'French (Monaco)',
				'fr-ch' => 'French (Switzerland)',
				'fr' => 'French (France)',
				'mk' => 'FYRO Macedonian',
				'gd' => 'Gaelic',
				'ka' => 'Georgian',
				'de-at' => 'German (Austria)',
				'de-li' => 'German (Liechtenstein)',
				'de-lu' => 'German (Luxembourg)',
				'de-ch' => 'German (Switzerland)',
				'de' => 'German (Germany)',
				'el' => 'Greek',
				'gu' => 'Gujarati',
				'he' => 'Hebrew',
				'hi' => 'Hindi',
				'hu' => 'Hungarian',
				'is' => 'Icelandic',
				'id' => 'Indonesian',
				'it-ch' => 'Italian (Switzerland)',
				'it' => 'Italian (Italy)',
				'ja' => 'Japanese',
				'kn' => 'Kannada',
				'kk' => 'Kazakh',
				'kok' => 'Konkani',
				'ko' => 'Korean',
				'kz' => 'Kyrgyz',
				'lv' => 'Latvian',
				'lt' => 'Lithuanian',
				'ms' => 'Malay',
				'ml' => 'Malayalam',
				'mt' => 'Maltese',
				'mr' => 'Marathi',
				'mn' => 'Mongolian (Cyrillic)',
				'ne' => 'Nepali (India)',
				'nb-no' => 'Norwegian (Bokmal)',
				'nn-no' => 'Norwegian (Nynorsk)',
				'no' => 'Norwegian (Bokmal)',
				'or' => 'Oriya',
				'pl' => 'Polish',
				'pt-br' => 'Portuguese (Brazil)',
				'pt' => 'Portuguese (Portugal)',
				'pa' => 'Punjabi',
				'rm' => 'Rhaeto-Romanic',
				'ro-md' => 'Romanian (Moldova)',
				'ro' => 'Romanian',
				'ru-md' => 'Russian (Moldova)',
				'ru' => 'Russian',
				'sa' => 'Sanskrit',
				'sr' => 'Serbian',
				'sk' => 'Slovak',
				'ls' => 'Slovenian',
				'sb' => 'Sorbian',
				'es-ar' => 'Spanish (Argentina)',
				'es-bo' => 'Spanish (Bolivia)',
				'es-cl' => 'Spanish (Chile)',
				'es-co' => 'Spanish (Colombia)',
				'es-cr' => 'Spanish (Costa Rica)',
				'es-do' => 'Spanish (Dominican Republic)',
				'es-ec' => 'Spanish (Ecuador)',
				'es-sv' => 'Spanish (El Salvador)',
				'es-gt' => 'Spanish (Guatemala)',
				'es-hn' => 'Spanish (Honduras)',
				'es-mx' => 'Spanish (Mexico)',
				'es-ni' => 'Spanish (Nicaragua)',
				'es-pa' => 'Spanish (Panama)',
				'es-py' => 'Spanish (Paraguay)',
				'es-pe' => 'Spanish (Peru)',
				'es-pr' => 'Spanish (Puerto Rico)',
				'es-us' => 'Spanish (United States)',
				'es-uy' => 'Spanish (Uruguay)',
				'es-ve' => 'Spanish (Venezuela)',
				'es' => 'Spanish (Traditional Sort)',
				'sx' => 'Sutu',
				'sw' => 'Swahili',
				'sv-fi' => 'Swedish (Finland)',
				'sv' => 'Swedish',
				'syr' => 'Syriac',
				'ta' => 'Tamil',
				'tt' => 'Tatar',
				'te' => 'Telugu',
				'th' => 'Thai',
				'ts' => 'Tsonga',
				'tn' => 'Tswana',
				'tr' => 'Turkish',
				'uk' => 'Ukrainian',
				'ur' => 'Urdu',
				'uz' => 'Uzbek',
				'vi' => 'Vietnamese',
				'xh' => 'Xhosa',
				'yi' => 'Yiddish',
				'zu' => 'Zulu'
			);

			return $a_languages;
		}
		
	}
	
	

?>
