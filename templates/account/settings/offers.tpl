<template parent="main" assign="PAGE.Body" global="PAGE.Title: `{LANG.Account settings}`" permissions="registered">
	
	<php>
		
		include_once(MARKET_TEMPLATE_DIR . '/account/common.php');
		
		if (defined('IN_MARKET')) {
			
			if ($_SESSION['User']['market_role_id'] == 2 && $_SESSION['User']['store']) {
			
				$this->assignGlobal('CURRENT.settings', 'active');
				
				$lng =& $this->getRef('Lang');
				$lng->strs['item_total'] = '{LANG.offer}';
				$lng->strs['items_total'] = '{LANG.offers}';
				
				// Offers index
				$sql = "SELECT * FROM store_data WHERE type='coupon' AND directory_id='" . sqlEscape($_SESSION['User']['store']) . "' ORDER BY date_to DESC";
				$this->assignNavigationValues($sql);
				if (sqlQuery($sql, $res)) {
					$this->disableTemplate('no-offer');
					while ($row = sqlFetchAssoc($res)) {
						$sql = "SELECT * FROM store_data WHERE type='image' AND name='" . sqlEscape($row['name']) . "' AND directory_id='" . sqlEscape($_SESSION['User']['store']) . "'";
						if (sqlQuery($sql, $res1)) {
							$row1 = sqlFetchAssoc($res1);
							$row['image'] = MARKET_Filter::createThumbnail($row1['data'], '80', true);
						}
						if (preg_match('@(\d{4})-(\d{2})-(\d{2})@', $row['date_to'], $matches)) {
							if (mktime('23', '59', '59', ltrim($matches[2], '0'), ltrim($matches[3], '0'), $matches[1]) < time()) {
								$row['expired'] = ' class="expired"';
								$row['status'] = '<div style="position: relative;"><div class="corner"><span>{LANG.Expired}</span></div></div>';
							}
						}
						$this->assignLocal('offer', 'OFFER', $row);
						$this->lightParseTemplate('OFFER', 'offer');
					}
				}
				else {
					$this->disableTemplate('offer');
				}
				
			}
			else {
				$req =& $this->getRef('Request');
				$req->httpError(403);
			}
		}
		
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
	
	<template name="js" assign="PAGE.Javascript">
		<script type="text/javascript">
			var mydelete = null;
			jQuery(document).ready(function() {
				setTimeout(function() { 
					$('.alert').fadeOut();
				}, 5000);
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
					<div id="offers" style="border: 1px solid #DFDFDF;">
						<div class="span6" style="float: none; margin: 0 auto; margin-top: 20px;">
							<template name="offers_index">
								<img src="{MARKET.WebDir}/img/promo.png" width="128" height="128" alt="" />
								<h2 style="margin-bottom: 20px; border-bottom: 1px solid #ddd;">{LANG.Manage your offers}</h2>
								
								<div>
									<div class="pull-left" style="margin-top: 5px;">{LANG.Found} {NAV.Found}</div>
									<div class="pull-right">{fix_toolbar:NAV.Toolbar}</div>
								</div>
								
								<div class="clearfix"></div>
								
								<table class="table table-striped" style="margin-top: 10px;">
									<tr><th>&nbsp;</th><th>{LANG.Title}</th><th>{LANG.Price}</th><th>{LANG.Valid from}</th><th>{LANG.Valid to}</th><th><a class="btn btn-warning pull-right" rel="tooltip" title="{LANG.New offer}" href="{MARKET.LWebDir}/account/settings/offer_edit.html"><i class="icon-plus icon-white"></i></a></th></tr>
									<template name="offer">
										<tr{OFFER.expired}><td>{OFFER.status}{OFFER.image}</td><td>{OFFER.title}</td><td>{OFFER.price}</td><td>{OFFER.date_from}</td><td>{OFFER.date_to}</td><td><a class="btn pull-right" rel="tooltip" title="{LANG.Edit}" href="{MARKET.LWebDir}/account/settings/offer_edit.html?id={OFFER.id}"><i class="icon-edit"></i></a></td></tr>
									</template>
									<template name="no-offer">
										<tr><td colspan="5">{LANG.There are no offers. Click "New offer" to add an offer.}</td></tr>
									</template>
								</table>
								
								<div class="double-border"><p><small><span>{NAV.Pages}</span></small></p></div>
							</template>
						</div>
					</div>
				</template>
				
			</div>
			
			<div class="menu span4">
				<ul class="well nav nav-list">
					<li><h3 style="border-bottom: 1px solid #ccc;">{LANG.Account options}</h3></li>
					<li><a href="{MARKET.LWebDir}/account/settings/index.html">{LANG.Personal details}</a></li>
					<li><a href="{MARKET.LWebDir}/account/settings/business.html">{LANG.Business details}</a></li>
					<li class="active"><a href="{MARKET.LWebDir}/account/settings/offers.html">{LANG.Offers management}</a></li>
				</ul>
			</div>
			
		</div>
	</div>
	
</template>