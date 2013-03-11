<template parent="main" assign="PAGE.Body" global="PAGE.Title: {LANG.Authentication};">
	<php>
		
		include_once(MARKET_TEMPLATE_DIR . '/account/common.php');
		
		if (defined('IN_MARKET')) {
			
			if (!session_id()) {
				// Start session
				$this->getRef('Session');
			}
			
			if ($_GET['logout'] && $_SESSION['User']['is_loggedin']) {
				logEvent('info', __('User log out'));
			}
			
			$auth =& $this->getRef('Auth');
			$auth->userLogout();
			
			if ($_GET['logout']) {
				// OK now redirect
				$req =& $this->getRef('Request');
				if ($_GET['redirect']) {
					$req->redirectTo(MARKET_WEB_DIR . '/' . $_GET['redirect']);
				}
				else {
					$req->redirectTo(MARKET_WEB_DIR . '/' . MARKET_LANG . '/index.html');
				}
			}
			
			if ($_POST['login'] && $_POST['password']) {
				$sql = "SELECT * FROM market_user WHERE username='" . sqlEscape($_POST['login']) . "' AND user_password='" . sqlEscape(md5($_POST['password'])) . "' AND user_active='1'";
				if ($auth->userLogin($sql)) {
					logEvent('info', __('User log in'));
					// OK now redirect
					$req =& $this->getRef('Request');
					if ($_GET['redirect']) {
						$req->redirectTo(MARKET_WEB_DIR . '/' . $_GET['redirect']);
					}
					else {
						$req->redirectTo(MARKET_WEB_DIR . '/' . MARKET_LANG . '/index.html');
					}
				}
				else {
					$sql = "SELECT * FROM market_user WHERE username='" . sqlEscape($_POST['login']) . "' AND user_password='" . sqlEscape(md5($_POST['password'])) . "'";
					if (sqlQuery($sql, $res)) {
						$user = sqlFetchAssoc($res);
						if ($user['activate_account']) {
							$this->assignGlobal('LOGIN.Message', '<div class="alert alert-warning">' . __('Your account is not activated yet. Please follow the instructions we have send you to activate your account.') . '<br><a class="blue" href="{MARKET.LWebDir}/account/activate_request.html?email={_SAFE_POST.login}">' . __('Send me the confirmation message again.') . '</a></div>');
						}
						else {
							$this->assignGlobal('LOGIN.Message', '<div class="alert alert-error">' . __('Your account has been deactivated by the administrator.') . '</div>');
						}
					}
					else {
						$this->assignGlobal('LOGIN.Message', '<div class="alert alert-error">' . __('Login incorrect.') . '</div>');
					}
				}
			}
			else {
				if ($_GET['redirect']) {
					$this->assignGlobal('LOGIN.Message', '<div class="alert alert-info">' . __('This page requires authentication.') . '</div>');
				}
				else {
					$this->assignGlobal('LOGIN.Message', '<div class="alert alert-info">' . __('Please enter your credentials.') . '</div>');
				}
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
			<div class="span6 offset3">
				<div class="well white">
					<h2>{LANG.Log In}
						<div class="pull-right">
							<small>
								<img style="padding-bottom: 10px;" src="{MARKET.WebDir}/img/user_icon.png" width="32" height="32" alt="" />
								<a href="{MARKET.LWebDir}/account/register.html?redirect={_SAFE_GET.redirect}">{LANG.New user registration}</a>
							</small>
						</div>
					</h2>
					{LOGIN.Message}
					<form  class="form-horizontal" action="{MARKET.Request}" method="post">
						<fieldset>
							<div class="control-group">
								<label class="control-label" for="login">{LANG.Email}:</label>
								<div class="controls">
									<input class="span3" id="login" name="login" type="text" value="{_POST.login}" />
								</div>
							</div>
							<div class="control-group">
								<label class="control-label" for="password">{LANG.Password}:</label>
								<div class="controls">
									<input class="span3" id="password" name="password" size="25" type="password" />
								</div>
							</div>
							<div class="control-group">
								<div class="controls">
									<label class="checkbox">
										<input name="remember_me" type="checkbox"> {LANG.Remember me}
									</label>
								</div>
							</div>
						</fieldset>
						<div class="form-actions">
							<button class="btn btn-primary" type="submit" id="user_submit">{LANG.Log In}</button> &nbsp; {LANG.or} <a href="{MARKET.LWebDir}/account/reset_request.html">{LANG.forgot your password?}</a>
						</div>
					</form>
				</div>
			</div>
		</div>
	</div>
	
</template>