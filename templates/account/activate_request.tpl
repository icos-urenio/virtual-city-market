<template parent="main" assign="PAGE.Body" global="PAGE.Title: `{LANG.Activate your account}`">
	
	<php>
		
		include_once(MARKET_TEMPLATE_DIR . '/account/common.php');
		
		if (defined('IN_MARKET')) {
			
			$auth =& $this->getRef('Auth');
			$auth->userLogout();
			
			if ($_GET['email']) {
				
				$error = '';
				
				// Email
				if (!validEmail($_GET['email'])) {
					$error = '<b>' . __('An error occured') . ':</b> ' . __('The email address is not valid.');
				}
				else {
					$sql = "SELECT * FROM market_user WHERE username='" . sqlEscape($_GET['email']) . "'";
					if (sqlQuery($sql, $res)) {
						
						$user = sqlFetchAssoc($res);
						
						if ($user['user_active']) {
							$error = $error = '<b>' . __('An error occured') . ':</b> ' . __('Your account is already activated.');
						}
						else if (!$user['user_active'] && !$user['activate_account']) {
							$error = $error = '<b>' . __('An error occured') . ':</b> ' . __('Your account cannot be activated.');
						}
						else {
							
							$_POST = $user;
							$_POST['email'] = $_POST['username'];
							
							$i = 0;
							while ($i < 10) { // Try at most 10 times to create a unique code
								$code = substr(md5(uniqid(rand(), true)), 0, 16);
								$sql = "SELECT * FROM market_user WHERE activate_account='" . sqlEscape($code) . "'";
								if (!sqlQuery($sql, $res)) {
									$sql = "UPDATE market_user SET activate_account='" . sqlEscape($code) . "', activate_account_tstamp=NOW() WHERE user_id='" . sqlEscape($_POST['user_id']) . "'";
									if (!sqlQuery($sql, $res)) {
										$error = '<b>' . __('An error occured') . '.</b> ' . __('Please try again later.');
									}
									break;
								}
								$i++;
							}
							// 10 times limit reached
							if ($i == 10) {
								$error = '<b>' . __('An error occured') . '.</b> ' . __('Please try again later.');
							}
							
							if (!$error) {
								// Send activation email
								
								// Mailer
								require_once(MARKET_ROOT_DIR . '/redist/phpmailer/class.phpmailer.php');
								$mail = new phpmailer();
								$mail->IsSMTP();
								
								// Variables
								$mail->Host = MARKET_SMTP_HOST;
								if (defined('MARKET_SMTP_FROM')) $mail->From = MARKET_SMTP_FROM; else $mail->From = 'noreply@' . $_SERVER['HTTP_HOST'];
								if (defined('MARKET_SMTP_FROM_NAME')) $mail->FromName = MARKET_SMTP_FROM_NAME;
								if (defined('MARKET_SMTP_USER') && defined('MARKET_SMTP_PASS')) {
									$mail->SMTPAuth = true;
									$mail->Username = MARKET_SMTP_USER;
									$mail->Password = MARKET_SMTP_PASS;
								}
								$mail->LF       = "\r\n";
								$mail->CharSet  = "utf-8";
								$mail->AddAddress($_POST['email'], $_POST['name'] . ' ' . $_POST['surname']);
								$mail->Subject  = __('Confirm your registration at') . ' "' . __('Virtual City Market') . '"';
								
								// Template variables
								$this->assignGlobal('MESSAGE', __('You received this message because you requested instructions to activate your account at'));
								$this->assignGlobal('ACTIVATION_CODE', $code);
								$this->assignGlobal('SUPPORT_EMAIL', SUPPORT_EMAIL);
								
								// Trim final ς from greek names
								if (MARKET_LANG == 'el') {
									$_POST['name'] = preg_replace('@ς$@U', '', $_POST['name']);
									$_POST['name'] = preg_replace('@ο$@U', 'ε', $_POST['name']);
									$_POST['surname'] = preg_replace('@ς$@U', '', $_POST['surname']);
									$_POST['surname'] = preg_replace('@ο$@U', 'ε', $_POST['surname']);
								}
								$this->assignGlobal('USER', array(
									'name' => $_POST['name'],
									'surname' => $_POST['surname']
								));
								
								// Load the template
								$this->loadTemplate('account/mail/activate_account');
								$this->parseTemplate('HTML');
								
								$html = $this->getFinalTemplate('HTML');
								$mail->MsgHTML($html);
								
								$this->disableTemplate('form');
								$this->enableTemplate('message_with_icon');
								$this->assignGlobal('DIV.Class', 'span6 offset3');
								if ($mail->Send()) {
									// Show success message
									$this->assignGlobal('ACTIVATE.Message', '<div class="alert alert-info">' . __('We have send a confirmation message to your email address. Please read it and follow the instructions to activate your account.') . '</div>');
									logEvent('info', __('User activation mail'), $new_user_id);
								}
								else {
									// Show failed message
									$this->assignGlobal('ACTIVATE.Message', '<div class="alert alert-error"><b>' . __('An error occured') . '.</b> ' . __('We failed to send you the confirmation message. Please try again later.') . '</div>');
									logEvent('error', __('User activation mail failed'));
								}
							}
						}
					}
					else {
						$error = $error = '<b>' . __('An error occured') . ':</b> ' . ('The email address is not registered.');
					}
				}
				if ($error) {
					$this->assignGlobal('ACTIVATE.Message', '<div class="alert alert-error">' . $error . '</div>');
				}
			}
			else {
				$this->assignGlobal('ACTIVATE.Message', '<div class="alert alert-info">' . __('Please enter your registered email address in the form below. We will send you instructions to activate your account.') . '</div>');
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
				<template name="form">
					<div class="well white">
						<h2>{PAGE.Title}</h2>
						{ACTIVATE.Message}
						<form class="form-horizontal" action="" method="GET">
							<fieldset>
								<div class="control-group">
									<label class="control-label" for="email">{LANG.Email address}:</label>
									<div class="controls">
										<input class="span3" id="email" name="email" type="text" value="{_SAFE_GET.email}" />
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
					<div class="pull-left"><img src="{MARKET.WebDir}/img/user.png" width="128" height="128" alt="" /></div>
					<div style="margin-left: 150px;">
						<h2>{PAGE.Title}</h2>
						{ACTIVATE.Message}
					</div>
				</template>
			</div>
		</div>
	</div>
	
</template>