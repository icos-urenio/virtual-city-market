<template parent="main" assign="PAGE.Body" global="PAGE.Title: {LANG.Reviews}">
	
	<php>
		
		$lng =& $this->getRef('Lang');
		
		$lng->strs['item_total'] = '{LANG.business with reviews}';
		$lng->strs['items_total'] = '{LANG.businesses with reviews}';
		
		// Force SQL class load
		sqlQuery('SELECT foo', $res);
		
		include(MARKET_TEMPLATE_DIR . '/categories.php');
		
		$SELECT = "directory.*, directory_ml.*, IF (business_name = '', directory_ml.name, business_name) AS business_title";
		$FROM = "directory STRAIGHT_JOIN directory_ml STRAIGHT_JOIN directory_ps STRAIGHT_JOIN store_data STRAIGHT_JOIN store_data_ps";
		$WHERE = "directory.id=directory_ml.id AND directory.id=directory_ps.id AND directory.id=store_data.directory_id AND store_data.id=store_data_ps.id AND store_data.type='comment' AND directory_ml.lang='" . MARKET_LANG . "' AND store_data.lang='" . MARKET_LANG . "' AND directory_ps.publish='1' GROUP BY directory.id ORDER BY business_title";
		
		if ($_GET['q']) {
			$this->assignGlobal('GET.q', htmlspecialchars($_GET['q']));
			$srh =& $this->getRef('Search');
			
			if ($_GET['content'] == 'city') {
				$search_in = 'city';
				$search_as = 'exact';
				$_GET['q'] = '"' . $_GET['q'] . '"';
			}
			else {
				$search_in = 'directory_ml.name, business_name, category, prof1, prof2, prof3, byline, address';
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
						$row['tags'] .= '<li><a href="{MARKET.LWebDir}/reviews/index.html?content=tag&q='.urlencode($tag).'">' . htmlspecialchars($tag) . '</a></li>';
					}
					$row['tags'] .= '</ul>';
				}
				
				// Rating
				$sql = "SELECT COUNT(*) AS count, AVG(rating) AS rating FROM store_data STRAIGHT_JOIN store_data_ps WHERE store_data.id=store_data_ps.id AND store_data_ps.publish='1' AND store_data.lang='" . MARKET_LANG . "' AND name='index' AND type='comment' AND rating <> '' AND directory_id='" . $row['id'] . "'";
				if (sqlQuery($sql, $res1)) {
					$row1 = sqlFetchAssoc($res1);
					if ($row1['count']) {
						$row['rating'] = '<div style="margin-top: 20px; text-align: center;">';
						$row['rating'] .= '<div data-average="' . $row1['rating'] . '" data-id="' . $row['id'] . '" class="jrating" style="margin: 0 auto 10px auto;"></div>';
						$row['rating'] .= '(' . $row1['count'] . (($row1['count'] == 1) ? ' {LANG.review}' : ' {LANG.reviews}') . ')';
						$row['rating'] .= '</div>';
					}
				}
				
				// Image
				$sql = "SELECT * FROM store_data STRAIGHT_JOIN store_data_ps WHERE store_data.id=store_data_ps.id AND store_data_ps.publish='1' AND directory_id='" . $row['id'] . "' AND (lang='' OR lang='" . MARKET_LANG . "') AND type='image' AND name='index' AND (date_from = '0000-00-00' OR date_from < '" . date('Y-m-d') . "') AND (date_to = '0000-00-00' OR date_to > '" . date('Y-m-d') . "') ORDER BY ord";
				if (sqlQuery($sql, $res1)) {
					$row1 = sqlFetchAssoc($res1);
					$row['image'] = MARKET_Filter::createThumbnail($row1['data'], '100', true, 'class="pull-left" style="margin-top: 7px;"');
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
	
	<template name="jrating_css" assign="PAGE.Style">
		<link href="{MARKET.WebDir}/redist/jrating/jRating.jquery.css" rel="stylesheet" type="text/css" />
	</template>
	
	<template name="jrating_js" assign="PAGE.Javascript">
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
	
	<div class="container">
		
		<div class="row">
			<div class="span12">
				<header id="archive-header">
					<h1>{LANG.User Reviews}</h1>
				</header>
			</div>
		</div>
		
		<div class="row">
			<div class="span8">
				
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
									<a href="{MARKET.LWebDir}/reviews/{ROW.path}/show.html">{ROW.image}</a>
									<div class="pull-left span5">
										<h2 title="{ROW.id}"><a href="{MARKET.LWebDir}/reviews/{ROW.path}/show.html">{ROW.business_title}</a></h2>
										<h3 style="line-height: 18px;">{ROW.byline}</h3>
										<address>
											{ROW.address}<br />
											{LANG.tel}. {ROW.phone}
										</address>
										<div class="clearfix" style="margin: 10px 0 10px -10px;">{ROW.tags}</div>
										<p><a class="blue" href="{MARKET.LWebDir}/reviews/{ROW.path}/show.html">{LANG.All reviews} &raquo;</a></p>
									</div>
									<div class="pull-right" style="margin: 15px 5px 0 0; width: 115px; text-align: center;">
										{ROW.show_on_map}
										{ROW.rating}
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
				
				<template name="categories">
					<ul id="ul0" class="well nav nav-list">
						<li><h3 style="border-bottom: 1px solid #ccc;">{LANG.Categories}</h3></li>
						<template name="category">
							<li><a class="collapse-toggle" href="#ul{ROW.ndx}" data-toggle="collapse" data-parent="#ul0">{ROW.title}<span class="caret pull-right"></span></a>
								{ROW.tags}
							</li>
						</template>
					</ul>
				</template>
				
				<template name="cities">
					<ul class="well nav nav-list" style="margin-top: 20px;">
						<li><h3 style="border-bottom: 1px solid #ccc;">{LANG.Cities}</h3></li>
						{CATEGORIES.Cities}
					</ul>
				</template>
				
			</div>
			
		</div>
	</div>
	
</template>