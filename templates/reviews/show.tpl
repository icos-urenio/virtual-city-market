<template parent="main" assign="PAGE.Body">
	
	<php>
		
		// Force SQL class load
		sqlQuery('SELECT foo', $res);
		
		$req =& $this->getRef('Request');
		
		if ($req->params[2]) {
			
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
								case 'page':
									$row['text-id'] = $row1['id'];
									$row['text-title'] = $row1['title'];
									$row['text'] = $row1['data'];
								break;
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
				
				// Comments
				if (is_array($row['comments'])) {
					
					foreach ($row['comments'] as $comment) {
						if ($user = getUser($comment['creator-id'])) {
							$comment['creator'] = $user['name'] . ' ' . $user['surname'];
							$comment['gravatar'] = '<img src="http://www.gravatar.com/avatar/' . $user['gravatar'] . '.jpg?d=mm&s=28" width="28" height="28" alt="' . $comment['creator'] . '" />';
						}
						$comment['created'] = getPeriodtoDate($comment['created']);
						$comment['comment'] = '<a name="comment' . $comment['comment-id'] . '"></a>' . htmlspecialchars($comment['comment']);
						$votes = explode("|", $comment['votes']);
						if ($total = $votes[0] + $votes[1]) {
							$comment['votes'] = $votes[0] . ' {LANG.of} ' . $total . ' {LANG.people} {LANG.found this review helpful}.';
							$comment['rate'] = '{LANG.Did you}{LANG.qmark}';
						}
						else {
							$comment['rate'] = '{LANG.Did you found this review helpful}{LANG.qmark}';
						}
						$this->assignLocal('comments', 'COMMENT', $comment);
						$this->parseTemplate('COMMENTS', 'comments');
						// Add divider
						$this->vars['global']['COMMENTS'] .= '<li class="divider"></li>';
					}
					// Remove last divider
					$this->vars['global']['COMMENTS'] = substr($this->vars['global']['COMMENTS'], 0, -(strlen('<li class="divider"></li>')));
					
					// Overall rating
					$sql = "SELECT COUNT(*) AS count, AVG(rating) AS rating FROM store_data WHERE name='index' AND type='comment' AND directory_id='" . $row['id'] . "'";
					if (sqlQuery($sql, $res1)) {
						$row1 = sqlFetchAssoc($res1);
						if ($row1['count']) {
							$row['rating'] = '<div class="well white">';
							$row['rating'] .= '<div class="pull-left" style="margin: 0; text-align: center;">';
							$row['rating'] .= '<div id="' . $row1['rating'] . '_' . $row['id'] . '" class="jrating" style="margin: 0 auto 10px auto;"></div>';
							$row['rating'] .= '(' . $row1['count'] . ' {LANG.reviews})';
							$row['rating'] .= '</div>';
							$row['rating'] .= '<div class="pull-right" style="margin: 10px 0;"><a class="btn" href=""><i class="icon-pencil"></i> {LANG.Write a review}</a></div>';
							$row['rating'] .= '<div class="clearfix"></div>';
							$row['rating'] .= '</div>';
						}
					}
					
				}
				else {
					$this->disableTemplate('comments_cnt');
				}
				
				$this->assignGlobal('PAGE.Title', $row['title']);
				$this->assignGlobal('QRCODE', $row['qrcode']);
				
				$this->assignGlobal('STORE', $row);
				$store = $row;
				
				// Google maps
				$this->assignGlobal('GMAPS', array(
					'api_key' => GMAP_API_KEY,
					'center_lat' => GMAP_CENTER_LAT,
					'center_lng' => GMAP_CENTER_LNG,
					'center_zoom' => GMAP_CENTER_ZOOM
				));
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
				$(".jrating").jRating({
					step: true,
					length: 5,
					isDisabled: true,
					bigStarsPath: '{MARKET.WebDir}/redist/jrating/icons/stars.png'
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
					
					<template name="comments_cnt">
						<h2 style="margin-bottom: 8px; margin-top: 20px;">{LANG.User reviews}</h2>
						{STORE.rating}
						<div class="span6">
							<ul class="comments unstyled">
								<template name="comments" divider="<li class='divider'></li>">
									<li>
										<div class="pull-left" style="margin: 6px 5px 5px 0;">{COMMENT.gravatar}</div>
										<small>{COMMENT.creator}<br><span class="muted">{COMMENT.created}</span></small>
										<div id="{COMMENT.rating}_{COMMENT.comment-id}" class="jrating"></div>
										<p>{nl2br:COMMENT.comment}</p>
										<small>{COMMENT.votes}</small>
										<small>{COMMENT.rate} &nbsp; <a class="btn btn-mini" href="#"><i class="icon-thumbs-up"></i> {LANG.Yes}</a> <a class="btn btn-mini" href="#"><i class="icon-thumbs-down"></i> {LANG.No}</a></small>
									</li>
								</template>
							</ul>
						</div>
					</template>
					
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