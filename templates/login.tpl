<template parent="main" assign="PAGE.Body" global="PAGE.Title: {LANG.Authentication};">
<php>
	if (defined('IN_MARKET')) {
		
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
			$sql = "SELECT * FROM market_user WHERE username='" . sqlEscape($_POST['login']) . "' AND user_password='" . sqlEscape(md5($_POST['password'])) . "'";
			if ($auth->userLogin($sql)) {
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
				$this->assignGlobal('LOGIN.Message', '<div class="alert alert-error">{LANG.Login incorrect.}</div>');
			}
		}
		else {
			if ($_GET['redirect']) {
				$this->assignGlobal('LOGIN.Message', '<div class="alert alert-info">{LANG.This page requires authentication.}</div>');
			}
			else {
				$this->assignGlobal('LOGIN.Message', '<div class="alert alert-info">{LANG.Please enter your credentials.}</div>');
			}
		}
		
	}
</php>
	
		<div id="main" class="container" style="padding-top: 60px">
			<div class="row">
				<div class="span6 offset3">
					<div class="well white">
						<h2>{LANG.Log In}</h2>
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
								<button class="btn btn-primary" type="submit" id="user_submit">{LANG.Log In}</button> or <a href="/users/password/new">{LANG.forgot your password?}</a>
							</div>
						</form>
					</div>
				</div>
			</div>
		</div>
		
</template>