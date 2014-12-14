<template parent="main" assign="PAGE.Body" global="PAGE.Title: `{LANG.Administration}`" permissions="admin">
	
	<php>
		
		if (defined('IN_MARKET')) {
			
			$req =& $this->getRef('Request');
			
			if ($req->params[1] == 'preview' && $_GET['url']) {
				if (preg_match('@\?@', $_GET['url'])) {
					$req->redirectTo(MARKET_WEB_DIR . '/' . $_GET['url'] . '&action=preview');
				}
				else {
					$req->redirectTo(MARKET_WEB_DIR . '/' . $_GET['url'] . '?action=preview');
				}
			}
			
			if ($_GET['action']) {
				switch ($_GET['action']) {
					case 'download_list':
						$sql = "SELECT lat, lng FROM directory WHERE lat <> 0 AND lng <> 0";
						if (sqlQuery($sql, $res)) {
							$str = 'Location' . "\n";
							while ($row = sqlFetchAssoc($res)) {
								$str .= $row['lat'] . ',' . $row['lng'] . "\n";
							}
							$str = trim($str);
							$this->contentType('text/csv', 'directory_coords_'. date('Y-m-d') . '.csv', strlen($str));
							print $str;
						}
					break;
					case 'getPIN':
						$i = 0;
						$pin = 0;
						while ($i < 10) { // Try at most 10 times to create a unique code
							$pin = rand(1, 9999);
							$sql = "SELECT * FROM directory WHERE pin='" . sqlEscape($pin) . "'";
							if (!sqlQuery($sql, $res)) {
								break; // Pin OK
							}
							$i++;
						}
						print sprintf('%04d', $pin);
					break;
				}
				exit;
			}
			
			// Valid paths
			$valid_pages = array('index', 'users', 'directory', 'marketplace', 'offers', 'reviews', 'html_pages');
			if (!in_array($req->params[1], $valid_pages)) {
				$req->httpError(404); // Not found
			}
			
			// Valid actions
			$valid_actions = array('index', 'search', 'edit', 'publish', 'unpublish', 'delete');
			
			// Valid tabs
			$valid_tabs = array(
				'index' 		=> array('', 'settings', 'log'),
				'users' 		=> array('index', 'roles', 'sessions'),
				'directory' 	=> array('index', 'cities', 'categories', 'subcategories', 'tools' => array('import', 'export', 'generate_pins', 'geocode')),
				'marketplace'	=> array('index', 'store_pages'),
				'offers' 		=> array('index'),
				'reviews' 		=> array('index'),
				'html_pages'	=> array('index', 'templates')
			);
			
			$count_params = count($req->params) - 1;
			switch ($count_params) {
				case 1:
					if ($req->params[1] != 'index') $req->httpError(404);
				break;
				case 2:
					if (in_array($req->params[$count_params], $valid_actions)) {
						if (!is_array($valid_tabs[$req->params[1]])) $req->httpError(404);
					}
					else {
						$req->httpError(404);
					}
				break;
				case 3:
					if (in_array($req->params[$count_params], $valid_actions)) {
						if (is_array($valid_tabs[$req->params[1]])) {
							if (!in_array($req->params[2], $valid_tabs[$req->params[1]])) $req->httpError(404);
						}
						else {
							$req->httpError(404);
						}
					}
					else {
						if (is_array($valid_tabs[$req->params[1]][$req->params[2]])) {
							if (!in_array($req->params[3], $valid_tabs[$req->params[1]][$req->params[2]])) $req->httpError(404);
						}
						else {
							$req->httpError(404);
						}
					}
				break;
				default:
					$req->httpError(404);
			}
			
			$tables = array (
				'log'			=> array('log'),
				'users'			=> array('market_user'),
				'roles'			=> array('market_role'),
				'sessions'		=> array('market_session'),
				'directory' 	=> array('directory', 'directory_ml', 'directory_ps'),
				'cities' 		=> array('directory', 'directory_ml', 'directory_ps'),
				'categories'	=> array('directory', 'directory_ml', 'directory_ps'),
				'subcategories'	=> array('directory', 'directory_ml', 'directory_ps'),
				'tools'		 	=> array('directory', 'directory_ml', 'directory_ps'),
				'marketplace' 	=> array('store_data', 'store_data_ps'),
				'store_pages' 	=> array('store_data', 'store_data_ps'),
				'store_files' 	=> array('store_data', 'store_data_ps'),
				'offers'	 	=> array('store_data', 'store_data_ps'),
				'offer_files'	=> array('store_data', 'store_data_ps'),
				'reviews'		=> array('store_data', 'store_data_ps'),
				'html_pages'	=> array('page', 'page_ml', 'page_ps'),
				'templates'		=> array('page_template')
			);
			
			$tables = $tables[$req->params[$count_params - 1]];
			
			$all_fields = array();
			if ($tables) {
				switch (count($tables)) {
					case 1:
						$sqls[] = "SHOW FIELDS FROM `" . $tables[0] . "`";
					break;
					case 2:
						$sqls[] = "SHOW FIELDS FROM `" . $tables[0] . "`";
						$sqls[] = "SHOW FIELDS FROM `" . $tables[1] . "`";
					break;
					case 3:
						$sqls[] = "SHOW FIELDS FROM `" . $tables[0] . "`";
						$sqls[] = "SHOW FIELDS FROM `" . $tables[1] . "`";
						$sqls[] = "SHOW FIELDS FROM `" . $tables[2] . "`";
					break;
				}
				foreach ($sqls as $key => $sql) {
					if (sqlQuery($sql, $res)) {
						while ($row = sqlFetchAssoc($res)) {
							if (!$all_fields[$row['Field']]) {
								$all_fields[$row['Field']] = $row;
								$all_fields[$row['Field']]['Table'] = $tables[$key];
							}
						}
					}
				}
			}
			
			// Menu hilights
			$this->assignGlobal('CURRENT.account', 'active');
			$this->assignGlobal('CURRENT.admin_' . $req->params[1], 'active');
			
			// Page title
			if ($req->params[1] != 'index') {
				// {LANG.Users administration}
				// {LANG.Directory administration}
				// {LANG.Marketplace administration}
				// {LANG.Offers administration}
				// {LANG.Reviews administration}
				// {LANG.Html pages administration}
				$this->assignGlobal('PAGE.Title', __(ucfirst(preg_replace('@_@', ' ', $req->params[1])) . ' administration'));
			}
			
			// Form name
			$form_name = __(preg_replace('@_@', ' ', preg_replace('@^market_@', '', $tables[0])));
			
			// No edit flag
			$no_edit = false;
			
			// Disable actions in popups
			if ($_GET['popup']) {
				$no_edit = true;
				$this->disableTemplate('new_record');
			}
			
			// Search
			$where = ''; $filters = '';
			if ($req->params[$count_params] == 'search') {
				$req->params[$count_params] = 'index';
				foreach ($_GET as $var => $val) {
					if ($var == 'q') {
						// Search
						$srh =& $this->getRef('Search');
						$search_in = ''; $search_as = '';
						foreach ($all_fields as $field) {
							$search_in .= $field['Table'] . '.' . $field['Field'] . ',';
							$search_as .= 'both,';
						}
						$search_in = substr($search_in, 0, -1);
						$search_as = substr($search_as, 0, -1);
						$cmd = "SEARCH IN " . $search_in . " OF foo WHERE 1 RETURN bar";
						$sql = $srh->searchFor('"' . trim($_GET['q']) . '"', $cmd, $search_as);
						if (preg_match('@\(\((.+)\)\)@', $sql, $matches)) {
							$where = " AND ((" . $matches[1] . "))";
						}
					}
					else {
						// Filter
						$filters .= '<div class="filter"><span class="label label-info">' . htmlspecialchars($var) . ':</span> ' .  htmlspecialchars($val) . '</div>';
						if (preg_match('@\,@', $var)) {
							$parts = explode(',', $var, 2);
							$var = '';
							foreach ($parts as $part) {
								$var .= '`' . $part . '`.';
							}
							$var = substr($var, 0, -1);
						}
						else {
							$var = '`' . $var . '`';
						}
						$where .= " AND " . sqlEscape($var) . " = '" . sqlEscape($val) . "'";
					}
				}
				if ($filters) $this->assignGlobal('FILTERS', $filters);
			}
			else {
				// Actions (Edit, Create, Publish/Unpublish, Delete)
				if ($tables) {
					switch ($req->params[$count_params]) {
						case 'edit':
							$this->enableTemplate('edit-form');
							$req->params[$count_params] = 'index';
							
							// Form action
							if ($_GET['id']) {
								// {LANG.Edit user}
								// {LANG.Edit role}
								// {LANG.Edit session}
								// {LANG.Edit directory}
								// {LANG.Edit store data}
								// {LANG.Edit page}
								// {LANG.Edit page template}
								$this->assignGlobal('FORM_ACTION', __('Edit ' . $form_name));
							}
							else {
								// {LANG.Create user}
								// {LANG.Create role}
								// {LANG.Create directory}
								// {LANG.Create store data}
								// {LANG.Create page}
								// {LANG.Create page template}
								$this->assignGlobal('FORM_ACTION', __('Create ' . $form_name));
							}
							
							$fields = array(
								'users' => array(
									'user_id' => array('Label' => 'ID'),
									'market_role_id' => array('Required' => true, 'Label' => __('Role'), 'Type' => 'select', 'Options' => 'SELECT id, title FROM market_role'),
									'name' => array('Suggested' => true),
									'surname' => array('Suggested' => true),
									'user_email' => array('Unique' => true, 'Required' => true, 'Label' => __('Email')),
									'user_password' => array('Type' => 'password', 'Label' => __('Password'), 'Properties' => ' autocomplete="off"', 'Value' => '', 'Help' => __('Leave the password blank if you do not wish to change it')),
									'store' => array('Label' => __('Directory ID'), 'Type' => 'popup', 'Action' => 'directory/index.html'),
									'user_active' => array('Label' => __('User active'))
								),
								'sessions' => array(
									'id',
									'session_id' => array('Label' => __('Session ID')),
									'expires' => array('Label' => __('Expires')),
									'data' => array('Label' => __('Data'), 'Help' => __('Note') . ': ' . __('You cannot edit your current session.'))
								),
								'directory' => array(
									'id',
									'pin' => array('Unique' => true, 'Label' => __('PIN code')),
									'path' => array('Unique' => true, 'Label' => __('Marketplace url'), 'Class' => 'typeahead span3', 'Properties' => ' data-path="directory.path"', 'Help' => __('The resulting url will be') . ': <span class="blue">/marketplace/your_value/index.html</span>. <br>' . __('The url may contain english characters (a-z), numbers (0-9) and the underscore (_).')),
									'category' => array('Suggested' => true, 'Type' => 'varchar', 'Class' => 'typeahead span3', 'Properties' => ' data-path="directory_ml.category"'),
									'prof1' => array('Group' => __('Subcategories'), 'Label' => __('Subcategory') . ' 1', 'Class' => 'typeahead span3', 'Properties' => ' data-path="directory_ml.prof"'),
									'prof2' => array('Group' => __('Subcategories'), 'Label' => __('Subcategory') . ' 2', 'Class' => 'typeahead span3', 'Properties' => ' data-path="directory_ml.prof"'),
									'prof3' => array('Group' => __('Subcategories'), 'Label' => __('Subcategory') . ' 3', 'Class' => 'typeahead span3', 'Properties' => ' data-path="directory_ml.prof"', 'Help' => '<b>' . __('Hint') . ':</b> ' . __('First select a category')),
									'name' => array('Type' => 'varchar', 'Label' => __('Owner name')),
									'business_name' => array('Suggested' => true, 'Type' => 'varchar'),
									'byline' => array('Type' => 'varchar'),
									'address' => array('Suggested' => true),
									'city' => array('Suggested' => true, 'Type' => 'varchar', 'Class' => 'typeahead span3', 'Properties' => ' data-path="directory_ml.city"'),
									'phone' => array('Suggested' => true, 'Type' => 'varchar'),
									'email' => array('Type' => 'varchar'),
									'url' => array('Type' => 'varchar'),
									'lat' => array('Suggested' => true, 'Group' => __('Location'), 'Label' => __('Latitude')),
									'lng' => array('Suggested' => true, 'Group' => __('Location'), 'Label' => __('Longitude')),
									'facebook' => array('Group' => __('Social media')),
									'twitter' => array('Group' => __('Social media')),
									'google' => array('Group' => __('Social media'), 'Label' => 'Google plus'),
									'youtube' => array('Group' => __('Social media'), 'Label' => 'YouTube')
								),
								'cities' => array(
									'city' => array('Class' => 'typeahead span3', 'Properties' => ' data-path="directory_ml.city"', 'Help' => __('Attention! You may be altering multiple directory records.'))
								),
								'categories' => array(
									'category' => array('Class' => 'typeahead span3', 'Properties' => ' data-path="directory_ml.category"', 'Help' => __('Attention! You may be altering multiple directory records.'))
								),
								'subcategories' => array(
									'prof1' => array('Label' => __('Subcategory'), 'Class' => 'typeahead span3', 'Properties' => ' data-path="directory_ml.prof"', 'Help' => __('Attention! You may be altering multiple directory records.'))
								),
								'offers' => array(
									'id',
									'directory_id' => array('Required' => true, 'Label' => __('Directory ID'), 'Type' => 'popup', 'Action' => 'directory/index.html'),
									'name' => array('Properties' => ' readonly="readonly"'),
									'title' => array('Required' => true),
									'data' => array('Required' => true, 'Label' => __('Description')),
									'price',
									'discount' => array('Required' => true),
									'date_from' => array('Label' => __('Date from')),
									'date_to' => array('Required' => true, 'Label' => __('Date to'))
								),
								'reviews' => array(
									'id',
									'directory_id' => array('Required' => true, 'Label' => __('Directory ID'), 'Type' => 'popup', 'Action' => 'directory/index.html'),
									'data' => array('Required' => true, 'Label' => __('Comment')),
									'updated' => array('Required' => true, 'Label' => __('Updated'))
								),
								'html_pages' => array(
									'id',
									'page_template_id' => array('Label' => __('Template ID'), 'Type' => 'popup', 'Action' => 'html_pages/templates/index.html'),
									'url' => array('Unique' => true, 'Required' => true, 'Label' => __('Url'), 'Class' => 'typeahead span3', 'Properties' => ' data-path="page.url"'),
									'title' => array('Suggested' => true, 'Type' => 'varchar'),
									'text' => array('Suggested' => true, 'is_HTML' => true, 'Label' => __('Text')),
									'is_type' => array('Required' => true, 'Label' => __('Type'))
								)
							);
							if ($fields[$req->params[$count_params - 1]]) {
								$fields = $fields[$req->params[$count_params - 1]];
							}
							else {
								$fields = $all_fields;
							}
							foreach ($fields as $key => $field) {
								if (is_array($field)) {
									$fields[$key] = array_merge($all_fields[$key], $field);
								}
								else {
									$fields[$key] = $all_fields[$field];
								}
							}
							
							// Password is required when creating a new user
							if ($req->params[$count_params - 1] == 'users' && !$_GET['id']) {
								$fields['user_password']['Required'] = true;
								unset($fields['user_password']['Help']);
							}
							
							// Load values
							$values = array();
							if ($_GET['id']) {
								switch (count($tables)) {
									case 1:
										if ($tables[0] == 'market_user') {
											$sql = "SELECT * FROM `" . $tables[0] . "` WHERE `" . $tables[0] . "`.user_id='" . sqlEscape($_GET['id']) . "'";
										}
										else {
											$sql = "SELECT * FROM `" . $tables[0] . "` WHERE `" . $tables[0] . "`.id='" . sqlEscape($_GET['id']) . "'";
										}
									break;
									case 2:
										// Store data (Offers, Reviews)
										$sql = "SELECT * FROM store_data STRAIGHT_JOIN store_data_ps WHERE store_data.id=store_data_ps.id AND lang='" . MARKET_LANG . "' AND store_data.id='" . sqlEscape($_GET['id']) . "'";
									break;
									case 3:
										switch ($req->params[$count_params - 1]) {
											case 'cities':
												$sql = "SELECT '" . sqlEscape($_GET['id']) . "' as city";
											break;
											case 'categories':
												$sql = "SELECT '" . sqlEscape($_GET['id']) . "' as category";
											break;
											case 'subcategories':
												$sql = "SELECT '" . sqlEscape($_GET['id']) . "' as prof1";
											break;
											default:
												$sql = "SELECT * FROM `" . $tables[0] . "` STRAIGHT_JOIN `" . $tables[1] . "` WHERE `" . $tables[0] . "`.id=`" . $tables[1] . "`.id AND lang='" . MARKET_LANG . "' AND `" . $tables[0] . "`.id='" . sqlEscape($_GET['id']) . "'";
										}
									break;
								}
								if (sqlQuery($sql, $res)) {
									$values = sqlFetchAssoc($res);
								}
							}
							
							// Save values
							if ($_POST && count($_POST)) {
								
								$errors = '';
								// Check required and unique fields
								foreach($fields as $field) {
									if ($field['Required'] && !$_POST[$field['Field']]) {
										$errors .= '<li>"' . $field['Label'] . '" ' . __("is required") . '.</li>';
									}
									if ($field['Unique'] && $_POST[$field['Field']]) {
										$sql = "SELECT * FROM `" . sqlEscape($field['Table']) . "` WHERE `" . sqlEscape($field['Field']) . "`='" . sqlEscape($_POST[$field['Field']]) . "'";
										if ($_POST['id']) {
											$sql .= " AND `" . sqlEscape($field['Table']) . "`.id<>'" . sqlEscape($_POST['id']) . "'";
										}
										if (sqlQuery($sql, $res)) {
											$errors .= '<li>"' . $field['Label'] . '" ' . __("already exists") . '.</li>';
										}
									}
								}
								
								// Special checks
								switch ($req->params[$count_params - 1]) {
									case 'directory':
										if (!($_POST['name'] || $_POST['business_name'])) {
											$errors .= '<li>' . __("Owner or business name is required.") . '</li>';
										}
									break;
								}
								
								if ($errors) {
									$values = array_merge($values, $_POST);
									$this->assignGlobal('EDIT_MESSAGE', '<div class="alert alert-error"><ul style="margin-bottom: 0;">' . $errors . '</ul></div>');
								}
								else {
									$sql_fields = array();
									
									if ($_POST['id']) {
										// Update
										foreach ($fields as $key => $field) {
											if (isset($_POST[$field['Field']])) {
												if ($_POST[$field['Field']] != $values[$field['Field']]) {
													if ($field['Type'] == 'password') {
														if ($_POST[$field['Field']]) $_POST[$field['Field']] = md5($_POST[$field['Field']]);
														else continue;
													}
													else if ($tables[0] == 'market_user') {
														if ($field['Field'] == 'user_email') {
															$sql_fields[$field['Table']] .= "`username` = '" . sqlEscape($_POST[$field['Field']]) . "', ";
														}
													}
													$sql_fields[$field['Table']] .= "`" . sqlEscape($field['Field']) . "` = '" . sqlEscape($_POST[$field['Field']]) . "', ";
												}
											}
										}
										if ($sql_fields) {
											$sqls = array();
											switch (count($tables)) {
												case 1:
													if ($tables[0] == 'market_user') {
														$sqls[] = "UPDATE market_user SET " . substr($sql_fields['market_user'], 0, -2) . " WHERE user_id='" . sqlEscape($_POST['id']) . "'";
													}
													else {
														$sqls[] = "UPDATE `" . sqlEscape($tables[0]) . "` SET " . substr($sql_fields[$tables[0]], 0, -2) . " WHERE id='" . sqlEscape($_POST['id']) . "'";
													}
												break;
												case 2:
													if ($sql_fields[$tables[0]] = substr($sql_fields[$tables[0]], 0, -2)) $sqls[] = "UPDATE `" . sqlEscape($tables[0]) . "` SET " . $sql_fields[$tables[0]] . " WHERE id='" . sqlEscape($_POST['id']) . "'";
													if ($sql_fields[$tables[1]] = substr($sql_fields[$tables[1]], 0, -2)) $sqls[] = "UPDATE `" . sqlEscape($tables[1]) . "` SET " . $sql_fields[$tables[1]] . " WHERE id='" . sqlEscape($_POST['id']) . "'";
												break;
												case 3:
													switch ($req->params[$count_params - 1]) {
														case 'cities':
															$sqls[] = "UPDATE directory_ml SET city = '" . sqlEscape($_POST['city']) . "' WHERE city='" . sqlEscape($_POST['id']) . "' AND lang='" . MARKET_LANG . "'";
														break;
														case 'categories':
															$sqls[] = "UPDATE directory_ml SET category = '" . sqlEscape($_POST['category']) . "' WHERE category='" . sqlEscape($_POST['id']) . "' AND lang='" . MARKET_LANG . "'";
														break;
														case 'subcategories':
															$sqls[] = "UPDATE directory_ml SET prof1 = '" . sqlEscape($_POST['prof1']) . "' WHERE prof1='" . sqlEscape($_POST['id']) . "' AND lang='" . MARKET_LANG . "'";
															$sqls[] = "UPDATE directory_ml SET prof1 = '" . sqlEscape($_POST['prof1']) . "' WHERE prof2='" . sqlEscape($_POST['id']) . "' AND lang='" . MARKET_LANG . "'";
															$sqls[] = "UPDATE directory_ml SET prof1 = '" . sqlEscape($_POST['prof1']) . "' WHERE prof3='" . sqlEscape($_POST['id']) . "' AND lang='" . MARKET_LANG . "'";
														break;
														default:
															if ($sql_fields[$tables[0]] = substr($sql_fields[$tables[0]], 0, -2)) $sqls[] = "UPDATE `" . sqlEscape($tables[0]) . "` SET " . $sql_fields[$tables[0]] . " WHERE id='" . sqlEscape($_POST['id']) . "'";
															if ($sql_fields[$tables[1]] = substr($sql_fields[$tables[1]], 0, -2)) $sqls[] = "UPDATE `" . sqlEscape($tables[1]) . "` SET " . $sql_fields[$tables[1]] . " WHERE id='" . sqlEscape($_POST['id']) . "' AND lang='" . MARKET_LANG . "'";
															$sqls[] = "UPDATE `" . sqlEscape($tables[2]) . "` SET updated=NOW() WHERE id='" . sqlEscape($_POST['id']) . "'";
													}
												break;
											}
											foreach ($sqls as $sql) {
												sqlQuery($sql, $res);
											}
											if ($tables[0] == 'directory' && $_POST['path']) {
												// Create store
												if (preg_match('@^[a-z0-9_]+$@', $_POST['path'])) {
													// Add page
													$sql = "SELECT * FROM store_data WHERE type='text' AND name='index' AND directory_id='" . sqlEscape($_POST['id']) . "'";
													if (sqlQuery($sql, $res)) {
														// Page already exists
													}
													else {
														$sql = "INSERT INTO store_data(directory_id, lang, type, name, title) VALUES('" . sqlEscape($_POST['id']) . "', '" . sqlEscape(MARKET_LANG) . "', 'text', 'index', '" . sqlEscape(__('New page')) . "')";
														if ($page_id = sqlQuery($sql, $res)) {
															// Insert permissions
															$sql = "INSERT INTO store_data_ps (id, creator, created, owner, role, updated, ups, gps, wps, publish) VALUES('" . $page_id . "', '" . $_SESSION['User']['user_id'] . "', NOW(), '" . $_SESSION['User']['user_id'] . "', '" . $_SESSION['User']['market_role_id'] . "', NOW(), '7', '2', '2', '0')";
															sqlQuery($sql, $res);
															
															$lng =& $this->getRef('Lang');
															$langs = $lng->getAvailable();
															foreach ($langs as $lang) {
																if ($lang != MARKET_LANG) {
																	$sql = "INSERT INTO store_data(directory_id, lang, type, name, title) VALUES('" . sqlEscape($_POST['id']) . "', '" . sqlEscape($lang) . "', 'text', 'index', '" . sqlEscape(__('New page')) . "')";
																	if ($page_id = sqlQuery($sql, $res)) {
																		// Insert permissions
																		$sql = "INSERT INTO store_data_ps (id, creator, created, owner, role, updated, ups, gps, wps, publish) VALUES('" . $page_id . "', '" . $_SESSION['User']['user_id'] . "', NOW(), '" . $_SESSION['User']['user_id'] . "', '" . $_SESSION['User']['market_role_id'] . "', NOW(), '7', '2', '2', '0')";
																		sqlQuery($sql, $res);
																	}
																}
															}
														}
													}
												}
											}
											unset($_SESSION['NAV.Vars']);
										}
										$req->redirectTo(MARKET_WEB_DIR . '/' . dirname($req->url) . '/index.html');
									}
									else {
										// Create
										foreach ($fields as $key => $field) {
											if (isset($_POST[$field['Field']])) {
												if ($field['Type'] == 'password') {
													if ($_POST[$field['Field']]) $_POST[$field['Field']] = md5($_POST[$field['Field']]);
													else continue;
												}
												else if ($tables[0] == 'market_user') {
													if ($field['Field'] == 'user_email') {
														$sql_fields[$field['Table']][0] .= "`username`, ";
														$sql_fields[$field['Table']][1] .= "'" . sqlEscape($_POST[$field['Field']]) . "', ";
													}
												}
												$sql_fields[$field['Table']][0] .= "`" . sqlEscape($field['Field']) . "`, ";
												$sql_fields[$field['Table']][1] .= "'" . sqlEscape($_POST[$field['Field']]) . "', ";
											}
										}
										if ($sql_fields) {
											$sqls = array();
											switch (count($tables)) {
												case 1:
													if ($tables[0] == 'market_user') {
														$sql = "SELECT MAX(user_id) FROM market_user";
														if (sqlQuery($sql, $res)) {
															$id = sqlResult($res, 0);
															if ($id) $id++;
															else $id = 1;
															$sqls[] = "INSERT INTO market_user (user_id, " . substr($sql_fields['market_user'][0], 0, -2) . ") VALUES ('" . sqlEscape($id) . "', " . substr($sql_fields['market_user'][1], 0, -2) . ")";
														}
													}
													else {
														$sqls[] = "INSERT INTO `" . sqlEscape($tables[0]) . "` (" . substr($sql_fields[$tables[0]][0], 0, -2) . ") VALUES (" . substr($sql_fields[$tables[0]][1], 0, -2) . ")";
													}
												break;
												case 2:
													// Store data (Offers, Reviews)
												break;
												case 3:
													$sql = "INSERT INTO `" . sqlEscape($tables[0]) . "` (" . substr($sql_fields[$tables[0]][0], 0, -2) . ") VALUES (" . substr($sql_fields[$tables[0]][1], 0, -2) . ")";
													if ($id = sqlQuery($sql, $res)) {
														if ($sql_fields[$tables[1]][0] = substr($sql_fields[$tables[1]][0], 0, -2)) {
															$sql = "INSERT INTO `" . sqlEscape($tables[1]) . "` (id, lang, " . $sql_fields[$tables[1]][0] . ") VALUES ('" . sqlEscape($id) . "', '" . MARKET_LANG . "', " . substr($sql_fields[$tables[1]][1], 0, -2) . ")";
														}
														else {
															$sql = "INSERT INTO `" . sqlEscape($tables[1]) . "` (id, lang) VALUES ('" . sqlEscape($id) . "', '" . MARKET_LANG . "')";
														}
														sqlQuery($sql, $res);
														
														$lng =& $this->getRef('Lang');
														$langs = $lng->getAvailable();
														foreach ($langs as $lang) {
															if ($lang != MARKET_LANG) {
																$sql = "INSERT INTO `" . sqlEscape($tables[1]) . "` (id, lang) VALUES ('" . sqlEscape($id) . "', '" . sqlEscape($lang) . "')";
																sqlQuery($sql, $res);
															}
														}
														
														$sql = "INSERT INTO `" . sqlEscape($tables[2]) . "` (id, creator, created, owner, role, updated, ups, gps, wps, publish) VALUES('" . sqlEscape($id) . "', '" . $_SESSION['User']['user_id'] . "', NOW(), '" . $_SESSION['User']['user_id'] . "', '" . $_SESSION['User']['market_role_id'] . "', NOW(), '7', '2', '2', '1')";
														sqlQuery($sql, $res);
														
														if ($tables[0] == 'directory' && isset($_POST['path'])) {
															// Create store
															if (preg_match('@^[a-z0-9_]+$@', $_POST['path'])) {
																// Add page
																$sql = "SELECT * FROM store_data WHERE type='text' AND name='index' AND directory_id='" . sqlEscape($id) . "'";
																if (sqlQuery($sql, $res)) {
																	// Page already exists
																}
																else {
																	$sql = "INSERT INTO store_data(directory_id, lang, type, name, title) VALUES('" . sqlEscape($id) . "', '" . sqlEscape(MARKET_LANG) . "', 'text', 'index', '" . sqlEscape(__('New page')) . "')";
																	if ($page_id = sqlQuery($sql, $res)) {
																		// Insert permissions
																		$sql = "INSERT INTO store_data_ps (id, creator, created, owner, role, updated, ups, gps, wps, publish) VALUES('" . $page_id . "', '" . $_SESSION['User']['user_id'] . "', NOW(), '" . $_SESSION['User']['user_id'] . "', '" . $_SESSION['User']['market_role_id'] . "', NOW(), '7', '2', '2', '0')";
																		sqlQuery($sql, $res);
																		$lng =& $this->getRef('Lang');
																		$langs = $lng->getAvailable();
																		foreach ($langs as $lang) {
																			if ($lang != MARKET_LANG) {
																				$sql = "INSERT INTO store_data(directory_id, lang, type, name, title) VALUES('" . sqlEscape($_POST['id']) . "', '" . sqlEscape($lang) . "', 'text', 'index', '" . sqlEscape(__('New page')) . "')";
																				if ($page_id = sqlQuery($sql, $res)) {
																					// Insert permissions
																					$sql = "INSERT INTO store_data_ps (id, creator, created, owner, role, updated, ups, gps, wps, publish) VALUES('" . $page_id . "', '" . $_SESSION['User']['user_id'] . "', NOW(), '" . $_SESSION['User']['user_id'] . "', '" . $_SESSION['User']['market_role_id'] . "', NOW(), '7', '2', '2', '0')";
																					sqlQuery($sql, $res);
																				}
																			}
																		}
																	}
																}
															}
														}
													}
												break;
											}
											foreach ($sqls as $sql) {
												sqlQuery($sql, $res);
											}
											unset($_SESSION['NAV.Vars']);
										}
										$req->redirectTo(MARKET_WEB_DIR . '/' . dirname($req->url) . '/index.html');
									}
								}
							}
							
							// Print form
							$previous_field = array();
							foreach ($fields as $key => $field) {
								if ($field['Field'] == 'id' || ($field['Table'] == 'market_user' && $field['Field'] == 'user_id')) { $field['Properties'] = ' disabled="disabled"'; $field['Class'] = 'span2'; }
								if (!isset($field['Label'])) $field['Label'] = __(ucfirst(preg_replace('@\bid\b@', 'ID', preg_replace('@_@', ' ', $field['Field']))));
								if (!isset($field['Value']) && $values[$field['Field']]) $field['Value'] = htmlspecialchars($values[$field['Field']]);
								if ($field['Class']) $field['Class'] = ' class="' . $field['Class'] . '"'; else $field['Class'] = ' class="span3"';
								if ($field['Help']) $field['Help'] = '<div class="help">' . $field['Help'] . '</div>';
								if ($field['Required']) $field['Label'] .= '<span class="muted">*</span>';
								if ($field['Suggested']) $field['Label'] .= '<span class="muted">ˣ</span>';
								if ($field['Group']) {
									$field['Type'] = 'group';
									if ($previous_field && $field['Group'] != $previous_field['Group']) {
										if ($previous_field['Field'] == 'lng') {
											$this->parseTemplate('FORM/GROUP/TEXT', 'form/map');
										}
										$this->assignLocal('form/group', 'FIELD', $previous_field);
										$this->parseTemplate('EDIT_FORM', 'form/group');
										$this->clearGlobal('FORM/GROUP/TEXT');
										$previous_field = array();
									}										
								}
								else if ($previous_field) {
									$this->assignLocal('form/group', 'FIELD', $previous_field);
									$this->parseTemplate('EDIT_FORM', 'form/group');
									$this->clearGlobal('FORM/GROUP/TEXT');
									$previous_field = array();
								}
								switch (preg_replace('@\(.+\)@', '', $field['Type'])) {
									case 'enum':
										if (preg_match('@\((.+)\)@', $field['Type'], $matches)) {
											if ($matches[1] == "'0','1'") {
												if ($field['Value']) {
													$field['Properties'] = ' checked="checked"';
												}
												$this->assignLocal('form/checkbox', 'FIELD', $field);
												$this->parseTemplate('EDIT_FORM', 'form/checkbox');
											}
											else {
												$parts = explode(',', $matches[1]);
												$this->clearGlobal('FORM/SELECT/OPTION');
												$this->assignLocal('form/select', 'FIELD', $field);
												foreach ($parts as $part) {
													$row = array();
													$row['id'] = substr($part, 1, -1);
													$row['title'] = substr($part, 1, -1);
													if ($row['id'] == $field['Value']) {
														$row['selected'] = ' selected="selected"';
													}
													$this->assignLocal('form/select/option', 'OPTION', $row);
													$this->parseTemplate('FORM/SELECT/OPTION', 'form/select/option');
												}
												$this->parseTemplate('EDIT_FORM', 'form/select');
											}
										}
									break;
									case 'date':
									case 'datetime':
										$field['Type'] = 'text';
										$field['Class'] = ' class="datepicker span3"';
										$this->assignLocal('form/text', 'FIELD', $field);
										$this->parseTemplate('EDIT_FORM', 'form/text');
									break;
									case 'text':
									case 'longtext':
										if ($field['is_HTML']) {
											switch (MARKET_LANG) {
												case 'el':
													$this->assignLocal('form/textarea/html/js', 'LOCALE', 'el-GR');
												break;
											}
											$this->parseTemplate('PAGE.Javascript', 'form/textarea/html/js');
											$this->assignLocal('form/textarea/html', 'FIELD', $field);
											$this->parseTemplate('EDIT_FORM', 'form/textarea/html');
										}
										else {
											$field['Class'] = ' class="span5"';
											$this->assignLocal('form/textarea', 'FIELD', $field);
											$this->parseTemplate('EDIT_FORM', 'form/textarea');
										}
									break;
									case 'password':
										$field['Type'] = 'Password';
										$this->assignLocal('form/text', 'FIELD', $field);
										$this->parseTemplate('EDIT_FORM', 'form/text');
									break;
									case 'select':
										if ($field['Options']) {
											if (sqlQuery($field['Options'], $res)) {
												$this->clearGlobal('FORM/SELECT/OPTION');
												$this->assignLocal('form/select', 'FIELD', $field);
												while ($row = sqlFetchAssoc($res)) {
													if ($row['id'] == $field['Value']) {
														$row['selected'] = ' selected="selected"';
													}
													$this->assignLocal('form/select/option', 'OPTION', $row);
													$this->parseTemplate('FORM/SELECT/OPTION', 'form/select/option');
												}
												$this->parseTemplate('EDIT_FORM', 'form/select');
											}
										}
									break;
									case 'popup':
										$field['Type'] = 'text';
										$field['Class'] = ' class="popup-input span2"';
										$field['Properties'] = ' readonly="readonly" data-action="' . $field['Action'] . '" data-title="' . __('Select') . ' ' . preg_replace('@<span.+@', '', $field['Label']) . '"';
										$this->assignLocal('form/text', 'FIELD', $field);
										$this->parseTemplate('EDIT_FORM', 'form/text');
									break;
									case 'group':
										$this->assignLocal('form/group/text', 'FIELD', $field);
										$this->parseTemplate('FORM/GROUP/TEXT', 'form/group/text');
										$previous_field = $field;
									break;
									case 'int':
										if ($field['Field'] == 'expires' && $field['Value']) {
											$field['Value'] = date('Y-m-d H:i:s', $field['Value']);
										}
									default:
										$field['Type'] = 'text';
										if ($field['Field'] == 'pin') {
											$field['Help'] = '<div class="hanging" style="margin-top: -30px;"><a class="btn generate_pin" href="#"><i class="icon-refresh"></i> ' . __('Generate') . '</a></div>';
										}
										$this->assignLocal('form/text', 'FIELD', $field);
										$this->parseTemplate('EDIT_FORM', 'form/text');
								}
							}
							// One more time
							if ($previous_field) {
								$this->assignLocal('form/group', 'FIELD', $previous_field);
								$this->parseTemplate('EDIT_FORM', 'form/group');
							}
						break;
						case 'publish':
							if ($_GET['id'] && preg_match('@^\d+$@', $_GET['id'])) {
								if ($tables[0] == 'market_user') {
									$sql = "UPDATE market_user SET user_active='1' WHERE user_id='" . sqlEscape($_GET['id']) . "' LIMIT 1";
								}
								else {
									$sql = "UPDATE `" . $tables[0] . "_ps` SET publish='1' WHERE id='" . sqlEscape($_GET['id']) . "' LIMIT 1";
								}
								sqlQuery($sql, $res);
								$req->redirectTo(MARKET_WEB_DIR . '/' . dirname($req->url) . '/index.html');
							}
							else {
								$req->httpError(400); // Bad request
							}
						break;
						case 'unpublish':
							if ($_GET['id'] && preg_match('@^\d+$@', $_GET['id'])) {
								if ($tables[0] == 'market_user') {
									$sql = "UPDATE market_user SET user_active='0' WHERE user_id='" . sqlEscape($_GET['id']) . "' LIMIT 1";
								}
								else {
									$sql = "UPDATE `" . $tables[0] . "_ps` SET publish='0' WHERE id='" . sqlEscape($_GET['id']) . "' LIMIT 1";
								}
								sqlQuery($sql, $res);
								$req->redirectTo(MARKET_WEB_DIR . '/' . dirname($req->url) . '/index.html');
							}
							else {
								$req->httpError(400); // Bad request
							}
						break;
						case 'delete':
							if ($_GET['id']) {
								$sqls = array();
								switch ($req->params[$count_params - 1]) {
									case 'cities':
										$sqls[] = "UPDATE directory_ml SET city='' WHERE city='" . sqlEscape($_GET['id']) . "'";
									break;
									case 'categories':
										$sqls[] = "UPDATE directory_ml SET category='' WHERE category='" . sqlEscape($_GET['id']) . "'";
									break;
									case 'subcategories':
										$sqls[] = "UPDATE directory_ml SET prof1='' WHERE prof1='" . sqlEscape($_GET['id']) . "'";
										$sqls[] = "UPDATE directory_ml SET prof2='' WHERE prof2='" . sqlEscape($_GET['id']) . "'";
										$sqls[] = "UPDATE directory_ml SET prof3='' WHERE prof3='" . sqlEscape($_GET['id']) . "'";
									break;
									default:
										// Normal table
										if ($tables[0] == 'market_user') {
											$sqls[] = "DELETE FROM `market_user` WHERE user_id='" . sqlEscape($_GET['id']) . "' LIMIT 1";
										}
										else {
											$sqls[] = "DELETE FROM `" . $tables[0] . "` WHERE id='" . sqlEscape($_GET['id']) . "' LIMIT 1";
											$sqls[] = "DELETE FROM `" . $tables[0] . "_ml` WHERE id='" . sqlEscape($_GET['id']) . "'";
											$sqls[] = "DELETE FROM `" . $tables[0] . "_ps` WHERE id='" . sqlEscape($_GET['id']) . "' LIMIT 1";
										}
								}
								foreach ($sqls as $sql) {
									sqlQuery($sql, $res);
								}
								unset($_SESSION['NAV.Vars']);
								$req->redirectTo(MARKET_WEB_DIR . '/' . dirname($req->url) . '/index.html');
							}
							else {
								$req->httpError(400); // Bad request
							}
						break;
					}
				}
			}
			
			if ($req->params[1] == 'index') {
				$this->disableTemplate('search-results');
				switch ($req->params[2]) {
					case 'settings':
						// Needed for map position
						$this->assignGlobal('PAGE.Class', 'home');
						
						// Enable template
						$this->enableTemplate('settings');
						
						// Load config
						$config = MARKET_ROOT_DIR . '/config.inc.php';
						if (@is_readable($config)) {
							$lines = file($config);
							
							if (@is_writable($config)) {
								if ($_POST && count($_POST)) {
									
									$valid_vars = array('MARKET_TIMEZONE', 'MARKET_SMTP_HOST', 'MARKET_SMTP_USER', 'MARKET_SMTP_PASS', 'MARKET_SMTP_FROM', 'MARKET_SMTP_FROM_NAME', 'SUPPORT_EMAIL', 'ANALYTICS_TRACKING_CODE', 'GMAP_API_KEY', 'GMAP_CENTER_LAT', 'GMAP_CENTER_LNG', 'GMAP_CENTER_ZOOM', 'FUSION_TABLE_LAYER', 'RECAPTCHA_PRIVATE_KEY', 'RECAPTCHA_PUBLIC_KEY');
									
									$str = '';
									$counti = count($lines);
									for ($i = 0; $i < $counti; $i++) {
										$lines[$i] = rtrim($lines[$i]);
										if (preg_match("@^(.+)define\('([^']+)',\s+'[^']*'\);(.*)$@", $lines[$i], $matches)) {
											if (in_array($matches[2], $valid_vars)) {
												$_POST[$matches[2]] = preg_replace("@'@", '', $_POST[$matches[2]]);
												$str .= "\tdefine('" . $matches[2] . "', '" . $_POST[$matches[2]] . "');" . $matches[3] . "\n";
											}
											else {
												$str .= $lines[$i] . "\n";
											}
										}
										else {
											$str .= $lines[$i] . "\n";
										}
									}
									
									// Save values
									if ($fh = fopen($config, 'w')) {
										fwrite($fh, $str);
										fclose($fh);
									}
									
									// Reload
									$req->redirectTo(MARKET_WEB_DIR . '/' . $req->url);
								}
							}
							else {
								$this->assignGlobal('SETTINGS_MESSAGE', '<div class="alert alert-error">' . __('Configuration file') . ' " ' . $config . '"' . __('is not writable') . '.</div>');
							}
							
							// Assign values
							$counti = count($lines);
							for ($i = 0; $i < $counti; $i++) {
								if (preg_match("@define\('([^']+)',\s+'([^']+)'\);@", $lines[$i], $matches)) {
									$this->assignGlobal($matches[1], $matches[2]);
									
									if ($matches[1] == 'MARKET_TIMEZONE') {
										$str = '<select id="MARKET_TIMEZONE" name="MARKET_TIMEZONE" class="span3">' . "\n";
										$timezones = DateTimeZone::listIdentifiers(DateTimeZone::ALL);
										foreach ($timezones as $timezone) {
											if ($timezone == $matches[2]) {
												$str .= '<option value="' . htmlspecialchars($timezone) . '" selected="selected">' . htmlspecialchars($timezone) . '</option>' . "\n";
											}
											else {
												$str .= '<option value="' . htmlspecialchars($timezone) . '">' . htmlspecialchars($timezone) . '</option>' . "\n";
											}
										}
										$str .= '</select>' . "\n";
										$this->assignGlobal('MARKET_TIMEZONE_SELECT', $str);
									}
								}
							}
						}
						else {
							// This can/should never happen
							// If the configuration is unreadable nothing works!
							$this->disableTemplate('settings_form');
							$this->assignGlobal('SETTINGS_MESSAGE', '<div class="alert alert-error">' . __('Configuration file') . ' "' . $config . '" ' . __('is not readable') . '.</div>');
						}
					break;
					case 'log':
						// {LANG.Log}
						$this->enableTemplate('search-results');
						$this->disableTemplate('new_record');
						$no_edit = true;
						$fields = array('label:ID;align:center;', 'label:' . __('Type') . ';translate:log_type;align:center;', __('Message'), 'field:user_id;translate:market_user.user_id.CONCAT(name, " ", surname);label:' . __('User') . ';', 'label:' . __('Timestamp') . ';align:center;');
						$sql = "SELECT id, type, text, user_id, tstamp FROM log WHERE user_id > 0" . $where;
						if (!$_GET['order']) {
							$sql .= " ORDER BY tstamp DESC";
						}
						//  The raptor WILL chase you!
						goto results;
					break;
					default:
						// Index
						$this->enableTemplate('index');
						
						// Statistics
						$stats = array();
						$sql = "SELECT COUNT(*) FROM directory_ml WHERE lang='" . MARKET_LANG . "'";
						if (sqlQuery($sql, $res)) {
							$stats['directory'] = sqlResult($res, 0);
						}
						$sql = "SELECT COUNT(*) FROM directory WHERE path<>''";
						if (sqlQuery($sql, $res)) {
							$stats['stores'] = sqlResult($res, 0);
						}
						$sql = "SELECT COUNT(*) FROM store_data WHERE type='coupon'";
						if (sqlQuery($sql, $res)) {
							$stats['offers'] = sqlResult($res, 0);
						}
						$sql = "SELECT COUNT(*) FROM store_data WHERE type='comment'";
						if (sqlQuery($sql, $res)) {
							$stats['reviews'] = sqlResult($res, 0);
						}
						$this->assignGlobal('STATS', $stats);
						
						// Latest
						$found = false;
						$sqls['directory'] = "SELECT IF(business_name <> '', business_name, name) AS business_name, '', '' FROM directory STRAIGHT_JOIN directory_ml STRAIGHT_JOIN directory_ps WHERE directory.id = directory_ml.id AND directory.id = directory_ps.id AND lang='" . MARKET_LANG . "' ORDER BY created DESC LIMIT 0,3";
						$sqls['marketplace'] = "SELECT IF(directory_ml.business_name <> '', directory_ml.business_name, directory_ml.name) AS business_name, '', CONCAT('marketplace/' , path, '/index.html') AS preview FROM store_data STRAIGHT_JOIN store_data_ps STRAIGHT_JOIN directory STRAIGHT_JOIN directory_ml STRAIGHT_JOIN directory_ps WHERE store_data.id = store_data_ps.id AND store_data.directory_id = directory.id AND directory.id = directory_ml.id AND directory.id = directory_ps.id AND store_data.lang='" . MARKET_LANG . "' AND  directory_ml.lang='" . MARKET_LANG . "' AND store_data.name='index' AND store_data.type='text' ORDER BY store_data_ps.created DESC LIMIT 0,3";
						$sqls['offers'] = "SELECT IF(directory_ml.business_name <> '', directory_ml.business_name, directory_ml.name) AS business_name, store_data.title, CONCAT('offers/' , path, '/', store_data.name, '.html') AS preview FROM store_data STRAIGHT_JOIN store_data_ps STRAIGHT_JOIN directory STRAIGHT_JOIN directory_ml STRAIGHT_JOIN directory_ps WHERE store_data.id = store_data_ps.id AND store_data.directory_id = directory.id AND directory.id = directory_ml.id AND directory.id = directory_ps.id AND store_data.lang='" . MARKET_LANG . "' AND  directory_ml.lang='" . MARKET_LANG . "' AND store_data.type='coupon' ORDER BY store_data_ps.created DESC LIMIT 0,3";
						$sqls['reviews'] = "SELECT IF(directory_ml.business_name <> '', directory_ml.business_name, directory_ml.name) AS business_name, data, CONCAT('reviews/' , path, '/show.html#comment', store_data.id) AS preview FROM store_data STRAIGHT_JOIN store_data_ps STRAIGHT_JOIN directory STRAIGHT_JOIN directory_ml STRAIGHT_JOIN directory_ps WHERE store_data.id = store_data_ps.id AND store_data.directory_id = directory.id AND directory.id = directory_ml.id AND directory.id = directory_ps.id AND store_data.lang='" . MARKET_LANG . "' AND  directory_ml.lang='" . MARKET_LANG . "' AND store_data.type='comment' ORDER BY store_data_ps.created DESC LIMIT 0,3";
						foreach ($sqls as $name => $sql) {
							if (sqlQuery($sql, $res)) {
								$found = true;
								$str = '<table class="latest table table-striped" style="margin: 0;">';
								while ($row = sqlFetchAssoc($res)) {
									$str .= '<tr>';
										foreach ($row as $key => $val) {
											if ($key == 'preview') {
												$str .= '<td style="text-align: center;"><a href="{MARKET.LWebDir}/admin/preview.html?url=' . urlencode($val) . '"><i class="icon-search"></i></a></td>';
											}
											else {
												$str .= '<td><div>' . htmlspecialchars($val) . '</div></td>';
											}
										}
									$str .= '</tr>';
								}
								$str .= '</table>';
								$this->assignLocal('latest', 'LATEST', array('name' => $name, 'title' => __(ucfirst(preg_replace('@_@', ' ', $name))), 'results' => $str));
								$this->parseTemplate('LATEST', 'latest');
							}
						}
						if (!$found) {
							$this->disableTemplate('latest');
							$this->assignGlobal('LATEST', __('Nothing found'));
						}
				}
			}
			else if ($req->params[1] == 'directory' && $req->params[2] == 'tools') {
				// Tools
				// {LANG.Tools}
				// {LANG.Import}
				// {LANG.Export}
				// {LANG.Generate pins}
				// {LANG.Geocode}
				
				$this->disableTemplate('search-results');
				$this->enableTemplate($req->params[3]);
				
				switch ($req->params[3]) {
					case 'import':
						// Import
						
						// Copied from above and mildly modified
						$fields = array(
							'id' => array('Label' => 'ID'),
							'category' => array('Suggested' => true, 'Type' => 'varchar', 'Class' => 'typeahead span3', 'Properties' => ' data-path="directory_ml.category"'),
							'prof1' => array('Group' => __('Subcategories'), 'Label' => __('Subcategory') . ' 1', 'Class' => 'typeahead span3', 'Properties' => ' data-path="directory_ml.prof"'),
							'prof2' => array('Group' => __('Subcategories'), 'Label' => __('Subcategory') . ' 2', 'Class' => 'typeahead span3', 'Properties' => ' data-path="directory_ml.prof"'),
							'prof3' => array('Group' => __('Subcategories'), 'Label' => __('Subcategory') . ' 3', 'Class' => 'typeahead span3', 'Properties' => ' data-path="directory_ml.prof"', 'Help' => '<b>' . __('Hint') . ':</b> ' . __('First select a category')),
							'name' => array('Type' => 'varchar', 'Label' => __('Owner name')),
							'business_name' => array('Suggested' => true, 'Type' => 'varchar'),
							'byline' => array('Type' => 'varchar'),
							'address' => array('Suggested' => true),
							'city' => array('Suggested' => true, 'Type' => 'varchar', 'Class' => 'typeahead span3', 'Properties' => ' data-path="directory_ml.city"'),
							'phone' => array('Suggested' => true, 'Type' => 'varchar'),
							'email' => array('Type' => 'varchar'),
							'url' => array('Type' => 'varchar'),
							'facebook' => array('Group' => __('Social media')),
							'twitter' => array('Group' => __('Social media')),
							'google' => array('Group' => __('Social media'), 'Label' => 'Google plus'),
							'youtube' => array('Group' => __('Social media'), 'Label' => 'YouTube')
						);
						
						foreach ($fields as $key => $field) {
							if (is_array($field)) {
								$fields[$key] = array_merge($all_fields[$key], $field);
							}
							else {
								$fields[$key] = $all_fields[$field];
							}
						}
						foreach ($fields as $key => $field) {
							if (!isset($field['Label'])) $fields[$key]['Label'] = __(ucfirst(preg_replace('@\bid\b@', 'ID', preg_replace('@_@', ' ', $field['Field']))));
						}
						
						$dir = MARKET_ROOT_DIR . '/uploads/import';
						$file = $dir . '/' . session_id() . 'catalog.xls';
						
						if (($_POST && count($_POST)) || $_FILES) {
							// Something posted
							
							if ($_POST['response'] == 'ok') {
								$this->disableTemplate('upload-preview');
								
								// Actual import
								if ($_POST['columns'] && preg_match('@[^,]@', $_POST['columns'])) {
									
									// Save configuration
									$auth =& $this->getRef('Auth');
									$auth->saveUserData('import_columns', $_POST['columns']);
									
									$columns = explode(',', $_POST['columns']);
									
									require_once(MARKET_ROOT_DIR . '/redist/php-excel-reader/excel_reader2.php');
									$wbk = new Spreadsheet_Excel_Reader($file);
									
									// Select first sheet
									$wst = $wbk->sheets[0];
									
									$start_at = 0;
									if ($_POST['has_headers']) { $start_at = 1; }
									
									$i = 0; $k = 0;
									while ($i < $wst['numRows']) {
										$i++;
										$found = false;
										for ($j = 1; $j <= $wst['numCols']; $j++) {
											if (trim($wst['cells'][$i][$j])) {
												$found = true;
												break;
											}
										}
										if ($found) {
											if ($k >= $start_at) {
												$found = false;
												$sql_fields = array();
												for ($j = 1; $j <= $wst['numCols']; $j++) {
													if ($columns[$j - 1]) {
														$field = $fields[$columns[$j - 1]];
														if ($field['Field'] == 'id') $found = trim($wst['cells'][$i][$j]);
														$sql_fields[$field['Table']][0] .= "`" . sqlEscape($field['Field']) . "`, ";
														$sql_fields[$field['Table']][1] .= "'" . sqlEscape(preg_replace('@\n@', '\n', getCorrectString($wst['cells'][$i][$j]))) . "', ";
													}
												}
												if ($found) {
													$id = $found;
													if ($sql_fields[$tables[1]][0] = substr($sql_fields[$tables[1]][0], 0, -2)) {
														$sql = "REPLACE INTO `" . sqlEscape($tables[1]) . "` (id, lang, " . $sql_fields[$tables[1]][0] . ") VALUES ('" . sqlEscape($id) . "', '" . MARKET_LANG . "', " . substr($sql_fields[$tables[1]][1], 0, -2) . ")";
													}
													sqlQuery($sql, $res);
													$sql = "UPDATE `" . sqlEscape($tables[2]) . "` SET updated=NOW() WHERE id='" . sqlEscape($id) . "'";
													if (!sqlQuery($sql, $res)) {
														$sql = "INSERT INTO `" . sqlEscape($tables[2]) . "` (id, creator, created, owner, role, updated, ups, gps, wps, publish) VALUES('" . sqlEscape($id) . "', '" . $_SESSION['User']['user_id'] . "', NOW(), '" . $_SESSION['User']['user_id'] . "', '" . $_SESSION['User']['market_role_id'] . "', NOW(), '7', '2', '2', '1')";
														sqlQuery($sql, $res);
													}
												}
												else {
													$sql_fields[$tables[0]][0] = "`id`, " . $sql_fields[$tables[0]][0];
													$sql_fields[$tables[0]][1] = "'', " . $sql_fields[$tables[0]][1];
													$sql = "INSERT INTO `" . sqlEscape($tables[0]) . "` (" . substr($sql_fields[$tables[0]][0], 0, -2) . ") VALUES (" . substr($sql_fields[$tables[0]][1], 0, -2) . ")";
													if ($id = sqlQuery($sql, $res)) {
														if ($sql_fields[$tables[1]][0] = substr($sql_fields[$tables[1]][0], 0, -2)) {
															$sql = "INSERT INTO `" . sqlEscape($tables[1]) . "` (id, lang, " . $sql_fields[$tables[1]][0] . ") VALUES ('" . sqlEscape($id) . "', '" . MARKET_LANG . "', " . substr($sql_fields[$tables[1]][1], 0, -2) . ")";
														}
														else {
															$sql = "INSERT INTO `" . sqlEscape($tables[1]) . "` (id, lang) VALUES ('" . sqlEscape($id) . "', '" . MARKET_LANG . "')";
														}
														sqlQuery($sql, $res);
														
														$lng =& $this->getRef('Lang');
														$langs = $lng->getAvailable();
														foreach ($langs as $lang) {
															if ($lang != MARKET_LANG) {
																$sql = "INSERT INTO `" . sqlEscape($tables[1]) . "` (id, lang) VALUES ('" . sqlEscape($id) . "', '" . sqlEscape($lang) . "')";
																sqlQuery($sql, $res);
															}
														}
														
														$sql = "INSERT INTO `" . sqlEscape($tables[2]) . "` (id, creator, created, owner, role, updated, ups, gps, wps, publish) VALUES('" . sqlEscape($id) . "', '" . $_SESSION['User']['user_id'] . "', NOW(), '" . $_SESSION['User']['user_id'] . "', '" . $_SESSION['User']['market_role_id'] . "', NOW(), '7', '2', '2', '1')";
														sqlQuery($sql, $res);
													}
												}
												if ($_POST['auto_generate'] && $id) {
													// Auto generated PIN
													$sql = "SELECT pin FROM directory WHERE id='" . sqlEscape($id) . "'";
													if (sqlQuery($sql, $res)) {
														if (!sqlResult($res, 0)) {
															// Generate PIN
															$l = 0;
															$pin = 0;
															while ($l < 10) { // Try at most 10 times to create a unique code
																$pin = rand(1, 9999);
																$sql = "SELECT * FROM directory WHERE pin='" . sqlEscape($pin) . "'";
																if (!sqlQuery($sql, $res)) {
																	break; // Pin OK
																}
																$l++;
															}
															if ($pin) {
																$sql = "UPDATE directory SET pin = '" . sqlEscape(sprintf('%04d', $pin)) . "' WHERE id='" . sqlEscape($id) . "'";
																sqlQuery($sql, $res);
															}
															else {
																// Fail silently
															}
														}
													}
												}
												if ($_POST['auto_geocode'] && $id) {
													$sql = "SELECT address, city FROM directory_ml WHERE lang='" . MARKET_LANG . "' AND id='" . sqlEscape($id) . "'";
													if (sqlQuery($sql, $res)) {
														$row = sqlFetchAssoc($res);
														$base_url = "https://maps.googleapis.com/maps/api/geocode/xml?key=" . GMAP_API_KEY;
														$address = $row['address'] . ', ' . $row['city'];
														$request_url = $base_url . "&address=" . urlencode($address);
														$xml = simplexml_load_file($request_url);
														if ($xml->status == 'OK') {
															// Successful geocode
															$lat = $xml->result->geometry->location->lat;
															$lng = $xml->result->geometry->location->lng;
															$sql = "UPDATE directory SET lat = '" . sqlEscape($lat) . "', lng = '" . sqlEscape($lng) . "' WHERE id = '" . sqlEscape($id) . "' LIMIT 1";
															sqlQuery($sql, $res);
														}
													}
												}
											}
											$k++;
										}
									}
									$str = '<div class="alert alert-info alert-block">';
										$str .= '<p>' . __('Import successful') . '. ' . __('Number of imported records') . ': ' . $k . '.</p>';
									$str .= '</div>';
									unset($_SESSION['NAV.Vars']);
								}
								else {
									$str = '<div class="alert alert-error alert-block">';
										$str .= '<p>' . __('No columns selected') . '. ' . __('Nothing imported') . '.</p>';
									$str .= '</div>';
								}
								$this->assignGlobal('UPLOAD_MESSAGE', $str);
								unlink($file);
							}
							else if ($_POST['response'] == 'cancel') {
								// Cancel
								$this->disableTemplate('upload-preview');
								$str = '<div class="alert alert-warning alert-block">';
									$str .= '<p>' . __('Import canceled') . '.</p>';
								$str .= '</div>';
								@unlink($file);
								$this->assignGlobal('UPLOAD_MESSAGE', $str);
							}
							else if ($_FILES) {
								if ($this->makeDir($dir)) {
									if (preg_match('@\.xls@', $_FILES['file']['name'])) {
										// Move file to temporary location
										if (@move_uploaded_file($_FILES['file']['tmp_name'], $file)) {
											// Redirect
											$req->redirectTo(MARKET_WEB_DIR . '/' . $req->url);
										}
										else {
											$this->disableTemplate('upload-preview');
											$str = '<div class="alert alert-error alert-block">';
												$str .= '<p>' . __('Cannot copy the file to the temporary directory') . ' "' . htmlspecialchars($dir) . '". ' . __('Import canceled') . '.</p>';
											$str .= '</div>';
										}
									}
									else {
										$this->disableTemplate('upload-preview');
										$str = '<div class="alert alert-error alert-block">';
											$str .= '<p>' . __('The file should be an "Excel 97-2003 Workbook (*.xls)"') . '. ' . __('Import canceled') . '.</p>';
										$str .= '</div>';
									}
								}
								else {
									$this->disableTemplate('upload-preview');
									$str = '<div class="alert alert-error alert-block">';
										$str .= '<p>' . __('Cannot create the temporary directory') . ' "' . htmlspecialchars($dir) . '". ' . __('Import canceled') . '.</p>';
									$str .= '</div>';
								}
								$this->assignGlobal('UPLOAD_MESSAGE', $str);
							}
							else {
								$this->disableTemplate('upload-preview');
								$str = '<div class="alert alert-error alert-block">';
									$str .= '<p>' . __('Select a file to import') . '.</p>';
								$str .= '</div>';
								$this->assignGlobal('UPLOAD_MESSAGE', $str);
							}
						}
						else if (@is_file($file) && is_readable($file)) {
							// File already uploaded
							
							$this->disableTemplate('upload');
							
							// Load configuration
							$columns = array();
							if ($_GET['last']) {
								$columns = explode(',', $_SESSION['User']['data']['import_columns']);
							}
							
							// Fields
							$i = 0;
							foreach ($fields as $field) {
								if (!$columns[$i]) {
									$str .= '<span><a id="' . $field['Field'] . '">' . htmlspecialchars($field['Label']) . '</a></span>';
								}
								$i++;
							}
							$this->assignGlobal('TAGS', $str);
							
							require_once(MARKET_ROOT_DIR . '/redist/php-excel-reader/excel_reader2.php');
							$wbk = new Spreadsheet_Excel_Reader($file);
							
							// Select first sheet
							$wst = $wbk->sheets[0];
							
							// Print table
							$str = '<div class="upload-preview-overlay"></div>';
							$str .= '<div class="upload-preview">';
								$str .= '<table class="table table-striped table-condensed" style="margin: 0; font-size: 12px;">';
									$str .= '<tr class="tags">';
									for ($j = 1; $j <= $wst['numCols']; $j++) {
										if ($columns[$j - 1]) {
											$field = $fields[$columns[$j - 1]];
											$str .= '<td><div class="target"><span><a id="' . $field['Field'] . '">' . htmlspecialchars($field['Label']) . '</a></span></div></td>';
										}
										else {
											$str .= '<td><div class="target"></div></td>';
										}
									}
									$str .= '</tr>';
									
									$i = 0; $k = 0;
									while ($k <= 13 && $i < $wst['numRows']) {
										$i++;
										$found = false;
										for ($j = 1; $j <= $wst['numCols']; $j++) {
											if (trim($wst['cells'][$i][$j])) {
												$found = true;
												break;
											}
										}
										if ($found) {
											$str .= '<tr>';
											for ($j = 1; $j <= $wst['numCols']; $j++) {
												$str .= '<td><div>';
													$str .= htmlspecialchars($wst['cells'][$i][$j]);
												$str .= '</div></td>';
											}
											$str .= '</tr>';
											$k++;
										}
									}
								$str .= '</table>';
							$str .= '</div>';
							
							$this->assignGlobal('RESULTS', $str);
						}
						else {
							$this->disableTemplate('upload-preview');
						}
					break;
					case 'export':
						// Export
						
						// Copied from above and mildly modified
						$fields = array(
							'id' => array('Label' => 'ID'),
							'pin' => array('Unique' => true, 'Label' => __('PIN code')),
							'category' => array('Suggested' => true, 'Type' => 'varchar', 'Class' => 'typeahead span3', 'Properties' => ' data-path="directory_ml.category"'),
							'prof1' => array('Group' => __('Subcategories'), 'Label' => __('Subcategory') . ' 1', 'Class' => 'typeahead span3', 'Properties' => ' data-path="directory_ml.prof"'),
							'prof2' => array('Group' => __('Subcategories'), 'Label' => __('Subcategory') . ' 2', 'Class' => 'typeahead span3', 'Properties' => ' data-path="directory_ml.prof"'),
							'prof3' => array('Group' => __('Subcategories'), 'Label' => __('Subcategory') . ' 3', 'Class' => 'typeahead span3', 'Properties' => ' data-path="directory_ml.prof"', 'Help' => '<b>' . __('Hint') . ':</b> ' . __('First select a category')),
							'name' => array('Type' => 'varchar', 'Label' => __('Owner name')),
							'business_name' => array('Suggested' => true, 'Type' => 'varchar'),
							'byline' => array('Type' => 'varchar'),
							'address' => array('Suggested' => true),
							'city' => array('Suggested' => true, 'Type' => 'varchar', 'Class' => 'typeahead span3', 'Properties' => ' data-path="directory_ml.city"'),
							'phone' => array('Suggested' => true, 'Type' => 'varchar'),
							'email' => array('Type' => 'varchar'),
							'url' => array('Type' => 'varchar'),
							'lat' => array('Suggested' => true, 'Group' => __('Location'), 'Label' => __('Latitude')),
							'lng' => array('Suggested' => true, 'Group' => __('Location'), 'Label' => __('Longitude')),
							'facebook' => array('Group' => __('Social media')),
							'twitter' => array('Group' => __('Social media')),
							'google' => array('Group' => __('Social media'), 'Label' => 'Google plus'),
							'youtube' => array('Group' => __('Social media'), 'Label' => 'YouTube')
						);
						
						foreach ($fields as $key => $field) {
							if (is_array($field)) {
								$fields[$key] = array_merge($all_fields[$key], $field);
							}
							else {
								$fields[$key] = $all_fields[$field];
							}
						}
						foreach ($fields as $key => $field) {
							if (!isset($field['Label'])) $fields[$key]['Label'] = __(ucfirst(preg_replace('@\bid\b@', 'ID', preg_replace('@_@', ' ', $field['Field']))));
						}
						
						if ($_GET['export']) {
							$str = '<html>';
							$str .= '<body>';
							// Print table
							$select_fields = '';
							foreach ($fields as $field) {
								$select_fields .= "`" . $field['Table'] . "`.`" . $field['Field'] . "`, ";
							}
							$sql = "SELECT " . substr($select_fields, 0, -2) . " FROM directory STRAIGHT_JOIN directory_ml WHERE directory.id = directory_ml.id AND lang = '" . MARKET_LANG . "'";
							if (sqlQuery($sql, $res)) {
								$str .= '<table border="1" style="font-size: 12px;">';
									$i = 0;
									while ($row = sqlFetchAssoc($res)) {
										if ($i == 0) {
											$str .= '<tr>';
											foreach ($row as $key => $val) {
												$str .= '<th>' . htmlspecialchars($fields[$key]['Label']) . '</th>';
											}
											$str .= '</tr>';
										}
										$str .= '<tr>';
										foreach ($row as $key => $val) {
											$str .= '<td>';
												$str .= htmlspecialchars($val);
											$str .= '</div>';
										}
										$str .= '</tr>';
										$i++;
									}
								$str .= '</table>';
							}
							$str .= '</body>';
							$str .= '</html>';
							$this->contentType('application/vnd.ms-excel', 'catalog_'. date('Y-m-d') . '.xls', strlen($str));
							print $str;
							exit;
						}
					break;
					case 'generate_pins':
						// Generate PINs
						if ($_GET['generate']) {
							$sql = "SELECT id FROM directory WHERE pin=''";
							if (sqlQuery($sql, $res)) {
								while ($row = sqlFetchAssoc($res)) {
									// Generate PIN
									$l = 0;
									$pin = 0;
									while ($l < 10) { // Try at most 10 times to create a unique code
										$pin = rand(1, 9999);
										$sql = "SELECT * FROM directory WHERE pin='" . sqlEscape($pin) . "'";
										if (!sqlQuery($sql, $res)) {
											break; // Pin OK
										}
										$l++;
									}
									if ($pin) {
										$sql = "UPDATE directory SET pin = '" . sqlEscape(sprintf('%04d', $pin)) . "' WHERE id='" . sqlEscape($row['id']) . "'";
										sqlQuery($sql, $res);
									}
									else {
										// Fail silently
									}
								}
							}
							$str = '<div class="alert alert-info alert-block">';
								$str .= '<p>' . __('PIN generation complete') . '.</p>';
							$str .= '</div>';
							$this->assignGlobal('GENERATE_MESSAGE', $str);
						}
					break;
					case 'geocode':
						// Geocode
						if ($_GET['geocode']) {
							if (defined('GMAP_API_KEY') && GMAP_API_KEY) {
								$sql = "SELECT directory.id, address, city FROM directory STRAIGHT_JOIN directory_ml WHERE directory.id=directory_ml.id AND lang='" . MARKET_LANG . "' AND lat='0' AND lng='0'";
								if (sqlQuery($sql, $res)) {
									$delay = 0;
									$base_url = "https://maps.googleapis.com/maps/api/geocode/xml?key=" . GMAP_API_KEY;
									while ($row = sqlFetchAssoc($res)) {
										$address = $row['address'] . ', ' . $row['city'];
										$geocode_pending = true;
										while ($geocode_pending) {
											$request_url = $base_url . "&address=" . urlencode($address);
											$xml = simplexml_load_file($request_url);
											switch ($xml->status) {
												case 'OK':
													// Successful geocode
													$lat = $xml->result->geometry->location->lat;
													$lng = $xml->result->geometry->location->lng;
													$sql = "UPDATE directory SET lat = '" . sqlEscape($lat) . "', lng = '" . sqlEscape($lng) . "' WHERE id = '" . sqlEscape($row['id']) . "' LIMIT 1";
													sqlQuery($sql, $res1);
													$geocode_pending = false;
												break;
												case 'REQUEST_DENIED':
													// Request denied
													$str = '<div class="alert alert-error alert-block">';
														$str .= '<p>' . __('The request was denied') . '. ' . __('Make sure you have enabled the Geocoding API for your Google Maps API key in the Google APIs console') . ': <a class="blue" href="https://code.google.com/apis/console/?noredirect">https://code.google.com/apis/console/</a>.</p>';
													$str .= '</div>';
												break 3;
												case 'OVER_QUERY_LIMIT':
													if ($delay) {
														// Over query limit
														$str = '<div class="alert alert-error alert-block">';
															$str .= '<p>' . __('Over quota') . '. ' . __('The Google Geocoding API allows 2,500 requests per 24 hour period') . '.</p>';
														$str .= '</div>';
														break 3;
													}
													// Sending geocodes too fast?
													$delay = 200000; // Safe limit
												break;
												default:
													// Failed
													$geocode_pending = false;
											}
											usleep($delay);
										}
									}
								}
								else {
									$str = '<div class="alert alert-error alert-block">';
										$str .= '<p>' . __('Nothing to geocode') . '.</p>';
									$str .= '</div>';
								}
							}
							else {
								$str = '<div class="alert alert-error alert-block">';
									$str .= '<p>' . __('No Google Maps API key') . '. ' . __('Go to settings and enter your Google Maps API key') . '.</p>';
								$str .= '</div>';
							}
							if (!$str) {
								$str = '<div class="alert alert-info alert-block">';
									$str .= '<p>' . __('Geocoding complete') . '.</p>';
								$str .= '</div>';
							}
							$this->assignGlobal('GEOCODE_MESSAGE', $str);
						}
					break;
				}
			}
			else {
				if (!$this->getTemplate('EDIT_FORM')) {
					$this->enableTemplate('search-results');
					switch ($req->params[1]) {
						case 'users':
							switch ($req->params[2]) {
								case 'index':
									$this->assignGlobal('DELETE_MESSAGE', __('Related data will not be deleted.') . ' ' . __('You may consider to disable the user instead.'));
									$fields = array('label:ID;align:center;', 'is_filter:true;field:market_role_id;translate:market_role.id.title;label:' . __('Role') . ';', __('User name'), __('Email'), 'action:directory/search.html;field:directory,id;label:' . __('Directory') . ';icon:icon-th-list;align:center;', 'publish');
									$sql = "SELECT user_id AS id, market_role_id AS role, CONCAT(name, ' ', surname) as name, user_email AS email, store, user_active as publish FROM market_user WHERE user_id > 0" . $where;
								break;
								case 'roles':
									// {LANG.Roles}
									$this->assignGlobal('DELETE_MESSAGE', __('You should not delete the default roles of the application!'));
									$fields = array('label:ID;align:center;', __('Role'));
									$sql = "SELECT id, title FROM market_role WHERE id > 0" . $where;
								break;
								case 'sessions':
									// {LANG.Sessions}
									$this->disableTemplate('new_record');
									$this->assignGlobal('DELETE_MESSAGE', __('Deleting a session will logout the corresponding user!'));
									$lifetime = get_cfg_var('session.gc_maxlifetime');
									$fields = array('label:ID;align:center;', 'translate:users_sessions_user;label:' . __('User') . ';', 'translate:users_sessions_time;label:' . __('Last access') . ';align:center;');
									$sql = "SELECT id, data, FROM_UNIXTIME(expires - " . sqlEscape($lifetime) . ") FROM market_session WHERE expires > UNIX_TIMESTAMP(NOW())" . $where;
									if (!$_GET['order']) {
										$sql .= " ORDER BY expires DESC";
									}
								break;
							}
						break;
						case 'directory':
							switch ($req->params[2]) {
								case 'index':
									$this->assignGlobal('DELETE_MESSAGE', __('Related data will not be deleted.') . ' ' . __('You may consider to disable the directory record instead.'));
									$fields = array('label:ID;align:center;', 'is_filter:true;field:category;label:' . __('Category') . ';', __('Business name'), __('Address'), 'is_filter:true;field:city;label:' . __('City') . ';', 'action:marketplace/search.html;field:path;label:' . __('Marketplace') . ';icon:icon-shopping-cart;align:center;', 'action:preview.html;field:url;target:preview;label:' . __('Preview') . ';icon:icon-search;align:center;', 'publish');
									$sql = "SELECT directory.id, category, IF(business_name <> '', business_name, name) AS business_name, address, city, path, CONCAT('marketplace/show.html%3Fid=', directory.id) AS preview, publish FROM directory STRAIGHT_JOIN directory_ml STRAIGHT_JOIN directory_ps WHERE directory.id = directory_ml.id AND directory.id = directory_ps.id AND lang='" . MARKET_LANG . "'" . $where;
								break;
								case 'cities':
									// {LANG.Cities}
									$this->disableTemplate('new_record');
									$this->assignGlobal('DELETE_MESSAGE', __('Deleting a city will affect the corresponding directory records.'));
									$fields = array(__('City'));
									$sql = "SELECT city FROM directory STRAIGHT_JOIN directory_ml STRAIGHT_JOIN directory_ps WHERE directory.id = directory_ml.id AND directory.id = directory_ps.id AND lang='" . MARKET_LANG . "' AND publish='1' AND city <> ''" . $where . " GROUP BY city";
									if (!$_GET['order']) {
										$sql .= " ORDER BY city";
									}
								break;
								case 'categories':
									// {LANG.Categories}
									$this->disableTemplate('new_record');
									$this->assignGlobal('DELETE_MESSAGE', __('Deleting a category will affect the corresponding directory records.'));
									$fields = array(__('Category'));
									$sql = "SELECT category FROM directory STRAIGHT_JOIN directory_ml STRAIGHT_JOIN directory_ps WHERE directory.id = directory_ml.id AND directory.id = directory_ps.id AND lang='" . MARKET_LANG . "' AND publish='1' AND category <> ''" . $where . " GROUP BY category";
									if (!$_GET['order']) {
										$sql .= " ORDER BY category";
									}
								break;
								case 'subcategories':
									// {LANG.Subcategories}
									$this->disableTemplate('new_record');
									$this->assignGlobal('DELETE_MESSAGE', __('Deleting a subcategory will affect the corresponding directory records.'));
									$fields = array(__('Subcategory'));
									$sql = "SELECT tag FROM (
												SELECT prof1 AS tag FROM directory STRAIGHT_JOIN directory_ml STRAIGHT_JOIN directory_ps WHERE directory.id = directory_ml.id AND directory.id = directory_ps.id AND lang='" . MARKET_LANG . "' AND publish='1' AND prof1 <> ''" . $where . "
												UNION ALL
												SELECT prof2 AS tag FROM directory STRAIGHT_JOIN directory_ml STRAIGHT_JOIN directory_ps WHERE directory.id = directory_ml.id AND directory.id = directory_ps.id AND lang='" . MARKET_LANG . "' AND publish='1' AND prof2 <> ''" . $where . "
												UNION ALL
												SELECT prof3 AS tag FROM directory STRAIGHT_JOIN directory_ml STRAIGHT_JOIN directory_ps WHERE directory.id = directory_ml.id AND directory.id = directory_ps.id AND lang='" . MARKET_LANG . "' AND publish='1' AND prof3 <> ''" . $where . "
											) a
											GROUP BY tag";
									if (!$_GET['order']) {
										$sql .= " ORDER BY tag";
									}
								break;
							}
						break;
						case 'marketplace':
							$this->disableTemplate('new_record');
							switch ($req->params[2]) {
								case 'index':
									$this->assignGlobal('DELETE_MESSAGE', __('Related data will not be deleted.') . ' ' . __('You may consider to disable the directory record instead.'));
									$fields = array('label:ID;align:center;', 'translate:muted;is_filter:true;field:category;label:' . __('Category') . ';', 'translate:muted;label:' . __('Business name') . ';', 'translate:muted;label:' . __('Address') . ';', 'translate:muted;is_filter:true;field:city;label:' . __('City') . ';', 'action:marketplace/store_pages/search.html;field:path;label:' . __('Pages') . ';icon:icon-file;align:center;', 'action:offers/search.html;field:path;label:' . __('Offers') . ';icon:icon-tag;align:center;', 'action:reviews/search.html;field:path;label:' . __('Reviews') . ';icon:icon-star-empty;align:center;', 'edit', 'publish');
									$sql = "SELECT store_data.id, directory_ml.category, IF(directory_ml.business_name <> '', directory_ml.business_name, directory_ml.name) AS business_name, directory_ml.address, directory_ml.city, path, path, path, CONCAT('edit/marketplace/' , path, '/index.html') AS edit, store_data_ps.publish FROM store_data STRAIGHT_JOIN store_data_ps STRAIGHT_JOIN directory STRAIGHT_JOIN directory_ml STRAIGHT_JOIN directory_ps WHERE store_data.id = store_data_ps.id AND store_data.directory_id = directory.id AND directory.id = directory_ml.id AND directory.id = directory_ps.id AND store_data.lang='" . MARKET_LANG . "' AND  directory_ml.lang='" . MARKET_LANG . "' AND store_data.name='index' AND store_data.type='text'" . $where;
								break;
								case 'store_pages':
									// {LANG.Store pages}
									$this->assignGlobal('DELETE_MESSAGE', __('Be warned that deleting the Store home page is the same as deleting the corresponding marketplace record.'));
									$fields = array('label:ID;align:center;', 'translate:muted;label:' . __('Business name') . ';', __('Page title'), __('Url'), 'action:preview.html;field:url;target:preview;label:' . __('Preview') . ';icon:icon-search;align:center;', 'edit', 'publish');
									$sql = "SELECT store_data.id, IF(directory_ml.business_name <> '', directory_ml.business_name, directory_ml.name) AS business_name, IF (store_data.title <> '', store_data.title, IF (store_data.name = 'index', '" . __('Store home') . "', 'Untitled')) AS store_data_title, CONCAT(path, '/', store_data.name, '.html') AS url, CONCAT('marketplace/' , path, '/', store_data.name, '.html') AS preview, CONCAT('edit/marketplace/' , path, '/', store_data.name, '.html') as edit, store_data_ps.publish FROM store_data STRAIGHT_JOIN store_data_ps STRAIGHT_JOIN directory STRAIGHT_JOIN directory_ml STRAIGHT_JOIN directory_ps WHERE store_data.id = store_data_ps.id AND store_data.directory_id = directory.id AND directory.id = directory_ml.id AND directory.id = directory_ps.id AND store_data.lang='" . MARKET_LANG . "' AND  directory_ml.lang='" . MARKET_LANG . "' AND ((store_data.name='index' AND store_data.type='text') OR store_data.type='page')" . $where;
								break;
							}
						break;
						case 'offers':
							$this->disableTemplate('new_record');
							switch ($req->params[2]) {
								case 'index':
									$fields = array('label:ID;align:center;', 'translate:muted;label:' . __('Business name') . ';', __('Offer title'), 'translate:muted;label:' . __('Active') . ';align:center;', 'action:preview.html;field:url;target:preview;label:' . __('Preview') . ';icon:icon-search;align:center;', 'publish');
									$sql = "SELECT store_data.id, IF(directory_ml.business_name <> '', directory_ml.business_name, directory_ml.name) AS business_name, store_data.title, IF (date_from < NOW() AND date_to > NOW(), '" . __('Yes') . "', '" . __('No') . "') AS active, CONCAT('offers/' , path, '/', store_data.name, '.html') AS preview, store_data_ps.publish FROM store_data STRAIGHT_JOIN store_data_ps STRAIGHT_JOIN directory STRAIGHT_JOIN directory_ml STRAIGHT_JOIN directory_ps WHERE store_data.id = store_data_ps.id AND store_data.directory_id = directory.id AND directory.id = directory_ml.id AND directory.id = directory_ps.id AND store_data.lang='" . MARKET_LANG . "' AND  directory_ml.lang='" . MARKET_LANG . "' AND store_data.type='coupon'" . $where;
								break;
							}
						break;
						case 'reviews':
							$this->disableTemplate('new_record');
							switch ($req->params[2]) {
								case 'index':
									$fields = array('label:ID;align:center;', 'translate:muted;label:' . __('Business name') . ';', __('Review'), 'action:preview.html;field:url;target:preview;label:' . __('Preview') . ';icon:icon-search;align:center;', 'publish');
									$sql = "SELECT store_data.id, IF(directory_ml.business_name <> '', directory_ml.business_name, directory_ml.name) AS business_name, store_data.data, CONCAT('reviews/' , path, '/show.html#comment', store_data.id) AS preview, store_data_ps.publish FROM store_data STRAIGHT_JOIN store_data_ps STRAIGHT_JOIN directory STRAIGHT_JOIN directory_ml STRAIGHT_JOIN directory_ps WHERE store_data.id = store_data_ps.id AND store_data.directory_id = directory.id AND directory.id = directory_ml.id AND directory.id = directory_ps.id AND store_data.lang='" . MARKET_LANG . "' AND  directory_ml.lang='" . MARKET_LANG . "' AND store_data.type='comment'" . $where;
								break;
							}
						break;
						case 'html_pages':
							switch ($req->params[2]) {
								case 'index':
									$fields = array('label:ID;align:center;', __('Url'), __('Title'), 'action:preview.html;field:url;target:preview;label:' . __('Preview') . ';icon:icon-search;align:center;', 'publish');
									$sql = "SELECT page.id, url, title, url as preview, publish FROM page STRAIGHT_JOIN page_ml STRAIGHT_JOIN page_ps WHERE page.id = page_ml.id AND page.id = page_ps.id AND lang='" . MARKET_LANG . "'" . $where;
								break;
								case 'templates':
									// {LANG.Templates}
									$fields = array('label:ID;align:center;', __('File'));
									$sql = "SELECT id, CONCAT(name, '.tpl') AS template_file FROM page_template WHERE 1" . $where;
								break;
							}
						break;
					}
					
					results:
					
					// New record button
					// {LANG.New user}
					// {LANG.New role}
					// {LANG.New directory}
					// {LANG.New page}
					// {LANG.New page template}
					$this->assignGlobal('NEW_RECORD_BUTTON', '<div class="pull-right" style="margin-right: 20px;"><a class="create btn btn-warning" href="{MARKET.LWebDir}/admin/' . $req->params[1] . (($req->params[2] != 'index') ? '/' . $req->params[2] : '') . '/edit.html"><i class="icon-plus icon-white"></i> ' . __('New ' . $form_name) . '</a></div>');
					
					if ($_GET['order'] && preg_match('@(.+) (ASC|DESC)@', $_GET['order'], $matches)) {
						$order['field'] = $matches[1];
						$order['order'] = $matches[2];
						$sql .= " ORDER BY " . sqlEscape($order['field']) . " " . $order['order'];
					}
					
					list($start, $show, $total) = $this->assignNavigationValues($sql, 'default', 0, 20, 0, true);
					
					if (sqlQuery($sql, $res)) {
						
						$this->disableTemplate('no-results');
						
						$i = 0;
						$str = '<table class="table table-striped results" style="margin-bottom: 0;">';
						
						$i = 0;
						$columns = array();
						foreach ($fields as $field) {
							if (preg_match_all('@(.+):(.+);@U', $field, $matches)) {
								foreach ($matches['0'] as $key => $val) {
									$columns[$i][$matches['1'][$key]] = $matches['2'][$key];
								}
							}
							else {
								$columns[$i]['label'] = $field;
							}
							$i++;
						}
						
						$i = 0;
						while ($field = sqlFetchField($res)) {
							if ($field->name != 'path' && $field->name != 'preview') {
								$columns[$i]['name'] = $field->name;
							}
							$i++;
						}
						
						// Table header
						$i = 0;
						$str .= '<tr>';
						if (!$no_edit) {
							if (in_array('publish', $fields)) {
								$str .= '<th colspan="3" style="background: #ddd;">&nbsp</td>';
							}
							else {
								$str .= '<th colspan="2" style="background: #ddd;">&nbsp</td>';
							}
						}
						foreach ($fields as $field) {
							if ($field != 'edit' && $field != 'publish') {
								if (!($no_edit && $columns[$i]['action'])) {
									$str .= '<th data-field="' . $columns[$i]['name'] . '"';
									if (!$columns[$i]['name']) {
										$str .= ' class="NOO"';
									}
									else if ($columns[$i]['name'] == $order['field']) {
										$str .= ' class="' . $order['order'] . '"';
									}
									if ($columns[$i]['align'] || $columns[$i]['name'] == 'id') {
										$str .= ' style="';
										if ($columns[$i]['name'] == 'id') {
											$str .= 'width: 60px;';
										}
										if ($columns[$i]['align']) {
											$str .= 'text-align: ' . $columns[$i]['align'] . ';';
										}
										$str .= '"';
									}
									$str .= '><span>';
									/*
									if ($columns[$i]['is_filter']) {
										$str .= '<a href="#" data-toggle="dropdown">';
											$str .= $columns[$i]['label'];
											$str .= ' <b class="caret" style="vertical-align: middle;"></b>';
										$str .= '</a>';
										$str .= '<ul class="dropdown-menu">';
											$str .= '<li>test</li>';
										$str .= '</ul>';
									}
									else {
									*/
										$str .= $columns[$i]['label'];
									//}
									$str .= '</span></th>';
								}
							}
							$i++;
						}
						$str .= '</tr>';
						
						// Table data
						while ($row = sqlFetchArray($res)) {
							$i = 0;
							$str .= '<tr>';
							if (!$no_edit) {
								if ($row['edit']) {
									$str .= '<td style="width: 14px;"><a href="{MARKET.LWebDir}/' . $row['edit'] . '" title="' . __('Edit') . '" target="edit"><i class="icon-edit" style="margin-top: 2px;"></i></a></td>';
								}
								else {
									$str .= '<td style="width: 14px;"><a href="{MARKET.LWebDir}/admin/' . $req->params[1] . (($req->params[2] != 'index') ? '/' . $req->params[2] : '') . '/edit.html?id=' . $row[0] . '" title="' . __('Edit') . '"><i class="icon-edit" style="margin-top: 2px;"></i></a></td>';
								}
								if (isset($row['publish'])) {
									if ($row['publish']) {
										$str .= '<td style="width: 14px;"><a href="{MARKET.LWebDir}/admin/' . $req->params[1] . (($req->params[2] != 'index') ? '/' . $req->params[2] : '') . '/unpublish.html?id=' . $row[0] . '" title="' . __('Disable') . '"><i class="icon-eye-open" style="margin-top: 3px;"></i></a></td>';
									}
									else {
										$str .= '<td style="width: 14px;"><a href="{MARKET.LWebDir}/admin/' . $req->params[1] . (($req->params[2] != 'index') ? '/' . $req->params[2] : '') . '/publish.html?id=' . $row[0] . '" title="' . __('Enable') . '"><i class="icon-eye-close icon-white" style="margin-top: 3px; background-color: #b94a48; border-radius: 2px;"></i></a></td>';
									}
								}
								$str .= '<td style="width: 14px;"><a class="delete" href="{MARKET.LWebDir}/admin/' . $req->params[1] . (($req->params[2] != 'index') ? '/' . $req->params[2] : '') . '/delete.html?id=' . $row[0] . '" title="' . __('Delete') . '"><i class="icon-remove" style="margin-top: 3px;"></i></a></td>';
							}
							foreach ($fields as $field) {
								if ($field != 'edit' && $field != 'publish') {
									if ($columns[$i]['translate']) {
										$parts = explode('.', $columns[$i]['translate']);
										if (count($parts) == 3) {
											$parts[2] = preg_replace('@"@', "'", $parts[2]);
											if (!$cache[$parts[0]][$parts[1]]) {
												$sql = "SELECT `" . $parts[1] . "`, " . $parts[2] . " FROM `" . $parts[0] . "`";
												if (sqlQuery($sql, $res1)) {
													while ($row1 = sqlFetchAssoc($res1)) {
														$cache[$parts[0]][$parts[1]][$row1[$parts[1]]] = $row1[$parts[2]];
													}
												}
											}
											$row[$i] = '<span class="muted">' . htmlspecialchars($cache[$parts[0]][$parts[1]][$row[$i]]) . '</span>';
										}
										else {
											// Special
											switch($columns[$i]['translate']) {
												case 'log_type':
													$row[$i] = '<span class="label label-' . $row[$i] . '">' . $row[$i] . '</span>';
												break;
												case 'users_sessions_user':
													$data = unserialize_session($row[$i]);
													$sql = "SELECT CONCAT(name, ' ', surname) FROM market_user WHERE user_id='" . sqlEscape($data['User']['user_id']) . "'";
													if (sqlQuery($sql, $res1)) {
														$row[$i] = '<span class="muted">' . htmlspecialchars(sqlResult($res1, 0)) . '</span>';
													}
												break;
												case 'users_sessions_time':
													$row[$i] = '<span class="muted">' . htmlspecialchars(getPeriodtoDate($row[$i])) . '</span>';
												break;
												default:
													// Muted
													$row[$i] = '<span class="muted">' . htmlspecialchars($row[$i]) . '</span>';
											}
										}
									}
									else {
										$row[$i] = htmlspecialchars($row[$i]);
									}
									if (!($no_edit && $columns[$i]['action'])) {
										if ($columns[$i]['align']) {
											$str .= '<td style="text-align: ' . $columns[$i]['align'] . '"><div>';
										}
										else {
											$str .= '<td><div>';
										}
										if ($row[$i]) {
											if ($columns[$i]['action']) {
												if (!$no_edit) {
													$icon = 'icon-share-alt';
													if ($columns[$i]['icon']) {
														$icon = $columns[$i]['icon'];
													}
													$target = '';
													if ($columns[$i]['target']) {
														$target = ' target="' . $columns[$i]['target'] . '"';
													}
													if ($columns[$i]['icon'] == 'icon-search') {
														$str .= '<a href="{MARKET.LWebDir}/admin/' . $columns[$i]['action'] . '?' . $columns[$i]['field'] . '=' . $row[$i] . '"' . $target . '><i class="' . $icon . '"></i></a>';
													}
													else {
														$str .= '<a href="{MARKET.LWebDir}/admin/' . $columns[$i]['action'] . '?' . $columns[$i]['field'] . '=' . $row[$i] . '"' . $target . '><i class="' . $icon . '"></i><i class="icon-arrow-right muted"></i></a>';
													}
												}
											}
											else {
												$str .= $row[$i];
											}
										}
										else {
											$str .= '&nbsp;';
										}
										$str .= '</div></td>';
									}
								}
								$i++;
							}
							$str .= '</tr>';
						}
						$str .= '</table>';
						$this->assignGlobal('RESULTS', $str);
					}
				}
				if ($_GET['popup']) {
					$this->parseTemplate('POPUP', 'search-results');
					$this->vars['global']['POPUP'] = preg_replace('@<form.+/form>@s', '', $this->vars['global']['POPUP']);
					$this->printTemplate('POPUP');
					exit;
				}
			}
			
			// Tabs
			if ($valid_tabs[$req->params[1]]) {
				$this->enableTemplate('submenu');
				foreach ($valid_tabs[$req->params[1]] as $key => $tab) {
					$row = array();
					if ($tab) {
						if (is_array($tab)) {
							foreach ($tab as $dropdown) {
								$row = array();
								$row['title'] = __(ucfirst(preg_replace('@_@', ' ', $dropdown)));
								$row['url'] = $req->params[1] . '/' . $key . '/' . $dropdown . '.html';
								if ($dropdown == $req->params[3]) {
									$row['current'] = 'active';
								}
								$this->assignLocal('submenu-dropdown-item', 'TAB', $row);
								$this->lightParseTemplate('SUBMENU-DROPDOWN-ITEM', 'submenu-dropdown-item');
							}
							$row['title'] = __(ucfirst(preg_replace('@_@', ' ', $key)));
							if ($key == $req->params[2]) {
								$row['current'] = 'active';
							}
							$this->assignLocal('submenu-dropdown', 'TAB', $row);
							$this->parseTemplate('SUBMENU-ITEM', 'submenu-dropdown');
						}
						else {
							if ($tab == 'index') {
								$row['url'] = $req->params[1] . '/index.html';
							}
							else {
								$row['url'] = $req->params[1] . '/' . $tab . '/index.html';
							}
							$row['title'] = __(ucfirst(preg_replace('@_@', ' ', $tab)));
							if ($tab == $req->params[2]) {
								$row['current'] = 'active';
							}
							$this->assignLocal('submenu-item', 'TAB', $row);
							$this->lightParseTemplate('SUBMENU-ITEM', 'submenu-item');
						}
					}
					else {
						$row['url'] = 'index.html';
						$row['title'] = __('Index');
						if (!$req->params[2]) {
							$row['current'] = 'active';
						}
						$this->assignLocal('submenu-item', 'TAB', $row);
						$this->lightParseTemplate('SUBMENU-ITEM', 'submenu-item');
					}
				}
			}
			
			// Google maps
			$this->assignGlobal('GMAPS', array(
				'api_key' => GMAP_API_KEY,
				'center_lat' => GMAP_CENTER_LAT,
				'center_lng' => GMAP_CENTER_LNG,
				'center_zoom' => GMAP_CENTER_ZOOM,
				'fusion_table' => FUSION_TABLE_LAYER
			));
		}
		
		function getCorrectString($str) {
			$foo = iconv('UTF-8', 'UTF-8', $str);
			if ($foo != $str) {
				$str = iconv('ISO-8859-1', 'UTF-8', $str);
			}
			return $str;
		}
		
		function unQuote($str) {
			$str = trim($str);
			if (preg_match('@^".*"$@', $str)) {
				$str = substr($str, 1, -1);
			}
			$str = preg_replace('@""@', '"', $str);
			return $str;
		}
		
		function fix_toolbar($str) {
			$lng =& MARKET_Base::getRef('Lang');
			$str = preg_replace('@<a class="@', '<a class="btn ', $str);
			$str = preg_replace('@<a href="@', '<a class="btn" href="', $str);
			$str = preg_replace('@<i>' . $lng->strs['First'] . '</i>@', '<i class="icon icon-fast-backward"></i>', $str);
			$str = preg_replace('@<i>' . $lng->strs['Last'] . '</i>@', '<i class="icon icon-fast-forward"></i>', $str);
			$str = preg_replace('@<i>' . $lng->strs['Previous'] . '</i>@', '<i class="icon icon-backward"></i>', $str);
			$str = preg_replace('@<i>' . $lng->strs['Next'] . '</i>@', '<i class="icon icon-forward"></i>', $str);
			return '<div class="btn-group">' . $str . '</div>';
		}
		
	</php>
	
	<template name="css" assign="PAGE.Style">
		<link href="{MARKET.WebDir}/redist/datepicker/datepicker.css" rel="stylesheet" type="text/css" />
		<link rel="stylesheet" href="{MARKET.WebDir}/redist/sweetalert/lib/sweet-alert.css">
		<style type="text/css">
			p.no-margin { margin-bottom: 0; }
			form .help { font-size: 13px; padding: 0 0 0 10px; }
			input[readonly], select[readonly], textarea[readonly] { cursor: default; position: relative; }
			.filter { float: left ; margin-right: 10px; }
			.tr-hover td { background-color: #ddeeff !important; }
			#popup td { cursor: default; }
			.popup-remove { position: absolute; margin-top: 8px !important; margin-left: -40px; }
			.popup-open { pointer-events: none; position: absolute; margin-top: 8px !important; margin-left: -20px; }
			.hanging { position: absolute; margin-left: 240px; width: 510px; }
			@media (min-width: 1200px) { .hanging { position: absolute; margin-left: 290px; } }
			@media (min-width: 768px) and (max-width: 979px) { .hanging { position: absolute; margin-left: 186px; width: 345px; } }
			@media (max-width: 767px) { .hanging { position: inherit; margin-top: 10px !important; margin-left: 0; width: 100%; } }
			.dropdown-menu .active > a, .dropdown-menu .active > a:hover { color: #fff; }
			.add-on { margin-top: 2px; }
			.table th { cursor: pointer; }
			.table th span { padding-left: 11px; background: url("{MARKET.WebDir}/img/sort.png") 0 5px no-repeat; }
			.table th.NOO span { background: none; }
			.table th.ASC span { background: url("{MARKET.WebDir}/img/sort_ASC.png") 0 9px no-repeat; }
			.table th.DESC span { background: url("{MARKET.WebDir}/img/sort_DESC.png") 0 8px no-repeat; }
			.working:after {
				content: url({MARKET.WebDir}/img/loading.png);
				margin-left: 5px;
			}
			.home #archive-header { border-top: none; padding-top: 0;}
			.controls label { float: none; font-size: 13px; margin: 0; padding: 5px 0 0; }
			.results th { white-space: nowrap; }
			.results td > div, .latest td > div { max-height: 100px; overflow: hidden; }
			.stats { color: #999; font-size: 12px; }
			.stats span { color: #333; float: left; margin-right: 5px; font-weight: bold; font-size: 32px; }
			.admin_language { margin-top: 15px;}
			.admin_language .langdrop { margin: 0;}
			h2.header { margin-bottom: 20px; border-bottom: 1px solid #ddd; }
		</style>
	</template>
	
	<template name="js" assign="PAGE.Javascript">
		<script type="text/javascript" src="{MARKET.WebDir}/redist/datepicker/bootstrap-datepicker.js"></script>
		<if expr="'{MARKET.Lang}' == 'el'">
			<script type="text/javascript" src="{MARKET.WebDir}/redist/datepicker/bootstrap-datepicker.el.js"></script>
		</if>
		<script src="{MARKET.WebDir}/redist/sweetalert/lib/sweet-alert.min.js"></script>
		<script type="text/javascript">
			jQuery(document).ready(function() {
				
				// Delete
				$('.delete').on('click', function(e) {
					var $that = $(this);
					swal(
						{
							title: "{LANG.Delete record}",
							text: "{DELETE_MESSAGE} {LANG.Are you sure you want to delete this record?}",
							type: "warning",
							showCancelButton: true,
							cancelButtonText: "{LANG.Cancel}",
							confirmButtonColor: "#DD6B55",
							confirmButtonText: "{LANG.Yes, delete it!}",
							closeOnConfirm: false
						},
						function(isConfirm) {
							if (isConfirm) {
								window.location.href = $that.attr('href');
							}
						}
					);
					e.preventDefault();
				});
				
				// Popup
				$('.popup-input').on('click', function(e) {
					var $that = $(this);
					$('#popup .modal-header h3').text($(this).attr('data-title'));
					if ($(this).attr('data-action')) {
						$.ajax({
							'url': '{MARKET.LWebDir}/admin/' + $(this).attr('data-action') + '?popup=true',
							success: function(data) {
								$('#popup .modal-body').html(data);
								$('.results').on('click', 'td', function(e) {
									$that.val($(this).siblings().first().text());
									$('#popup').modal('hide');
								});
								$('.results')
									.on('mouseenter', 'tr', function(e) { $(this).addClass('tr-hover') })
									.on('mouseleave', 'tr', function(e) { $(this).removeClass('tr-hover') });
								$('#popup').modal('show');
							}
						});
					}
				});
				$('.popup-input').after('<i class="popup-remove icon-remove"></i><i class="popup-open icon-share"></i>');
				$('.popup-remove').on('click', function(e) {
					$(this).parent().find('input').val('');
				});
				
				// Generate PIN
				$('.generate_pin').on('click', function(e) {
					var $that = $(this);
					$that.addClass('working');
					$.ajax({
						url: 'index.html?action=getPIN',
						success: function(pin) {
							$that.removeClass('working');
							if (pin == '0000') {
								swal(
									{
										title: "{LANG.Error}",
										text: "{LANG.Could not generate PIN. Please try again.}",
										type: "warning",
										showCancelButton: false,
										confirmButtonColor: "#DD6B55",
										confirmButtonText: "OK",
										closeOnConfirm: true
									}
								);
							}
							else {
								$('#pin').val(pin);
							}
						}
					});
					e.preventDefault();
				});
				
				// Autocomplete
				$('input.typeahead').attr('autocomplete','off');
				$('input.typeahead').typeahead({
					source: function (query, process) {
						var url = "{MARKET.LWebDir}/admin/typeahead.html";
						if (this.$element.attr('id').match(/^prof/) && $('#category').val()) {
							url = "{MARKET.LWebDir}/admin/typeahead.html?filter=" + encodeURIComponent($('#category').val());
						}
						$.ajax({
							type: "POST",
							url: url,
							data: "query=" + query + "&path=" + encodeURIComponent(this.$element.attr('data-path')),
							success: function (data) {
								process(JSON.parse(data));
							}
						});
					},
					matcher: function(item) { return true; },
					sorter: function(items) { return items; },
					highlighter: function(item) { return item; }
				});
				// Datepicker
				$('.datepicker').each(function() {
					if ($(this).val() == '0000-00-00') {
						$(this).val('');
					}
				});
				$('.datepicker').datepicker({
					format: 'yyyy-mm-dd',
					startDate: '{TODAY}',
					language: '{MARKET.Lang}'
				});
				$('#date_from, #date_to').datepicker().on('changeDate', function(e){
					$('#date_from, #date_to').datepicker('hide');
				});
				
				// Readonly
				$('input[readonly]').on('focus', function() {
					$(this).blur();
				});
				
				// Sort
				$('.results th:not([data-field=""]')
					.on('click', function(e) {
						if ($(this).hasClass('ASC')) {
							rIU('order', $(this).attr('data-field') + '+DESC');
						}
						else if ($(this).hasClass('DESC')) {
							rIU('order', '');
						}
						else {
							rIU('order', $(this).attr('data-field') + '+ASC');	
						}
						e.preventDefault();
					});
					
			});
		</script>
	</template>
	
	<template name="map">
		<if expr="'{MARKET.Params.1}' == 'index' && '{MARKET.Params.2}' == 'settings'">
			<div id="map"></div>
		</if>
	</template>
	
	<div class="container" style="position: relative;">
		
		<div class="row">
			<div class="span12">
				<header id="archive-header">
					<h1>{PAGE.Title}</h1>
				</header>
			</div>
		</div>
		
		<div class="row">
			<div class="span9">
				
				<template name="submenu" disabled="true">
				<div class="pull-right">
					<template name="admin_language_cnt">
						<div id="lang-select" class="admin_language pull-left">
							<form action="{MARKET.Request}">
								<select id="lang" name="lang" class="span2">
									<template name="language">
										<option {ROW.selected} title="{MARKET.WebDir}/{ROW.lang}/{MARKET.Request}" value="{ROW.lang}">{ROW.language}</option>
									</template>
								</select><input value="{LANG.Select}" type="submit" />
							</form>
						</div>
					</template>
				</div>
					<div id="submenu" style="background: url({MARKET.WebDir}/img/inner-shadow.png) repeat-x; padding: 10px 0;">
						<ul class="nav nav-pills" style="margin: 0;">
							<template name="submenu-item">
								<li class="{TAB.current}"><a href="{MARKET.LWebDir}/admin/{TAB.url}">{TAB.title}</a></li>
							</template>
							<template name="submenu-dropdown-disabled" disabled="true">
								<template name="submenu-dropdown">
									<li class="{TAB.current} dropdown"><a class="dropdown-toggle" data-toggle="dropdown" href="#">{TAB.title} <b class="caret"></b></a>
										<ul class="dropdown-menu">
											<template name="submenu-dropdown-item">
												<li class="{TAB.current}"><a href="{MARKET.LWebDir}/admin/{TAB.url}">{TAB.title}</a></li>
											</template>
										</ul>
									</li>
								</template>
							</template>
						</ul>
					</div>
				</template>
				
				<template name="index" disabled="true">
					
					<!-- INDEX -->
					
					<div class="row stats">
						<div class="span2">
							<div class="well well-small">
								<span>{STATS.directory}</span> {LANG.directory records}
							</div>
						</div>
						<div class="span2">
							<div class="well well-small">
								<span>{STATS.stores}</span> {LANG.marketplace stores}
							</div>
						</div>
						<div class="span2">
							<div class="well well-small">
								<span>{STATS.offers}</span> {LANG.offers}
							</div>
						</div>
						<div class="span2">
							<div class="well well-small">
								<span>{STATS.reviews}</span> {LANG.reviews}
							</div>
						</div>
					</div>
					<h2 class="header">{LANG.Latest additions}</h2>
					<template name="latest">
						<div class="well well-small white">
							<div class="pull-right" style="margin-top: 5px;"><a class="blue" href="{MARKET.LWebDir}/admin/{LATEST.name}/index.html">{LANG.View all} <i class="icon-arrow-right"></i></a></div>
							<h3>{LATEST.title}</h3>
							<style>
								.latest td:nth-child(1) { width: 35%; }
								.latest td:nth-child(2) { width: 55%; }
								.latest td:nth-child(3) { width: 10%; }
							</style>
							{LATEST.results}
						</div>
					</template>
					
				</template>
				
				<template name="settings" disabled="true">
					
					<!-- SEETINGS -->
					
					<template name="settings_js" assign="PAGE.Javascript">
						<script type="text/javascript" src="http://maps.googleapis.com/maps/api/js?key={GMAPS.api_key}&sensor=true"></script>
						<script type="text/javascript" src="{MARKET.WebDir}/redist/gmaps.js"></script>
						<script>
						
							var map;
							
							jQuery(document).ready(function() {
								
								map = new GMaps({
									div: '#map',
									lat: {GMAPS.center_lat},
									lng: {GMAPS.center_lng},
									zoom: {GMAPS.center_zoom},
									panControl: true,
									zoomControl: true,
									mapTypeControl: false,
									scaleControl: false,
									streetViewControl: false,
									overviewMapControl: false,
								});
								
								if ('{GMAPS.fusion_table}') {
									map.loadFromFusionTables({
										query: {
											select: '\'location\'',
											from: '{GMAPS.fusion_table}'
										},
										clickable: false
									});
								}
								
								GMaps.on('center_changed', map, function() {
									var location = map.getCenter();
									$('#GMAP_CENTER_LAT').val(location.lat());
									$('#GMAP_CENTER_LNG').val(location.lng());
								});
								
								GMaps.on('zoom_changed', map, function() {
									zoomLevel = map.getZoom();
									$('#GMAP_CENTER_ZOOM').val(zoomLevel);
								});
								
								var $target = $('#MARKET_SMTP_HOST');
								if ($target.val()) {
									if ($target.val().match(/^(ssl|tls):\/\/(.+):\d+$/)) {
										$('#MARKET_SMTP_TLS').prop('checked', true);
									}
								}
							});

						</script>
					</template>
					
					{SETTINGS_MESSAGE}
					
					<template name="settings_form">
						<form method="POST" action="" class="form-horizontal" style="padding: 10px;">
							
							<h2 class="header">{LANG.Server timezone}</h2>
							<fieldset>
								<div class="control-group">
									<label for="MARKET_TIMEZONE" class="control-label"><b>{LANG.Timezone}:</b></label>
									<div class="controls">
										{MARKET_TIMEZONE_SELECT}
									</div>
								</div>
							</fieldset>
							
							<h2 class="header">{LANG.Mail settings}</h2>
							<fieldset>
								<div class="control-group">
									<label class="control-label"><b>{LANG.Connection settings}:</b></label>
									<div class="controls">
										<label for="MARKET_SMTP_HOST" class="span3">{LANG.SMTP host}:</label><input type="text" value="{MARKET_SMTP_HOST}" name="MARKET_SMTP_HOST" id="MARKET_SMTP_HOST" class="span3"><div style="font-size: 13px; padding: 0 0 0 10px;"><input type="checkbox" value="" name="" id="MARKET_SMTP_TLS"> {LANG.SSL/TLS encryption}</div>
										<label for="MARKET_SMTP_USER" class="span3">{LANG.SMTP user}:</label><input type="text" value="{MARKET_SMTP_USER}" name="MARKET_SMTP_USER" id="MARKET_SMTP_USER" class="span3">
										<label for="MARKET_SMTP_PASS" class="span3">{LANG.SMTP password}:</label><input type="text" value="{MARKET_SMTP_PASS}" name="MARKET_SMTP_PASS" id="MARKET_SMTP_PASS" class="span3">
									</div>
								</div>
								<div class="control-group">
									<label class="control-label"><b>{LANG.Outgoing email}:</b></label>
									<div class="controls">
										<label for="MARKET_SMTP_FROM" class="span3">{LANG.Email from}:</label><input type="text" value="{MARKET_SMTP_FROM}" name="MARKET_SMTP_FROM" id="MARKET_SMTP_FROM" class="span3">
										<label for="MARKET_SMTP_FROM_NAME" class="span3">{LANG.Name from}:</label><input type="text" value="{MARKET_SMTP_FROM_NAME}" name="MARKET_SMTP_FROM_NAME" id="MARKET_SMTP_FROM_NAME" class="span3">
									</div>
								</div>
								<div class="control-group">
									<label for="SUPPORT_EMAIL" class="control-label"><b>{LANG.Support email address}:</b></label>
									<div class="controls">
										<input type="text" value="{SUPPORT_EMAIL}" name="SUPPORT_EMAIL" id="SUPPORT_EMAIL" class="span3">
									</div>
								</div>
							</fieldset>
							
							<h2 class="header">{LANG.Google analytics}</h2>
							<fieldset>
								<div class="control-group">
									<label for="ANALYTICS_TRACKING_CODE" class="control-label"><b>{LANG.Tracking code}:</b></label>
									<div class="controls">
										<input type="text" value="{ANALYTICS_TRACKING_CODE}" name="ANALYTICS_TRACKING_CODE" id="ANALYTICS_TRACKING_CODE" class="span3">
										<div class="help">{LANG.Enter your Google analytics tracking code} (UA-XXXXXXXX-X)</div>
									</div>
								</div>
							</fieldset>
							
							<h2 class="header">{LANG.Google maps}</h2>
							<fieldset>
								<div class="control-group">
									<label for="GMAP_API_KEY" class="control-label"><b>{LANG.Google Maps API key}:</b></label>
									<div class="controls">
										<input type="text" value="{GMAP_API_KEY}" name="GMAP_API_KEY" id="GMAP_API_KEY" class="span3">
										<div class="help">{LANG.Get your key from}: <a class="blue" target="_new" href="https://code.google.com/apis/console">https://code.google.com/apis/console</a></div>
									</div>
								</div>
								<div class="control-group">
									<label class="control-label"><b>{LANG.Default map center}:</b></label>
									<div class="controls">
										<label for="GMAP_CENTER_LAT" class="span3">{LANG.Latitude}:</label><input type="text" value="{GMAP_CENTER_LAT}" name="GMAP_CENTER_LAT" id="GMAP_CENTER_LAT" class="span3">
										<label for="GMAP_CENTER_LNG" class="span3">{LANG.Longitude}:</label><input type="text" value="{GMAP_CENTER_LNG}" name="GMAP_CENTER_LNG" id="GMAP_CENTER_LNG" class="span3">
									</div>
								</div>
								<div class="control-group">
									<label for="GMAP_CENTER_ZOOM" class="control-label"><b>{LANG.Default zoom level}:</b></label>
									<div class="controls">
										<input type="text" value="{GMAP_CENTER_ZOOM}" name="GMAP_CENTER_ZOOM" id="GMAP_CENTER_ZOOM" class="span3">
										<div class="help"><b>{LANG.Hint}:</b> {LANG.Try to reposition the map above}...</div>
									</div>
								</div>
							</fieldset>
							
							<h2 class="header">{LANG.Google fusion table layer}</h2>
							<fieldset>
								<div class="control-group">
									<label for="FUSION_TABLE_LAYER" class="control-label"><b>{LANG.Table ID}:</b></label>
									<div class="controls">
										<input type="text" value="{FUSION_TABLE_LAYER}" name="FUSION_TABLE_LAYER" id="FUSION_TABLE_LAYER" class="span3">
										<div class="help">{LANG.Enter the tableId of a public shared fusion table}.<br><a class="blue" href="?action=download_list">{LANG.Click here}</a> {LANG.to download a list of location points in your directory}.<br>{LANG.For more information read the tutorial at}: <a class="blue" target="_new" href="https://support.google.com/fusiontables/answer/2527132">https://support.google.com/fusiontables/answer/2527132</a></div>
									</div>
								</div>
							</fieldset>
							
							<h2 class="header">{LANG.reCAPTCHA settings}</h2>
							<fieldset>
								<div class="control-group">
									<label for="RECAPTCHA_PRIVATE_KEY" class="control-label"><b>{LANG.reCAPTCHA private key}:</b></label>
									<div class="controls">
										<input type="text" value="{RECAPTCHA_PRIVATE_KEY}" name="RECAPTCHA_PRIVATE_KEY" id="RECAPTCHA_PRIVATE_KEY" class="span3">
									</div>
								</div>
								<div class="control-group" style="margin-bottom: 0;">
									<label for="RECAPTCHA_PUBLIC_KEY" class="control-label"><b>{LANG.reCAPTCHA public key}:</b></label>
									<div class="controls">
										<input type="text" value="{RECAPTCHA_PUBLIC_KEY}" name="RECAPTCHA_PUBLIC_KEY" id="RECAPTCHA_PUBLIC_KEY" class="span3">
										<div class="help">{LANG.Get your keys from}: <a class="blue" target="_new" href="https://www.google.com/recaptcha/admin/create">https://www.google.com/recaptcha/admin/create</a></div>
									</div>
								</div>
							</fieldset>
							
							<div class="form-actions white" style="border-top: none;">
								<button class="btn btn-primary" type="submit">{LANG.Update settings}</button>
							</div>
							
						</form>
					</template>
					
				</template>
				
				
				<template name="import" disabled="true">
					
					<!-- IMPORT -->
					<link href="{MARKET.WebDir}/redist/jquery-ui.min.css" rel="stylesheet" type="text/css" />
					<style>
						.upload-preview { height: 410px; overflow: hidden; overflow-x: scroll; }
						.upload-preview-overlay { position: absolute; margin-top: 35px; width: 830px; height: 355px; background: url("{MARKET.WebDir}/img/upload-preview-overlay.png"); pointer-events: none; }
						.target { margin-bottom: 4px; font-weight: bold; text-align: center; height: 20px; border: 2px dotted #ccc; background: #f9f9f9; transition: all 0.5s; }
						.target a:hover { text-decoration: none; }
						.target.ui-state-active { border-color: #cc4400; background: #fff; }
						.target a { margin-left: 13px; }
						.tags span { display: inline-block; white-space: nowrap; }
						.tags a { cursor: default; }
						.upload-preview tr:nth-child(1) td { background-color: #eee !important; }
						.upload-preview td > div { max-height: 50px; min-width: 40px; overflow: hidden; }
					</style>
					
					<template name="import/js" assign="PAGE.Javascript">
						<script type="text/javascript" src="{MARKET.WebDir}/redist/jquery-ui.min.js"></script>
						<script>
							jQuery(document).ready(function() {
								// File input
								$('input[type=file]').change(function() {
									$('#appended').val($(this).val());
								});
								
								// Has headers
								$('#has_headers').on('click', function(e) {
									var $target = $('.upload-preview').find('tr:eq(1)');
									if ($(this).is(":checked")) {
										$target.hide();
									}
									else {
										$target.show();
									}
								});
								
								// Drag and drop
								$('.tags span').draggable({
									revert: 'invalid',
									stack: ".tags span",
									start: function(event, ui) {
										if ($(this).css('position') == 'static') {
											$(this).css({position:'absolute'});
										}
									}
								});
								$('div > .tags').droppable({
									accept: '.tags span',
									drop: function(event, ui) {
										$(this).append($(ui.draggable));
										$(ui.draggable).css({position:'static'});
										checkOptions();
									}
								});
								$('.target').droppable({
									hoverClass: "ui-state-active",
									accept: '.tags span',
									drop: function(event, ui) { 
										$(this).droppable('option', 'accept', ui.draggable);
										$(this).append($(ui.draggable));
										$(ui.draggable).css({position:'static'});
										checkOptions();
									},
									out: function(event, ui){
										$(this).droppable('option', 'accept', '.tags span');
									}   
								});
								
								setTimeout(function() { $('.alert').fadeOut() }, 5000);
								
								checkOptions();
								
							});
							
							function checkOptions() {
								if ($('tr.tags a[id="pin"]').length) {
									disableOption('auto_generate');
								}
								if ($('tr.tags a[id="address"]').length && $('tr.tags a[id="city"]').length) {
									enableOption('auto_geocode');
								}
								if ($('tr.tags a[id="lat"]').length || $('tr.tags a[id="lng"]').length) {
									disableOption('auto_geocode');
								}
							}
							
							function disableOption(option) {
								var $that = $('#' + option);
								$that.prop('checked', false);
								$that.prop('disabled', true);
								$('label[for="' + option + '"]').addClass('muted');
							}
							
							function enableOption(option) {
								var $that = $('#' + option);
								$that.prop('disabled', false);
								$('label[for="' + option + '"]').removeClass('muted');
							}
							
							function addColumns() {
								var columns = [];
								$('.target').each(function(i) { columns[i] = $(this).find('a').attr('id') });
								$('#columns').val(columns.join());
							}
							
						</script>
					</template>
					<template name="upload">
						<div class="well white">
							<h2 class="header">{LANG.File import}</h2>
							{UPLOAD_MESSAGE}
							<form class="well" action="" method="post" enctype="multipart/form-data">
								<label>{LANG.Select file}:</label>
								<input id="lefile" name="file" type="file" accept="application/vnd.ms-excel" style="visibility:hidden; position:absolute;">
								<div class="input-append">
									<input id="appended" class="input-large" type="text" readonly="readonly" onclick="$('input[id=lefile]').click();" style="cursor:auto; background-color:#fff">
									<a class="btn" onclick="$('input[id=lefile]').click();">{LANG.Select}</a>
								</div>
								<button type="submit" class="btn btn-primary">{LANG.Import}</button>
							</form>
						</div>
					</template>
					<template name="upload-preview">
						<form class="well white" action="" method="POST" onsubmit="addColumns()">
							<h2 class="header">{LANG.File import}</h2>
							
							<p>{LANG.Drag and drop the field names to the corresponding columns of the file}.</p>
							
							<div class="well well-small">
								<div class="tags" style="min-height: 50px;">
									{TAGS}
								</div>
								<div class="clearfix"></div>
							</div>
							
							<div class="pull-right">
								<a class="btn" href="?last=true"><i class="icon-repeat"></i> {LANG.Last configuration}</a> &nbsp
								<a class="btn" href=""><i class="icon-refresh"></i> {LANG.Reset}</a>
							</div>
							
							<div style="margin: 25px 0 5px;">
								<input style="margin: 0;" type="checkbox" value="1" name="has_headers" id="has_headers"> <label for="has_headers" style="display: inline-block; font-size: 13px;">{LANG.My data has headers}</label>
								<input style="margin: 0 0 0 20px;" type="checkbox" value="1" name="auto_generate" id="auto_generate"> <label for="auto_generate" style="display: inline-block; font-size: 13px;">{LANG.Auto generate PIN}</label>
								<input style="margin: 0 0 0 20px;" type="checkbox" value="1" name="auto_geocode" id="auto_geocode" disabled="disabled"> <label for="auto_geocode" class="muted" style="display: inline-block; font-size: 13px;">{LANG.Auto geocode}</label>
							</div>
							
							<div class="clearfix"></div>
							
							{RESULTS}
							
							<p style="border-top:1px solid #ccc; padding-top: 10px;">
								<button type="cancel" class="btn" onclick="$('input[name=response]').val('cancel');">{LANG.Cancel}</button> &nbsp;
								<button type="submit" class="btn btn-primary" onclick="$('input[name=response]').val('ok');">{LANG.Import}</button>
							</p>
							
							<input name="response" type="hidden">
							<input id="columns" name="columns" type="hidden">
						</form>
					</template>
					
				</template>
				
				<template name="export" disabled="true">
					
					<!-- EXPORT -->
					
					<div class="well white">
						<h2 class="header">{LANG.File export}</h2>
						<div class="well">
							<p>{LANG.Click the button to export the catalog in "HTML for MS Excel" format}.</p>
							<p><small><b>{LANG.Note}:</b> {LANG.Excel may complain about format / extension mismatch, but it is safe to load the file anyway}.</small></p>
							<a href="?export=true" class="btn btn-primary">{LANG.Export}</a>
						</div>
					</div>
					
				</template>
				
				<template name="generate_pins" disabled="true">
					
					<!-- GENERATE PINS -->
					
					<div class="well white">
						<h2 class="header">{LANG.Generate Pins}</h2>
						{GENERATE_MESSAGE}
						<div class="well">
							<p>{LANG.Click the button to generate missing pins in your catalog}.</p>
							<a href="?generate=true" class="btn btn-primary">{LANG.Generate}</a>
						</div>
					</div>
					
				</template>
				
				<template name="geocode" disabled="true">
					
					<!-- GEOCODE -->
					
					<div class="well white">
						<h2 class="header">{LANG.Geocode}</h2>
						{GEOCODE_MESSAGE}
						<div class="well">
							<p>{LANG.Click the button to geocode missing locations in your catalog}.</p>
							<p><small><b>{LANG.Note}:</b> {LANG.You should have enabled the Geocoding API for your Google Maps API key}.</small></p>
							<a href="?geocode=true" class="btn btn-primary">{LANG.Geocode}</a>
						</div>
					</div>
					
				</template>
				
				<template name="edit-form" disabled="true">
					
					<!-- EDIT FORM -->
					
					<form method="POST" action="" class="form-horizontal" style="padding: 10px;">
						<h2 class="header">{FORM_ACTION}</h2>
						{EDIT_MESSAGE}
						{EDIT_FORM}
						<div class="form-actions" style="border-top: none;">
							<a class="btn" href="javascript:history.go(-1);">{LANG.Cancel}</a>
							<button class="btn btn-primary" type="submit">{LANG.Save record}</button>
						</div>
						<p><small>* {LANG.Required fields}&nbsp;&nbsp;&nbsp;&nbsp;ˣ {LANG.Suggested fields}</small></p>
						<input type="hidden" name="id" value="{_SAFE_GET.id}">
					</form>
				</template>
				
				<template name="form-items" disabled="true">
				
					<!-- FORM ITEMS -->
					
					<template name="form/text">
						<div class="control-group">
							<label for="{FIELD.Field}" class="control-label"><b>{FIELD.Label}:</b></label>
							<div class="controls">
								<input type="{FIELD.Type}" value="{FIELD.Value}" name="{FIELD.Field}" id="{FIELD.Field}"{FIELD.Class}{FIELD.Properties}>
								{FIELD.Help}
							</div>
						</div>
					</template>
					<template name="form/textarea">
						<div class="control-group">
							<label for="{FIELD.Field}" class="control-label"><b>{FIELD.Label}:</b></label>
							<div class="controls">
								<textarea type="{FIELD.Type}" name="{FIELD.Field}" id="{FIELD.Field}" rows="3"{FIELD.Class}{FIELD.Properties}>{FIELD.Value}</textarea>
								{FIELD.Help}
							</div>
						</div>
					</template>
					<template name="form/textarea/html">
						<template name="form/textarea/html/css" assign="PAGE.Style">
							<link href="{MARKET.WebDir}/redist/bootstrap-wysihtml5/dist/bootstrap-wysihtml5-0.0.2.css" rel="stylesheet" type="text/css" />
							<style>
								.wysihtml5-toolbar li:nth-child(2) {
									float: none;
								}
							</style>
						</template>
						<template name="form/textarea/html/js" assign="PAGE.Javascript">
							<script type="text/javascript" src="{MARKET.WebDir}/redist/bootstrap-wysihtml5/lib/js/wysihtml5-0.3.0.min.js"></script>
							<script type="text/javascript" src="{MARKET.WebDir}/redist/bootstrap-wysihtml5/dist/bootstrap-wysihtml5-0.0.2.min.js"></script>
							<if expr="'LOCALE'">
								<script type="text/javascript" src="{MARKET.WebDir}/redist/bootstrap-wysihtml5/src/locales/bootstrap-wysihtml5.{LOCALE}.js"></script>
							</if>
							<script>
								jQuery(document).ready(function() {
									$('.html_editor').wysihtml5({locale: "{LOCALE}"});
								});
							</script>
						</template>
						<div class="control-group">
							<label for="{FIELD.Field}" class="control-label"><b>{FIELD.Label}:</b></label>
							<div class="controls well well-small" style="margin-bottom: 0;">
								<textarea type="{FIELD.Type}" name="{FIELD.Field}" id="{FIELD.Field}" rows="10" class="html_editor span6" style="width: 98%"{FIELD.Properties}>{FIELD.Value}</textarea>
								{FIELD.Help}
							</div>
						</div>
					</template>
					<template name="form/select">
						<div class="control-group">
							<label for="{FIELD.Field}" class="control-label"><b>{FIELD.Label}:</b></label>
							<div class="controls">
								<select name="{FIELD.Field}" id="{FIELD.Field}"{FIELD.Class}{FIELD.Properties}>
									<template name="form/select/option">
										<option value="{OPTION.id}"{OPTION.selected}>{OPTION.title}</option>
									</template>
								</select>
								{FIELD.Help}
							</div>
						</div>
					</template>
					<template name="form/checkbox">
						<div class="control-group">
							<label for="{FIELD.Field}" class="control-label"><b>{FIELD.Label}:</b></label>
							<div class="controls">
								<input type="hidden" value="0" name="{FIELD.Field}">
								<input type="checkbox" value="1" name="{FIELD.Field}" id="{FIELD.Field}"{FIELD.Properties}>
								{FIELD.Help}
							</div>
						</div>
					</template>
					<template name="form/group">
						<div class="control-group">
							<label class="control-label"><b>{FIELD.Group}:</b></label>
							<div class="controls">
								{FORM/GROUP/TEXT}
							</div>
						</div>
					</template>
					<template name="form/group/text">
						<label for="{FIELD.Field}" class="span3">{FIELD.Label}:</label><input type="text" value="{FIELD.Value}" name="{FIELD.Field}" id="{FIELD.Field}"{FIELD.Class}{FIELD.Properties}>
						{FIELD.Help}
					</template>
					<template name="form/map">
						<style>
							#map { height: 290px; }
						</style>
						<template name="form/map/js" assign="PAGE.Javascript">
							<script type="text/javascript" src="http://maps.googleapis.com/maps/api/js?key={GMAPS.api_key}&sensor=true"></script>
							<script type="text/javascript" src="{MARKET.WebDir}/redist/gmaps.js"></script>
							<script>
							
								var map;
								var marker;
								
								jQuery(document).ready(function() {
									
									map = new GMaps({
										div: '#map',
										lat: {GMAPS.center_lat},
										lng: {GMAPS.center_lng},
										zoom: 16,
										panControl: false,
										streetViewControl: false
									});
									
									if ($('#lat').val() && $('#lng').val()) {
										marker = map.addMarker({lat: $('#lat').val(), lng: $('#lng').val(), draggable: true});
									}
									else {
										marker = map.addMarker({lat: {GMAPS.center_lat}, lng: {GMAPS.center_lng}, draggable: true});
									}
									map.fitZoom();
									setTimeout(function() {
										if (map.getZoom() > map.zoom) map.setZoom(map.zoom);
									}, 100);
									
									google.maps.event.addListener(marker, "dragend", function (e) {
										var location = e.latLng;
										$('#lat').val(location.lat());
										$('#lng').val(location.lng());
									});
									
									$('.geolocate').on('click', function(e) {
										var $that = $(this);
										$that.addClass('working');
										$.ajax({
											url: 'https://maps.googleapis.com/maps/api/geocode/json?key={GMAPS.api_key}&address=' + encodeURIComponent($('#address').val() + ', ' + $('#city').val()),
											success: function(data) {
												$that.removeClass('working');
												if (data.status == 'OK') {
													var location = data.results[0].geometry.location;
													marker.setPosition(location);
													map.panTo(location);
													$('#lat').val(location.lat);
													$('#lng').val(location.lng);
												}
												else {
													swal(
														{
															title: "{LANG.Error}",
															text: "{LANG.Location not found.}",
															type: "warning",
															showCancelButton: false,
															confirmButtonColor: "#DD6B55",
															confirmButtonText: "OK",
															closeOnConfirm: true
														}
													);
												}
											}
										});
										e.preventDefault();
									});
									
								});
							</script>
						</template>
						<div class="hanging" style="margin-top: -85px;">
							<a class="btn geolocate" style="margin-bottom: 5px;"href="#"><i class="icon-map-marker"></i> {LANG.Geolocate}</a>
							<div id="map"></div>
						</div>
					</template>
					
				</template>
				
				<template name="search-results" disabled="true">
					
					<!-- RESULTS -->
					
					<form class="well well-small form-inline" action="search.html">
						<label><b>{LANG.Search}:</b></label>
						&nbsp;
						<input name="q" type="text" value="{_SAFE_GET.q}" placeholder="{LANG.Keywords}">
						&nbsp;
						<button class="btn btn-primary" type="submit">{LANG.Go}</button>
					</form>
					<template name="search-toolbar">
						<div id="toolbar" style="margin-bottom: 10px;">
							<div class="pull-left">
								<div class="pull-left" style="margin-top: 5px;">{LANG.Found} {NAV.Found}</div>
								<div class="pull-left" style="margin: 5px 0 0 20px;">{FILTERS}</div>
							</div>
							<div class="pull-right">{fix_toolbar:NAV.Toolbar}</div>
							<template name="new_record">
								{NEW_RECORD_BUTTON}
							</template>
							<div class="clearfix"></div>
						</div>
					</template>
					<template name="results">
						<table class="table table-striped" style="margin-bottom: 0;"><tr><td></td></tr></table>
					</template>
					<template name="no-results">
						<div class="alert alert-info info well">
							<button class="close" data-dismiss="alert" type="button">×</button>
							{LANG.No results}...
						</div>
					</template>
					<template name="pagination">
						<div class="double-border">
							<p><small><span>{NAV.Pages}</span></small></p>
						</div>
					</template>
					
				</template>
				
			</div>
			
			<div class="menu span3">
				<ul class="well nav nav-list">
					<li><h3 style="border-bottom: 1px solid #ccc;">{LANG.Administration}</h3></li>
					<li class="{CURRENT.admin_index}"><a href="{MARKET.LWebDir}/admin/index.html"><i class="icon-home"></i> {LANG.Home}</a></li>
					<li class="{CURRENT.admin_users}"><a href="{MARKET.LWebDir}/admin/users/index.html"><i class="icon-user"></i> {LANG.Users}</a></li>
					<li class="{CURRENT.admin_directory}"><a href="{MARKET.LWebDir}/admin/directory/index.html"><i class="icon-th-list"></i> {LANG.Directory}</a></li>
					<li class="{CURRENT.admin_marketplace}"><a href="{MARKET.LWebDir}/admin/marketplace/index.html"><i class="icon-shopping-cart"></i> {LANG.Marketplace}</a></li>
					<li class="{CURRENT.admin_offers}"><a href="{MARKET.LWebDir}/admin/offers/index.html"><i class="icon-tag"></i> {LANG.Offers}</a></li>
					<li class="{CURRENT.admin_reviews}"><a href="{MARKET.LWebDir}/admin/reviews/index.html"><i class="icon-star-empty"></i> {LANG.Reviews}</a></li>
					<li class="{CURRENT.admin_html_pages}"><a href="{MARKET.LWebDir}/admin/html_pages/index.html"><i class="icon-file"></i> {LANG.HTML Pages}</a></li>
				</ul>
			</div>
		</div>
		
	</div>
	
	<div class="modal hide fade" id="popup">
		<div class="modal-header">
			<a class="close" data-dismiss="modal">×</a>
			<h3>{LANG.Select}</h3>
		</div>
		<div class="modal-body">
		</div>
	</div>
</template>