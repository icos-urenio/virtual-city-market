<template parent="main" assign="PAGE.Body" global="PAGE.Title: {LANG.Business Directory}">
	
	<php>
		
		$lng =& $this->getRef('Lang');
		
		$lng->strs['item_total'] = '{LANG.business}';
		$lng->strs['items_total'] = '{LANG.businesses}';
		
		// Force SQL class load
		sqlQuery('SELECT foo', $res);
		
		$sql = "SELECT category FROM directory_ml WHERE lang='" . MARKET_LANG . "' GROUP BY category ORDER BY category";
		if (sqlQuery($sql, $res)) {
			$i = 1;
			while ($row = sqlFetchAssoc($res)) {
				$str = '';
				$sql = "SELECT prof1, prof2, prof3 FROM directory_ml WHERE category='" . sqlEscape($row['category']) . "'";
				if (sqlQuery($sql, $res1)) {
					$tags = array();
					while ($row1 = sqlFetchAssoc($res1)) {
						for ($j = 1; $j <= 3; $j++) {
							if ($row1['prof' . $j] && !in_array($row1['prof' . $j], $tags)) {
								$tags[] = $row1['prof' . $j];
							}
						}
					}
					asort($tags);
					if ($_COOKIE['mplace_menu'] & pow(2, $i - 1)) {
						$str = '<ul id="ul' . $i . '" class="tags in collapse">';
					}
					else {
						$str = '<ul id="ul' . $i . '" class="tags collapse">';
					}
					foreach ($tags as $tag) {
						$str .= '<li><a href="{MARKET.LWebDir}/directory/index.html?content=tag&q='.urlencode($tag).'">' . htmlspecialchars($tag) . '</a></li>';
					}
					$str .= '</ul>';
				}
				$this->assignLocal('category', 'ROW', array(
					'ndx' => $i,
					'title' => $row['category'],
					'tags' => $str
				));
				$this->lightParseTemplate('CATEGORY', 'category');
				$i++;
			}
		}
		
		// Cities
		$sql = "SELECT city FROM directory_ml GROUP BY city ORDER BY city";
		if (sqlQuery($sql, $res)) {
			$cities = array();
			while ($row = sqlFetchAssoc($res)) {
				$cities[] = $row['city'];
			}
			asort($cities);
			$str = '';
			foreach ($cities as $city) {
				$str .= '<li><a href="{MARKET.LWebDir}/directory/index.html?content=city&q='.urlencode($city).'">' . htmlspecialchars($city) . '</a></li>';
			}
			$this->assignGlobal('CATEGORIES.Cities', $str);
		}
		
		$SELECT = "*, IF (business_name = '', name, business_name) AS title";
		$FROM = "directory STRAIGHT_JOIN directory_ml STRAIGHT_JOIN directory_ps";
		$WHERE = "directory.id=directory_ml.id AND directory.id=directory_ps.id AND directory_ml.lang='" . MARKET_LANG . "' AND directory_ps.publish='1' ORDER BY title";
		
		if ($_GET['q']) {
			$this->assignGlobal('GET.q', htmlspecialchars($_GET['q']));
			$srh =& $this->getRef('Search');
			
			if ($_GET['content'] == 'city') {
				$search_in = 'city';
				$search_as = 'exact';
				$_GET['q'] = '"' . $_GET['q'] . '"';
			}
			else {
				$search_in = 'name, business_name, category, prof1, prof2, prof3, byline, address';
				$search_as = '';
			}
			$cmd = "SEARCH IN " . $search_in . " OF $FROM RETURN $SELECT WHERE " . $WHERE . "";
			$sql = $srh->searchFor($_GET['q'], $cmd, $search_as);
		}
		else {
			$sql = "SELECT $SELECT FROM $FROM WHERE $WHERE";
		}
		
		$this->assignNavigationValues($sql, 'default', 0, 20, 50, true);
		
		if (sqlQuery($sql, $res)) {
			$this->disableTemplate('no-results');
			while ($row = sqlFetchAssoc($res)) {
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
				$this->assignLocal('result', 'ROW', $row);
				$this->lightParseTemplate('RESULT', 'result');
			}
		}
		else {
			$this->disableTemplate('results');
		}
		
		// Google maps
		$this->assignGlobal('GMAPS', array(
			'api_key' => GMAP_API_KEY,
			'center_lat' => GMAP_CENTER_LAT,
			'center_lng' => GMAP_CENTER_LNG,
			'center_zoom' => GMAP_CENTER_ZOOM
		));
		
		function fix_toolbar($str) {
			$str = preg_replace('@<a class="@', '<a class="btn ', $str);
			$str = preg_replace('@<a href="@', '<a class="btn" href="', $str);
			$str = preg_replace('@><i>' . __('First') . '</i>@', ' title="' . __('First') . '" rel="tooltip"><i class="icon-fast-backward"></i>', $str);
			$str = preg_replace('@><i>' . __('Last') . '</i>@', ' title="' . __('Last') . '" rel="tooltip"><i class="icon-fast-forward"></i>', $str);
			$str = preg_replace('@><i>' . __('Previous') . '</i>@', ' title="' . __('Previous') . '" rel="tooltip"><i class="icon-backward"></i>', $str);
			$str = preg_replace('@><i>' . __('Next') . '</i>@', ' title="' . __('Next') . '" rel="tooltip"><i class="icon-forward"></i>', $str);
			return '<div class="btn-group">' . $str . '</div>';
		}
		
	</php>
	
	<div class="container">
		
		<div class="row">
			<div class="span12">
				<header id="archive-header">
					<h1>{LANG.Business Directory}</h1>
				</header>
			</div>
		</div>
		
		<div class="row">
			<div class="span8">
				
				<div id="map-wrap">
					<script type="text/javascript" src="http://maps.googleapis.com/maps/api/js?key={GMAPS.api_key}&sensor=true"></script>
					<script type="text/javascript" src="{MARKET.WebDir}/redist/gmaps.js"></script>
					<script>
						
						var map = null;
						var marker_me = null;
						var markers = null;
						
						google.maps.event.addDomListener(window, 'load', function(){
							
							map = new GMaps({
								div: '#map',
								lat: {GMAPS.center_lat},
								lng: {GMAPS.center_lng},
								zoom: {GMAPS.center_zoom},
								panControl: false,
								streetViewControl: false
							});
							
							// Geolocation
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
								url: "ajax.html?" + $.url().attr('query'),
								dataType: "json",
								success: function(response) {
									markers = map.addMarkers(response);
									map.fitZoom();
									setTimeout(function(){
										if (map.getZoom() > 17) map.setZoom(17);
									}, 100);
								}
							});
						});
						
					</script>
					<div id="map"></div>
				</div>
				
				<div class="clearfix"></div>
				
				<form class="well form-inline">
					<label><b>{LANG.Search}:</b></label>
					&nbsp;
					<input name="q" type="text" value="{GET.q}" placeholder="{LANG.Keywords}">
					&nbsp;
					<label class="checkbox">
						<input name="near" type="checkbox" data-toggle="modal" data-target="#not-implemented"> {LANG.Near me}
					</label>
					&nbsp;
					<button class="btn btn-primary" type="submit">{LANG.Go}</button>
				</form>
				
				<template name="results">
					<div class="results">
						
						<div>
							<div class="pull-left" style="margin-top: 5px;">{LANG.Found} {NAV.Found}</div>
							<div class="pull-right">{fix_toolbar:NAV.Toolbar}</div>
						</div>
						
						<div class="clearfix"></div>
						
						<ul class="listing unstyled" style="margin-top: 10px;">
							<template name="result">
								<li>
									<div class="pull-left span5">
										<h2 title="{ROW.id}"><a href="{MARKET.LWebDir}/marketplace/show.html?id={ROW.id}">{ROW.title}</a></h2>
										<h3 style="line-height: 18px;">{ROW.byline}</h3>
										<address>
											{ROW.address}<br />
											{LANG.tel}. {ROW.phone}
										</address>
										<div class="clearfix" style="margin: 10px 0 10px -10px;">{ROW.tags}</div>
										<p><a class="blue" href="{MARKET.LWebDir}/marketplace/show.html?id={ROW.id}">{LANG.More info} &raquo;</a></p>
									</div>
									<div class="pull-right" style="margin: 15px 5px 0 0; width: 115px; text-align: center;">
										{ROW.show_on_map}
									</div>
									<div class="clearfix"></div>
								</li>
							</template>
						</ul>
						
						<div class="clearfix"></div>
						
						<div class="double-border"><p><small><span>{NAV.Pages}</span></small></p></div>
						
					</div>
				</template>
				<template name="no-results">
					<div class="alert alert-info info well">
						<button class="close" data-dismiss="alert" type="button">×</button>
						{LANG.No results}...
					</div>
				</template>
				
			</div>
			
			<div class="mplace_menu menu span4">
				
				<ul id="ul0" class="well nav nav-list">
					<li><h3 style="border-bottom: 1px solid #ccc;">{LANG.Categories}</h3></li>
					<template name="category">
						<li><a class="collapse-toggle" href="#ul{ROW.ndx}" data-toggle="collapse" data-parent="#ul0">{ROW.title}<span class="caret pull-right"></span></a>
							{ROW.tags}
						</li>
					</template>
				</ul>
				
				<ul class="well nav nav-list" style="margin-top: 20px;">
					<li><h3 style="border-bottom: 1px solid #ccc;">{LANG.Cities}</h3></li>
					{CATEGORIES.Cities}
				</ul>
				
			</div>
			
		</div>
	</div>
	
</template>