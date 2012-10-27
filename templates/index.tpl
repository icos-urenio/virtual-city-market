<template parent="main" assign="PAGE.Body" global="PAGE.Title: {LANG.Virtual City Market}; PAGE.Class: home">
	
	<php>
		// Featured
		$SELECT = "directory.*, directory_ml.*, IF (business_name = '', directory_ml.name, business_name) AS business_title, store_data.data AS image";
		$FROM = "directory STRAIGHT_JOIN directory_ml STRAIGHT_JOIN directory_ps STRAIGHT_JOIN store_data";
		$WHERE = "directory.id=directory_ml.id AND directory.id=directory_ps.id AND directory.id=store_data.directory_id AND store_data.name='index' AND store_data.type='image' AND directory_ml.lang='" . MARKET_LANG . "' AND directory_ps.publish='1'";
		$sql = "SELECT $SELECT FROM $FROM WHERE $WHERE GROUP BY directory.id ORDER BY RAND() LIMIT 0,4";
		if (sqlQuery($sql, $res)) {
			while ($row = sqlFetchAssoc($res)) {
				$row['address'] = ($row['address']) ? $row['address'] . ', ' . $row['city'] : $row['city'];
				$row['image'] = MARKET_Filter::createThumbnail($row['image'], '270x230', true, 'class="photo"');
				$this->assignLocal('featured', 'ROW', $row);
				$this->lightParseTemplate('FEATURED', 'featured');
			}
		}
		else {
			$this->disableTemplate('featured_cnt');
		}
		
		// Google maps
		$this->assignGlobal('GMAPS', array(
			'api_key' => GMAP_API_KEY,
			'center_lat' => GMAP_CENTER_LAT,
			'center_lng' => GMAP_CENTER_LNG,
			'center_zoom' => GMAP_CENTER_ZOOM
		));
	</php>
	
	<template name="css" assign="PAGE.Style">
		<link href="{MARKET.WebDir}/redist/flexslider/flexslider.css" rel="stylesheet" type="text/css" />
	</template>
	
	<template name="js" assign="PAGE.Javascript">
		<script type="text/javascript" src="{MARKET.WebDir}/redist/flexslider/jquery.flexslider-min.js"></script>
		<script type="text/javascript" src="http://maps.googleapis.com/maps/api/js?key={GMAPS.api_key}&sensor=true"></script>
		<script type="text/javascript" src="{MARKET.WebDir}/redist/gmaps.js"></script>
		<script>
		
			var map;
			
			google.maps.event.addDomListener(window, 'load', function() {
			
				infoWindow = new google.maps.InfoWindow({});
				
				map = new GMaps({
					div: '#map',
					lat: {GMAPS.center_lat},
					lng: {GMAPS.center_lng},
					zoom: {GMAPS.center_zoom},
					panControl: false,
					zoomControl: false,
					mapTypeControl: false,
					scaleControl: false,
					streetViewControl: false,
					overviewMapControl: false
				});
				
			});

			jQuery(window).load(function($) {
				jQuery('.flexslider').flexslider({
					animation: "fade",
					slideDirection: "horizontal",
					slideshow: true, 
					slideshowSpeed: 7000,
					animationDuration: 600,  
					directionNav: true,
					keyboardNav: true,
					randomize: false,
					pauseOnAction: true,
					pauseOnHover: false,
					controlsContainer: '.slideshow',
					animationLoop: true,
					controlNav: false
				});  
			});
		</script>
	</template>
	
	<div id="map"></div>
	
	<div class="container">
		
		<div class="row">
			<div class="span12">
				
				<div class="flex-container">
					<div class="flexslider span12">
						<div style="padding: 10px 40px 0;">
							<ul class="slides">
								<li>
									<img src="{MARKET.WebDir}/img/placeholder.jpg" width="256" height="256" alt="" />
									<div class="flex-caption">
										<h2>{LANG.Business Directory}</h2>
										<h4>Lorem ipsum dolor sit amet, consectetur adipiscing elit.</h4>
									</div>
									<p class="flex-action"><a class="btn btn-primary btn-large" href="{MARKET.LWebDir}/directory/index.html">{LANG.Search the directory} &raquo;</a></p>
								</li>
								<li>
									<img src="{MARKET.WebDir}/img/placeholder.jpg" width="256" height="256" alt="" />
									<div class="flex-caption">
										<h2>{LANG.City Marketplace}</h2>
										<h4>Fusce purus erat, fermentum ut aliquet in, pharetra commodo lorem.</h4>
									</div>
									<p class="flex-action"><a class="btn btn-primary btn-large" href="{MARKET.LWebDir}/marketplace/index.html">{LANG.Browse the marketplace} &raquo;</a></p>
								</li>
								<li>
									<img src="{MARKET.WebDir}/img/placeholder.jpg" width="256" height="256" alt="" />
									<div class="flex-caption">
										<h2>{LANG.Offers and Coupons}</h2>
										<h4>Fusce purus erat, fermentum ut aliquet in, pharetra commodo lorem.</h4>
									</div>
									<p class="flex-action"><a class="btn btn-primary btn-large" href="{MARKET.LWebDir}/offers/index.html">{LANG.Find offers} &raquo;</a></p>
								</li>
								<li>
									<img src="{MARKET.WebDir}/img/placeholder.jpg" width="256" height="256" alt="" />
									<div class="flex-caption">
										<h2>{LANG.User Reviews}</h2>
										<h4>Donec magna lorem, suscipit non tristique ut, cursus accumsan sapien.</h4>
									</div>
									<p class="flex-action"><a class="btn btn-primary btn-large" href="{MARKET.LWebDir}/reviews/index.html">{LANG.Read reviews} &raquo;</a></p>
								</li>
							</ul>
						</div>	
					</div>
				</div>
				
			</div>
		</div>
		
		<template name="featured_cnt">
			<div class="row">
				<section id="featured-listings">
					<h3 class="border-bottom span12"><span>{LANG.Featured Listings}</span></h3>
					<template name="featured">
						<article class="span3">
							<div class="img-wrap">
								<a href="{MARKET.LWebDir}/marketplace/{ROW.path}">{ROW.image}</a>
							</div>
							<div class="featured-listing-info">
								<h6><a href="{MARKET.LWebDir}/marketplace/{ROW.path}">{ROW.business_title}</a></h6>
								<p>{ROW.address}</p>
							</div>	
						</article>
					</template>
				</section>
			</div>
		</template>
		
	</div>
</div>
</template>