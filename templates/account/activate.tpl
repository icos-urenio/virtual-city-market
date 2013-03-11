<template parent="main" assign="PAGE.Body" global="PAGE.Title: `{LANG.Activate your account}`">
	
	<php>
		
		include_once(MARKET_TEMPLATE_DIR . '/account/common.php');
		
		if (defined('IN_MARKET')) {
			
			$auth =& $this->getRef('Auth');
			$auth->userLogout();
			
			$error = false;
			if ($_GET['code']) {
				$sql = "SELECT * FROM market_user WHERE activate_account='" . sqlEscape($_GET['code']) . "' AND DATE_ADD(activate_account_tstamp, INTERVAL 2 HOUR) > NOW()";
				if (sqlQuery($sql, $res)) {
					$user = sqlFetchAssoc($res);
					$sql = "UPDATE market_user SET user_active='1', activate_account='' WHERE user_id='" . $user['user_id'] . "'";
					if (sqlQuery($sql, $res)) {
						$this->assignGlobal('ACTIVATE.Message', '<div class="alert alert-info">' . __('Your account was activated successfully.') . ' ' . __('You can now use your email and password to') . ' <a class="blue" href="{MARKET.LWebDir}/login.html">' . __('Log In') . '</a></div>');
						logEvent('info', __('User activation'), $user['user_id']);
					}
					else {
						$this->assignGlobal('ACTIVATE.Message', '<div class="alert alert-error">' . '<b>' . __('An error occured') . '.</b> ' . __('Please try again later.') . '</div>');
						logEvent('info', __('User activation failed'), $user['user_id']);
					}
				}
				else {
					$error = true;
				}
				
			}
			else {
				$error = true;
			}
			if ($error) {
				$this->assignGlobal('ACTIVATE.Message', '<div class="alert alert-error"><b>' . __('An error occured') . '.</b> ' . __('Please make sure that you followed the correct link from the activation email.') . ' ' . __('The link is valid for two hours and one time use only.') . '<br><a class="blue" href="{MARKET.LWebDir}/account/activate_request.html">' . __('Send me the confirmation message again.') . '</a></div>');
			}
		}
		
	</php>
	
	<div class="container">
		<div class="row">
			<div class="span12">
				<header id="archive-header">
					&nbsp;
				</header>
			</div>
		</div>
	</div>
	
	<div id="main" class="container">
		<div class="row">
			<div class="offset3 span6">
				<div class="pull-left"><img src="{MARKET.WebDir}/img/user.png" width="128" height="128" alt="" /></div>
				<div style="margin-left: 150px;">
					<h2>{PAGE.Title}</h2>
					{ACTIVATE.Message}
				</div>
			</div>
		</div>
	</div>
	
</template>