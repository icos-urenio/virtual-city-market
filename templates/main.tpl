<template name="main" hidden="true">
<php>
	if (defined('IN_MARKET')) {
		// Navigation current item
		$req =& $this->getRef('Request');
		$this->assignGlobal('CURRENT.' . $req->params[0], 'active');
		
		// Gravatar
		if ($_SESSION['User']['is_loggedin']) {
			$this->assignGlobal('USER.gravatar', md5(strtolower(trim($_SESSION['User']['user_email']))));
		}
		
		// Mercury
		if ($GLOBALS['MARKET_mode'] == 'edit') {
			$this->enableTemplate('editor_js');
		}
		
		// Lang
		$lng =& $this->getRef('Lang');
		$langs = $lng->getAvailable();
		if (count($langs) == 1) {
			$this->disableTemplate('language_cnt');
		}
		else {
			$a_languages = $lng->a_languages();
			foreach ($langs as $lang) {
				$this->assignLocal('language', 'ROW', array(
					'lang' => $lang,
					'language' => $a_languages[$lang]
				));
				if ($lang == MARKET_LANG) {
					$this->assignLocal('language', 'ROW.selected', ' selected="selected"');
				}
				$this->lightParseTemplate('LANGUAGE', 'language');
			}
		}
		
		function getUser($user_id) {
			$sql = "SELECT * FROM market_user WHERE user_id='" . sqlEscape($user_id) . "'";
			if (sqlQuery($sql, $res)) {
				$row = sqlFetchAssoc($res);
				$row['gravatar'] =  md5(strtolower(trim($row['user_email'])));
				return $row;
			}
			return false;
		}
		
		function getPeriodtoDate($date) {
			$period = time() - strtotime($date.'+02:00');
			$period = formatPeriod($period);
			if ($period <> __('now')) $period .= ' {LANG.ago}';
			return $period;
		}
		
		function formatPeriod($secs) {
			$second =  1;
			$minute = 60;
			$hour =   60 * $minute;
			$day = 	  24 * $hour;
			$week =    7 * $day;
			$month =  30 * $day;
			$year =  365 * $day;
			// {LANG.seconds}
			// {LANG.minutes}
			// {LANG.hours}
			// {LANG.days}
			// {LANG.weeks}
			// {LANG.months}
			// {LANG.years}
			if ($secs <= 0) { $output = __('now');
			} else if ($secs > $second && $secs < $minute)   { $output = round($secs / $second) . ' {LANG.second}';
			} else if ($secs >= $minute && $secs < $hour)    { $output = round($secs / $minute) . ' {LANG.minute}';
			} else if ($secs >= $hour && $secs < $day)       { $output = round($secs / $hour) . ' {LANG.hour}';
			} else if ($secs >= $day && $secs < $week)       { $output = round($secs / $day) . ' {LANG.day}';
			} else if ($secs >= $week && $secs < $month)     { $output = round($secs / $week) . ' {LANG.week}';
			} else if ($secs >= $month && $secs < $year)     { $output = round($secs / $month) . ' {LANG.month}';
			} else if ($secs >= $year && $secs < $year * 10) { $output = round($secs / $year) . ' {LANG.year}';
			} else { $output = '{LANG.more than a decade ago}'; }
			 
			if ($output <> __('now')) {
				$output = (substr($output, 0, 2) <> '1 ') ? substr($output, 0, -1) . 's}' : $output;
			}
			return $output;
		}
		
		function getStoreDataByName($store_name) {
			return getStoreData($store_name, 'name');
		}
		
		function getStoreDataById($store_id) {
			return getStoreData($store_id, 'id');
		}
		
		function getStoreData($store, $type = 'name') {
			
			$SELECT = "*, IF (business_name = '', name, business_name) AS title";
			$FROM = "directory STRAIGHT_JOIN directory_ml STRAIGHT_JOIN directory_ps";
			$WHERE = "directory.id=directory_ml.id AND directory.id=directory_ps.id AND directory_ml.lang='" . MARKET_LANG . "' AND directory_ps.publish='1'";
			
			if ($type == 'id') {
				$WHERE .= " AND directory.id='" . sqlEscape($store) . "'";
			}
			else {
				$WHERE .= " AND directory.path='" . sqlEscape($store) . "'";
			}
			
			$sql = "SELECT $SELECT FROM $FROM WHERE $WHERE";
			
			if (sqlQuery($sql, $res)) {
				$store = sqlFetchAssoc($res);
				$store['address'] = ($store['address']) ? $store['address'] . ', ' . $store['city'] : $store['city'];
				// Main page
				$sql = "SELECT * FROM store_data STRAIGHT_JOIN store_data_ps WHERE store_data.id=store_data_ps.id AND store_data_ps.publish='1' AND directory_id='" . $store['id'] . "' AND (lang='' OR lang='" . MARKET_LANG . "') AND name='index' AND (date_from = '0000-00-00' OR date_from < '" . date('Y-m-d') . "') AND (date_to = '0000-00-00' OR date_to > '" . date('Y-m-d') . "') ORDER BY created DESC";
				if (sqlQuery($sql, $res1)) {
					while ($row1 = sqlFetchAssoc($res1)) {
						if ($store[$row1['type']]) {
							if (is_array($store[$row1['type']])) {
								$store[$row1['type']][] = $row1['data'];
							}
							else {
								$foo = $store[$row1['type']];
								$store[$row1['type']] = array();
								$store[$row1['type']][] = $foo;
								$store[$row1['type']][] = $row1['data'];
							}
						}
						else {
							switch ($row1['type']) {
								case 'page':
									$store['text-id'] = $row1['id'];
									$store['text-title'] = $row1['title'];
									$store['text'] = $row1['data'];
								break;
								case 'comment':
									$store['comments'][] = array();
									$index = count($store['comments']) - 1;
									$store['comments'][$index]['comment-id'] = $row1['id'];
									$store['comments'][$index]['creator-id'] = $row1['creator'];
									$store['comments'][$index]['created'] = $row1['created'];
									$store['comments'][$index]['rating'] = $row1['rating'];
									$store['comments'][$index]['votes'] = $row1['votes'];
									$store['comments'][$index]['comment'] = $row1['data'];
								break;
								
								default:
									$store[$row1['type'] . '-id'] = $row1['id'];
									$store[$row1['type']] = $row1['data'];
							}
						}
					}
				}
				
				// Image
				if (is_array($store['image'])) {
					$store['image'] = MARKET_Filter::createThumbnail($store['image'][0], '100', true, 'class="pull-left" style="margin-right: 10px;"');
				}
				else if ($store['image']) {
					$store['image'] = MARKET_Filter::createThumbnail($store['image'], '100', true, 'class="pull-left" style="margin-right: 10px;"');
				}
				return $store;
			}
			return false;
		}
	}
