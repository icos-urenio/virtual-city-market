<template parent="main" assign="PAGE.Body">
	
	<php>
		
		// Force SQL class load
		sqlQuery('SELECT foo', $res);
		
		$req =& $this->getRef('Request');
		
		$SELECT = "*, IF (business_name = '', name, business_name) AS business_title";
		$FROM = "directory STRAIGHT_JOIN directory_ml STRAIGHT_JOIN directory_ps";
		$WHERE = "directory.id=directory_ml.id AND directory.id=directory_ps.id AND directory_ml.lang='" . MARKET_LANG . "' AND directory_ps.publish='1' AND directory.path='" . sqlEscape($req->params[1]) . "'";
		
		$sql = "SELECT $SELECT FROM $FROM WHERE $WHERE";
		if (sqlQuery($sql, $res)) {
			$row = sqlFetchAssoc($res);
			$row['address'] = ($row['address']) ? $row['address'] . ', ' . $row['city'] : $row['city'];
			
			// Offer
			$sql = "SELECT * FROM store_data STRAIGHT_JOIN store_data_ps WHERE store_data.id=store_data_ps.id AND store_data_ps.publish='1' AND directory_id='" . $row['id'] . "' AND (lang='' OR lang='" . MARKET_LANG . "') AND name='" . sqlEscape($req->params[2]) . "' AND (date_from = '0000-00-00' OR date_from < '" . date('Y-m-d') . "') AND (date_to = '0000-00-00' OR date_to > '" . date('Y-m-d') . "') ORDER BY ord";
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
						if ($row1['type'] == 'coupon') {
							foreach ($row1 as $key => $val) {
								if ($key != 'id') {
									$row[$key] = $val;
								}
							}
						}
						else {
							$row[$row1['type']] = $row1['data'];
						}
					}
				}
			}
			
			if ($_GET['device'] == 'mobile') {
				$this->disableTemplate('coupons_cnt');
				if (is_array($row['image'])) {
					$row['image'] = MARKET_Filter::createThumbnail($row['image'][0], '320x480', true, 'class="photo"');
				}
				else {
					$row['image'] = MARKET_Filter::createThumbnail($row['image'], '320x380', true, 'class="photo"');
				}
				$this->assignGlobal('PAGE.Title', $row['title']);
				$this->assignGlobal('ROW', $row);
				$this->lightParseTemplate('MOBILE', 'mobile');
				print $this->printTemplate('MOBILE');
				exit;
			}
			else {
				$this->disableTemplate('mobile');
			}
			
			// Gallery
			if (is_array($row['image'])) {
				$str = '<div class="flexslider">';
				$str .= '<ul class="slides">';
				foreach($row['image'] as $image) {
					$str .= '<li>' . MARKET_Filter::createThumbnail($image, '570x380', true, 'class="photo"') . '</li>';
				}
				$str .= '</ul>';
				$str .= '</div>';
				$row['image'] = $str;
				$this->enableTemplate('flexslider_js');
				$this->enableTemplate('flexslider_css');
			}
			else if ($row['image']) {
				$row['image'] = MARKET_Filter::createThumbnail($row['image'], '570x380', true, 'class="photo"');
			}
			
			// QR code
			$row['qrcode'] = MARKET_Filter::marketQRCode('http://' . $_SERVER['HTTP_HOST'] . MARKET_WEB_DIR . '/' . MARKET_LANG . '/offers/' . $row['path'] . '/' . $row['name'] . '.html?device=mobile');
			
			// Duration
			if ($row['date_to'] != '0000-00-00' && preg_match('@(\d{4})-(\d{2})-(\d{2})@', $row['date_to'], $matches)) {
				$row['date'] = '<h3 class="duration"><span><b>{LANG.Offer valid}:</b></span> {LANG.until} ' . MARKET_Filter::marketDate($row['date_to'], 'j M Y') . '</h3>';
			}
			
			// More Offers
			$sql = "SELECT * FROM store_data STRAIGHT_JOIN store_data_ps WHERE store_data.id=store_data_ps.id AND store_data_ps.publish='1' AND directory_id='" . $row['id'] . "' AND name<>'" . sqlEscape($row['name']) . "' AND (lang='' OR lang='" . MARKET_LANG . "') AND type='coupon' AND (date_from = '0000-00-00' OR date_from < '" . date('Y-m-d') . "') AND (date_to = '0000-00-00' OR date_to > '" . date('Y-m-d') . "') ORDER BY ord";
			if (sqlQuery($sql, $res1)) {
				while ($row1 = sqlFetchAssoc($res1)) {
					$row1['path'] = $req->params[1];
					// What else is available?
					$sql = "SELECT * FROM store_data STRAIGHT_JOIN store_data_ps WHERE store_data.id=store_data_ps.id AND store_data_ps.publish='1' AND directory_id='" . $row['id'] . "' AND (lang='' OR lang='" . MARKET_LANG . "') AND type <> 'coupon' AND name='" . sqlEscape($row1['name']) . "' AND (date_from = '0000-00-00' OR date_from < '" . date('Y-m-d') . "') AND (date_to = '0000-00-00' OR date_to > '" . date('Y-m-d') . "') ORDER BY ord";
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
					
					$this->assignLocal('coupon', 'ROW', $row1);
					$this->lightParseTemplate('COUPON', 'coupon');
				}
			}
			else {
				$this->disableTemplate('coupons_cnt');
			}
			
			$this->assignGlobal('PAGE.Title', $row['title']);
			$this->assignGlobal('QRCODE', $row['qrcode']);
			$this->assignGlobal('ROW', $row);
			
		}
		else {
			$req->httpError(404);
		}
		
	</php>
	
	<template name="flexslider_css" assign="PAGE.Style" disabled="true">
		<link href="{MARKET.WebDir}/redist/flexslider/flexslider.css" rel="stylesheet" type="text/css" />
	</template>
	
	<template name="jrating_css" assign="PAGE.Style" disabled="true">
		<link href="{MARKET.WebDir}/redist/jrating/jRating.jquery.css" rel="stylesheet" type="text/css" />
	</template>
	
	<template name="flexslider_js" assign="PAGE.Javascript" disabled="true">
		<script type="text/javascript" src="{MARKET.WebDir}/redist/flexslider/jquery.flexslider-min.js"></script>
		<script>
			jQuery(document).ready(function($) {
				$('.flexslider').flexslider();
			});
		</script>
	</template>
	
	<template name="jrating_js" assign="PAGE.Javascript" disabled="true">
		<script src="{MARKET.WebDir}/redist/jrating/jRating.jquery.js"></script>
		<script>
			jQuery(document).ready(function($) {
				$(".jrating").jRating({
					step: true,
					length: 5,
					isDisabled: true,
					bigStarsPath: '{MARKET.WebDir}/redist/jrating/icons/stars.png'
				});
			});
		</script>
	</template>
	
	<template name="snippets" assign="PAGE.Javascript" disabled="true">
		<script>
			jQuery(window).on('mercury:ready', function() {
				Mercury.Snippet.load({
					snippet_1: {name: 'example', options: {'options[favorite_beer]': "Bells Hopslam", 'options[first_name]': "Jeremy"}}
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
				lat: 40.546868,
				lng: 23.020292,
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
										draggable : false,
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
						map.fitZoom();
						setTimeout(function(){
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
					<h1><a href="{MARKET.LWebDir}/marketplace/{MARKET.Params.1}">{PAGE.Title}</a></h1>
				</header>
			</div>
		</div>
		
		<div class="row">
			
			<div class="span7">
			
				<div class="coupon" style="margin-top: 20px;">
					{ROW.image}
					<p style="margin-top: 20px;">{nl2br:ROW.data}</p>
					<h3 class="price"><span><b>{LANG.Price}:</b></span> {ROW.price}</h3>
					{ROW.date}
					<p class="discount" style="margin-right: 70px;"><span>{LANG.Discount}:</span> {ROW.discount}%</p>
				</div>
				
				<template name="coupons_cnt">
					<h2 style="margin-top: 40px; margin-bottom: 10px;">{LANG.More offers}</h2>
					<div class="coupons row">
						<template name="coupon">
							<a href="{MARKET.LWebDir}/offers/{ROW.path}/{ROW.name}.html">
							<div class="coupon span3">
								{ROW.image}
								<div>
									<h3>{ROW.title}</h3>
									<p class="price"><span>{LANG.Price}:</span> {ROW.price}</p>
								</div>
								<p class="discount"><span>{LANG.Discount}:</span> {ROW.discount}%</p>
							</div>
							</a>
						</template>
					</div>
				</template>
				
			</div>
			
			<div class="span5">
				
				<div class="well white" style="text-align: center;">
					<h3>{LANG.This offer on your mobile}</h3>
					<img src="{QRCODE}" />
					<p><small>{LANG.Load this offer on your mobile and show it at the store to get the discount}</small></p>
				</div>
				
				<div class="well white">
					<h2><a href="{MARKET.LWebDir}/marketplace/{ROW.path}/index.html">{ROW.business_name}</a></h2>
					<h3 style="line-height: 18px;">{ROW.byline}</h3>
					<address>
						{ROW.address}<br />
						{LANG.tel}. {ROW.phone}
					</address>
					
					<div id="map-wrap"><div id="map"></div></div>
					
					<p class="pull-right"><a class="btn" href="{MARKET.LWebDir}/marketplace/{ROW.path}/index.html">{LANG.Go to the store} &raquo;</a></p>
					
					<div class="clearfix"></div>
				</div>
				
			</div>
		</div>
		
	</div>
	
	<template name="mobile">
		<!DOCTYPE html>
		<!-- paulirish.com/2008/conditional-stylesheets-vs-css-hacks-answer-neither/ -->
		<!--[if lt IE 7]> <html class="no-js lt-ie9 lt-ie8 lt-ie7" lang="{MARKET.Lang}"> <![endif]-->
		<!--[if IE 7]>    <html class="no-js lt-ie9 lt-ie8" lang="{MARKET.Lang}"> <![endif]-->
		<!--[if IE 8]>    <html class="no-js lt-ie9" lang="{MARKET.Lang}"> <![endif]-->
		<!--[if gt IE 8]><!--> <html class="no-js" lang="{MARKET.Lang}"> <!--<![endif]-->
			<head>
				<meta charset="utf-8">
				
				<title>{strip_tags:PAGE.Title}</title>
				
				<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1, user-scalable=no">
				<link rel="stylesheet" href="{MARKET.WebDir}/redist/bootstrap/css/bootstrap.min.css">
				
				<script src="{MARKET.WebDir}/redist/modernizr-2.5.3.min.js"></script>
				
				<link href="{MARKET.WebDir}/css/style.css" rel="stylesheet" type="text/css" />
			</head>
			<body>
				
				<div class="coupon">
					{ROW.image}
					<div>
						<h3>{ROW.title}</h3>
						<p class="price"><span>{LANG.Price}:</span> {ROW.price}</p>
					</div>
					<p class="discount"><span>{LANG.Discount}:</span> {ROW.discount}%</p>
				</div>
				<div class="well white">
					<h2>{ROW.business_name}</h2>
					<h3 style="line-height: 18px;">{ROW.byline}</h3>
					<address>
						{ROW.address}<br />
						{LANG.tel}. {ROW.phone}
					</address>
					<div class="clearfix"></div>
				</div>
				
			</body>
		</html>
	</template>
	
</template>