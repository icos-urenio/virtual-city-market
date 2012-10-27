<template name="debug" hidden="true">
	
	<style>
		#debug .subnav {
			width: 100%;
			height: 36px;
			background-color: #eeeeee; /* Old browsers */
			background-repeat: repeat-x; /* Repeat the gradient */
			background-image: -moz-linear-gradient(top, #f5f5f5 0%, #eeeeee 100%); /* FF3.6+ */
			background-image: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#f5f5f5), color-stop(100%,#eeeeee)); /* Chrome,Safari4+ */
			background-image: -webkit-linear-gradient(top, #f5f5f5 0%,#eeeeee 100%); /* Chrome 10+,Safari 5.1+ */
			background-image: -ms-linear-gradient(top, #f5f5f5 0%,#eeeeee 100%); /* IE10+ */
			background-image: -o-linear-gradient(top, #f5f5f5 0%,#eeeeee 100%); /* Opera 11.10+ */
			filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='#f5f5f5', endColorstr='#eeeeee',GradientType=0 ); /* IE6-9 */
			background-image: linear-gradient(top, #f5f5f5 0%,#eeeeee 100%); /* W3C */
			border: 1px solid #e5e5e5;
			-webkit-border-radius: 4px;
			-moz-border-radius: 4px;
			border-radius: 4px;
		}
		
		#debug .subnav .nav {
			margin-bottom: 0;
		}
		
		#debug .subnav .nav > li > a {
			margin: 0;
			padding-top:    11px;
			padding-bottom: 11px;
			border-left: 1px solid #f5f5f5;
			border-right: 1px solid #e5e5e5;
			-webkit-border-radius: 0;
			-moz-border-radius: 0;
			border-radius: 0;
		}
		
		#debug .subnav .nav > .active > a,
		#debug .subnav .nav > .active > a:hover {
			padding-left: 13px;
			color: #777;
			background-color: #e9e9e9;
			border-right-color: #ddd;
			border-left: 0;
			-webkit-box-shadow: inset 0 3px 5px rgba(0,0,0,.05);
			-moz-box-shadow: inset 0 3px 5px rgba(0,0,0,.05);
			box-shadow: inset 0 3px 5px rgba(0,0,0,.05);
		}
		
		#debug .subnav .nav > .active > a .caret,
		#debug .subnav .nav > .active > a:hover .caret {
			border-top-color: #777;
		}
		
		#debug .subnav .nav > li:first-child > a,
		#debug .subnav .nav > li:first-child > a:hover {
			border-left: 0;
			padding-left: 12px;
			-webkit-border-radius: 4px 0 0 4px;
			-moz-border-radius: 4px 0 0 4px;
			border-radius: 4px 0 0 4px;
		}
		
		#debug .subnav .nav > li:last-child > a {
			border-right: 0;
		}
		
		#debug .subnav .dropdown-menu {
			-webkit-border-radius: 0 0 4px 4px;
			-moz-border-radius: 0 0 4px 4px;
			border-radius: 0 0 4px 4px;
		}
		
		/* Fixed subnav on scroll, but only for 980px and up (sorry IE!) */
		@media (min-width: 980px) {
			#debug .subnav-fixed {
				position: fixed;
				top: 40px;
				left: 0;
				right: 0;
				z-index: 1020; /* 10 less than .navbar-fixed to prevent any overlap */
				border-color: #d5d5d5;
				border-width: 0 0 1px; /* drop the border on the fixed edges */
				-webkit-border-radius: 0;
				-moz-border-radius: 0;
				border-radius: 0;
				-webkit-box-shadow: inset 0 1px 0 #fff, 0 1px 5px rgba(0,0,0,.1);
				-moz-box-shadow: inset 0 1px 0 #fff, 0 1px 5px rgba(0,0,0,.1);
				box-shadow: inset 0 1px 0 #fff, 0 1px 5px rgba(0,0,0,.1);
				filter: progid:DXImageTransform.Microsoft.gradient(enabled=false); /* IE6-9 */
			}
			
			#debug .subnav-fixed .nav {
				margin: 0 auto;
				padding: 0 1px;
			}
			
			#debug .subnav .nav > li:first-child > a,
			#debug .subnav .nav > li:first-child > a:hover {
				-webkit-border-radius: 0;
				-moz-border-radius: 0;
				border-radius: 0;
			}
		}

		#debug .brand {
			float: left;
			color: #999999;
			font-size: 20px;
			font-weight: 200;
			line-height: 1;
			padding: 8px 20px 12px;
			text-shadow: 0 1px 0 rgba(0, 0, 0, 0.1), 0 0 30px rgba(0, 0, 0, 0.125);
		}
		
		#debug section {
			padding: 60px 20px 0 20px;
		}
		
		#debug .label-error {
			background-color: #B94A48;
		}
		
		#debug .page-header {
			padding-bottom: 0;
		}
		
	</style>
	
	<!-- Start debug output -->

	<div id="debug" class="container">
		
		<div class="well" style="background: #fff">

			<div class="subnav">
				<h2 class="brand">{LANG.Debug}</h2>
				<ul class="nav nav-pills">
					<li><a href="#errors">{LANG.Errors}</a></li>
					<li><a href="#variables">{LANG.Variables}</a></li>
					<li><a href="#sqlqueries">{LANG.SQL Queries}</a></li>
					<li><a href="#profiler">{LANG.Profiler}</a></li>
					<li><a href="#resources">{LANG.Resources}</a></li>
				</ul>
			</div>

			<section id="errors">
				<div class="page-header">
					<h3>{LANG.Errors}: <small>{NUM_OF_ERRORS}</small></h3>
				</div>
				<template name="errors_cnt">
					<div style="padding-left: 20px">
						<table>
							<template name="error">
								<tr><td valign="top"><b>{MARKET.aa}.</b></td><td style="padding: 0 5px;"><span class="label label-{TYPE}">{ucfirst:TYPE}</span></td><td>{VALUE}</td></tr>
							</template>
						</table>
					</div>
				</template>
			</section>
			
			<section id="variables">
				<div class="page-header">
					<h3>{LANG.Variables}: <small>{NUM_OF_VARS}</small></h3>
				</div>
				<template name="variables_cnt">
					<table class="table table-bordered table-condensed table-striped">
						<tr>
							<th style="width: 25%;">Variable</th>
							<th style="width: 75%;">Value</th>
						</tr>
						<template name="variable">
							<tr valign="top"><td><b>{VARIABLE}</b></td><td>{VALUE}</td></tr>
						</template>
					</table>
				</template>
			</section>
			
			<section id="sqlqueries">
				<div class="page-header">
					<h3>{LANG.SQL Queries}: <small>{NUM_OF_SQLS}</small></h3>
				</div>
				<table width="100%">
					<tr>
						<td>
							<template name="sql">
								<h4>{SQL_QUERY}</h4>
								<p>{SQL_INFO}</p>
								<template name="sql_cnt">
									<table class="table table-bordered table-condensed table-striped">
										<thead>
										<tr>
											<th style="width: 10%;">Table</th>
											<th style="width: 10%;">Type</th>
											<th style="width: 15%;">Possible_keys</th>
											<th style="width: 15%;">Key</th>
											<th style="width: 8%;">Key_len</th>
											<th style="width: 15%;">Ref</th>
											<th style="width: 8%;">Rows</th>
											<th style="width: 19%;">Extra</th>
										</tr>
										</thead>
										<template name="explain">
											<tr align="center">
												<td>{TABLE}</td>
												<td>{TYPE}</td>
												<td>{POSSIBLE_KEYS}</td>
												<td>{KEY}</td>
												<td>{KEY_LEN}</td>
												<td>{REF}</td>
												<td>{ROWS}</td>
												<td>{EXTRA}</td>
											</tr>
										</template>
									</table>
								</template>
							</template>
						</td>
					</tr>
				</table>
			</section>

			<section id="profiler">
				<div class="page-header">
					<h3>{LANG.Profiler}: <small>{NUM_OF_TIMERS}</small></h3>
				</div>
				<template name="profiler_cnt">
					<table class="table table-bordered table-condensed table-striped">
						<thead>
						<tr>
							<th style="width: 15%;">Timer</th>
							<th style="width: 70%;">Description</th>
							<th style="width: 15%;">Elapsed time</th>
						</tr>
						</thead>
						<template name="profile">
							<tr valign="top"><td><b>{TIMER}</b></td><td>{DESCRIPTION}</td><td>{ELAPSED}</td></tr>
						</template>
					</table>
				</template>
			</section>
			
			<section id="resources">
				<div class="page-header">
					<h3>{LANG.Resources}:</h3>
				</div>
				<p><b>Memory used:</b> {b2KB:MEMORY_USED}</p>
				<p><b>Execution time:</b> {ELAPSED_TIME} secs.</p>
			</section>

		</div>
	</div>
	
	<!-- End Debug output -->
	
</template>