</php>
<!DOCTYPE html>
<!-- paulirish.com/2008/conditional-stylesheets-vs-css-hacks-answer-neither/ -->
<!--[if lt IE 7]> <html class="no-js lt-ie9 lt-ie8 lt-ie7" lang="{MARKET.Lang}"> <![endif]-->
<!--[if IE 7]>    <html class="no-js lt-ie9 lt-ie8" lang="{MARKET.Lang}"> <![endif]-->
<!--[if IE 8]>    <html class="no-js lt-ie9" lang="{MARKET.Lang}"> <![endif]-->
<!--[if gt IE 8]><!--> <html class="no-js" lang="{MARKET.Lang}"> <!--<![endif]-->
	<head>
		<meta charset="utf-8">
		
		<!-- Use the .htaccess and remove these lines to avoid edge case issues.
			 More info: h5bp.com/i/378 -->
		<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
		
		<title>{strip_tags:PAGE.Title}</title>
		<meta name="description" content="" />
		<link rel="shortcut icon" href="{MARKET.WebDir}/favicon.ico">
		
		<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1, user-scalable=no">
		<link rel="stylesheet" href="{MARKET.WebDir}/redist/bootstrap/css/bootstrap.min.css">
		<link rel="stylesheet" href="{MARKET.WebDir}/redist/bootstrap/css/bootstrap-responsive.min.css">
		
		<!-- All JavaScript at the bottom, except this Modernizr build. -->
		<script src="{MARKET.WebDir}/redist/modernizr-2.5.3.min.js"></script>
		
		{PAGE.Style}
		<link href="{MARKET.WebDir}/css/style.css" rel="stylesheet" type="text/css" />
		<link href="{MARKET.WebDir}/css/lang.css" rel="stylesheet" type="text/css" />
		
		<script type="text/javascript">
		 var _gaq = _gaq || [];
		 _gaq.push(['_setAccount', 'UA-35951847-1']);
		_gaq.push(['_trackPageview']);
							
		 (function() {
		  var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
		  ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
		  var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
		 })();
		</script>
		
	</head>
	<body class="{PAGE.Class}">
		
		<!-- Prompt IE 6 users to install Chrome Frame. -->
		<!--[if lt IE 7]>
			<link href="{MARKET.WebDir}/css/bootstrap.ie6.css" rel="stylesheet">
			<p class=chromeframe>Your browser is <em>ancient!</em> <a href="http://browsehappy.com/">Upgrade to a different browser</a> or <a href="http://www.google.com/chromeframe/?redirect=true">install Google Chrome Frame</a> to experience this site.</p>
		<![endif]-->
			
		<a name="top"></a>
		
		<div class="container" role="masthead"> 
		
			<header>
				<a id="logo" href="{MARKET.LWebDir}/index.html"><h1>{LANG.Virtual City Market}<small>{LANG.ORGANIZATION} - {LANG.SMART CITY SERVICES}</small></h1></a>
				<nav>
					<ul class="nav nav-pills">
						<li id="home" class="{CURRENT.index}"><a href="{MARKET.LWebDir}/index.html" title="{LANG.Home}">{LANG.Home}</a></li>
						<li class="{CURRENT.directory}"><a href="{MARKET.LWebDir}/directory/index.html">{LANG.Directory}</a></li>
						<li class="{CURRENT.marketplace}"><a href="{MARKET.LWebDir}/marketplace/index.html">{LANG.Marketplace}</a></li>
						<li class="{CURRENT.offers}"><a href="{MARKET.LWebDir}/offers/index.html">{LANG.Offers}</a></li>
						<li class="{CURRENT.reviews}"><a href="{MARKET.LWebDir}/reviews/index.html">{LANG.Reviews}</a></li>
						<template name="account_settings">
							<if expr="'{_SESSION.User.is_loggedin}'">
								<li class="dropdown {CURRENT.account}"><a class="dropdown-toggle" data-toggle="dropdown" href="#">{LANG.Account} <b class="caret"></b></a>
									<ul class="dropdown-menu">
										<li class="user-box">
											<img class="pull-left" style="margin-right: 5px;" src="http://www.gravatar.com/avatar/{USER.gravatar}.jpg?d=mm&s=20" width="20" height="20" alt="" />
											{_SESSION.User.name} {_SESSION.User.surname}
										</li>
										<li class="divider"></li>
										<li class="{CURRENT.settings}"><a href="{MARKET.LWebDir}/account/settings/index.html">{LANG.Settings}</a></li>
							</if>
							<if expr="'{_SESSION.User.is_admin}'">
								<li class="{CURRENT.admin}"><a href="{MARKET.LWebDir}/admin/index.html">{LANG.Administration}</a></li-->
							</if>
							<if expr="'{_SESSION.User.is_loggedin}'">
										<li><a href="{MARKET.LWebDir}/login.html?logout=true&redirect=index.html">{LANG.Log Out}</a></li>
									</ul>
								</li>
								<else>
									<li class="{CURRENT.login}"><a href="{MARKET.LWebDir}/login.html">{LANG.Sign In}</a></li>
								</else>
							</if>
						</template>
					</ul>
				</nav>
			</header>
			
		</div>
			
		{PAGE.Body}
		
		<!-- JavaScript at the bottom for fast page loading -->
			
			<!-- Grab Google CDN's jQuery, with a protocol relative URL; fall back to local if offline -->
			<script src="//ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js"></script>
			<script>window.jQuery || document.write('<script src="{MARKET.WebDir}/redist/jquery-1.8.2.min.js"><\/script>')</script>
			
			<script src="{MARKET.WebDir}/redist/bootstrap/js/bootstrap.min.js"></script>
			<script src="{MARKET.WebDir}/lang/{MARKET.Lang}/Strings.inc.js"></script>
			<script src="{MARKET.WebDir}/redist/jquery.url.js"></script>
			<script src="{MARKET.WebDir}/redist/jquery.cookie.js"></script>
			<script src="{MARKET.WebDir}/js/market-place.js"></script>
			<script src="{MARKET.WebDir}/redist/lang.js"></script>
			
			<template name="editor_js" disabled="true">
				<script>
					var navigator_language = '{MARKET.Lang}-foo';
				</script>
				<script src="{MARKET.WebDir}/redist/mercury/javascripts/mercury_loader.js?src={MARKET.WebDir}/redist/mercury&pack=bundled"></script>
				<script>
					jQuery(window).on('mercury:ready', function() {
						Mercury.on('saved', function() {
							alert('{LANG.Save successful}...')
						});
					});
				</script>
			</template>
			
			{PAGE.Javascript}
			
		<!-- end scripts-->
		
		<div class="container" role="footer">
			<footer class="border-top">
				<nav class="left">
					<div class="menu">
						<ul style="margin-left: 0;">
							<li><a href="{MARKET.LWebDir}/index.html">{LANG.Home}</a></li>
							<li><a href="{MARKET.LWebDir}/directory/index.html">{LANG.Directory}</a></li>
							<li><a href="{MARKET.LWebDir}/marketplace/index.html">{LANG.Marketplace}</a></li>
							<li><a href="{MARKET.LWebDir}/offers/index.html">{LANG.Offers}</a></li>
							<li><a href="{MARKET.LWebDir}/reviews/index.html">{LANG.Reviews}</a></li>
						</ul>
					</div>
				</nav>
				<p class="right">&copy; 2013 {LANG.Organization}, <a class="blue" href="{MARKET.LWebDir}/terms.html">{LANG.All rights reserved}</a>. <a href="#top" id="back-to-top">{LANG.Back to top} ↑</a></p>
				
				<div class="clearfix"></div>
				
				<template name="language_cnt">
					<div id="lang-select" class="pull-left">
						<form action="{MARKET.Request}">
							<select id="lang" name="lang" class="span2">
								<template name="language">
									<option {ROW.selected} title="{MARKET.WebDir}/{ROW.lang}/index.html" value="{ROW.lang}">{ROW.language}</option>
								</template>
							</select><input value="{LANG.Select}" type="submit" />
						</form>
					</div>
				</template>
			</footer>
		</div>
		
		<div class="modal hide fade" id="not-implemented">
			<div class="modal-header">
				<a class="close" data-dismiss="modal">×</a>
				<h3>{LANG.Not implemented}</h3>
			</div>
			<div class="modal-body">
				<p>{LANG.The requested action is not implemented}.</p>
			</div>
			<div class="modal-footer">
				<button class="btn btn-primary" data-dismiss="modal">OK</button>
			</div>
		</div>
		
	</body>
</html>
</template>