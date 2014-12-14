<template parent="main" assign="PAGE.Body" global="PAGE.Title: {LANG.Offers}">
	
	<php>
		
		$lng =& $this->getRef('Lang');
		
		$lng->strs['item_total'] = '{LANG.offer}';
		$lng->strs['items_total'] = '{LANG.offers}';
		
		// Force SQL class load
		sqlQuery('SELECT foo', $res);
		
		include(MARKET_TEMPLATE_DIR . '/categories.php');
		
		$SELECT = "store_data.*, directory.path";
		$FROM = "store_data STRAIGHT_JOIN store_data_ps STRAIGHT_JOIN directory STRAIGHT_JOIN directory_ml STRAIGHT_JOIN directory_ps";
		$WHERE = "store_data.id=store_data_ps.id AND store_data.directory_id=directory.id AND store_data.directory_id=directory_ml.id AND store_data.directory_id=directory_ps.id AND directory_ps.publish='1' AND store_data_ps.publish='1' AND (store_data.lang='' OR store_data.lang='" . MARKET_LANG . "') AND directory_ml.lang='" . MARKET_LANG . "' AND type='coupon' AND (date_from = '0000-00-00' OR date_from <= '" . date('Y-m-d') . "') AND (date_to = '0000-00-00' OR date_to >= '" . date('Y-m-d') . "') ORDER BY store_data_ps.created DESC";
		
		if ($_GET['q']) {
			$this->assignGlobal('GET.q', htmlspecialchars($_GET['q']));
			$srh =& $this->getRef('Search');
			
			if ($_GET['content'] == 'city') {
				$search_in = 'city';
				$search_as = 'exact';
				$_GET['q'] = '"' . $_GET['q'] . '"';
			}
			else {
				$search_in = 'store_data.title, store_data.data, directory_ml.name, business_name, category, prof1, prof2, prof3, byline, address';
				$search_as = '';
			}
			$cmd = "SEARCH IN " . $search_in . " OF $FROM RETURN $SELECT WHERE " . $WHERE . "";
			$sql = $srh->searchFor($_GET['q'], $cmd, $search_as);
		}
		else {
			$sql = "SELECT $SELECT FROM $FROM WHERE $WHERE";
		}
		
		$this->assignNavigationValues($sql, 'default', 0, 9, 30, true);
		
		if (sqlQuery($sql, $res)) {
			$this->disableTemplate('no-coupons');
			while ($row = sqlFetchAssoc($res)) {
				// What else is available?
				$sql = "SELECT * FROM store_data STRAIGHT_JOIN store_data_ps WHERE store_data.id=store_data_ps.id AND store_data_ps.publish='1' AND directory_id='" . $row['directory_id'] . "' AND (lang='' OR lang='" . MARKET_LANG . "') AND type <> 'coupon' AND name='" . sqlEscape($row['name']) . "' ORDER BY ord";
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
							$row[$row1['type']] = $row1['data'];
						}
					}
				}
				$image = (is_array($row['image'])) ? $row['image'][0] : $row['image'];
				$row['image'] = MARKET_Filter::createThumbnail($image, '240', true);
				
				if (!$row['path']) $row['path'] = $row['directory_id'];
				
				$this->assignLocal('coupon', 'ROW', $row);
				$this->lightParseTemplate('COUPON', 'coupon');
			}
		}
		else {
			$this->disableTemplate('coupons');
		}
		
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
	
	<div class="container">
		
		<div class="row">
			<div class="span12">
				<header id="archive-header">
					<h1>{LANG.Offers}</h1>
				</header>
			</div>
		</div>
		
		<div class="row">
			<div class="span9">
				
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
				
				<template name="coupons">
					<div>
						<div class="pull-left" style="margin-top: 5px;">{LANG.Found} {NAV.Found}</div>
						<div class="pull-right">{fix_toolbar:NAV.Toolbar}</div>
					</div>
					<div class="clearfix"></div>
					<div class="coupons row">
						<template name="coupon">
							<a href="{MARKET.LWebDir}/offers/{ROW.path}/{ROW.name}.html">
							<div class="coupon span3" style="margin-top: 20px;">
								{ROW.image}
								<div>
									<h3>{ROW.title}</h3>
									<if expr="'{ROW.price}'">
										<p class="price"><span>{LANG.Price}:</span> {ROW.price}</p>
									</if>
								</div>
								<p class="discount"><span>Έκπτωση:</span> {ROW.discount}%</p>
							</div>
							</a>
						</template>
					</div>
					<div class="clearfix"></div>
					<div class="double-border"><p><small><span>{NAV.Pages}</span></small></p></div>
				</template>
				
				<template name="no-coupons">
					<div class="alert alert-info info well">
						<button class="close" data-dismiss="alert" type="button">×</button>
						{LANG.No results}...
					</div>
				</template>
				
			</div>
			
			<div class="mplace_menu menu span3">
				
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