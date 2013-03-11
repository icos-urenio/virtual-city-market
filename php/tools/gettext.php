<?php
	
	define('MARKET_ROOT_DIR', preg_replace('@\\\@', '/', dirname(dirname(dirname(__FILE__)))));
	define('MARKET_WEB_DIR', preg_replace('@\\\@', '/', substr(MARKET_ROOT_DIR, strlen($_SERVER['DOCUMENT_ROOT']))));
	
	$config = MARKET_ROOT_DIR . '/config.inc.php';
	if (@is_file($config) && @is_readable($config)) {
		require($config);
	}
	
	/* ----- STEP 1 ----- */
	
	// Find all application strings and create the application.pot
	$strings = array();
	$files = array_merge(getFiles(MARKET_ROOT_DIR . '/templates'), getFiles(MARKET_ROOT_DIR . '/js'));
	foreach ($files as $file) {
		$contents = implode('', file($file));
		// Templates and PHP
		if (preg_match_all('@\{LANG.([^\}]+)\}@', $contents, $matches)) {
			foreach ($matches[0] as $key => $val) {
				$strings[$matches[1][$key]] = $matches[1][$key];
			}
		}
		// Javascript and PHP
		if (preg_match_all('@\_\(\'([^\']+)\'\)@', $contents, $matches)) {
			foreach ($matches[0] as $key => $val) {
				$strings[$matches[1][$key]] = $matches[1][$key];
			}
		}
	}
	asort($strings);
	
	$str = '';
	foreach ($strings as $string) {
		$str .= 'msgid "' . preg_replace('@\\"@', '\\"', $string) . '"' . "\n";
		$str .= 'msgstr ""' . "\n\n";
	}
	
	if ($fp = fopen(MARKET_ROOT_DIR . '/lang/application.pot', 'w')) {
		fwrite($fp, $str);
		fclose($fp);
	}
	
	/* ----- STEP 2 ----- */
	
	// Read the application.po and create the Strings.inc.php and Strings.inc.js files
	// Do it for each directory found in lang directory
	$exclude_array = explode('|', '.|..');
	$dir = MARKET_ROOT_DIR . '/lang/';
	if ($dirh = opendir($dir)) {
		while (false !== ($file = readdir($dirh))) {
			if (!in_array($file, $exclude_array)) {
				if (is_dir($dir . $file . '/')) {
					$php = '<?php' . "\n";
					$php .= '// DO NOT EDIT' . "\n";
					$js = '// DO NOT EDIT' . "\n";
					$js .= 'lang = new Array()' . "\n";
					$fname = $dir . $file . '/application.po';
					if (@is_file($fname) && @is_readable($fname)) {
						$contents = implode('', file($fname));
						if ($counti = preg_match_all('@msgid\s+((?:".*(?<!\\\\)"\s*)+)\s+msgstr\s+((?:".*(?<!\\\\)"\s*)+)@', $contents, $matches)) {
							for ($i = 0; $i < $counti; $i++) {
								list ($key, $val) = sanitize($matches[1][$i], $matches[2][$i]);
								if ($key) { // Skip meta
									if (!$val) $val = $key; // Default string
									$php .= '$this->strs[\'' . $key . '\'] = \'' . $val . '\';' . "\n";
									$js .= 'lang[\'' . $key . '\'] = \'' . $val . '\';' . "\n";
								}
							}
						}
					}
					$php .= '?>';
					if ($fp = fopen($dir . $file . '/Strings.inc.php', 'w')) {
						fwrite($fp, $php);
						fclose($fp);
					}
					if ($fp = fopen($dir . $file . '/Strings.inc.js', 'w')) {
						fwrite($fp, $js);
						fclose($fp);
					}
				}
			}
		}
	}
	
	/* ----- DONE ----- */
	
	function getFiles($dir, $exclude = ".|..", $recursive = true) {
		$dir = rtrim($dir, '/') . '/';
		if ($dirh = opendir($dir)) {
			$exclude_array = explode('|', $exclude);
			$result = array();
			while (false !== ($file = readdir($dirh))) {
				if (!in_array($file, $exclude_array)) {
					if (is_dir($dir . $file . '/')) {
						if ($recursive) $result = array_merge($result, getFiles($dir . $file . '/', $exclude, $recursive));
					} else {
						$result[] = $dir . $file;
					}
				}
			}
			closedir($dirh);
		}
		return $result;
	}
	
	function sanitize($key, $val) {
		$key = substr(trim(preg_replace('@"\n"@', '', $key)), 1, -1);
		$key = preg_replace('@\\\"@', '"', $key);
		$val = substr(trim(preg_replace('@"\n"@', '', $val)), 1, -1);
		$val = preg_replace('@\\\"@', '"', $val);
		return array($key, $val);
	}
	
?>