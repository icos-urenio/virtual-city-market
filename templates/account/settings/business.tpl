<template parent="main" assign="PAGE.Body" global="PAGE.Title: `{LANG.Account settings}`" permissions="registered">
	
	<php>
		
		include_once(MARKET_TEMPLATE_DIR . '/account/common.php');
		
		if (defined('IN_MARKET')) {
			
			if ($_SESSION['User']['market_role_id'] == 2) {
			
				$this->assignGlobal('CURRENT.settings', 'active');
				
				if ($_POST && count($_POST)) {
					
					$errors = array();
					
					if ($_SESSION['User']['store']) {
					
						if ($_POST['submit_url']) {
							// Create marketplace store
							if ($_POST['page_url']) {
								if (preg_match('@^[a-z0-9_]+$@', $_POST['page_url'])) {
									$sql = "SELECT * FROM directory WHERE path='" . sqlEscape($_POST['page_url']) . "'";
									if (sqlQuery($sql, $res)) {
										print __('This page already exists.');
									}
									else {
										$sql = "UPDATE directory SET path='" . sqlEscape($_POST['page_url']) . "' WHERE id='" . sqlEscape($_SESSION['User']['store']) . "'";
										if (sqlQuery($sql, $res)) {
											// Add page
											$sql = "SELECT * FROM store_data WHERE type='text' AND name='index' AND directory_id='" . sqlEscape($_SESSION['User']['store']) . "'";
											if (sqlQuery($sql, $res)) {
												// Page already exists
												print 'redirect: ' . MARKET_WEB_DIR . '/' . MARKET_LANG . '/edit/marketplace/' . $_POST['page_url'] . '/index.html';
											}
											else {
												$sql = "INSERT INTO store_data(directory_id, lang, type, name, title) VALUES('" . sqlEscape($_SESSION['User']['store']) . "', '" . sqlEscape(MARKET_LANG) . "', 'text', 'index', '" . sqlEscape(__('New page')) . "')";
												if ($page_id = sqlQuery($sql, $res)) {
													// Insert permissions
													$sql = "INSERT INTO store_data_ps (id, creator, created, owner, role, updated, ups, gps, wps, publish) VALUES('" . $page_id . "', '" . $_SESSION['User']['user_id'] . "', NOW(), '" . $_SESSION['User']['user_id'] . "', '" . $_SESSION['User']['market_role_id'] . "', NOW(), '7', '2', '2', '1')";
													sqlQuery($sql, $res);
													// Redirect to new page
													print 'redirect: ' . MARKET_WEB_DIR . '/' . MARKET_LANG . '/edit/marketplace/' . $_POST['page_url'] . '/index.html';
												}
												else {
													print __('An error occured') . '.';
												}
											}
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
						else {

							
							// Required fields
							$required_fields = array(
								'business_name'	=> __('Your business name is required.'),
								'byline'		=> __('The byline is required.'),
								'category'		=> __('The category is required.'),
								'address'		=> __('Your business address is required.'),
								'city'			=> __('The city is required.')
							);
							
							foreach ($required_fields as $required_field => $message) {
								if (!$_POST[$required_field]) {
									$errors[$required_field] = $message;
								}
							}
							
							if ($errors) {
								$this->assignGlobal('STORE.Message', '<div class="alert alert-error">' . __('There are errors. Please review the form and correct the fields marked in red.') . '</div>');
								foreach ($errors as $key => $error) {
									$this->assignGlobal('ERROR.' . $key, '<span class="help-inline">' . htmlspecialchars($error) . '</span>');
									$this->assignGlobal('ERROR.C' . $key, ' error');
								}
							}
							else {
								// Update store
								$fields = array('name', 'business_name', 'byline', 'category', 'prof', 'address', 'city', 'phone', 'url', 'facebook', 'twitter', 'google', 'youtube');
								$sql = "UPDATE directory_ml SET ";
								foreach ($fields as $field) {
									if ($field == 'prof') {
										if (is_array($_POST['prof'])) {
											$i = 1;
											foreach ($_POST['prof'] as $prof) {
												if ($i > 3) break;
												if ($prof) {
													$sql1 = "SELECT * FROM directory_ml WHERE category='" . sqlEscape($_POST['category']) . "' AND (prof1='" . sqlEscape($prof) . "' OR prof2='" . sqlEscape($prof) . "' OR prof3='" . sqlEscape($prof) . "')";
													if (sqlQuery($sql1, $res)) {
														$sql .= "prof" . $i . "='" . sqlEscape($prof) . "', ";
														$i++;
													}
												}
											}
											if ($i <= 3) {
												for ($i = $i; $i <= 3; $i++) {
													$sql .= "prof" . $i . "='', ";
												}
											}
										}
									}
									else {
										$sql .= $field . "='" . sqlEscape($_POST[$field]) . "', ";
									}
								}
								$sql = substr($sql, 0, -2) . " WHERE lang='" . MARKET_LANG . "' AND id='" . sqlEscape($_SESSION['User']['store']) . "'";
								if (sqlQuery($sql, $res)) {
									$this->assignGlobal('STORE.Message', '<div class="alert alert-info">' . __('Your business details were updated successfully.') . '</div>');
								}
							}
						}
					}
					// PIN
					else if (!$_SESSION['User']['store'] && $_POST['pin']) {
						$sql = "SELECT id FROM directory WHERE pin='" . sqlEscape($_POST['pin']) . "'";
						if (sqlQuery($sql, $res)) {
							$store_id = sqlResult($res, 0);
							$sql = "SELECT * FROM market_user WHERE store='" . $store_id . "'";
							if (sqlQuery($sql, $res)) {
								$store_id = 0;
								$errors['pin'] = __('This PIN code is already used. Please contact your professional association.');
							}
						}
						else {
							$errors['pin'] = __('The PIN code is incorrect.');
						}
						
						if ($errors) {
							$this->assignGlobal('STORE.Message', '<div class="alert alert-error">' . __('There are errors. Please review the form and correct the fields marked in red.') . '</div>');
							foreach ($errors as $key => $error) {
								$this->assignGlobal('ERROR.' . $key, '<span class="help-inline">' . htmlspecialchars($error) . '</span>');
								$this->assignGlobal('ERROR.C' . $key, ' error');
							}
						}
						else {
							$sql = "UPDATE market_user SET store='" . $store_id . "' WHERE user_id='" . sqlEscape($_SESSION['User']['user_id']) . "'";
							if (sqlQuery($sql, $res)) {
								// Reload Session
								$auth =& $this->getRef('Auth');
								$sql = "SELECT * FROM market_user WHERE user_id='" . sqlEscape($_SESSION['User']['user_id']) . "'";
								$auth->userLogin($sql);
							}
						}
					}
					else {
						// Hmm... A user without a store posted on the store form?
						$this->assignGlobal('STORE.Message', '<div class="alert alert-error">' . __('An error occured') . '. ' . __('Please try again later.') . '</div>');
					}
				}
				
				if ($_SESSION['User']['store']) {
					
					// Google maps
					$this->enableTemplate('gmap_js');
					$this->assignGlobal('GMAPS', array(
						'api_key' => GMAP_API_KEY,
						'center_lat' => GMAP_CENTER_LAT,
						'center_lng' => GMAP_CENTER_LNG,
						'center_zoom' => GMAP_CENTER_ZOOM
					));
					
					$this->enableTemplate('store_form');
					
					// Load store data
					$sql = "SELECT * FROM directory STRAIGHT_JOIN directory_ml STRAIGHT_JOIN directory_ps WHERE directory.id=directory_ml.id AND directory.id=directory_ps.id AND directory_ml.lang='" . MARKET_LANG . "' AND directory_ps.publish='1' AND directory.id='" . sqlEscape($_SESSION['User']['store']) . "'";
					if (sqlQuery($sql, $res)) {
						$row = sqlFetchAssoc($res);
						foreach ($row as $key => $val) {
							if (!$_POST[$key]) {
								$_POST[$key] = $val;
							}
						}
						$this->assignPHPVars($this->templates['store_form']['text']);
					}
					
					if ($_POST['path']) {
						$this->disableTemplate('addpage-link');
					}
					
				}
				else {
					$this->enableTemplate('pin_form');
				}
				
				$this->assignPHPVars($this->templates['menu']['text']);
			}
			else {
				$req =& $this->getRef('Request');
				$req->httpError(403);
			}
		}
	</php>
	
	<template name="css" assign="PAGE.Style">
		<link href="{MARKET.WebDir}/redist/ajax-chosen/dist/chosen/chosen.css" rel="stylesheet" type="text/css" />
		<style type="text/css">
			legend { font-size: 18px; font-family: 'Ubuntu Condensed', Arial, sans-serif; margin-bottom: 0; }
			.help-inline small { font-size: 12px; }
			.help-block small { font-size: 12px; color: #666; }
			.help-block { margin-top: 10px; }
			option { padding: 0 15px; }
			option.disabled { padding: 0 5px; color: #666; border-bottom: 1px solid #ccc; background: #f5f5f5; }
		</style>
	</template>
	
	<template name="js" assign="PAGE.Javascript">
		<script src="{MARKET.WebDir}/redist/jquery.form/jquery.form.js"></script>
		<script type="text/javascript" src="{MARKET.WebDir}/js/chosen.jquery-modified.js"></script>
		<script type="text/javascript" src="{MARKET.WebDir}/js/ajax-chosen-modified.js"></script>
		<script type="text/javascript">
			jQuery(document).ready(function() {
				
				setTimeout(function() { 
					$('.alert').fadeOut();
				}, 5000);
				
				$('#category').on('change', function() {
					$("#prof").empty();
					$("#prof").ajaxChosen({
						type: 'POST',
						url: '{MARKET.LWebDir}/account/ajax_chosen.html?category=' + encodeURIComponent($('#category').val()),
						dataType: 'json',
						minTermLength: 0
					}, function (data) {
							var results = {};
							$.each(data, function (i, val) {
								results[i] = val;
							});
							return results;
					});
					$("#prof").trigger("liszt:updated");
				});
				
				$("#prof").ajaxChosen({
					type: 'POST',
					url: '{MARKET.LWebDir}/account/ajax_chosen.html?category=' + encodeURIComponent($('#category').val()),
					dataType: 'json',
					minTermLength: 0
				}, function (data) {
						var results = {};
						$.each(data, function (i, val) {
							results[i] = val;
						});
						return results;
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
			});
		</script>
	</template>
	
	<template name="gmap_js" assign="PAGE.Javascript" disabled="true">
		<script type="text/javascript" src="http://maps.googleapis.com/maps/api/js?key={GMAPS.api_key}&sensor=true"></script>
		<script type="text/javascript" src="{MARKET.WebDir}/redist/gmaps.js"></script>
		<script>
			
			var map = null;
			var marker_me = null;
			var markers = null;
			
			jQuery(document).ready(function($) {
				
				map = new GMaps({
					div: '#map',
					lat: {GMAPS.center_lat},
					lng: {GMAPS.center_lng},
					zoom: 16,
					panControl: false,
					streetViewControl: false
				});
				
				$.ajax({
					type: "GET",
					url: "{MARKET.LWebDir}/marketplace/ajax_store.html?path=" + encodeURIComponent('{MARKET.LWebDir}/edit/marketplace/show.html') + '&id={_SAFE_SESSION.User.store}',
					dataType: "json",
					success: function(response) {
						markers = map.addMarkers(response);
						for (var i = 0; i < markers.length; i++) {
							var marker = markers[i];
							google.maps.event.addListener(marker, "dragend", function (event) {
								$.ajax({
									type: "GET",
									url: "{MARKET.LWebDir}/marketplace/ajax_store.html?path=" + encodeURIComponent('{MARKET.LWebDir}/edit/marketplace/show.html') + '&id={_SAFE_SESSION.User.store}' + '&marker=' + event.latLng.toString()
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
	
	<div class="container" style="position: relative;">
		
		<div class="row">
			<div class="span12">
				<header id="archive-header">
					<h1>{PAGE.Title}</h1>
				</header>
			</div>
		</div>
		
		<div class="row">
		
			<div class="span8">
				
				<template name="store">
					<div id="business" style="border: 1px solid #DFDFDF;">
						<div class="span6" style="float: none; margin: 0 auto; margin-top: 20px;">
							<template name="store_form" disabled="true">
								<img src="{MARKET.WebDir}/img/shopping_cart.png" width="128" height="128" alt="" />
								<template name="addpage-link">
									<div class="pull-right"><a class="btn btn-warning" href="#addpage" data-toggle="modal"><i class="icon-plus icon-white"></i> {LANG.Create marketplace store}</a></div>
									<div id="addpage" class="modal fade">
										<div class="modal-header">
											<a data-dismiss="modal" class="close">?</a>
											<h3>{LANG.Create marketplace store}</h3>
										</div>
										<form id="pageForm" action="" method="POST">
											<div class="modal-body">
												<div class="control-group">
													<label class="control-label" for="page_url">{LANG.Enter a url for your marketplace store}:</label>
													<div class="controls input-prepend input-append">
														<span class="add-on">/marketplace/</span><input class="span2" id="page_url" name="page_url" type="text" value="" /><span class="add-on">.html</span>
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
								<div class="span4" style="position: absolute; right: 20px; margin-top: 20px;">
									<div id="map-wrap"><div id="map"></div></div>
									<div class="pull-right"><a class="btn" href="{MARKET.LWebDir}/marketplace/show.html?id={_SAFE_POST.id}">{LANG.Go to the store} &raquo;</a></div>
								</div>
								<h2 style="margin-bottom: 20px; border-bottom: 1px solid #ddd;">{LANG.Edit your store details}</h2>
								{STORE.Message}
								<form class="form-horizontal" action="" method="POST">
									<fieldset>
										<div class="control-group{ERROR.Cname}">
											<label class="control-label" for="name">{LANG.Name}:</label>
											<div class="controls">
												<input class="span3" id="name" name="name" type="text" value="{_SAFE_POST.name}" />{ERROR.name}
											</div>
										</div>
										<div class="control-group{ERROR.Cbusiness_name}">
											<label class="control-label" for="business_name">{LANG.Company name}:</label>
											<div class="controls">
												<input class="span3" id="business_name" name="business_name" type="text" value="{_SAFE_POST.business_name}" />{ERROR.business_name}
											</div>
										</div>
										<div class="control-group{ERROR.Cbyline}">
											<label class="control-label" for="byline">{LANG.Byline}:</label>
											<div class="controls">
												<input class="span3" id="byline" name="byline" type="text" value="{_SAFE_POST.byline}" />{ERROR.byline}
											</div>
										</div>
										<div class="control-group{ERROR.Ccategory}">
											<label class="control-label" for="category">{LANG.Category}:</label>
											<div class="controls">
												<select class="span3" id="category" name="category">
													<option value="" class="disabled">{LANG.Please select}</option>
													<template name="category" has_input="category" source="SELECT category FROM directory_ml WHERE lang='{MARKET.Lang}' GROUP BY category ORDER BY category">
														<option value="{htmlspecialchars:CATEGORY}">{htmlspecialchars:CATEGORY}</option>
													</template>
												</select>
												{ERROR.category}
											</div>
										</div>
										<div class="control-group{ERROR.Cprof}">
											<label class="control-label" for="prof">{LANG.Subcategory}:</label>
											<div class="controls">
												<select class="span3" id="prof" name="prof[]" multiple="" data-placeholder="&nbsp;">
													<template name="prof" source="SELECT prof1, prof2, prof3 FROM directory_ml WHERE lang='{MARKET.Lang}' AND id='{_SESSION.User.store}'">
														<option value="{htmlspecialchars:PROF1}" selected="">{htmlspecialchars:PROF1}</option>
														<option value="{htmlspecialchars:PROF2}" selected="">{htmlspecialchars:PROF2}</option>
														<option value="{htmlspecialchars:PROF3}" selected="">{htmlspecialchars:PROF3}</option>
													</template>
												</select>
												<span class="help-block"><small>{LANG.You may select up to three subcategories.}</small></span>
											</div>
											{ERROR.prof}
										</div>
										<div class="control-group{ERROR.Caddress}">
											<label class="control-label" for="address">{LANG.Address}:</label>
											<div class="controls">
												<textarea rows="2" class="span3" id="address" name="address">{_SAFE_POST.address}</textarea>{ERROR.address}
											</div>
										</div>
										<div class="control-group{ERROR.Ccity}">
											<label class="control-label" for="city">{LANG.City}:</label>
											<div class="controls">
												<select class="span3" id="city" name="city">
													<option value="" class="disabled">{LANG.Please select}</option>
													<template name="city" has_input="city" source="SELECT city FROM directory_ml WHERE lang='{MARKET.Lang}' GROUP BY city ORDER BY city">
														<option value="{htmlspecialchars:CITY}">{htmlspecialchars:CITY}</option>
													</template>
												</select>
												{ERROR.city}
											</div>
										</div>
										<div class="control-group{ERROR.Cphone}">
											<label class="control-label" for="phone">{LANG.Phone}:</label>
											<div class="controls">
												<input class="span3" id="phone" name="phone" type="text" value="{_SAFE_POST.phone}" />{ERROR.phone}
											</div>
										</div>
										<div class="control-group{ERROR.Curl}">
											<label class="control-label" for="url">{LANG.Url}:</label>
											<div class="controls">
												<input class="span3" id="url" name="url" type="text" value="{_SAFE_POST.url}" />{ERROR.url}
											</div>
										</div>
									</fieldset>
									<fieldset>
										<a name="social">
										<legend>{LANG.Social networks}</legend>
										<div class="control-group{ERROR.Cfacebook}">
											<label class="control-label" for="facebook">{LANG.Facebook}:</label>
											<div class="controls">
												<input class="span3" id="facebook" name="facebook" type="text" value="{_SAFE_POST.facebook}" />{ERROR.facebook}
											</div>
										</div>
										<div class="control-group{ERROR.Ctwitter}">
											<label class="control-label" for="twitter">{LANG.Twitter}:</label>
											<div class="controls">
												<input class="span3" id="twitter" name="twitter" type="text" value="{_SAFE_POST.twitter}" />{ERROR.twitter}
											</div>
										</div>
										<div class="control-group{ERROR.Cgoogle}">
											<label class="control-label" for="google">{LANG.Google}:</label>
											<div class="controls">
												<input class="span3" id="google" name="google" type="text" value="{_SAFE_POST.google}" />{ERROR.google}
											</div>
										</div>
										<div class="control-group{ERROR.Cyoutube}">
											<label class="control-label" for="youtube">{LANG.Youtube}:</label>
											<div class="controls">
												<input class="span3" id="youtube" name="youtube" type="text" value="{_SAFE_POST.youtube}" />{ERROR.youtube}
											</div>
										</div>
										<div class="form-actions white" style="border-top: none;">
											<button class="btn btn-primary" type="submit" id="user_submit" name="store_form" value="true">{LANG.Update store}</button>
										</div>
									</fieldset>
								</form>
							</template>
						
							<template name="pin_form" disabled="true">
								<img src="{MARKET.WebDir}/img/code.png" width="128" height="128" alt="" />
								<form class="form-horizontal" action="" method="POST">
									<h2 style="margin-bottom: 20px; border-bottom: 1px solid #ddd;">{LANG.Enter your PIN code}</h2>
									{STORE.Message}
									<fieldset>
										<div class="pin control-group{ERROR.Cpin}">
											<label class="control-label" for="pin">{LANG.PIN Code}:</label>
											<div class="controls">
												<input class="span2" id="pin" name="pin" type="text" value="{_SAFE_POST.pin}" />{ERROR.pin}
												<span class="help-block"><small>{LANG.Local businesses should acquire a PIN code from their professional association to access their business information.}</small></span>
											</div>
										</div>
										<div class="form-actions white" style="border-top: none;">
											<button class="btn btn-primary" type="submit" id="user_submit" name="store_form" value="true">{LANG.Submit PIN}</button>
										</div>
									</fieldset>
								</form>
							</template>
						</div>
					</div>
				</template>
			</div>
			
			<template name="menu">
				<div class="menu span4">
					<ul class="well nav nav-list">
						<li><h3 style="border-bottom: 1px solid #ccc;">{LANG.Account options}</h3></li>
						<li><a href="{MARKET.LWebDir}/account/settings/index.html">{LANG.Personal details}</a></li>
						<li class="active"><a href="{MARKET.LWebDir}/account/settings/business.html">{LANG.Business details}</a></li>
						<if expr="'{_SESSION.User.store}'">
							<li><a href="{MARKET.LWebDir}/account/settings/offers.html">{LANG.Offers management}</a></li>
						</if>
					</ul>
				</div>
			</template>
			
		</div>
	</div>
	
</template>