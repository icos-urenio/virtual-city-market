<?php
/**
 * @version     1.0a
 * @package     virtualCityMarket
 * @copyright   Copyright (C) 2012 Logotech S.A.. All rights reserved.
 * @license     GNU Affero General Public License version 3 or later; see LICENSE.txt
 * @author      Dimitrios Mitzias for Logotech S.A.
 */
 
	require_once('MARKET_Base.class.php');
	require_once('MARKET_Filter.class.php');
	
	class MARKET_Template extends MARKET_Base
	{
		var $dir = '';
		
		var $vars = array();
		var $templates = array();
		var $filemaps = array();
		
		var $main_template = 'main';
		
		var $is_loaded = array();
		var $is_parsed = array();
		var $is_disabled = array();
		var $last_loaded = '';
		var $last_parsed = '';
		
		var $permissions = 'public';
		
		var $options = array(
			'remove_empty_tags' => true,
			'trim_empty' => false,
			'enable_pages' => true,
			'parse_if_statements' => true,
		);
		
		
		function MARKET_Template()
		{
			if (defined('MARKET_TEMPLATE_DIR')) $this->setDir(MARKET_TEMPLATE_DIR);
			$this->assignGlobalVars();
		}
		
		
		function setDir($dir)
		{
			if (@is_dir($dir) && @is_readable($dir)) {
				$this->dir = $dir;
				$this->filemaps = $this->loadFilemaps();
				return true;
			}
			$this->raiseError(MARKET_ERROR_RETURN,
				__FUNCTION__ . '(): Template directory "' . htmlspecialchars($dir) . '" is not readable or does not exist',
				__FILE__, __LINE__
			);
			return false;
		}
		
		
		function loadFilemaps()
		{	
			$filemaps = array();
			$fname = $this->dir . '/templates.map';
			if (@is_file($fname) && @is_readable($fname)) {
				$lines = @file($fname);
				$counti = count($lines);
				for ($i = 0; $i < $counti; $i++) {
					$lines[$i] = trim($lines[$i]);
					if ($lines[$i]) {
						$parts = explode("\t", $lines[$i], 2);
						$filemaps[$i]['regexp'] = trim($parts[0]);
						$filemaps[$i]['file'] = trim($parts[1]);
					}
				}
			}
			return $filemaps;
		}
		
		
		function assignGlobalVars()
		{
			$req = $this->getRef('Request');
			$lng = $this->getRef('Lang');
			
			$this->assignLocal('sglobal', array(
				'MARKET.Lang' => $lng->lang,
				'PAGE.Title' => 'untitled',
				'MARKET.Server' => $_SERVER['HTTP_HOST'],
				'MARKET.WebDir' => MARKET_WEB_DIR,
				'MARKET.LWebDir' => MARKET_WEB_DIR . '/' . MARKET_LANG,
				'MARKET.Request' => $req->request
			));
			
			// Params
			$this->assignLocal('sglobal', 'MARKET.Params', $req->params);
			
			// Locale strings
			// $this->assignLocal('sglobal', 'LANG', $lng->strs);
		}
		
		
		function loadPage($url)
		{
			global $MARKET_mode;
			
			if ($this->options['enable_pages']) {
				if (preg_match('@^\d+$@', $url)) {
					$sql = "SELECT page_template.name AS template_name, page.id, title, summary, text, is_type, market_user.name, market_user.surname, market_user.user_email, DATE_FORMAT(updated, '%d/%m/%Y %H:%i') AS date FROM page LEFT JOIN page_ml USING (id) LEFT JOIN page_ps USING (id) LEFT JOIN market_user ON market_user.user_id=creator LEFT JOIN page_template ON page_template.id=page_template_id WHERE page.id='" . sqlEscape($url) . "' AND publish='1' AND page_ml.lang='" . MARKET_LANG . "'";
				}
				else {
					$sql = "SELECT page_template.name AS template_name, page.id, title, summary, text, is_type, market_user.name, market_user.surname, market_user.user_email, DATE_FORMAT(updated, '%d/%m/%Y %H:%i') AS date FROM page LEFT JOIN page_ml USING (id) LEFT JOIN page_ps USING (id) LEFT JOIN market_user ON market_user.user_id=creator LEFT JOIN page_template ON page_template.id=page_template_id WHERE url='" . sqlEscape($url) . "' AND publish='1' AND page_ml.lang='" . MARKET_LANG . "'";
				}
				if (sqlQuery($sql, $res)) {
					$row = sqlFetchAssoc($res);
					
					$this->assignGlobal(array(
						'PAGE.Id'		=> $row['id'],
						'PAGE.Summary'	=> $row['summary'],
						'PAGE.Title'	=> $row['title'],
						'PAGE.Text'		=> $row['text'],
						'PAGE.Author'	=> $row['name'] . ' ' . $row['surname'] . ', ' . MARKET_Filter::noSpam($row['email']),
						'PAGE.Mtime'	=> $row['date']
					));
					
					if ($row['is_type'] == 'passthrough') {
						return substr($url, 0, strrpos($url, '.'));
					}
					else if ($row['is_type'] == 'template') {
						$tname = substr($url, 0, strrpos($url, '.'));
						$this->preParseTemplate($tname, explode("\n", $row['text']));
						$this->parseTemplate('PAGE.Text', $tname, MARKET_DO_NOT_APPEND);
					}
					return $row['template_name'];
				}
			}
			return preg_replace('@\.html$@', '', $url);
		}
		
		
		function loadTemplate($tname, $direct = true)
		{
			if (!isset($this->is_loaded[$tname])) {
				if ($fname = $this->getFilename($tname)) {
					$tlines = @file($fname);
					$this->preParseTemplate($tname, $tlines, $direct);
				}
				else {
					// Error has been set by getFilename()
					return false;
				}
			}
			return true;
		}
		
		
		function getFilename($tname)
		{
			$fname = $this->dir . '/' . $tname . '.tpl';
			if (@is_file($fname) && @is_readable($fname)) {
				return $fname;
			}
			else {
				$fname = $this->dir . '/default/' . $tname . '.tpl';
				if (@is_file($fname) && @is_readable($fname)) {
					return $fname;
				}
				else if ($this->filemaps) {
					foreach ($this->filemaps as $val) {
						if (preg_match('@' . $val['regexp'] . '@', $tname . '.tpl', $matches)) {
							$fname = $this->dir . '/' . preg_replace('@' . $val['regexp'] . '@', $val['file'], $tname . '.tpl');
							if (@is_file($fname) && @is_readable($fname)) {
								return $fname;
							}
							else {
								$this->raiseError(MARKET_ERROR_RETURN,
									__FUNCTION__ . '(): Cannot locate template "' . htmlspecialchars($fname) . '" although a file map exists',
									__FILE__, __LINE__
								);
								return false;
							}
						}
					}
				}
			}
			$this->raiseError(MARKET_ERROR_RETURN,
				__FUNCTION__ . '(): Cannot locate template "' . htmlspecialchars($tname) . '" in directory "' . htmlspecialchars($this->dir) . '"',
				__FILE__, __LINE__
			);
			return false;
		}
		
		
		function preParseTemplate($tname, $tlines, $direct = true)
		{
			$eL = array();
			$level = 0;
			
			// Assign PHP Vars
			$this->assignPhpVars(implode('', $tlines));
			
			$counti = count($tlines);
			for ($i = 0; $i < $counti; $i++) {
				if (preg_match('@<(/?template)@', $tlines[$i], $matches)) {
					if ($matches[1] == 'template') {
						$tag = $this->readTag($tlines, $i, $counti);
						$attr = $this->parseAttributes($tag);
						if (!isset($attr['name'])) {
							if ($level == 0) {
								$attr['name'] = $tname;
							}
							else {
								// Random name
								$attr['name'] = md5(uniqid(rand(), true));
							}
						}
						
						if ($level != 0) {
							$eL['children'][] = $attr['name'];
							$eL['text'] .= '{' . strtoupper($attr['name']) . '}' . "\n";
							$this->addTemplate($attr['name'], $attr, $eL['name'], $direct);
						}
						else {
							$this->addTemplate($attr['name'], $attr, '', $direct);
						}
						$eL =& $this->templates[$attr['name']];
						
						// Disabled
						if ($eL['disabled']) $this->is_disabled[$eL['name']] = true;
						
						// Load children templates
						if (isset($eL['include']) && $eL['include'] && preg_match('@(.+)\.tpl$@', $eL['include'], $matches)){
							if (!$this->is_loaded[$matches[1]]) {
								$this->loadTemplate($matches[1], MARKET_INDIRECT_CALL);
								$this->linkTemplates($matches[1], $eL['name']);
								$eL['text'] .= '{' .strtoupper($matches[1]) . '}' . "\n";
							}
						}
						
						// Load parent template
						if (isset($eL['parent']) && $eL['parent']) {
							if (!$this->is_loaded[$eL['parent']]) $this->loadTemplate($eL['parent']);
							$this->linkTemplates($attr['name'], $eL['parent']);
						}
						
						$direct = false;
						$level++;
						
						if (preg_match('@/>$@', $tag)) {
							$eL =& $this->templates[$eL['parent']];
							$level--;
						}
					}
					else {
						$eL =& $this->templates[$eL['parent']];
						$level--;
					}
					
				}
				else if (preg_match('@<php>@', $tlines[$i])) {
					$i++;
					while (!preg_match('@</php>@', $tlines[$i]) && $i < $counti) {
						$tlines[$i] = trim($tlines[$i]);
						if ($tlines[$i]) {
							$eL['script'] .= $tlines[$i] . "\n";
						}
						$i++;
					}
				}
				else {
					$eL['text'] .= rtrim($tlines[$i]) . "\n";
				}
			}
		}
		
		
		function assignPhpVars($ttext)
		{
			if (preg_match_all('@_(SESSION|POST|GET)\.[A-Za-z0-9_\.\[\]]+}@U', $ttext, $matches)) {
				if ($matches[1][0] == 'SESSION' && !session_id()) {
					// Start session
					$this->getRef('Session');
				}
				foreach ($matches[0] as $match) {
					$var = substr($match, 0, -1);
					$parts = explode('.', $var);
					if (($counti = count($parts)) > 1) {
						$val = $parts[0];
						for ($i = 1; $i < $counti; $i++) {
							$val .= "['" . $parts[$i] . "']";
						}
						$expr = '$this->assignGlobal(\'' . $var . '\', $' . $val . ');';
						eval($expr);
						
						$expr = '$this->assignGlobal(\'_SAFE' . $var . '\', htmlspecialchars($' . $val . '));';
						eval($expr);
					}
				}
			}
		}
		
		
		function addTemplate($name, $attr, $parent, $direct)
		{
			$this->templates[$name] = array();
			
			$template =& $this->templates[$name];
			
			$template['name'] = $name;
			$template['parent'] = $parent;
			if (is_array($attr)) {
				foreach ($attr as $key=>$val) {
					switch ($key) {
						case 'global':
							$template['global'] = $this->parseProperties($val);
						break;
						case 'permissions':
							$this->permissions = $val;
						break;
						default:
							$template[$key] = $val;
					}
				}
			}
			$this->is_loaded[$name] = true;
			if ($direct) $this->last_loaded = $name;
		}
		
		
		function linkTemplates($child, $parent)
		{
			$this->templates[$child]['parent'] = $parent;
			if (!@in_array($child, $this->templates[$parent]['children'])) {
				$this->templates[$parent]['children'][] = $child;
			}
		}
		
		
		function parseTemplate($var = '', $tname = '', $append = true)
		{
			global $MARKET_mode;
			
			$tname = $tname ? $tname : $this->last_loaded;
			
			if ($this->is_loaded[$tname]) {
				if (!$this->is_disabled[$tname]) {
					$parsed = '';
					
					// Short name
					$template =& $this->templates[$tname];
					
					if ($template['include'] && preg_match('@\.php$@', $template['include'])) $this->includePhpFile($template['include']);
					
					if ($template['script']) eval($template['script']);
					
					// Parse children
					if (is_array($template['children'])) {
						foreach ($template['children'] as $child) {
							if (!$this->is_parsed[$child]) {
								$this->parseTemplate(strtoupper($child), $child);
							}
						}
					}
					
					if ($template['source']) {
						// Parse the source
						$source = $this->replaceVars('sglobal', $template['source']);
						if ($source) {
							// Source is an SQL query
							if (preg_match("@^SELECT@", $source)) {
								$sql = $source;
								// Navigation
								if ($template['navigation']) {
									list($layout, $start, $show, $limit, $javascript) = $this->arrayTrim(explode(',', $template['navigation'], 5));
									$this->assignNavigationValues($sql, $layout, $start, $show, $limit, $javascript);
								}
								if (sqlQuery($sql, $res)) {
									while ($row = sqlFetchAssoc($res)) {
										foreach ($row as $key=>$val) {
											$this->assignLocal($tname, strtoupper($key), $val);
										}
										// Template has a radio, checkbox or option input. Try to determine whether it has to be checked.
										if ($template['has_input']) {
											$parsed .= $this->checkInput($this->replaceVars($tname, $template['has_input']), $this->replaceVars($tname, $template['text']));
										}
										else {
											$parsed .= rtrim($this->replaceVars($tname, $template['text'])) . $template['divider'] . "\n";
										}
									}
									// Remove divider from end of string
									if ($template['divider']) $parsed = substr($parsed, 0, -(strlen($template['divider']) + 1));
								}
								else {
									// Alternate text
									$parsed .= $this->replaceVars($tname, $template['alt']);
								}
							}
							else {
								$arr = $this->parseSource($source);
								$i = 1;
								foreach ($arr as $val) {
									$this->assignLocal($tname, 'MARKET.aa', $i);
									$this->assignLocal($tname, $val);
									$parsed .= $this->replaceVars($tname, $template['text']) . $template['divider'];
									$i++;
								}
								// Remove divider from end of string
								if ($template['divider']) $parsed = substr($parsed, 0, -(strlen($template['divider']) + 1));
							}
						}
					}
					else {
						// Template has a radio, checkbox or option input. Try to determine whether it has to be checked.
						if ($template['has_input']) {
							$parsed .= $this->checkInput($this->replaceVars($tname, $template['has_input']), $this->replaceVars($tname, $template['text']));
						}
						else {
							$parsed .= $this->replaceVars($tname, $template['text']);
						}
					}
					
					// Global vars
					if ($template['global']) {
						foreach($template['global'] as $key=>$val) {
							$this->assignGlobal($key, $this->replaceVars($tname, $val));
						}
					}
					
					// Assign the parsed template
					if ($template['assign']) {
						$this->assignGlobal($template['assign'], $parsed, $append);
						$this->last_parsed = $template['assign'];
					}
					else {
						if ($var) {
							$this->assignGlobal($var, $parsed, $append);
							$this->last_parsed = $var;
						}
						else {
							$this->assignGlobal(strtoupper($tname), $parsed, $append);
							$this->last_parsed = strtoupper($tname);
						}
					}
					$this->is_parsed[$tname] = true;
					$this->clearLocal($tname);
				}
				else {
					$this->raiseError(MARKET_ERROR_WARNING,
						__FUNCTION__ . '(): Template "' . htmlspecialchars($tname) . '" is disabled',
						__FILE__, __LINE__
					);
				}
			}
			else {
				$this->raiseError(MARKET_ERROR_RETURN,
					__FUNCTION__ . '(): Template "' . htmlspecialchars($tname) . '" is not loaded',
					__FILE__, __LINE__
				);
			}
		}
		
		
		function includePhpFile($fname)
		{
			$fname = $this->dir . '/' . $fname;
			if (@is_file($fname) && @is_readable($fname)) {
				include_once($fname);
			}
			else {
				$this->raiseError(MARKET_ERROR_WARNING,
					__FUNCTION__ . '(): file "' . htmlspecialchars($fname) . '" not found for inclusion',
					__FILE__, __LINE__
				);
			}
		}
		
		
		function lightParseTemplate($var = '', $tname = '', $append = true)
		{
			// Parse the last loaded template if no template name is given
			$tname = $tname ? $tname : $this->last_loaded;
			
			if ($this->is_loaded[$tname]) {
				if (!$this->is_disabled[$tname]) {
					$parsed = $this->replaceVars($tname, $this->templates[$tname]['text']);
					$this->assignGlobal(strtoupper($tname), $parsed, $append);
					$this->last_parsed = strtoupper($tname);
					$this->is_parsed[$tname] = true;
					$this->clearLocal($tname);
				}
				else {
					$this->raiseError(MARKET_ERROR_WARNING,
						__FUNCTION__ . '(): Template "' . htmlspecialchars($tname) . '" is disabled',
						__FILE__, __LINE__
					);
				}
			}
			else {
				$this->raiseError(MARKET_ERROR_RETURN,
					__FUNCTION__ . '(): Template "' . htmlspecialchars($tname) . '" is not loaded',
					__FILE__, __LINE__
				);
			}
		}
		
		
		function checkInput($input, $str)
		{
			// Determine type
			if (preg_match('@<input.*type="([^"]+)@', $str, $matches)) {
				$type = $matches[1];
			}
			else if (preg_match('@<option@', $str)) {
				$type = 'select';
			}
			if ($type) {
				switch ($type) {
					case 'radio':
						if (isset($_POST[$input]) || isset($_GET[$input])) {
							if (isset($_POST[$input])) {
								$str = preg_replace('@<input value="' . $this->pregAddSlashes($_POST[$input]) . '"([^/]*)@', '<input value="' . htmlspecialchars($_POST[$input]) . '"\\1checked="checked" ', $str);
							}
							else if (isset($_GET[$input])) {
								$str = preg_replace('@<input value="' . $this->pregAddSlashes($_GET[$input]) . '"([^/]*)@', '<input value="' . htmlspecialchars($_GET[$input]) . '"\\1checked="checked" ', $str);
							}
						}
					break;
					case 'checkbox':
						if (preg_match('@([a-z_]*)\[\]@', $input, $matches)) {
							// Name is an array
							if ($_POST[$matches[1]] || $_GET[$matches[1]]) {
								if (isset($_POST[$matches[1]])) {
									foreach ($_POST[$matches[1]] AS $key => $val) {
										$str = preg_replace('@<input value="' . $this->pregAddSlashes($val) . '"([^/]*)@', '<input value="' . htmlspecialchars($val) . '"\\1checked="checked" ', $str);
									}
								}
								else if (isset($_GET[$matches[1]])) {
									foreach ($_GET[$matches[1]] AS $key => $val) {
										$str = preg_replace('@<input value="' . $this->pregAddSlashes($val) . '"([^/]*)@', '<input value="' . htmlspecialchars($val) . '"\\1checked="checked" ', $str);
									}
								}
							}
						}
						else {
							if ($_POST[$input] || $_GET[$input]) {
								if (isset($_POST[$input])) {
									$str = preg_replace('@<input value="' . $this->pregAddSlashes($_POST[$input]) . '"([^/]*)@', '<input value="' . htmlspecialchars($_POST[$input]) . '"\\1checked="checked" ', $str);
								}
								else if (isset($_GET[$input])) {
									$str = preg_replace('@<input value="' . $this->pregAddSlashes($_GET[$input]) . '"([^/]*)@', '<input value="' . htmlspecialchars($_GET[$input]) . '"\\1checked="checked" ', $str);
								}
							}
						}
					break;
					case 'select':
						if (preg_match('@([a-z_]+)\[([^\]]*)\]@', $input, $matches)) {
							$input = $matches[1];
							// Name is an array
							if (is_array($_POST[$input]) || is_array($_GET[$input])) {
								if (preg_match_all('@value="([^"]*)@', $str, $matches)) {
									foreach ($matches[0] as $key => $val) {
										$value = $matches[1][$key];
									 	if ((is_array($_POST[$input]) && in_array($value, $_POST[$input])) || (is_array($_GET[$input]) && in_array($value, $_GET[$input]))) {
											$str = preg_replace('@<option value="' . $value . '"([^>]*)@', '<option value="' . $value . '"\\1 selected="selected"', $str);
										}
									}
								}
								// $str = preg_replace('@<option([^>]*)@', '<option\\1selected="selected"', $str);
							}
						}
						else {
							if (preg_match_all('@value="([^"]*)@', $str, $matches)) {
								foreach($matches[0] as $key => $val) {
									$value = $matches[1][$key];
								 	if (($_POST[$input] && $_POST[$input] == $value) || ($_GET[$input] && $_GET[$input] == $value)) {
										$str = preg_replace('@<option value="' . $value . '"([^>]*)@', '<option value="' . $value . '"\\1 selected="selected"', $str);
									}
								}
							}
						}
					break;
				}
			}
			else {
				$this->raiseError(MARKET_ERROR_RETURN,
					'checkInput(): Could not determine type for input "' . $input . '"',
					__FILE__, __LINE__
				);
			}
			return $str;
		}
		
		
		function printTemplate($var = '')
		{
			print $this->getFinalTemplate($var);
		}
		
		
		function getFinalTemplate($var = '')
		{
			// Get the last parsed template if no template name is given
			$var = $var ? $var : $this->last_parsed;
			
			$str = $this->replaceVars('global', $this->vars['global'][$var]);
			$str = $this->replaceVars('sglobal', $str);
			// Translation
			if (preg_match_all('@{LANG\.(.+?)}@', $str, $matches)) {
				$lng = $this->getRef('Lang');
				foreach ($matches[0] as $key => $val) {
					if ($lng->strs[$matches[1][$key]]) {
						$str = preg_replace('@{LANG\.' . $this->pregEscape($matches[1][$key]) . '}@', $lng->strs[$matches[1][$key]], $str);
					}
				}
				$str = preg_replace('@{LANG\.(.+?)}@', "$1", $str);
			}
			$str = $this->removeEmptyTags($str);
			$str = $this->trimEmpty($str);
			$str = $this->parseIfStatements($str);
			
			return $str;
		}
		
		
		function getTemplate($var)
		{
			return $this->vars['global'][$var];
		}
		
		
		function getVariable($tname, $var)
		{
			return $this->vars[$tname][$var];
		}
		
		
		function assignGlobal($var, $val = '', $append = false)
		{
			$this->assignLocal('global', $var, $val, $append);
		}
		
		
		function assignLocal($tname, $var, $val = '', $append = false)
		{
			if (is_array($var)) {
				foreach ($var as $key=>$val) {
					$this->assign($tname, $key, $val, $append);
				}
			}
			else {
				$this->assign($tname, $var, $val, $append);
			}
		}
		
		
		function assign($tname, $var, $vals, $append = false)
		{
			if ($vals && is_array($vals)) {
				foreach ($vals as $key=>$val) {
					$this->assign($tname, $var . '.' . $key, $val, $append);
				}
			}
			else {
				if ($append) {
					$this->vars[$tname][$var] .= $vals;
				}
				else {
					$this->vars[$tname][$var] = $vals;
				}
			}
		}
		
		
		function assignSource($tname, $source)
		{
			$this->templates[$tname]['source'] = $source;
		}
		
		
		function parseSource($source)
		{
			$ret = array();
			$i = 0;
			$lines = $this->explodeString(';', $source);
			if (is_array($lines)) {
				foreach($lines as $line) {
					$pairs = $this->explodeString(',', $line);
					if (is_array($pairs)) {
						foreach($pairs as $pair) {
							list($var, $val) = $this->explodeString(':', $pair, 2);
							// Remove backquotes if any
							$val = preg_replace('@`@', '', $val);
							$ret[$i][strtoupper($var)] = $val;
						}
					}
					$i++;
				}
			}
			
			return $ret;
		}
		
		
		function clearGlobal($var)
		{
			$this->clearLocal('global', $var);
		}
		
		
		function clearLocal($tname, $var = '')
		{
			if ($var && is_array($this->vars[$tname])) {
				foreach ($this->vars[$tname] as $key => $val) {
					if ($key == $var || preg_match('@^' . $var . '\.@', $key)) {
						unset($this->vars[$tname][$key]);
					}
				}
			}
			else unset($this->vars[$tname]);
		}
		
		
		function enableTemplate($tname)
		{
			$this->is_disabled[$tname] = false;
		}
		
		
		function disableTemplate($tname)
		{
			$this->is_disabled[$tname] = true;
		}
		
		
		function replaceVars($tname, $ttext)
		{
			if (!strstr($ttext, '{')) return $ttext;
			
			$str = preg_split('@\{(?=(([A-Za-z0-9\_]+:)?[A-Za-z0-9_\.\,\ \/\:\-\\\'\(\)]+)\})@', $ttext);
			
			$res = '';
			$counti = count($str);
			if ($counti > 1) {
				for ($i = 0; isset($str[$i]); $i++) {
					if ($i == 0) {
						$res .= $str[0];
					}
					else {
						$line = explode('}', $str[$i], 2);
						$key = $line[0];
						if (strstr($key, ':')) {
							list($func, $vars) = explode(':', $key, 2);
							$vars = $this->explodeString(',', $vars);
							$function = '';
							if (function_exists($func)) {
								$function = $func;
							}
							else if (in_array(strtolower($func), $this->arrayLower(get_class_methods('MARKET_Filter')))) {
								$function = 'MARKET_Filter::' . $func;
							}
							if ($function) {
								$expr = '$res .= ' . $function	. '(';
								foreach ($vars AS $key=>$val) {
									if ($key == 0) {
										$foo = (isset($this->vars[$tname][$val])) ? $this->vars[$tname][$val] : ((isset($this->vars['global'][$val])) ? $this->vars['global'][$val] : $this->vars['sglobal'][$val]);
										$expr .= '$foo, ';
									}
									else {
										if (preg_match('@^[A-Z\_]+$@', $val)) {
											$expr .= $val . ', ';
										}
										else {
											$expr .= '"' . addslashes($val) . '", ';
										}
									}
								}
								$expr = substr($expr, 0, -2);
								$expr .= ') . $line[1];';
								eval($expr);
							}
							else {
								$res .= '{' . $key;
								if (count ($line) >	0) {
									$res .= '}';
									$res .= $line[1];
								}
							}
						}
						else if ($key && isset($this->vars[$tname][$key])) {
							$res .= $this->vars[$tname][$key] . $line[1];
						}
						else if ($key && isset($this->vars['global'][$key])) {
							$res .= $this->vars['global'][$key] . $line[1];
						}
						else if ($key && preg_match('@^MARKETConfig\.(.*)$@', $key, $matches) && defined($matches[1])) {
							$res .= constant($matches[1]) . $line[1];
						}
						else {
							$res .= '{' . $key;
							if (count ($line) >	0) {
								$res .= '}';
								$res .= $line[1];
							}
						}
					}
				}
			}
			else {
				$res = $str[0];
			}
			return $res;
		}
		
		
		function removeEmptyTags($str)
		{
			if ($this->options['remove_empty_tags']) {
				$str = preg_replace('@\{(?!__)[A-Za-z0-9_\.\-\/]+\}@', '', $str);
			}
			return $str;
		}
		
		
		function trimEmpty($str)
		{
			if ($this->trim_empty) {
				$lines = explode("\n", $str);
				$counti = count($lines);
				$str = '';
				for ($i = 0; $i < $counti; $i++) {
					$lines[$i] = trim($lines[$i]);
					if ($lines[$i]) {
						$str .= $lines[$i] . "\n";
					}
				}
			}
			return $str;
		}
		
		
		function parseIfStatements($str)
		{
			if ($this->options['parse_if_statements'] && strstr($str, '<if ')) {
				$lines = explode("\n", $str);
				$counti = count($lines);
				$str = '';
				for ($i = 0; $i < $counti; $i++) {
					if (preg_match('@<(if |elif|else)@', $lines[$i], $keyword)) {
						if ($keyword[1] == 'else') {
							$i++;
							$str .= $this->regExpLines($lines, $i, $counti, '@(</else)@');
							$this->regExpLines($lines, $i, $counti, '@(</if)@');
						}
						else {
							$tag = $this->readTag($lines, $i, $counti);
							if (preg_match('@expr="(.+)"@', $tag, $expr)) {
								$i++;
								if (eval('return(' . $expr[1] . ');')) {
									switch ($keyword[1]) {
										case 'if ' :
											$str .= $this->regExpLines($lines, $i, $counti, '@(<elif|<else|</if)@');
										break;
										case 'elif' :
											$str .= $this->regExpLines($lines, $i, $counti, '@(</elif)@');
										break;
									}
									$this->regExpLines($lines, $i, $counti, '@(</if)@');
								}
								else {
									$this->regExpLines($lines, $i, $counti, '@(<elif|<else|</if)@');
								}
							}
						}
					}
					else {
						$str .= $lines[$i] . "\n";
					}
				}
			}
			return $str;
		}
		
		
		function regExpLines($lines, &$i, $counti, $regexp)
		{
			$str = '';
			while (!preg_match($regexp, $lines[$i]) && $i < $counti) {
				$str .= $lines[$i] . "\n";
				$i++;
			}
			if (!preg_match('@</@', $lines[$i])) $i--;
			return $str;
		}
		
		
		function getCountSql(&$sqp)
		{
			if (!is_object($sqp) && preg_match('@^SELECT@', $sqp)) {
				$sql = $sqp;
				$sqp =& $this->getRef('Sql_Parser');
				$sqp->parseSQL($sql);
			}

			if ($sqp->sql['GROUP BY']) {
				if (preg_match('@(.+)AS ' . $sqp->sql['GROUP BY'] . '@', $sqp->sql['SELECT'], $matches)) {
					$sql = "SELECT " . $matches[1] . "AS " . $sqp->sql['GROUP BY'] . " FROM " . $sqp->sql['FROM'];
					if ($sqp->sql['WHERE'] != '1') {
						$sql .= " WHERE " . $sqp->sql['WHERE'];
					}
					$sql .= " GROUP BY " . $sqp->sql['GROUP BY'];
					if ($found = sqlQuery($sql, $res)) {
						$count_sql = 'SELECT ' . $found;
					}
					else {
						$count_sql = 'SELECT 0';
					}
				}
				else {
					if (preg_match('@\,@', $sqp->sql['GROUP BY'])) {
						$parts = explode(',', $sqp->sql['GROUP BY']);
						$count_sql = "SELECT COUNT(DISTINCT ";
						foreach ($parts as $part) {
							$count_sql .= trim($part) . ", ";
						}
						$count_sql = substr($count_sql, 0, -2);
						$count_sql .= ") ";
					}
					else {
						$count_sql = "SELECT COUNT(DISTINCT " . $sqp->sql['GROUP BY'] . ") ";
					}
					$count_sql .= "FROM " . $sqp->sql['FROM'];
					if ($sqp->sql['WHERE'] != '1') {
						$count_sql .= " WHERE " . $sqp->sql['WHERE'];
					}
				}
			}
			else {
				if ($sqp->sql['SELECT DISTINCT']) {
					if (preg_match('@^([^ ]*)@', $sqp->sql['SELECT DISTINCT'], $matches)) {
						$count_sql = "SELECT COUNT(DISTINCT " . $matches[1] . ") FROM " . $sqp->sql['FROM'];
					}
				}
				else {
					$count_sql = "SELECT COUNT(*) FROM " . $sqp->sql['FROM'];
				}
				if ($sqp->sql['WHERE'] != '1') {
					$count_sql .= " WHERE " . $sqp->sql['WHERE'];
				}
			}
			
			// Simple Multilingual Join
			if (preg_match("@SELECT COUNT\(\*\) FROM ([^\ ]+) STRAIGHT_JOIN ([^\ ]+)_ml WHERE 1 AND ([^\ ]+)\.id=([^\ ]+)_ml\.id AND ([^\ ]+)_ml\.lang='([^']+)'$@", $count_sql, $matches)) {
				if ($matches[1] = $matches[2]) {
					$count_sql = "SELECT COUNT(*) FROM " . $matches[2] . "_ml WHERE lang='" . $matches[6] . "'";
				}
			}
			
			// Simple Multilingual Join With Permissions
			if (preg_match("@SELECT COUNT\(\*\) FROM ([^\ ]+) STRAIGHT_JOIN ([^\ ]+)_ml STRAIGHT_JOIN ([^\ ]+)_ps WHERE 1 AND ([^\ ]+)\.id=([^\ ]+)_ps\.id AND ([^\ ]+)_ps\.owner='([^']+)' AND ([^\ ]+)\.id=([^\ ]+)_ml\.id AND ([^\ ]+)_ml\.lang='([^']+)'$@", $count_sql, $matches)) {
				if ($matches[1] = $matches[2]) {
					$count_sql = "SELECT COUNT(*) FROM " . $matches[1] . "_ml STRAIGHT_JOIN " . $matches[1] . "_ps WHERE " . $matches[1] . "_ml.id = " . $matches[1] . "_ps.id AND owner='" . $matches[7] . "' AND lang='" . $matches[11] . "'";
				}
			}
			
			return $count_sql;
		}
		
		
		function assignNavigationValues(&$sql, $layout = 'default', $start = 0, $show = 10, $limit = 0, $javascript = false, $group = false, $absolute = false)
		{
			
			if (preg_match('@\d+@', $_GET['show'])) $show = $_GET['show'];
			if (preg_match('@\d+@', $_GET['page'])) $start = ($_GET['page'] - 1) * $show;
			if (isset($_GET['start']) && preg_match('@\d+@', $_GET['start'])) $start = $_GET['start'];
			if ($limit && $show > $limit) $show = $limit;
			if (!$show) $show = 10;
			
			if ($start < 0) $start = 0;
			
			$start = floor($start/$show) * $show;
			
			if (preg_match('@^SELECT@', $sql)) {

				$sig = md5($sql . $_GET['group']);

				$sqp =& $this->getRef('Sql_Parser');
				$sqp->parseSQL($sql);

				if ($_SESSION['NAV.Vars']['NAV.Sig'] == $sig) {
					$total = $_SESSION['NAV.Vars']['NAV.Total'];
					$stotal = $_SESSION['NAV.Vars']['NAV.STotal'];
					// Group on parent_id
					if ($group && $_GET['group'] && !$_GET['gid'] && !$_GET['expand']) {
						if (strstr($sqp->sql['FROM'], ' ')) {
							$table = substr($sqp->sql['FROM'], 0, strpos($sqp->sql['FROM'], ' '));
						}
						else {
							$table = $sqp->sql['FROM'];
						}
						$sqp->sql['WHERE'] .= " AND " . $table . ".parent_id=''";
						$sql = $sqp->getSQL();
					}
				}
				else {
					$count_sql = $this->getCountSql($sqp);
					if (sqlQuery($count_sql, $res)) {
						$total = sqlResult($res, 0);
						if ($_GET['gid'] && preg_match('@UNION@', $sql)) $total++;
					}
					
					// Group on parent_id
					if ($group && $_GET['group'] && !$_GET['gid'] && !$_GET['expand']) {
						if (strstr($sqp->sql['FROM'], ' ')) {
							$table = substr($sqp->sql['FROM'], 0, strpos($sqp->sql['FROM'], ' '));
						}
						else {
							$table = $sqp->sql['FROM'];
						}
						$sqp->sql['WHERE'] .= " AND " . $table . ".parent_id=''";
						$count_sql = $this->getCountSql($sqp);
						if (sqlQuery($count_sql, $res)) {
							$stotal = $total;
							$total = sqlResult($res, 0);
						}
						$sql = $sqp->getSQL();
					}
				}
				$_SESSION['NAV.Vars']['NAV.Sig']	= $sig;
				$_SESSION['NAV.Vars']['NAV.Total']	= $total;
				$_SESSION['NAV.Vars']['NAV.STotal'] = $stotal;
				
				if ($start > $total ) $start = 0;
				
				// Modify the sql
				$sql .= " LIMIT $start, $show";
			}
			else if (preg_match('@^\d+$@', $sql)) {
				$total = $sql;
			}
			else {
				$this->raiseError(MARKET_ERROR_WARNING,
					'assignNavigationValues(): wrong datatype for first argument',
					__FILE__, __LINE__
				);
				$total = 0;
			}
			
			if ($start > $total ) $start = 0;
			
			// First
			if ($start == 0) $first = -1;
			
			// Previous
			if (($previous = $start - $show) < 0) $previous = 0;
			
			// Next
			if (($next = $start + $show) >= $total) {
				$next = -1;
				$end = $total;
			}
			else {
				$end = $start + $show;
			}
			
			// Last
			if (($last = floor(($total-1) / $show) * $show) <= $start) $last = -1;
			
			$lng =& $this->getRef('Lang');
			
			// Found
			if ($total == 0) {
				$found = '0 ' . $lng->strs['items_total'];
			}
			else if ($total == 1) {
				if ($stotal) {
					if ($stotal == 1) {
						$found = '1 ' . $lng->strs['item_total'] . ' ' . $lng->strs['in'];
					}
					else {
						$found = $stotal . ' ' . $lng->strs['items_total'] . ' ' . $lng->strs['in'];
					}
					$found .= ' 1 ' . $lng->strs['set'];
				}
				else {
					$found = '1 ' . $lng->strs['item_total'];
				}
			}
			else {
				if ($stotal) {
					$found = MARKET_Filter::marketNumber($stotal) . ' ' . $lng->strs['items_total'] . ' ' . $lng->strs['in'] . ' ' . MARKET_Filter::marketNumber($total) . ' ' . $lng->strs['sets'] . ' [' . $lng->strs['sets'] . ' ' . ($start + 1) . ' - ' . $end . ']';
				}
				else {
					if ($show == 1) {
						$found = MARKET_Filter::marketNumber($total) . ' ' . $lng->strs['items_total'] . ' [' . ($start + 1) . ']';
					}
					else {
						$found = MARKET_Filter::marketNumber($total) . ' ' . $lng->strs['items_total'] . ' [' . ($start + 1) . ' - ' . $end . ']';
					}
				}
			}
			
			$req =& $this->getRef('Request');
			
			// Pages
			$num_of_pages = ceil($total / $show);
			if ($num_of_pages) {
				$pagesx = '';
				$page_num = floor($start / $show);
				// Previous
				if ($first == -1 || $start == 0) {
					$pages = '<span class="disabled prev_page">' . $lng->strs['Previous'] . '</span><span class="gap"> &nbsp;</span> ';
					$this->assignGlobal('PAGESX.Previous', '<span class="disabled prev_page">&laquo; ' . substr($lng->strs['Previous'], 4) . '</span> ');
				}
				else {
					$href = ($javascript) ? "javascript:rIU('start', '" . $previous . "')" : (($absolute) ? '{MARKET.WebDir}/' : '') . $req->replaceInUrl('start', $previous);
					$pages = '<a class="previous_page" href="' . $href . '">' . $lng->strs['Previous'] . '</a><span class="gap"> &nbsp;</span> ';
					$this->assignGlobal('PAGESX.Previous', '<a class="previous_page" href="' . $href . '">&laquo; ' . substr($lng->strs['Previous'], 4) . '</a> ');
				}
				if ($page_num < 4) {
					$start_from = 1;
					$up_to = ($page_num == 3) ? 6 : 5;
				}
				else {
					// First
					$href = ($javascript) ? "javascript:rIU('start', '0')" : (($absolute) ? '{MARKET.WebDir}/' : '') . $req->replaceInUrl('start', 0);
					if ($num_of_pages != 5) {
						$pages .= '<a class="first_page" href="' . $href . '">1<span class="ellipsis">...</span></a> ';
						$pagesx .= '<a href="' . $href . '">1</a> <span class="gap">…</span> ';
					}
					if ($page_num > $num_of_pages - 5) {
						$start_from = ($page_num == $num_of_pages - 4) ? $num_of_pages - 5 : $num_of_pages - 4 ;
						$up_to = $num_of_pages;
					}
					else {
						$start_from = $page_num - 1;
						$up_to = $page_num + 3;
					}
				}
				for ($i = $start_from; $i <= $up_to; $i++) {
					if ($i <= $num_of_pages ) {
						if ($i == $page_num + 1) {
							$pages .= '<span class="current_page">[' . $i . ']</span> ';
							$pagesx .= '<span class="current">' . $i . '</span> ';
						}
						else {
							$href = ($javascript) ? "javascript:rIU('start', '" . (($i - 1) * $show) . "')" : (($absolute) ? '{MARKET.WebDir}/' : '') . $req->replaceInUrl('start', ($i - 1) * $show );
							$pages .= '<a class="some_page" href="' . $href . '">' . $i . '</a> ';
							$pagesx .= '<a href="' . $href . '">' . $i . '</a> ';
						}
					}
				}
				
				// Last
				if ($up_to < $num_of_pages - 1) {
					$href = ($javascript) ? "javascript:rIU('start', '" . (($num_of_pages - 1) * $show) . "')" : (($absolute) ? '{MARKET.WebDir}/' : '') . $req->replaceInUrl('start', ($num_of_pages - 1) * $show);
					$pages .= '<a class="last_page" href="' . $href . '"><span class="ellipsis">...</span>' . $num_of_pages . '</a> ';
					$pagesx .= '<span class="gap">…</span> <a href="' . $href . '">' . $num_of_pages . '</a> ';
				}
				
				$this->assignGlobal('PAGESX.Pages', $pagesx);
				
				// Next
				if ($last == -1) {
					$pages .= '<span class="gap">&nbsp; </span><span class="disabled next_page">' . $lng->strs['Next'] . '</span>';
					$this->assignGlobal('PAGESX.Next', '<span class="disabled next_page">' . substr($lng->strs['Next'], 0, -4) . ' &raquo;</span> ');
				}
				else {
					$href = ($javascript) ? "javascript:rIU('start', '" . $next . "')" : (($absolute) ? '{MARKET.WebDir}/' : '') . $req->replaceInUrl('start', $next);
					$pages .= '<span class="gap">&nbsp; </span><a class="next_page" href="' . $href . '">' . $lng->strs['Next'] . '</a>';
					$this->assignGlobal('PAGESX.Next', '<a class="next_page" href="' . $href . '">' . substr($lng->strs['Next'], 0, -4) . ' &raquo;</a> ');
				}
				
				$this->loadTemplate($layout . '/navigation', MARKET_INDIRECT_CALL);
				$this->parseTemplate('foo', 'pagesx');
			
			}
			
			if ($layout) {
				$rels = '';
				if ($first == -1) {
					$this->assignGlobal(array(
						'NAV.Lnk_First'	=> '<a class="disabled"><i>' . $lng->strs['First'] . '</i></a>',
						'NAV.Lnk_Previous' => '<a class="disabled"><i>' . $lng->strs['Previous'] . '</i></a>'
					));
				}
				else {
					$href1 = ($javascript) ? "javascript:rIU('start', '0');" : (($absolute) ? '{MARKET.WebDir}/' : '') . $req->replaceInUrl('start', 0);
					$href2 = ($javascript) ? "javascript:rIU('start', '" . $previous . "');" : (($absolute) ? '{MARKET.WebDir}/' : '') . $req->replaceInUrl('start', $previous);
					$this->assignGlobal(array(
						'NAV.Lnk_First'	=> '<a href="' . $href1 . '"><i>' . $lng->strs['First'] . '</i></a>',
						'NAV.Lnk_Previous' => '<a href="' . $href2 . '"><i>' . $lng->strs['Previous'] . '</i></a>'
					));
					$rels .= '<link rel="first" href="' . (($absolute) ? '{MARKET.WebDir}/' : '') . $req->replaceInUrl('start', 0) . '" />' . "\n";
					$rels .= '<link rel="previous" href="' . (($absolute) ? '{MARKET.WebDir}/' : '') . $req->replaceInUrl('start', $previous) . '" />' . "\n";
				}
				if ($last == -1) {
					$this->assignGlobal(array(
						'NAV.Lnk_Next' => '<a class="disabled"><i>' . $lng->strs['Next'] . '</i></a>',
						'NAV.Lnk_Last' => '<a class="disabled"><i>' . $lng->strs['Last'] . '</i></a>'
					));
				}
				else {
					$href1 = ($javascript) ? "javascript:rIU('start', '" . $next . "');" : (($absolute) ? '{MARKET.WebDir}/' : '') . $req->replaceInUrl('start', $next);
					$href2 = ($javascript) ? "javascript:rIU('start', '" . $last . "');" : (($absolute) ? '{MARKET.WebDir}/' : '') . $req->replaceInUrl('start', $last);
					$this->assignGlobal(array(
						'NAV.Lnk_Next'	=> '<a href="' . $href1 . '"><i>' . $lng->strs['Next'] . '</i></a>',
						'NAV.Lnk_Last'	=> '<a href="' . $href2 . '"><i>' . $lng->strs['Last'] . '</i></a>'
					));
					$rels .= '<link rel="next" href="' . (($absolute) ? '{MARKET.WebDir}/' : '') . $req->replaceInUrl('start', $next) . '" />' . "\n";
					$rels .= '<link rel="last" href="' . (($absolute) ? '{MARKET.WebDir}/' : '') . $req->replaceInUrl('start', $last) . '" />' . "\n";
				}
				if ($group) {
					if ($_GET['group']) {
						$href = ($javascript) ? "javascript:rIU('group', '0');" : (($absolute) ? '{MARKET.WebDir}/' : '') . $req->replaceInUrl('group', '0');
						$this->assignGlobal('NAV.Group', '<span id="group"><a class="selected" href="' . $href . '"><i>' . $lng->strs['Group'] . '</i></a></span>');
					}
					else if ($_GET['version_history'] || is_object($sqp) && !preg_match('@parent_id@', $sqp->sql['SELECT'])) {
						$this->assignGlobal('NAV.Group', '<span id="group"><a class="disabled"><i>' . $lng->strs['Group'] . '</i></a></span>');
					}
					else {
						$href = ($javascript) ? "javascript:rIU('group', '1');" : (($absolute) ? '{MARKET.WebDir}/' : '') . $req->replaceInUrl('group', '1');
						$this->assignGlobal('NAV.Group', '<span id="group"><a href="' . $href . '"><i>' . $lng->strs['Group'] . '</i></a></span>');
					}
				}
				$this->assignGlobal('PAGE.Rels', $rels);
				$this->loadTemplate($layout . '/navigation', MARKET_INDIRECT_CALL);
				$this->parseTemplate('foo', 'toolbar');
				
			}
			
			$this->assignGlobal(array(
				'NAV.Start'	=> $start + 1,
				'NAV.Page'	=> $page_num + 1,
				'NAV.End'	=> $end,
				'NAV.Found'	=> $found,
				'NAV.Show'	=> $show,
				'NAV.Total'	=> $total,
				'NAV.Previous' => $previous,
				'NAV.Next'	=> $next,
				'NAV.Last'	=> $last,
				'NAV.Pages'	=> $pages
			));
			
			// Next Page
			if ($next != -1) {
				$this->assignGlobal('NAV.NextPage', $page_num + 2);
			}
			else {
				$this->assignGlobal('NAV.NextPage', 1);
			}
			
			return array($start, $show, $total, $end);
		}
		
		
	 }
	 
?>
