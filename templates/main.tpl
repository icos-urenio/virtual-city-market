<template name="main" hidden="true">
<php>
	if (defined('IN_MARKET')) {
		// Navigation current item
		$req =& $this->getRef('Request');
		$this->assignGlobal('CURRENT.' . $req->params[0], 'active');
		
		// Gravatar
		if ($_SESSION['User']['is_logedin']) {
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
			if (preg_match('@(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})@', $date, $matches)) {
				$period = mktime() - mktime($matches[4], $matches[5], $matches[6], $matches[2], $matches[3], $matches[1]);
				$period = formatPeriod($period) . ' {LANG.ago}';
			}
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
			if ($secs <= 0) { $output = '{LANG.now}';
			} else if ($secs > $second && $secs < $minute)   { $output = round($secs / $second) . ' {LANG.second}';
			} else if ($secs >= $minute && $secs < $hour)    { $output = round($secs / $minute) . ' {LANG.minute}';
			} else if ($secs >= $hour && $secs < $day)       { $output = round($secs / $hour) . ' {LANG.hour}';
			} else if ($secs >= $day && $secs < $week)       { $output = round($secs / $day) . ' {LANG.day}';
			} else if ($secs >= $week && $secs < $month)     { $output = round($secs / $week) . ' {LANG.week}';
			} else if ($secs >= $month && $secs < $year)     { $output = round($secs / $month) . ' {LANG.month}';
			} else if ($secs >= $year && $secs < $year * 10) { $output = round($secs / $year) . ' {LANG.year}';
			} else { $output = '{LANG.more than a decade ago}'; }
			 
			if ($output <> '{LANG.now}') {
				$output = (substr($output, 0, 2) <> '1 ') ? substr($output, 0, -1) . 's}' : $output;
			}
			return $output;
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
					</ul>
				</nav>
				<template name="user">
					<if expr="'{_SESSION.User.is_logedin}'">
						<div class="user">
							<a href="http://www.gravatar.com/" target="new"><img src="http://www.gravatar.com/avatar/{USER.gravatar}.jpg?d=mm&s=28" width="28" height="28" alt="{_SESSION.User.user_email}" /></a>
							&nbsp;{_SESSION.User.name} {_SESSION.User.surname}&nbsp;
							<a class="btn" href="{MARKET.WebDir}/login.html?logout=true">{LANG.Logout}</a>
						</div>
					</if>
				</template>
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
				<script src="{MARKET.WebDir}/redist/mercury/javascripts/mercury_loader.js?src={MARKET.WebDir}/redist/mercury&pack=bundled"></script>
				<script>
					jQuery(window).on('mercury:saved', function() {
						alert('{LANG.Save successful}...')
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
				<p class="right">&copy; 2012 {LANG.Organization}, {LANG.All Rights Reserved}. <a href="#top" id="back-to-top">{LANG.Back to top} ↑</a></p>
				
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