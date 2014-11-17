<template parent="main" assign="PAGE.Body">
	
	<php>
		
		// Force SQL class load
		sqlQuery('SELECT foo', $res);
		
		$req =& $this->getRef('Request');
		
		$SELECT = "*, IF (business_name = '', name, business_name) AS title";
		$FROM = "directory STRAIGHT_JOIN directory_ml STRAIGHT_JOIN directory_ps";
		$WHERE = "directory.id=directory_ml.id AND directory.id=directory_ps.id AND directory_ml.lang='" . MARKET_LANG . "'";
		if (!($_SESSION['User']['market_role_id'] == 1 && $_GET['action'] == 'preview')) {
			$WHERE .= " AND directory_ps.publish='1'";
		}
		
		if ($_GET['id'] && preg_match('@^\d+$@', $_GET['id'])) {
			$this->disableTemplate('store');
			$WHERE .= " AND directory.id='" . sqlEscape($_GET['id']) . "'";
		}
		else if ($req->params[1] != 'show') {
			$this->disableTemplate('listing');
			$WHERE .= " AND directory.path='" . sqlEscape($req->params[1]) . "'";
		}
		else {
			$req->httpError(404);
		}
		
		$sql = "SELECT $SELECT FROM $FROM WHERE $WHERE";
		if (sqlQuery($sql, $res)) {
			$row = sqlFetchAssoc($res);
			
			if (!($_SESSION['User']['market_role_id'] == 1 && $_GET['action'] == 'preview')) {
				$sql = "SELECT * FROM store_data STRAIGHT_JOIN store_data_ps WHERE store_data.id=store_data_ps.id AND store_data_ps.publish='1' AND directory_id='" . $row['id'] . "' AND lang='" . MARKET_LANG . "' AND name='index' AND type='text'";
				if (!sqlQuery($sql, $res1)) {
					// Store disabled
					$row['path'] = '';
					if (!$_GET['id']) {
						$req->httpError(404);
					}				
				}
			}
			
			if ($_GET['id'] && $row['path']) {
				// Redirect
				if ($_GET['action'] == 'preview') {
					$req->redirectTo(MARKET_WEB_DIR . '/' . MARKET_LANG . '/marketplace/' . $row['path'] . '/index.html?action=preview');
				}
				else {
					$req->redirectTo(MARKET_WEB_DIR . '/' . MARKET_LANG . '/marketplace/' . $row['path'] . '/index.html');
				}
			}
			$row['address'] = ($row['address']) ? $row['address'] . ', ' . $row['city'] : $row['city'];
			if ($row['prof1']) {
				$tags = array();
				for ($i = 1; $i <= 3; $i++) {
					if ($row['prof' . $i] && !in_array($row['prof' . $i], $tags)) {
						$tags[] = $row['prof' . $i];
					}
				}
				asort($tags);
				$row['tags'] = '<ul class="tags gray">';
				foreach ($tags as $tag) {
					$row['tags'] .= '<li><a href="{MARKET.LWebDir}/directory/index.html?content=tag&q='.urlencode($tag).'">' . htmlspecialchars($tag) . '</a></li>';
				}
				$row['tags'] .= '</ul>';
			}
			if ($row['lat'] > 0 && $row['lng'] > 0) {
				$row['show_on_map'] =  '<div class="pull-right" style="margin: 15px 5px 0 0;">
											<a class="show-on-map" href="#m' . $row['id'] . '"><i class="icon icon-map-marker"></i> {LANG.Show on map}</a>
										</div>';
			}
			
			if ($row['path']) {
				$edit_url = '{MARKET.LWebDir}/edit/marketplace/' . $req->params[1];
				$noedit_url = '{MARKET.LWebDir}/marketplace/' . $req->params[1];
				if ($req->params[2]) {
					$edit_url .= '/' . $req->params[2] . '.html';
					$noedit_url .= '/' . $req->params[2] . '.html';
				}
				$this->assignGlobal('EDIT.url', $edit_url);
				$this->assignGlobal('NOEDIT.url', $noedit_url);
			}
			else {
				$edit_url = '{MARKET.LWebDir}/account/settings/business.html';
				$this->assignGlobal('EDIT.url', $edit_url);
			}
			
			if ($row['path']) {
				if (!$req->params[2] || $req->params[2] == 'index') {
					// Main page
					$sql = "SELECT * FROM store_data STRAIGHT_JOIN store_data_ps WHERE store_data.id=store_data_ps.id AND directory_id='" . $row['id'] . "' AND (lang='' OR lang='" . MARKET_LANG . "') AND name='index' AND type<>'page' AND (date_from = '0000-00-00' OR date_from < '" . date('Y-m-d') . "') AND (date_to = '0000-00-00' OR date_to > '" . date('Y-m-d') . "')";
				}
				else {
					// A page
					$sql = "SELECT * FROM store_data STRAIGHT_JOIN store_data_ps WHERE store_data.id=store_data_ps.id AND directory_id='" . $row['id'] . "' AND (lang='' OR lang='" . MARKET_LANG . "') AND name='" . sqlEscape($req->params[2]) . "' AND (date_from = '0000-00-00' OR date_from < '" . date('Y-m-d') . "') AND (date_to = '0000-00-00' OR date_to > '" . date('Y-m-d') . "')";
				}
				if (!($_SESSION['User']['market_role_id'] == 1 && $_GET['action'] == 'preview')) {
					$sql .= " AND store_data_ps.publish='1'";
				}
				$sql .= " ORDER BY ord";
			}
			else {
				$sql = "";
			}
			
			if (sqlQuery($sql, $res1)) {
				while ($row1 = sqlFetchAssoc($res1)) {
					if ($row[$row1['type']]) {
						if (is_array($row[$row1['type']])) {
							$row[$row1['type']][] = $row1['data'];
						}
						else {
							$foo = $row[$row1['type']];
							$row[$row1['type']] = array();
							$row[$row1['type']][] = $foo;
							$row[$row1['type']][] = $row1['data'];
						}
					}
					else {
						switch ($row1['type']) {
							case 'page':
								$row['text-id'] = $row1['id'];
								$row['header'] = $row1['title'];
								$row['text'] = $row1['data'];
							break;
							case 'comment':
								$row['comments'][] = array();
								$index = count($row['comments']) - 1;
								$row['comments'][$index]['comment-id'] = $row1['id'];
								$row['comments'][$index]['creator-id'] = $row1['creator'];
								$row['comments'][$index]['created'] = $row1['created'];
								$row['comments'][$index]['rating'] = $row1['rating'];
								$row['comments'][$index]['comment'] = $row1['data'];
							break;
							
							default:
								$row[$row1['type'] . '-id'] = $row1['id'];
								$row[$row1['type']] = $row1['data'];
						}
					}
				}
			}
			else {
				// $req->httpError(404);
			}
			
			// Gallery
			if (is_array($row['image'])) {
				
				$this->enableTemplate('flexslider_js');
				$this->enableTemplate('flexslider_css');
				
				if ($_GET['mercury_frame'] == 'true') {
					$str = '<table class="table table-striped table-condensed" style="margin-bottom: 0;">';
					foreach($row['image'] as $image) {
						$str .= '<tr>';
						$str .= '<td>' . MARKET_Filter::createThumbnail($image, '80x80', true, 'class="photo"') . '</td><td>' . basename($image) . '</td><td>' . MARKET_Filter::b2KB(filesize(MARKET_ROOT_DIR. '/' . $image)) . '</td><td><a class="btn delete_image" href="#" data-image="' . htmlspecialchars($image) . '">{LANG.Delete}</td>';
						$str .= '</tr>';
					}
					$str .= '</table>';
					$row['edit_slider'] = $str;
				}
				
				$str = '<div class="flexslider">';
				$str .= '<ul class="slides">';
				foreach($row['image'] as $image) {
					$str .= '<li>' . MARKET_Filter::createThumbnail($image, '570x380', true, 'class="photo"') . '</li>';
				}
				$str .= '</ul>';
				$str .= '</div>';
				$row['image'] = $str;
				
			}
			else if ($row['image']) {
				if ($_GET['mercury_frame'] == 'true') {
					$image = $row['image'];
					$str = '<table class="table table-striped table-condensed" style="margin-bottom: 0;">';
					$str .= '<tr>';
					$str .= '<td>' . MARKET_Filter::createThumbnail($image, '80x80', true, 'class="photo"') . '</td><td>' . basename($image) . '</td><td>' . MARKET_Filter::b2KB(filesize(MARKET_ROOT_DIR. '/' . $image)) . '</td><td><a class="btn delete_image" href="#" data-image="' . htmlspecialchars($image) . '">{LANG.Delete}</td>';
					$str .= '</tr>';
					$str .= '</table>';
					$row['edit_slider'] = $str;
				}
				$row['image'] = MARKET_Filter::createThumbnail($row['image'], '570x380', true, 'class="photo"');
			}
			
			// QR code
			if ($row['path']) {
				$row['qrcode'] = MARKET_Filter::marketQRCode('http://' . $_SERVER['HTTP_HOST'] . MARKET_WEB_DIR . '/' . MARKET_LANG . '/marketplace/' . $row['path']);
			}
			else {
				$row['qrcode'] = MARKET_Filter::marketQRCode('http://' . $_SERVER['HTTP_HOST'] . MARKET_WEB_DIR . '/' . MARKET_LANG . '/marketplace/show.html?id=' . $row['id']);
			}
			
			// Social
			$found = false;
			$row1 = array();
			$arr = array('twitter', 'facebook', 'google', 'youtube');
			foreach ($arr as $key => $val) {
				if ($row[$val]) {
					$row1['type'] = $val;
					$row1['url'] = $row[$val];
					$this->assignLocal('social', 'ROW', $row1);
					$this->lightParseTemplate('SOCIAL', 'social');
					$found = true;
				}
			}
			if (!$found) $this->disableTemplate('social_cnt');
			
			// Comments
			if (is_array($row['comments'])) {
				
				$this->enableTemplate('jrating_js');
				$this->enableTemplate('jrating_css');
				
				foreach ($row['comments'] as $comment) {
					if ($user = getUser($comment['creator-id'])) {
						$comment['creator'] = $user['name'] . ' ' . $user['surname'];
						$comment['gravatar'] = '<img src="http://www.gravatar.com/avatar/' . $user['gravatar'] . '.jpg?d=mm&s=28" width="28" height="28" alt="' . $comment['creator'] . '" />';
					}
					$comment['created'] = getPeriodtoDate($comment['created']);
					$comment['comment'] = '<a href="{MARKET.LWebDir}/reviews/' . $row['path'] . '/show.html#comment' . $comment['comment-id'] . '">' . htmlspecialchars(MARKET_Filter::marketSummary($comment['comment'], 150)) . ((mb_strlen($comment['comment']) > 150) ? ' <span class="blue">{LANG.more}</span>' : '') . '</a>';
					$this->assignLocal('comments', 'COMMENT', $comment);
					$this->parseTemplate('COMMENTS', 'comments');
					// Add divider
					$this->vars['global']['COMMENTS'] .= '<li class="divider"></li>';
				}
				// Remove last divider
				$this->vars['global']['COMMENTS'] = substr($this->vars['global']['COMMENTS'], 0, -(strlen('<li class="divider"></li>')));
			}
			else {
				$this->disableTemplate('comments_cnt');
			}
			
			// More pages
			$sql = "SELECT * FROM store_data STRAIGHT_JOIN store_data_ps WHERE store_data.id=store_data_ps.id AND store_data_ps.publish='1' AND directory_id='" . $row['id'] . "' AND (lang='' OR lang='" . MARKET_LANG . "') AND type='page' ORDER BY ord";
			if (sqlQuery($sql, $res1)) {
				while ($row1 = sqlFetchAssoc($res1)) {
					$row1['path'] = $req->params[1];
					if ($row1['name'] == $req->params[2]) {
						$row1['class'] = ' class="active"';
					}
					if ($GLOBALS['MARKET_mode'] == 'edit') {
						$row1['remove_page'] = '<a class="remove_page" href="{MARKET.LWebDir}/edit/marketplace/' . $row1['path'] . '/index.html?remove_id=' . $row1['id'] . '" style="float: right;"><i class="icon-remove"></i></a>';
					}
					$this->assignLocal('pages', 'ROW', $row1);
					$this->lightParseTemplate('PAGES', 'pages');
				}
			}
			else {
				$this->disableTemplate('pages_cnt');
			}
			
			$this->assignGlobal('PAGE.Title', $row['title']);
			$this->assignGlobal('QRCODE', $row['qrcode']);
			
			$this->assignGlobal('STORE', $row);
			$store = $row;
			
			// Offers
			$sql = "SELECT * FROM store_data STRAIGHT_JOIN store_data_ps WHERE store_data.id=store_data_ps.id AND store_data_ps.publish='1' AND directory_id='" . $row['id'] . "' AND (lang='' OR lang='" . MARKET_LANG . "') AND type='coupon' AND (date_from = '0000-00-00' OR date_from <= '" . date('Y-m-d') . "') AND (date_to = '0000-00-00' OR date_to >= '" . date('Y-m-d') . "') ORDER BY ord";
			if (sqlQuery($sql, $res1)) {
				while ($row1 = sqlFetchAssoc($res1)) {
					$row1['path'] = $store['path'];
					// What else is available?
					$sql = "SELECT * FROM store_data STRAIGHT_JOIN store_data_ps WHERE store_data.id=store_data_ps.id AND store_data_ps.publish='1' AND directory_id='" . $row['id'] . "' AND (lang='' OR lang='" . MARKET_LANG . "') AND type <> 'coupon' AND name='" . sqlEscape($row1['name']) . "' AND (date_from = '0000-00-00' OR date_from <= '" . date('Y-m-d') . "') AND (date_to = '0000-00-00' OR date_to >= '" . date('Y-m-d') . "') ORDER BY ord";
					if (sqlQuery($sql, $res2)) {
						while ($row2 = sqlFetchAssoc($res2)) {
							if ($row1[$row2['type']]) {
								if (is_array($row1[$row2['type']])) {
									$row1[$row2['type']][] = $row2['data'];
								}
								else {
									$foo = $row1[$row2['type']];
									$row1[$row2['type']] = array();
									$row1[$row2['type']][] = $foo;
									$row1[$row2['type']][] = $row2['data'];
								}
							}
							else {
								$row1[$row2['type']] = $row2['data'];
							}
						}
					}
					
					$image = (is_array($row1['image'])) ? $row1['image'][0] : $row1['image'];
					$row1['image'] = MARKET_Filter::createThumbnail($image, '240', true);
					
					if (!$row1['path']) $row1['path'] = $row1['directory_id'];
					
					$this->assignLocal('coupon', 'ROW', $row1);
					$this->lightParseTemplate('COUPON', 'coupon');
				}
			}
			else {
				$this->disableTemplate('coupons_cnt');
			}
			
			// Google maps
			$this->assignGlobal('GMAPS', array(
				'api_key' => GMAP_API_KEY,
				'center_lat' => GMAP_CENTER_LAT,
				'center_lng' => GMAP_CENTER_LNG,
				'center_zoom' => GMAP_CENTER_ZOOM
			));
			
			// Edit
			if ($GLOBALS['MARKET_mode'] == 'edit') {
				
				if ($_SESSION['User']['market_role_id'] == 1 || $_SESSION['User']['store'] == $store['id']) {
					
					if ($_GET['mercury_frame'] == 'true') {
						$this->enableTemplate('fileupload_css');
						$this->enableTemplate('fileupload_js');
						$this->enableTemplate('fileupload');
						
						$this->enableTemplate('pages_cnt');
						$this->enableTemplate('addpage-link');
						
						$this->enableTemplate('social_cnt');
						$this->enableTemplate('editsocial-link');
						
						$this->enableTemplate('closeedit-link');
						
					}
				
					// Disable no-edit templates
					foreach($this->templates as $val) {
						if (preg_match('@no-edit$@', $val['name'])) {
							$this->is_disabled[$val['name']] = true;
						}
					}
					
					if ($_POST['content']) {
						
						$content = json_decode($_POST['content'], true);
						foreach ($content as $key => $val) {
							switch ($key) {
								case 'store-name':
									$table = 'directory_ml';
									$field = 'business_name';
									$id = $store['id'];
								break;
								case 'store-byline':
									$table = 'directory_ml';
									$field = 'byline';
									$id = $store['id'];
								break;
								case 'store-address':
									$table = 'directory_ml';
									$field = 'address';
									$id = $store['id'];
									// Strip city from address
									$val['value'] = trim(substr($val['value'], 0, strrpos($val['value'], ',')));
								break;
								case 'store-phone':
									$table = 'directory_ml';
									$field = 'phone';
									$id = $store['id'];
								break;
								case 'store-url':
									$table = 'directory_ml';
									$field = 'url';
									$id = $store['id'];
								break;
								case 'store-header':
									$table = 'store_data';
									$field = 'title';
									$id = $store['text-id'];
								break;
								case 'store-text':
									$table = 'store_data';
									$field = 'data';
									$id = $store['text-id'];
								break;
							}
							if ($table && $field && $id) {
								$values[$table . '.' . $id][$field] = $val['value'];
							}
						}
						foreach ($values as $key => $vals) {
							list($table, $id) = explode('.', $key, 2);
							$sql = '';
							foreach ($vals as $key => $val) {
								$sql .= $key . " = '" . sqlEscape($val) . "', ";
							}
							$sql = "UPDATE " . $table . " SET " . substr($sql, 0, -2) . " WHERE id = '" . sqlEscape($id) . "'";
							if (preg_match('@_ml$@', $table)) {
								$sql .= " AND lang = '" . MARKET_LANG . "'";
								$table_ps = substr($table, 0, -3) . '_ps';
							}
							else {
								$table_ps = $table . '_ps';
							}
							
							if (sqlQuery($sql, $res)) {
								$sql = "UPDATE " . $table_ps . " SET updated = NOW() WHERE id = '" . sqlEscape($id) . "'";
								sqlQuery($sql, $res);
							}
						}
						
						exit;
					}
					else if ($_POST['submit_url']) {
						if ($_POST['page_url']) {
							if (preg_match('@^[a-z0-9_]+$@', $_POST['page_url'])) {
								$sql = "SELECT * FROM store_data WHERE type='page' AND directory_id='" . sqlEscape($row['id']) . "' AND name='" . sqlEscape($_POST['page_url']) . "'";
								if (sqlQuery($sql, $res)) {
									print __('This page already exists.');
								}
								else {
									// Add page
									$sql = "SELECT MAX(ord) FROM store_data WHERE type='page' AND directory_id='" . sqlEscape($row['id']) . "'";
									if (sqlQuery($sql, $res)) {
										$ord = sqlResult($res, 0) + 1;
									}
									else {
										$ord = 1;
									}
									$sql = "INSERT INTO store_data(directory_id, lang, type, name, title, ord) VALUES('" . sqlEscape($row['id']) . "', '" . sqlEscape(MARKET_LANG) . "', 'page', '" . sqlEscape($_POST['page_url']) . "', '" . sqlEscape(__('New page')) . "', '" . sqlEscape($ord) . "')";
									if ($page_id = sqlQuery($sql, $res)) {
										// Insert permissions
										$sql = "INSERT INTO store_data_ps (id, creator, created, owner, role, updated, ups, gps, wps, publish) VALUES('" . $page_id . "', '" . $_SESSION['User']['user_id'] . "', NOW(), '" . $_SESSION['User']['user_id'] . "', '" . $_SESSION['User']['market_role_id'] . "', NOW(), '7', '2', '2', '1')";
										sqlQuery($sql, $res);
										// Redirect to new page
										print 'redirect: ' . MARKET_WEB_DIR . '/' . MARKET_LANG . '/edit/marketplace/' . $req->params[1] . '/' . $_POST['page_url'] . '.html';
									}
									else {
										print __('An error occured') . '.';
									}
								}
							}
							else {
								print __('The url may contain english characters (a-z), numbers (0-9) and the underscore (_).');
							}
						}
						else {
							print __('The url cannot be blank.');
						}
						exit;
					}
					else if ($_GET['remove_id']) {
						$sql = "SELECT * FROM store_data WHERE type='page' AND directory_id='" . sqlEscape($row['id']) . "' AND id='" . sqlEscape($_GET['remove_id']) . "'";
						if (sqlQuery($sql, $res)) {
							$sql = "DELETE FROM store_data WHERE id='" . sqlEscape($_GET['remove_id']) . "'";
							sqlQuery($sql, $res);
							$sql = "DELETE FROM store_data_ps WHERE id='" . sqlEscape($_GET['remove_id']) . "'";
							sqlQuery($sql, $res);
						}
					}
				}
				else {
					$req->httpError(403); // Access denied
				}
			}
			else {
				// Edit page link
				if ($_SESSION['User']['is_loggedin']) {
					if ($_SESSION['User']['market_role_id'] == 1 || $_SESSION['User']['store'] == $store['id']) {
						if ($row['path']) {
							$this->enableTemplate('edit-link');
						}
						else {
							$this->enableTemplate('pin-link');
						}
					}
					else if (!$_SESSION['User']['store']) {
						$this->enableTemplate('pin-link');
					}
				}
			}
		}
		else {
			$req->httpError(404);
		}
		
	</php>
	
	<template name="flexslider_css" assign="PAGE.Style" disabled="true">
		<link href="{MARKET.WebDir}/redist/flexslider/flexslider.css" rel="stylesheet" type="text/css" />
	</template>
	
	<template name="flexslider_js" assign="PAGE.Javascript" disabled="true">
		<script type="text/javascript" src="{MARKET.WebDir}/redist/flexslider/jquery.flexslider-min.js"></script>
		<script>
			jQuery(document).ready(function($) {
				$('.flexslider').flexslider();
			});
		</script>
	</template>
	
	<template name="jrating_css" assign="PAGE.Style" disabled="true">
		<link href="{MARKET.WebDir}/redist/jrating/jRating.jquery.css" rel="stylesheet" type="text/css" />
	</template>
	
	<template name="jrating_js" assign="PAGE.Javascript" disabled="true">
		<script src="{MARKET.WebDir}/redist/jrating/jRating.jquery.js"></script>
		<script>
			jQuery(document).ready(function($) {
				$(".jrating").jRating({
					length: 5,
					rateMax: 5,
					decimalLength: 1,
					isDisabled: true,
					bigStarsPath: '{MARKET.WebDir}/redist/jrating/icons/stars.png'
				});
			});
		</script>
	</template>
	
	<template name="fileupload_css" assign="PAGE.Style" disabled="true">
		<link href="{MARKET.WebDir}/redist/fileupload/css/jquery.fileupload-ui.css" rel="stylesheet" type="text/css" />
	</template>
	
	<template name="fileupload_js" assign="PAGE.Javascript" disabled="true">
		<script src="{MARKET.WebDir}/redist/jquery.form/jquery.form.js"></script>
		<script src="{MARKET.WebDir}/redist/fileupload/js/vendor/jquery.ui.widget.js"></script>
		<script src="{MARKET.WebDir}/redist/fileupload/js/jquery.iframe-transport.js"></script>
		<script src="{MARKET.WebDir}/redist/fileupload/js/jquery.fileupload.js"></script>
		<script>
			jQuery(document).ready(function($) {
				// Initialize the jQuery File Upload widget:
				$('#fileupload').fileupload({
					dataType: 'json',
					autoUpload: true,
					done: function (e, data) {
						$(this).find('.fileupload-buttonbar .progress').addClass('fade');
						$.each(data.result.files, function (index, file) {
							$('#mediaForm input[name="filename"]').val($('#mediaForm input[name="filename"]').val() + '|' + file.url);
							$('.preview').find('tbody').append('<tr><td><img width="80" height="80" class="photo" src="' + decodeURIComponent(file.thumbnail_url) + '"></td><td>' + file.name + '</td><td>' + file.size + '</td><td>&nbsp;</td></tr>');
						});
					},
					progressall: function (e, data) {
						var $progress = $(this).find('.fileupload-buttonbar .progress');
						$progress.removeClass('fade');
						$progress.find('.bar').css( 'width', parseInt(data.loaded / data.total * 100, 10) + '%' );
					}
				});
				$('#mediaButton').on('click', function(e) {
					$('#mediaForm').submit();
					$('#media').modal('hide');
					e.preventDefault();
				});
				$('#pageForm').ajaxForm({
					success: function(responseText) {
						if (responseText.match(/^redirect:/)) {
							window.top.location.href = responseText.substr(10);
						}
						else {
							alert(responseText);
						}
					}
				});
				$('#mediaForm').ajaxForm({
					success: function() {
						window.top.location.href = window.top.location.href;
					}
				});
				$('.delete_image').on('click', function(e){
					if (confirm(_('Are you sure you want to delete this image?'))) {
						$('#mediaForm input[name="remove_filename"]').val($('#mediaForm input[name="remove_filename"]').val() + '|' + $(this).attr('data-image'));
						$(this).closest('tr').remove();
					}
					e.preventDefault();
					e.stopPropagation();
				});
				$('.remove_page').on('click', function(e){
					if (confirm(_('Are you sure you want to delete this page?'))) {
						// do nothing
					}
					else {
						e.preventDefault();
						e.stopPropagation();
					}
				});
			});
		</script>
	</template>
	
	<template name="gmap_js" assign="PAGE.Javascript">
		<script type="text/javascript" src="http://maps.googleapis.com/maps/api/js?key={GMAPS.api_key}&sensor=true"></script>
		<script type="text/javascript" src="{MARKET.WebDir}/redist/gmaps.js"></script>
		<script>
			
			var map = null;
			var marker_me = null;
			var markers = null;
			
			google.maps.event.addDomListener(window, 'load', function() {
			
				map = new GMaps({
					div: '#map',
					lat: {GMAPS.center_lat},
					lng: {GMAPS.center_lng},
					zoom: 16,
					panControl: false,
					streetViewControl: false
				});
				
				var blueIcon = "http://www.google.com/intl/en_us/mapfiles/ms/micons/blue-dot.png";
				
				map.addControl({
					position: 'top_right',
					text: _('Geolocate'),
					style: {
						margin: '5px',
						padding: '1px 6px',
						border: 'solid 1px #717B87',
						background: '#fff'
					},
					events: {
						click: function() {
							GMaps.geolocate({
								success: function(position) {
									if (marker_me != null) marker_me.setMap(null);
									map.setCenter(position.coords.latitude, position.coords.longitude);
									marker_me = map.addMarker({
										lat: position.coords.latitude,
										lng: position.coords.longitude,
										title: _('Me'),
										draggable: false,
										icon: blueIcon,
										animation : google.maps.Animation.DROP
									});
								},
								error: function(error){
									alert(_('Geolocation failed') +': ' + error.message);
								},
								not_supported: function(){
									alert(_('Your browser does not support geolocation'));
								}
							});
						}
					}
				});
				
				// Load Markers
				$.ajax({
					type: "GET",
					url: "{MARKET.LWebDir}/marketplace/ajax_store.html?path=" + $.url().attr('path') + '&' + $.url().attr('query'),
					dataType: "json",
					success: function(response) {
						markers = map.addMarkers(response);
						for (var i = 0; i < markers.length; i++) {
							var marker = markers[i];
							google.maps.event.addListener(marker, "dragend", function (event) {
								$.ajax({
									type: "GET",
									url: "{MARKET.LWebDir}/marketplace/ajax_store.html?path=" + $.url().attr('path') + '&' + $.url().attr('query') + '&marker=' + event.latLng.toString()
								});
							});
						}
						map.fitZoom();
						setTimeout(function() {
							if (map.getZoom() > map.zoom) map.setZoom(map.zoom);
						}, 100);
					}
				});
			});
			
		</script>
	</template>
	
	<div class="container">
		
		<div class="row">
			<div class="span12">
				<header id="archive-header">
					<h1 data-mercury="simple" id="store-name" class="span6" style="margin-left: 0;"><a href="{MARKET.LWebDir}/marketplace/show.html?id={STORE.id}">{PAGE.Title}</a></h1>
					<template name="edit-link" disabled="true">
						<div style="margin: -36px 10px 0 0; text-align: right;">
							<a class="btn btn-warning" href="{EDIT.url}"><i class="icon-edit icon-white"></i> {LANG.Edit page}</a>
						</div>
					</template>
					<template name="closeedit-link" disabled="true">
						<div style="margin: -36px 10px 0 0; text-align: right;">
							<a class="btn btn-warning" href="{NOEDIT.url}"><i class="icon-remove icon-white"></i> {LANG.Close editor}</a>
						</div>
					</template>
				</header>
			</div>
		</div>
		
		<template name="store">
			<div class="row">
			
				<div class="span9">
				
					<div class="row">
						
						<div class="span6">
					
							<div style="margin-top: 10px;">
								<h3 style="line-height: 18px;" data-mercury="simple" id="store-byline">{STORE.byline}</h3>
								<address>
									<div data-mercury="simple" id="store-address">{STORE.address}</div>
									<div data-mercury="simple" id="store-phone">{STORE.phone}</div>
									<div data-mercury="simple" id="store-url">{autolink:STORE.url}</div>
								</address>
							</div>
							<template name="fileupload" disabled="true">
								<div class="pull-right" style="margin: 10px; position: relative; z-index: 1000;"><a class="btn add" href="#media" data-toggle="modal"><i class="icon-camera"></i> {LANG.Edit slider}</a></div>
								<div id="media" class="modal fade">
									<div class="modal-header">
										<a data-dismiss="modal" class="close">×</a>
										<h3>{LANG.Edit slider}</h3>
									</div>
									<div class="modal-body">
										<form id="fileupload" action="{MARKET.LWebDir}/upload.html" method="POST" enctype="multipart/form-data">
											<div class="fileupload-buttonbar" style="float: left; width: 100%;">
												<span class="btn fileinput-button">
												<i class="icon-plus"></i>
												<span>{LANG.Add image}...</span>
													<input type="file" name="files[]" accept="image/jpeg,image/gif,image/png">
												</span>
												<!-- The global progress bar -->
												<div class="progress progress-success progress-striped active fade" style="margin: 5px 0 0 210px;">
													<div style="width:0%;" class="bar"></div>
												</div>
											</div>
											<div class="clearfix"></div>
											<div class="preview">
												<div class="well white">
													{STORE.edit_slider}
												</div>
											</div>
										</form>
										<form id="mediaForm" method="POST" action="{MARKET.LWebDir}/upload.html">
											<input type="hidden" value="" name="filename">
											<input type="hidden" value="" name="remove_filename">
											<input type="hidden" value="slider" name="source">
										</form>
									</div>
									<div class="modal-footer">
										<a class="btn btn-primary" id="mediaButton" href="#">{LANG.OK}</a>
										<a data-dismiss="modal" class="btn" href="#">{LANG.Cancel}</a>
									</div>
								</div>
							</template>
							{STORE.image}
							<div class="clearfix"></div>
							<h2 data-mercury="simple" id="store-header" placeholder="{LANG.Subtitle}">{STORE.header}</h2>
							<div style="margin-top: 20px;" data-mercury="full" id="store-text">
								{STORE.text}
							</div>
							
						</div>
						
						<div class="span3">
							
							<template name="qrcode_cnt">
								<div class="well white" style="text-align: center;">
									<h3>{LANG.This page on your mobile}
									<a href="#dialog01" class="help icon muted" data-toggle="modal"><i class="icon-info-sign"></i></a>
									<div id="dialog01" class="modal hide fade" style="text-align: left;">
										<div class="modal-header">
											<button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
											<h3>How can I use a QR code?</h3>
										</div>
										<div class="modal-body">
											<blockquote>
												<p style="font-size: 13px;">QR Codes can be used in Google's mobile Android operating system using Google Goggles or 3rd party barcode scanners.<br>QR Codes can be used in iOS devices [iPhone/iPod/iPad] via 3rd party barcode scanners...<br>Nokia's Symbian operating system features a barcode scanner which can read QR Codes...<br>With BlackBerry devices, the App World application can natively scan QR Codes...<br>Windows Phone 7.5 is able to scan QR Codes through the Bing search app.</p>
												<small><cite><a class="blue" href="http://en.wikipedia.org/wiki/QR_code">QR Code</a></cite> from Wikipedia: The free encyclopedia</small>
											</blockquote>
										</div>
									</div>
									</h3>
									<img src="{QRCODE}" width="132" height="132" />
								</div>
							</template>
							
							<template name="pages_cnt">
								<div class="well white">
									<h3>{LANG.Learn more}</h3>
									<ul class="nav nav-list">
										<template name="pages">
											<li{ROW.class}>{ROW.remove_page}<a href="{MARKET.LWebDir}/marketplace/{ROW.path}/{ROW.name}.html">{htmlspecialchars:ROW.title}</a></li>
										</template>
									</ul>
									<template name="addpage-link" disabled="true">
										<div class="pull-right" style="margin: 5px 0 10px 10px; position: relative; z-index: 1000;"><a class="btn" href="#addpage" data-toggle="modal"><i class="icon-plus"></i> {LANG.Add page}</a></div>
										<div id="addpage" class="modal fade">
											<div class="modal-header">
												<a data-dismiss="modal" class="close">×</a>
												<h3>{LANG.Add page}</h3>
											</div>
											<form id="pageForm" action="" method="POST">
												<div class="modal-body">
													<div class="control-group">
														<label class="control-label" for="page_url">{LANG.Enter a url for your new page}:</label>
														<div class="controls input-prepend input-append">
															<span class="add-on">/marketplace/{MARKET.Params.1}/</span><input class="span2" id="page_url" name="page_url" type="text" value="" /><span class="add-on">.html</span>
															<span class="help-block" style="font-size: 15px;"><small>{LANG.The url may contain english characters (a-z), numbers (0-9) and the underscore (_).}</small></span>
														</div>
													</div>
												</div>
												<div class="modal-footer">
													<a data-dismiss="modal" class="btn" href="#">{LANG.Cancel}</a>
													<button type="submit" class="btn" name="submit_url" value="yes">{LANG.OK}</button>
												</div>
											</form>
										</div>
									</template>
								</div>
							</template>
							
							<template name="social_cnt">
								<div class="well white">
									<h3 style="margin-bottom: 8px;">{LANG.Follow us}</h3>
									<ul class="social">
										<template name="social">
											<li><a class="{ROW.type}" href="{ROW.url}">{ucfirst:ROW.type}</a></li>
										</template>
									</ul>
									<template name="editsocial-link" disabled="true">
										<div class="pull-right" style="margin: 5px 0 10px 10px; position: relative; z-index: 1000;"><a class="btn" href="{MARKET.WebDir}/account/settings/business.html#social"><i class="icon-globe"></i> {LANG.Edit links}</a></div>
									</template>
								</div>
							</template>
						</div>
					</div>
						
					<template name="coupons_cnt">
						<div class="row" style="margin-top: 20px;">
							<div class="span9">
								<h2 style="margin-bottom: 10px;">{LANG.Our offers}</h2>
								<div class="coupons row">
									<template name="coupon">
										<a href="{MARKET.LWebDir}/offers/{ROW.path}/{ROW.name}.html">
										<div class="coupon span3" style="margin-bottom: 40px;">
											{ROW.image}
											<div>
												<h3>{ROW.title}</h3>
												<if expr="'{ROW.price}'">
													<p class="price"><span>{LANG.Price}:</span> {ROW.price}</p>
												</if>
											</div>
											<p class="discount"><span>{LANG.Discount}:</span> {ROW.discount}%</p>
										</div>
										</a>
									</template>
								</div>
							</div>
						</div>
					</template>
				</div>
				
				<div class="span3">
					
					<div id="map-wrap"><div id="map"></div></div>
					
					<template name="comments_cnt">
						<div class="well white">
							<h3 style="margin-bottom: 8px;">{LANG.User reviews}</h3>
							<ul class="comments unstyled">
								<template name="comments" divider="<li class='divider'></li>">
									<li>
										<div class="pull-left" style="margin: 6px 5px 5px 0;">{COMMENT.gravatar}</div>
										<small>{COMMENT.creator}<br><span class="muted">{COMMENT.created}</span></small>
										<div data-average="{COMMENT.rating}" data-id="{COMMENT.comment-id}" class="jrating"></div>
										<small>{COMMENT.comment}</small>
									</li>
								</template>
							</ul>
							<div class="pull-right"><a class="btn btn-mini" href="{MARKET.LWebDir}/reviews/{STORE.path}/show.html">{LANG.All reviews} &raquo;</a></div>
							<div class="clearfix"></div>
						</div>
					</template>
					
					<div class="well white" style="text-align: center;">
						<h3 style="margin-bottom: 8px;">{LANG.You have something to say?}</h3>
						<a class="btn" href="{MARKET.LWebDir}/reviews/{STORE.path}/review.html"><i class="icon-pencil"></i> {LANG.Write a review}</a>
					</div>
					
					<template name="pin-link" disabled="true">
						<div style="margin-top: 40px;">
							<h3 style="border-bottom: 1px solid #ccc; margin-bottom: 10px; text-align: right;">{LANG.Is this your business?}</h3>
							<p style="text-align: right;"><a class="btn" href="{MARKET.WebDir}/account/settings/business.html"><i class="icon-edit"></i> {LANG.Manage page}</a></p>
						</div>
					</template>
					
				</div>
				
			</div>
			
		</template>
		
		<template name="listing">
			<div class="row">
			
				<div class="span9">
					
					<div style="margin-top: 10px;">
						<h3 style="line-height: 18px;" data-mercury="simple" id="store-byline">{STORE.byline}</h3>
						<address>
							<div data-mercury="simple" id="store-address">{STORE.address}</div>
							<div data-mercury="simple" id="store-phone">{STORE.phone}</div>
							<div data-mercury="simple" id="store-url">{autolink:STORE.url}</div>
						</address>
					</div>
					{STORE.image}
					<p style="margin-top: 20px;">{nl2br:STORE.text}</p>
					
					<div id="map-wrap"><div id="map"></div></div>
					
					<template name="coupons_cnt">
						<div class="row" style="margin-top: 20px;">
							<div class="span9">
								<h2 style="margin-bottom: 10px;">{LANG.Our offers}</h2>
								<div class="coupons row">
									<template name="coupon">
										<a href="{MARKET.LWebDir}/offers/{ROW.path}/{ROW.name}.html">
										<div class="coupon span3" style="margin-bottom: 40px;">
											{ROW.image}
											<div>
												<h3>{ROW.title}</h3>
												<if expr="'{ROW.price}'">
													<p class="price"><span>{LANG.Price}:</span> {ROW.price}</p>
												</if>
											</div>
											<p class="discount"><span>{LANG.Discount}:</span> {ROW.discount}%</p>
										</div>
										</a>
									</template>
								</div>
							</div>
						</div>
					</template>
					
					<template name="pin-link" disabled="true">
						<div style="margin-top: 40px;">
							<h3 style="border-bottom: 1px solid #ccc; margin-bottom: 10px;">{LANG.Is this your business?}</h3>
							<p><a class="btn" href="{MARKET.WebDir}/account/settings/business.html"><i class="icon-edit"></i> {LANG.Manage page}</a></p>
						</div>
					</template>
					
				</div>
				
				<div class="span3">
					<div class="well white" style="text-align: center;">
						<h3>{LANG.This page on your mobile}
							<a href="#dialog01" class="help icon muted" data-toggle="modal"><i class="icon-info-sign"></i></a>
							<div id="dialog01" class="modal hide fade" style="text-align: left;">
								<div class="modal-header">
									<button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
									<h3>How can I use a QR code?</h3>
								</div>
								<div class="modal-body">
									<blockquote>
										<p style="font-size: 13px;">QR Codes can be used in Google's mobile Android operating system using Google Goggles or 3rd party barcode scanners.<br>QR Codes can be used in iOS devices [iPhone/iPod/iPad] via 3rd party barcode scanners...<br>Nokia's Symbian operating system features a barcode scanner which can read QR Codes...<br>With BlackBerry devices, the App World application can natively scan QR Codes...<br>Windows Phone 7.5 is able to scan QR Codes through the Bing search app.</p>
										<small><cite><a class="blue" href="http://en.wikipedia.org/wiki/QR_code">QR Code</a></cite> from Wikipedia: The free encyclopedia</small>
									</blockquote>
								</div>
							</div>
						</h3>
						<img src="{QRCODE}" width="132" height="132" />
					</div>
					<template name="social_cnt">
						<div class="well white">
							<h3 style="margin-bottom: 8px;">{LANG.Follow us}</h3>
							<ul class="social">
								<template name="social">
									<li><a class="{ROW.type}" href="{ROW.url}">{ucfirst:ROW.type}</a></li>
								</template>
							</ul>
							<template name="editsocial-link" disabled="true">
								<div class="pull-right" style="margin: 5px 0 10px 10px; position: relative; z-index: 1000;"><a class="btn" href="{MARKET.WebDir}/account/settings/business.html#social"><i class="icon-globe"></i> {LANG.Edit links}</a></div>
							</template>
						</div>
					</template>
					
				</div>
				
			</div>
		</template>
		
	</div>
	
</template>