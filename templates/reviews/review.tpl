<template parent="main" assign="PAGE.Body" permissions="registered">
	
	<php>
		
		// Force SQL class load
		sqlQuery('SELECT foo', $res);
		
		$req =& $this->getRef('Request');
		
		if ($req->params[2] == 'review') {
			
			$SELECT = "*, IF (business_name = '', name, business_name) AS title";
			$FROM = "directory STRAIGHT_JOIN directory_ml STRAIGHT_JOIN directory_ps";
			$WHERE = "directory.id=directory_ml.id AND directory.id=directory_ps.id AND directory_ml.lang='" . MARKET_LANG . "' AND directory_ps.publish='1'";
			
			$WHERE .= " AND directory.path='" . sqlEscape($req->params[1]) . "'";
			
			$sql = "SELECT $SELECT FROM $FROM WHERE $WHERE";
			if (sqlQuery($sql, $res)) {
				
				$row = sqlFetchAssoc($res);
				$row['address'] = ($row['address']) ? $row['address'] . ', ' . $row['city'] : $row['city'];
				
				// Main page
				$sql = "SELECT * FROM store_data STRAIGHT_JOIN store_data_ps WHERE store_data.id=store_data_ps.id AND store_data_ps.publish='1' AND directory_id='" . $row['id'] . "' AND (lang='' OR lang='" . MARKET_LANG . "') AND name='index' AND type<>'page' AND (date_from = '0000-00-00' OR date_from < '" . date('Y-m-d') . "') AND (date_to = '0000-00-00' OR date_to > '" . date('Y-m-d') . "') ORDER BY ord";
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
								case 'comment':
									$row['comments'][] = array();
									$index = count($row['comments']) - 1;
									$row['comments'][$index]['comment-id'] = $row1['id'];
									$row['comments'][$index]['creator-id'] = $row1['creator'];
									$row['comments'][$index]['created'] = $row1['created'];
									$row['comments'][$index]['rating'] = $row1['rating'];
									$row['comments'][$index]['votes'] = $row1['votes'];
									$row['comments'][$index]['comment'] = $row1['data'];
								break;
								
								default:
									$row[$row1['type'] . '-id'] = $row1['id'];
									$row[$row1['type']] = $row1['data'];
							}
						}
					}
				}
				
				// Image
				if (is_array($row['image'])) {
					$row['image'] = MARKET_Filter::createThumbnail($row['image'][0], '100', true, 'class="pull-left" style="margin-right: 10px;"');
				}
				else if ($row['image']) {
					$row['image'] = MARKET_Filter::createThumbnail($row['image'], '100', true, 'class="pull-left" style="margin-right: 10px;"');
				}
				
				$this->assignGlobal('PAGE.Title', $row['title']);
				
				$this->assignGlobal('STORE', $row);
				$store = $row;
				
				// Google maps
				$this->assignGlobal('GMAPS', array(
					'api_key' => GMAP_API_KEY,
					'center_lat' => GMAP_CENTER_LAT,
					'center_lng' => GMAP_CENTER_LNG,
					'center_zoom' => GMAP_CENTER_ZOOM
				));
				
				
				if ($_POST && count($_POST)) {
					if ($_POST['comment']) {
						$sql = "INSERT INTO store_data(id, directory_id, name, type, votes, data) VALUES ('', '" . $store['id'] . "', 'index', 'comment', '', '" . sqlEscape($_POST['comment']) . "')";
						if ($id = sqlQuery($sql, $res)) {
							// Insert permissions
							$sql = "INSERT INTO store_data_ps (id, creator, created, owner, role, updated, ups, gps, wps, publish) VALUES('" . $id . "', '" . $_SESSION['User']['user_id'] . "', NOW(), '" . $_SESSION['User']['user_id'] . "', '" . $_SESSION['User']['market_role_id'] . "', NOW(), '7', '2', '2', '1')";
							sqlQuery($sql, $res);
						}
						if ($_POST['rating']) {
							$sql = "UPDATE store_data SET rating='" . sqlEscape($_POST['rating']) . "' WHERE id='" . $id . "'";
							sqlQuery($sql, $res);
						}
					}
					// Redirect
					$req->redirectTo(MARKET_WEB_DIR . '/' . MARKET_LANG . '/reviews/' . $req->params[1] . '/show.html');
				}
			}
			else {
				$req->httpError(404);
			}
		}
		else {
			$req->httpError(404);
		}
		
	</php>
	
	<template name="jrating_css" assign="PAGE.Style">
		<link href="{MARKET.WebDir}/redist/jrating/jRating.jquery.css" rel="stylesheet" type="text/css" />
	</template>
	
	<template name="jrating_js" assign="PAGE.Javascript">
		<script src="{MARKET.WebDir}/redist/jrating/jRating.jquery.js"></script>
		<script>
			jQuery(document).ready(function($) {
				$(".jrate").jRating({
					length: 5,
					rateMax: 5,
					decimalLength: 1,
					nbRates: 1000,
					canRateAgain: true,
					bigStarsPath: '{MARKET.WebDir}/redist/jrating/icons/stars.png',
					phpPath: '../ajax.html',
					onSuccess: function(el, data) {
						$('#rating').val(data);
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
			function log(h) {
				document.getElementById("log").innerHTML += h + "<br />";
			};
			
		</script>
	</template>
	
	<div class="container">
		
		<div class="row">
			<div class="span12">
				<header id="archive-header">
					<h1 class="span6" style="margin-left: 0;"><a href="{MARKET.LWebDir}/marketplace/{MARKET.Params.1}">{PAGE.Title}</a></h1>
				</header>
			</div>
		</div>
		
		<template name="store">
			<div class="row">
			
				<div class="span7">
				
					<div style="margin-top: 10px;">
						{STORE.image}
						<h3 style="line-height: 18px;">{STORE.byline}</h3>
						<address>
							<div>{STORE.address}</div>
							<div>{STORE.phone}</div>
							<div id="store-url">{autolink:STORE.url}</div>
						</address>
						<div class="clearfix"></div>
					</div>
					
					<h2 style="margin-bottom: 8px; margin-top: 20px;">{LANG.Write a review}</h2>
					
					<form accept-charset="UTF-8" action="" method="post" style="margin: 0;">
						<div>
							{LANG.Your rating}:
							<div data-average="0" data-id="{STORE.id}" class="jrate"></div>
						</div>
						<div style="margin-top: 20px;">
							{LANG.Your comment}:
							<textarea style="width: 98%; height: 150px;" rows="7" id="comment" name="comment" value=""></textarea>
						</div>
						<div class="modal-footer">
							<button id="submit" name="submit" class="btn btn-primary" type="submit">{LANG.OK}</button>
							<a class="btn" href="javascript:history.go(-1)">{LANG.Cancel}</a>
						</div>
						<input type="hidden" id="rating" name="rating" value="">
					</form>
					
				</div>
				
				<div class="span5">
					<div class="well white">
						<div id="map-wrap"><div id="map"></div></div>
						<div class="pull-right"><a class="btn" href="{MARKET.LWebDir}/marketplace/{STORE.path}/index.html">{LANG.Go to the store} &raquo;</a></div>
						<div class="clearfix"></div>
					</div>
				</div>
				
			</div>
			
		</template>
		
	</div>
	
</template>