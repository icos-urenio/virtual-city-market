<template parent="main" assign="PAGE.Body" global="PAGE.Title: `{LANG.Password reset}`">
	<php>
		
		include_once(MARKET_TEMPLATE_DIR . '/account/common.php');
		
		if (defined('IN_MARKET')) {
			
			$auth =& $this->getRef('Auth');
			$auth->userLogout();
			
			$error = false;
			if ($_GET['code']) {
			
				if ($_POST['password'] && $_POST['password2']) {
					
					$errors = array();
					
					// Password
					if ($_POST['password']) {
						if (mb_strlen($_POST['password']) >= 8) {
							if (preg_match('@\d+@', $_POST['password'])) {
								if ($_POST['password'] != $_POST['password2']) {
									$errors['password2'] = __('Passwords do not match.');
								}
							}
							else {
								$errors['password'] = __('Your password should include at least one (1) number.');
							}
						}
						else {
							$errors['password'] = __('Your password should be at least eight (8) characters long.');
						}
					}
					
					if ($errors) {
						$this->assignGlobal('REGISTER.Message', '<div class="alert alert-error">' . __('There are errors. Please review the form and correct the fields marked in red.') . '</div>');
						foreach ($errors as $key => $myerror) {
							$this->assignGlobal('ERROR.' . $key, '<span class="help-inline">' . htmlspecialchars($myerror) . '</span>');
							$this->assignGlobal('ERROR.C' . $key, ' error');
						}
					}
					else {
						// New Password
						$sql = "SELECT * FROM market_user WHERE reset_password='" . sqlEscape($_GET['code']) . "' AND DATE_ADD(reset_password_tstamp, INTERVAL 2 HOUR) > NOW()";
						if (sqlQuery($sql, $res)) {
							$user = sqlFetchAssoc($res);
							$sql = "UPDATE market_user SET user_password=MD5('" . sqlEscape($_POST['password']) . "'), reset_password='' WHERE user_id='" . $user['user_id'] . "'";
							$this->disableTemplate('form');
							$this->enableTemplate('message_with_icon');
							if (sqlQuery($sql, $res)) {
								$this->assignGlobal('RESET.Message', '<div class="alert alert-info">' . __('Your password was changed successfully.') . ' ' . __('You can now use your email and password to') . ' <a class="blue" href="{MARKET.LWebDir}/login.html">' . __('Log In') . '</a></div>');
								logEvent('info', __('User password change'), $user['user_id']);
							}
							else {
								$this->assignGlobal('RESET.Message', '<div class="alert alert-info"><b>' . __('An error occured') . '.</b> ' . __('Please try again later.') . '</div>');
								logEvent('info', __('User password change failed'), $user['user_id']);
							}
						}
						else {
							$error = true;
						}
					}
				}
				else {
					$this->assignGlobal('RESET.Message', '<div class="alert alert-info">' . __('Please enter your new password in the form below.') . '</div>');
				}
			}
			else {
				$error = true;
			}
			if ($error) {
				$this->disableTemplate('form');
				$this->enableTemplate('message_with_icon');
				$this->assignGlobal('RESET.Message', '<div class="alert alert-error"><b>' . __('An error occured') . '.</b> ' . __('Please make sure that you followed the correct link from the password reset email.') . ' ' . __('The link is valid for two hours and one time use only.') . '</div>');
			}
		}
		
	</php>
	
	<style>
		.help-block small { font-size: 12px; color: #666; }
	</style>
	
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
				<template name="form">
					<div class="well white">
						<h2>{PAGE.Title}</h2>
						{RESET.Message}
						<form class="form-horizontal" action="" method="POST">
							<fieldset>
								<div class="control-group{ERROR.Cpassword}">
									<label class="control-label" for="password">{LANG.Password}:</label>
									<div class="controls">
										<input class="span3" id="password" name="password" type="password" value="" />{ERROR.password}
									</div>
								</div>
								<div class="control-group{ERROR.Cpassword2}">
									<label class="control-label" for="password2">{LANG.Repeat password}:</label>
									<div class="controls">
										<input class="span3" id="password2" name="password2" type="password" value="" />{ERROR.password2}
										<span class="help-block"><small>{LANG.Your password should be at least eight (8) characters long and include at least one (1) number.}</small></span>
									</div>
								</div>
							</fieldset>
							<div class="form-actions">
								<button class="btn btn-primary" type="submit" id="user_submit">{LANG.Submit}</button>
							</div>
						</form>
					</div>
				</template>
				<template name="message_with_icon" disabled="true">
					<div class="pull-left"><img src="{MARKET.WebDir}/img/lock.png" width="128" height="128" alt="" /></div>
					<div style="margin-left: 150px;">
						<h2>{PAGE.Title}</h2>
						{RESET.Message}
					</div>
				</template>
			</div>
		</div>
	</div>
</template>