<template parent="main" assign="PAGE.Body" global="PAGE.Title: `{LANG.Account settings}`" permissions="registered">
	
	<php>
		
		include_once(MARKET_TEMPLATE_DIR . '/account/common.php');
		
		if (defined('IN_MARKET')) {
			
			$this->assignGlobal('CURRENT.settings', 'active');
			
			$today = date('Y-m-d');
			$this->assignGlobal('TODAY', $today);
			
			if ($_SESSION['User']['market_role_id'] == 2 && $_SESSION['User']['store']) {
			
				if ($_POST && count($_POST)) {
					
					// Required fields
					$required_fields = array(
						'title'		=> __('The title is required.'),
						'data'		=> __('The description is required.'),
						'discount'	=> __('The discount is required.'),
						'date_to'	=> __('The expiration date is required.')
					);
					
					foreach ($required_fields as $required_field => $message) {
						if (!$_POST[$required_field]) {
							$errors[$required_field] = $message;
						}
					}
					
					if ($errors) {
						$this->assignGlobal('OFFER.Message', '<div class="alert alert-error">' . __('There are errors. Please review the form and correct the fields marked in red.') . '</div>');
						foreach ($errors as $key => $error) {
							$this->assignGlobal('ERROR.' . $key, '<span class="help-inline">' . htmlspecialchars($error) . '</span>');
							$this->assignGlobal('ERROR.C' . $key, ' error');
						}
					}
					else {
						$fields = array('title', 'price', 'data', 'discount', 'date_from', 'date_to');
						
						if ($_GET['id']) {
							// Update offer
							$sql = "UPDATE store_data SET ";
							foreach ($fields as $field) {
								$sql .= $field . "='" . sqlEscape($_POST[$field]) . "', ";
							}
							$sql = substr($sql, 0, -2) . " WHERE id='" . sqlEscape($_GET['id']) . "'";
							if (sqlQuery($sql, $res)) {
								// Update permissions
								$sql = "UPDATE store_data_ps SET updated=NOW() WHERE id='" . sqlEscape($_GET['id']) . "'";
								sqlQuery($sql, $res);
								$this->assignGlobal('OFFER.Message', '<div class="alert alert-info">' . __('Your offer was updated successfully.') . '</div>');
							}
							// Update image
							if ($_POST['filename']) {
								$_POST['filename'] = preg_replace('@^' . MARKET_WEB_DIR . '/@', '', urldecode($_POST['filename']));
								if (@is_file(MARKET_ROOT_DIR . '/' . $_POST['filename'])) {
									if ($image_data = getImageData($_GET['id'])) {
										$sql = "UPDATE store_data SET data='" . sqlEscape($_POST['filename']) . "' WHERE id='" . sqlEscape($image_data['id']) . "'";
										if (sqlQuery($sql, $res)) {
											// Update permissions
											$sql = "UPDATE store_data_ps SET updated=NOW() WHERE id='" . sqlEscape($image_data['id']) . "'";
											sqlQuery($sql, $res);
											$this->assignGlobal('OFFER.Message', '<div class="alert alert-info">' . __('Your offer was updated successfully.') . '</div>');
										}
									}
								}
							}
						}
						else {
							// New offer
							$sql = "SELECT name FROM store_data WHERE type='coupon' AND directory_id='" . sqlEscape($_SESSION['User']['store']) . "' ORDER BY name DESC";
							if (sqlQuery($sql, $res)) {
								$row = sqlFetchAssoc($res);
								$coupon = preg_replace('@coupon-0+@', '', $row['name']);
								$coupon++;
							}
							else {
								$coupon = 1;
							}
							$sql = "INSERT INTO store_data (id, directory_id, lang, name, type, title, price, data, discount, date_from, date_to) VALUES ('', '" . sqlEscape($_SESSION['User']['store']) . "', '" . MARKET_LANG . "', '" . sqlEscape('coupon-' . sprintf('%04d', $coupon)) . "', 'coupon', ";
							foreach ($fields as $field) {
								$sql .= "'" . sqlEscape($_POST[$field]) . "', ";
							}
							$sql = substr($sql, 0, -2) . ")";
							if ($offer_id = sqlQuery($sql, $res)) {
								
								// Insert permissions
								$sql = "INSERT INTO store_data_ps (id, creator, created, owner, role, updated, ups, gps, wps, publish) VALUES('" . $offer_id . "', '" . $_SESSION['User']['user_id'] . "', NOW(), '" . $_SESSION['User']['user_id'] . "', '" . $_SESSION['User']['market_role_id'] . "', NOW(), '7', '2', '2', '1')";
								sqlQuery($sql, $res);
								
								// Insert image
								$sql = "INSERT INTO store_data (id, directory_id, name, type) VALUES ('', '" . sqlEscape($_SESSION['User']['store']) . "', '" . sqlEscape('coupon-' . sprintf('%04d', $coupon)) . "', 'image')";
								if ($image_id = sqlQuery($sql, $res)) {
									// Insert image permissions
									$sql = "INSERT INTO store_data_ps (id, creator, created, owner, role, updated, ups, gps, wps, publish) VALUES('" . $image_id . "', '" . $_SESSION['User']['user_id'] . "', NOW(), '" . $_SESSION['User']['user_id'] . "', '" . $_SESSION['User']['market_role_id'] . "', NOW(), '7', '2', '2', '1')";
									sqlQuery($sql, $res);
								}
								
								// Update image
								if ($_POST['filename']) {
									$_POST['filename'] = preg_replace('@^' . MARKET_WEB_DIR . '/@', '', urldecode($_POST['filename']));
									if (@is_file(MARKET_ROOT_DIR . '/' . $_POST['filename'])) {
										if ($image_data = getImageData($offer_id)) {
											$sql = "UPDATE store_data SET data='" . sqlEscape($_POST['filename']) . "' WHERE id='" . sqlEscape($image_data['id']) . "'";
											if (sqlQuery($sql, $res)) {
												// Update permissions
												$sql = "UPDATE store_data_ps SET updated=NOW() WHERE id='" . sqlEscape($image_data['id']) . "'";
												sqlQuery($sql, $res);
											}
										}
									}
								}
								
								// OK now redirect
								$req =& $this->getRef('Request');
								$req->redirectTo(MARKET_WEB_DIR . '/' . MARKET_LANG . '/account/settings/offer_edit.html?id=' . $offer_id);
							}
						}
					}
				}
				
				// Edit
				if ($_GET['id']) {
					$sql = "SELECT * FROM store_data WHERE id='" . sqlEscape($_GET['id']) . "' AND type='coupon' AND directory_id='" . sqlEscape($_SESSION['User']['store']) . "'";
					if (sqlQuery($sql, $res)) {
						$row = sqlFetchAssoc($res);
						if ($image_data = getImageData($_GET['id'])) {
							$row['filename'] = $image_data['data'];
							$row['image'] = MARKET_Filter::createThumbnail($image_data['data'], '240', true);
						}
						else {
							$_POST['image'] = MARKET_Filter::createThumbnail('foo', '240', true);
						}
						if ($row['date_from'] == '0000-00-00') $row['date_from'] = '';
						if ($row['date_to'] == '0000-00-00') $row['date_to'] = '';
						foreach ($row as $key => $val) {
							if ($key == 'image') {
								$_POST[$key] = $val;
							}
							else if (!$_POST[$key]) {
								$_POST[$key] = $val;
							}
						}
						$this->assignPHPVars($this->templates['offers_form']['text']);
						$this->assignPHPVars($this->templates['coupon']['text']);
						$this->assignGlobal('BUTTON.text', __('Update offer'));
					}
					else {
						$req =& $this->getRef('Request');
						$req->httpError(404);
					}
				}
				else {
					// New offer
					$_POST['image'] = MARKET_Filter::createThumbnail('foo', '240', true);
					$this->assignPHPVars($this->templates['coupon']['text']);
					$this->assignGlobal('BUTTON.text', __('Create offer'));
				}
				
			}
			else {
				$req =& $this->getRef('Request');
				$req->httpError(403);
			}
		}
		
		function getImageData($offer_id) {
			$row = array();
			$sql = "SELECT * FROM store_data WHERE id='" . sqlEscape($offer_id) . "' AND type='coupon' AND directory_id='" . sqlEscape($_SESSION['User']['store']) . "'";
			if (sqlQuery($sql, $res)) {
				$row = sqlFetchAssoc($res);
				$sql = "SELECT * FROM store_data WHERE type='image' AND name='" . sqlEscape($row['name']) . "' AND directory_id='" . sqlEscape($_SESSION['User']['store']) . "'";
				if (sqlQuery($sql, $res)) {
					$row = sqlFetchAssoc($res);
				}
			}
			return $row;
		}
		
	</php>
	
	<template name="css" assign="PAGE.Style">
		<link href="{MARKET.WebDir}/redist/datepicker/datepicker.css" rel="stylesheet" type="text/css" />
		<link href="{MARKET.WebDir}/redist/fileupload/css/jquery.fileupload-ui.css" rel="stylesheet" type="text/css" />
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
		<script type="text/javascript" src="{MARKET.WebDir}/redist/datepicker/bootstrap-datepicker.js"></script>
		<if expr="'{MARKET.Lang}' == 'el'">
			<script type="text/javascript" src="{MARKET.WebDir}/redist/datepicker/bootstrap-datepicker.el.js"></script>
		</if>
		<script src="{MARKET.WebDir}/redist/jquery.form/jquery.form.js"></script>
		<script src="{MARKET.WebDir}/redist/fileupload/js/vendor/jquery.ui.widget.js"></script>
		<script src="{MARKET.WebDir}/redist/fileupload/js/jquery.iframe-transport.js"></script>
		<script src="{MARKET.WebDir}/redist/fileupload/js/jquery.fileupload.js"></script>
		<script type="text/javascript">
			jQuery(document).ready(function() {
				setTimeout(function() { 
					$('.alert').fadeOut();
				}, 5000);
				
				// Datepicker
				$('.datepicker').datepicker({
					format: 'yyyy-mm-dd',
					startDate: '{TODAY}',
					language: '{MARKET.Lang}'
				});
				
				$("#title").on("keyup", function() { $(".coupon h3").text($("#title").val()); });
				$("#price").on("keyup", function() { if ($("#price").val()) { $(".coupon .price").show(); $(".coupon .price span.value").text($("#price").val()); } else $(".coupon .price").hide(); });
				$("#discount").on("keyup", function() { $(".coupon .discount span.value").text($("#discount").val()); });
				
				$('.add-icon').hover(function() {
					$(this).append('<div class="zoomOverlay" />');
					$(this).find('.zoomOverlay').css({
						opacity: 0,
						display: 'block',
						backgroundColor: '#000000'
					}); 
					$(this).find('.zoomOverlay').stop().animate({ opacity: 0.6 }, 300);
				}, function() {
					var $that = $(this).find('.zoomOverlay');
					$that.stop().animate({ opacity: 0 }, 300, function() {$that.remove()});
				});
				
				// Initialize the jQuery File Upload widget:
				$('#fileupload').fileupload({
					dataType: 'json',
					autoUpload: true,
					done: function (e, data) {
						$(this).find('.fileupload-buttonbar .progress').addClass('fade');
						$.each(data.result.files, function (index, file) {
							$('#mediaForm input[name="filename"]').val(file.url);
							$('.preview').html('<div class="well"><table width="100%"><tr><td align="center"><div><img class="original" src="' + file.thumbnail_url + '" width="240"></div></td></table></div>');
						});
					},
					progressall: function (e, data) {
						var $progress = $(this).find('.fileupload-buttonbar .progress');
						$progress.removeClass('fade');
						$progress.find('.bar').css( 'width', parseInt(data.loaded / data.total * 100, 10) + '%' );
					}
				});
				$('#mediaForm').ajaxForm({
					target: $('#coupon-image'),
					beforeSubmit: function() {
						$('#mainForm input[name="filename"]').val($('#mediaForm input[name="filename"]').val());
					}
				});
				$('#mediaButton').on('click', function(e) {
					$('#mediaForm').submit();
					$('#media').modal('hide');
					e.preventDefault();
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
				
				<template name="offers">
					<div id="offers" class="tab-pane" style="border: 1px solid #DFDFDF;">
						<div class="span6" style="float: none; margin: 0 auto; margin-top: 20px;">
							<template name="offers_form">
								<img src="{MARKET.WebDir}/img/promo.png" width="128" height="128" alt="" />
								<h2 style="margin-bottom: 20px; border-bottom: 1px solid #ddd;">{LANG.Edit your offer}</h2>
								{OFFER.Message}
								<div class="form-horizontal">
									<div class="control-group">
										<label class="control-label"></label>
										<div class="controls">
											<template name="coupon">
												<a class="add-icon" href="#media" data-toggle="modal">
													<div class="coupon span3" style="margin: 0;">
														<span id="coupon-image">{_POST.image}</span>
														<div>
															<h3>{_SAFE_POST.title}</h3>
															<p class="price"><span>{LANG.Price}:</span> <span class="value">{_SAFE_POST.price}</span></p>
														</div>
														<p class="discount"><span class="value" style="display: inline;">{_SAFE_POST.discount}</span>%</p>
													</div>
												</a>
												<div id="media" class="modal fade">
													<div class="modal-header">
														<a data-dismiss="modal" class="close">×</a>
														<h3>{LANG.Image upload}</h3>
													</div>
													<div class="modal-body">
														<form id="fileupload" action="{MARKET.LWebDir}/upload.html" method="POST" enctype="multipart/form-data">
															<div class="fileupload-buttonbar" style="float: left; width: 100%;">
																<span class="btn fileinput-button">
																<i class="icon-plus"></i>
																<span>{LANG.Change image}...</span>
																	<input type="file" name="files[]" accept="image/jpeg,image/gif,image/png">
																</span>
																<!-- The global progress bar -->
																<div class="progress progress-success progress-striped active fade" style="margin: 5px 0 0 210px;">
																	<div style="width:0%;" class="bar"></div>
																</div>
															</div>
															<div class="clearfix"></div>
															<div class="preview"><div class="well"><table width="100%"><tr><td align="center"><div>{_POST.image}</div></td></table></div></div>
														</form>
														<form id="mediaForm" method="POST" action="{MARKET.LWebDir}/upload.html">
															<input type="hidden" value="{_SAFE_POST.filename}" name="filename">
														</form>
													</div>
													<div class="modal-footer">
														<a class="btn btn-primary" id="mediaButton" href="#">{LANG.OK}</a>
														<a data-dismiss="modal" class="btn" href="#">{LANG.Cancel}</a>
													</div>
												</div>
											</template>
										</div>
									</div>
								</div>
								<form id="mainForm" class="form-horizontal" action="" method="POST">
									<fieldset>
										<div class="control-group{ERROR.Ctitle}">
											<label class="control-label" for="title">{LANG.Title}:</label>
											<div class="controls">
												<input class="span3" id="title" name="title" type="text" value="{_SAFE_POST.title}" />{ERROR.title}
											</div>
										</div>
										<div class="control-group{ERROR.Cdata}">
											<label class="control-label" for="data">{LANG.Description}:</label>
											<div class="controls">
												<textarea class="span3" id="data" name="data" rows="5">{_SAFE_POST.data}</textarea>{ERROR.data}
											</div>
										</div>
										<div class="control-group{ERROR.Cprice}">
											<label class="control-label" for="price">{LANG.Price}:</label>
											<div class="controls">
												<input class="span3" id="price" name="price" type="text" value="{_SAFE_POST.price}" />{ERROR.price}
												<span class="help-block"><small>{LANG.Enter the price of the discounted item. This is a free text field.}</small></span>
											</div>
										</div>
										<div class="control-group{ERROR.Cdiscount}">
											<label class="control-label" for="discount">{LANG.Discount}:</label>
											<div class="controls">
												<input class="span3" id="discount" name="discount" type="text" value="{_SAFE_POST.discount}" />{ERROR.discount}
												<span class="help-block"><small>{LANG.Enter the discount percent as a single number (i.e. without the %).}</small></span>
											</div>
										</div>
										<div class="control-group{ERROR.Cdate_from}">
											<label class="control-label" for="date_from">{LANG.Valid from}:</label>
											<div class="controls">
												<input class="span3 datepicker" type="text" id="date_from" name="date_from" value="{_SAFE_POST.date_from}" />{ERROR.date_from}
											</div>
										</div>
										<div class="control-group{ERROR.Cdate_to}">
											<label class="control-label" for="date_to">{LANG.Valid to}:</label>
											<div class="controls">
												<input class="span3 datepicker" type="text" id="date_to" name="date_to" value="{_SAFE_POST.date_to}" />{ERROR.date_to}
											</div>
										</div>
										<div class="form-actions white" style="border-top: none;">
											<button class="btn btn-primary" type="submit" id="user_submit" name="offers_form" value="true">{BUTTON.text}</button>
											<a class="btn" href="{MARKET.LWebDir}/account/settings/offers.html">{LANG.Cancel}</a>
										</div>
									</fieldset>
									<input type="hidden" name="filename" value="">
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
						<li><a href="{MARKET.LWebDir}/account/settings/business.html">{LANG.Business details}</a></li>
						<li class="active"><a href="{MARKET.LWebDir}/account/settings/offers.html">{LANG.Offers management}</a></li>
					</ul>
				</div>
			</template>
			
		</div>
	</div>
	
</template>