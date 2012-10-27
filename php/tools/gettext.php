<?php
	
	define('MARKET_ROOT_DIR', preg_replace('@\\\@', '/', dirname(dirname(dirname(__FILE__)))));
	define('MARKET_WEB_DIR', preg_replace('@\\\@', '/', substr(MARKET_ROOT_DIR, strlen($_SERVER['DOCUMENT_ROOT']))));
	
	$config = MARKET_ROOT_DIR . '/config.inc.php';
	if (@is_file($config) && @is_readable($config)) {
		require($config);
	}
	
	// Load default.pot
	$default = array();
	$lines = file(MARKET_ROOT_DIR . '/lang/default.pot');
	foreach ($lines as $line) {
		if (preg_match('@msgid \"(.+)\"@', $line, $matches)) {
			$default[] = $matches[1];
		}
	}
	
	$files = array_merge(getFiles(MARKET_ROOT_DIR . '/templates'), getFiles(MARKET_ROOT_DIR . '/js'));
	
	$strings = array();
	foreach ($files as $file) {
		if (preg_match_all('@\{LANG.([^\}]+)\}@', implode("\n", file($file)), $matches)) {
			foreach ($matches[0] as $key => $val) {
				if (!in_array($matches[1][$key], $default)) {
					$strings[$matches[1][$key]] = $matches[1][$key];
				}
			}
		}
		if (preg_match_all('@\_\(\'([^\']+)\'\)@', implode("\n", file($file)), $matches)) {
			foreach ($matches[0] as $key => $val) {
				if (!in_array($matches[1][$key], $default)) {
					$strings[$matches[1][$key]] = $matches[1][$key];
				}
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
					$fname = $dir . $file . '/default.po';
					if (@is_file($fname) && @is_readable($fname)) {
						$lines = file($fname);
						$counti = count($lines);
						for ($i = 0; $i < $counti; $i++) {
							if (preg_match('@^msgid "(.+)"$@', $lines[$i], $matches)) {
								$key = $matches[1];
								$i++;
								$val = '';
								if (preg_match('@^msgstr "(.+)"$@', $lines[$i], $matches)) {
									$val = $matches[1];
								}
								if (!$val) $val = $key;
								$php .= '$this->strs[\'' . $key . '\'] = \'' . $val . '\';' . "\n";
								$js .= 'lang[\'' . $key . '\'] = \'' . $val . '\';' . "\n";
							}
						}
					}
					$fname = $dir . $file . '/application.po';
					if (@is_file($fname) && @is_readable($fname)) {
						$lines = file($fname);
						$counti = count($lines);
						for ($i = 0; $i < $counti; $i++) {
							if (preg_match('@^msgid "(.+)"$@', $lines[$i], $matches)) {
								$key = $matches[1];
								$i++;
								$val = '';
								if (preg_match('@^msgstr "(.+)"$@', $lines[$i], $matches)) {
									$val = $matches[1];
								}
								if (!$val) $val = $key;
								$php .= '$this->strs[\'' . $key . '\'] = \'' . $val . '\';' . "\n";
								$js .= 'lang[\'' . $key . '\'] = \'' . $val . '\';' . "\n";
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
?>