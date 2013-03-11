<template parent="main">
	
	<php>
		
		if (defined('IN_MARKET')) {
			
			switch ($_SERVER['REQUEST_METHOD']) {
				case 'GET':
					if ($_GET['action']) {
						switch ($_GET['action']) {
							case 'getSliderFiles':
								header('Vary: Accept');
								if (isset($_SERVER['HTTP_ACCEPT']) && (strpos($_SERVER['HTTP_ACCEPT'], 'application/json') !== false)) {
									header('Content-type: application/json');
								}
								else {
									header('Content-type: text/plain');
								}
								$files = array();
								if ($sql1) {
									$sql1 .= " AND directory_id='" . sqlEscape($row['id']) . "'";
									if (sqlQuery($sql1, $res1)) {
										while ($row1 = sqlFetchAssoc($res1)) {
											$file['name'] = basename($row1['data']);
											$file['size'] = MARKET_Filter::b2KB(filesize(MARKET_ROOT_DIR . '/' . $row1['data']));
											$file['url'] = 'http://' . $_SERVER['HTTP_HOST'] . '/' . MARKET_WEB_DIR . '/' . $row1['data'];
											$file['thumbnail_url'] = 'http://' . $_SERVER['HTTP_HOST'] . '/' . MARKET_Filter::createThumbnail($row1['data'], '80', false);
											$files[] = $file;
										}
									}
								}
								print '{"files":' . json_encode($files) . '}';
							break;
						}
					}
				break;
				case 'POST':
					if ($_SESSION['User']['market_role_id'] == 2 && $_SESSION['User']['store']) {
						if (isset($_POST['filename']) || isset($_POST['remove_filename'])) {
							// Slider
							if ($_POST['source'] == 'slider') {
								if (isset($_POST['filename'])) {
									$files = preg_split('@\|@', $_POST['filename'], -1, PREG_SPLIT_NO_EMPTY);
									foreach ($files as $file) {
										$file = preg_replace('@^' . MARKET_WEB_DIR . '/@', '', urldecode($file));
										if (@is_file(MARKET_ROOT_DIR . '/' . $file)) {
											// Insert image
											$sql = "SELECT MAX(ord) FROM store_data WHERE type='image' AND name='index' AND directory_id='" . sqlEscape($_SESSION['User']['store']) . "'";
											if (sqlQuery($sql, $res)) {
												$ord = sqlResult($res, 0) + 1;
											}
											else {
												$ord = 1;
											}
											$sql = "INSERT INTO store_data (id, directory_id, name, type, data, ord) VALUES ('', '" . sqlEscape($_SESSION['User']['store']) . "', 'index', 'image', '" . sqlEscape($file) . "', '" . sqlEscape($ord) . "')";
											if ($image_id = sqlQuery($sql, $res)) {
												// Insert image permissions
												$sql = "INSERT INTO store_data_ps (id, creator, created, owner, role, updated, ups, gps, wps, publish) VALUES('" . $image_id . "', '" . $_SESSION['User']['user_id'] . "', NOW(), '" . $_SESSION['User']['user_id'] . "', '" . $_SESSION['User']['market_role_id'] . "', NOW(), '7', '2', '2', '1')";
												sqlQuery($sql, $res);
											}
										}
									}
								}
								if (isset($_POST['remove_filename'])) {
									$files = preg_split('@\|@', $_POST['remove_filename'], -1, PREG_SPLIT_NO_EMPTY);
									foreach ($files as $file) {
										$sql = "DELETE FROM store_data WHERE directory_id='" . sqlEscape($_SESSION['User']['store']) . "' AND name='index' AND type='image' AND data='" . sqlEscape($file) . "'";
										if ($image_id = sqlQuery($sql, $res)) {
											$sql = "DELETE FROM store_data_ps WHERE id='" . sqlEscape($image_id) . "'";
											sqlQuery($sql, $res);
										}
									}
								}
							}
							else {
								// User clicked the OK button
								print MARKET_Filter::createThumbnail(preg_replace('@^' . MARKET_WEB_DIR . '/@', '', urldecode($_POST['filename'])), '240', true);
							}
						}
						else {
							require(MARKET_ROOT_DIR . '/redist/fileupload/server/php/UploadHandler.php');
							$this->makeDir(MARKET_ROOT_DIR . '/uploads/' . $_SESSION['User']['user_id'] . '/');
							$this->makeDir(MARKET_ROOT_DIR . '/uploads/' . $_SESSION['User']['user_id'] . '/thumbnail/');
							$options = array(
								'upload_dir' => MARKET_ROOT_DIR . '/uploads/' . $_SESSION['User']['user_id'] . '/',
								'upload_url' => MARKET_WEB_DIR . '/uploads/' . $_SESSION['User']['user_id'] . '/',
								'image_versions' => array(
									'thumbnail' => array(
										'max_width' => 240,
										'max_height' => 240
									)
								)
							);
							$upload_handler = new UploadHandler($options);
							$upload_handler->post(false);
						}
					}
					break;
				default:
					$req =& $this->getRef('Request');
					$req->httpError(405); // Not Allowed
			}
		}
		exit;
		
	</php>
	
</template>