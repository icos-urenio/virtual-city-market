<template parent="main" assign="PAGE.Body" global="PAGE.Title: `{LANG.Register}`">
	
	<php>
		
		require_once(MARKET_ROOT_DIR . '/redist/recaptcha-php/recaptchalib.php');
		include_once(MARKET_TEMPLATE_DIR . '/account/common.php');
		
		if (defined('IN_MARKET')) {
		
			$auth =& $this->getRef('Auth');
			$auth->userLogout();
				
			$this->assignGlobal('DIV.Class', 'span9 offset1');
		
			if ($_POST && count($_POST)) {
			
				$store_id = 0;
				$role_id = 0;
				$errors = array();
				
				// Email
				if ($_POST['email']) {
					if (!validEmail($_POST['email'])) {
						$errors['email'] = __('The email address is not valid.');
					}
					else {
						$sql = "SELECT user_id FROM market_user WHERE username='" . sqlEscape($_POST['email']) . "'";
						if (sqlQuery($sql, $res)) {
							$errors['email'] = ('The email address is already registered.');
						}
					}
				}
				
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
				
				// User Type
				if ($_POST['type']) {
					if ($_POST['type'] == 'business') {
						$role_id = '2';
						$this->assignGlobal('OPTION.business', ' selected=""');
						$this->assignGlobal('PIN.show', ' display: block;');
						if ($_POST['pin']) {
							$sql = "SELECT id FROM directory WHERE pin='" . sqlEscape($_POST['pin']) . "'";
							if (sqlQuery($sql, $res)) {
								$store_id = sqlResult($res, 0);
								$sql = "SELECT * FROM market_user WHERE store='" . $store_id . "'";
								if (sqlQuery($sql, $res)) {
									$store_id = 0;
									$errors['pin'] = __('This PIN code is already used. Please contact your professional association.');
								}
							}
							else {
								$errors['pin'] = __('The PIN code is incorrect.');
							}
						}
					}
					else {
						$role_id = '3';
						$this->assignGlobal('OPTION.visitor', ' selected=""');
						$this->assignGlobal('PIN.show', ' display: none;');
					}
				}
				else {
					$this->assignGlobal('PIN.show', ' display: none;');
				}
				
				// Agree
				if ($_POST['agree']) {
					$this->assignGlobal('OPTION.agree', ' checked=""');
				}
				
				// Required fields
				$required_fields = array(
					'email'		=> __('Your email address is required.'),
					'password'	=> __('The password is required.'),
					'name'		=> __('Your name is required.'),
					'surname'	=> __('Your surname is required.'),
					'type'		=> __('The user type is required.'),
					'agree'		=> __('You must agree whith the terms of use to create an account.')
				);
				
				foreach ($required_fields as $required_field => $message) {
					if (!$_POST[$required_field]) {
						$errors[$required_field] = $message;
					}
				}
				
				// check reCAPTCHA
				if ($_POST['recaptcha_challenge_field'] && $_POST['recaptcha_response_field']) {
					$resp = recaptcha_check_answer(
						RECAPTCHA_PRIVATE_KEY,
						$_SERVER['REMOTE_ADDR'],
						$_POST['recaptcha_challenge_field'],
						$_POST['recaptcha_response_field']
					);
					if (!$resp->is_valid) {
						$errors['recaptcha'] = __('The reCAPTCHA was not correct. Please try again...');
					}
				}
				else {
					$errors['recaptcha'] = __('The reCAPTCHA was not correct. Please try again...');
				}
				
				$code = '';
				// Create activation code
				$i = 0;
				while ($i < 10) { // Try at most 10 times to create a unique code
					$code = substr(md5(uniqid(rand(), true)), 0, 16);
					$sql = "SELECT * FROM market_user WHERE activate_account='" . sqlEscape($code) . "'";
					if (!sqlQuery($sql, $res)) {
						break; // Code OK
					}
					$i++;
				}
				// 10 times limit reached
				if ($i == 10) {
					$errors['general'] = __('An error occured') . '. ' . __('Please try again later.');
				}
				
				if ($errors) {
					if ($errors['general']) {
						$this->assignGlobal('REGISTER.Message', '<div class="alert alert-error">' . $errors['general'] . '</div>');
					}
					else {
						$this->assignGlobal('REGISTER.Message', '<div class="alert alert-error">' . __('There are errors. Please review the form and correct the fields marked in red.') . '</div>');
					}
					foreach ($errors as $key => $error) {
						$this->assignGlobal('ERROR.' . $key, '<span class="help-inline">' . htmlspecialchars($error) . '</span>');
						$this->assignGlobal('ERROR.C' . $key, ' error');
					}
					// reCAPTCHA
					$this->assignGlobal('RECAPTCHA', recaptcha_get_html(RECAPTCHA_PUBLIC_KEY));
				}
				else {
					
					$sql = "SELECT MAX(user_id) FROM market_user";
					if (sqlQuery($sql, $res)) {
						$new_user_id = sqlResult($res, 0) + 1;
						$sql = "INSERT INTO market_user(user_id, market_role_id, username, user_password, activate_account, activate_account_tstamp, name, surname, store, user_email) VALUES ('" . $new_user_id . "', '" . $role_id . "', '" . sqlEscape($_POST['email']) . "', '" . sqlEscape(md5($_POST['password'])) . "', '" . sqlEscape($code) . "', NOW(), '" . sqlEscape($_POST['name']) . "', '" . sqlEscape($_POST['surname']) . "', '" . $store_id . "', '" . sqlEscape($_POST['email']) . "')";
						sqlQuery($sql, $res);
						
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
						$this->assignGlobal('MESSAGE', __('You received this message because you have just created an account at'));
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
						$this->assignGlobal('DIV.Class', 'span6 offset3');
						if ($mail->Send()) {
							// Show success message
							$this->assignGlobal('REGISTER.Message', '<div class="alert alert-info">' . __('Your account was created successfully but is not activated yet.') . ' ' . __('We have send a confirmation message to your email address. Please read it and follow the instructions to activate your account.') . '</div>');
							logEvent('info', __('User registration'), $new_user_id);
						}
						else {
							// Show failed message
							$this->assignGlobal('REGISTER.Message', '<div class="alert alert-error"><b>' . __('An error occured') . '.</b> ' . __('We failed to send you the confirmation message. Please try again later.') . '</div>');
							$sql = "DELETE FROM market_user WHERE user_id='" . $new_user_id . "'";
							sqlQuery($sql, $res);
							logEvent('error', __('User registration failed'));
						}
					}
				}
			}
			else {
				// reCAPTCHA
				$this->assignGlobal('RECAPTCHA', recaptcha_get_html(RECAPTCHA_PUBLIC_KEY));
				$this->assignGlobal('PIN.show', ' display: none;');
				$this->assignGlobal('REGISTER.Message', '<div class="alert alert-info">' . __('Please use the following form to create your user account. All fields are required.') . '</div>');
			}
		}
		
	</php>
	
	<style>
		legend { font-size: 18px; font-family: 'Ubuntu Condensed', Arial, sans-serif; margin-bottom: 0; }
		.help-inline small { font-size: 12px; }
		.help-block small { font-size: 12px; color: #666; }
		option { padding: 0 15px; }
		option.disabled { padding: 0 5px; color: #666; border-bottom: 1px solid #ccc; background: #f5f5f5; }
		#recaptcha_area { margin: 0 auto; }
	</style>
	
	<template name="js" assign="PAGE.Javascript">
		<script type="text/javascript">
			jQuery(document).ready(function() {
				$('#type').on('change', function() {
					if ($('#type').val() == 'business')
						$('.pin').fadeIn();
					else
						$('.pin').fadeOut();
				});
			});
		</script>
	</template>
	
	<script type="text/javascript">
		var RecaptchaOptions = {
			lang : '{MARKET.Lang}'
		};
	</script>
	
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
			<div class="{DIV.Class}">
				<div class="pull-left"><img src="{MARKET.WebDir}/img/user.png" width="128" height="128" alt="" /></div>
				<div style="margin-left: 150px;">
					<h2>{PAGE.Title}</h2>
					{REGISTER.Message}
					<template name="form">
						<form class="form-horizontal" action="" method="POST">
							<fieldset>
								<legend>{LANG.Login details}</legend>
								<div class="control-group{ERROR.Cemail}">
									<label class="control-label" for="email">{LANG.Email address}:</label>
									<div class="controls">
										<input class="span3" id="email" name="email" type="text" value="{_SAFE_POST.email}" />{ERROR.email}
										<span class="help-block"><small>{LANG.Your email address will be used to activate your account.}</small></span>
									</div>
								</div>
								<div class="control-group{ERROR.Cpassword}">
									<label class="control-label" for="password">{LANG.Password}:</label>
									<div class="controls">
										<input class="span3" id="password" name="password" type="password" value="" autocomplete="off" />{ERROR.password}
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
							<fieldset>
								<legend>{LANG.User details}</legend>
								<div class="control-group{ERROR.Cname}">
									<label class="control-label" for="name">{LANG.Name}:</label>
									<div class="controls">
										<input class="span3" id="name" name="name" type="text" value="{_SAFE_POST.name}" />{ERROR.name}
									</div>
								</div>
								<div class="control-group{ERROR.Csurname}">
									<label class="control-label" for="surname">{LANG.Surname}:</label>
									<div class="controls">
										<input class="span3" id="surname" name="surname" type="text" value="{_SAFE_POST.surname}" />{ERROR.surname}
									</div>
								</div>
								<div class="control-group{ERROR.Ctype}" style="margin-bottom: 0px;">
									<label class="control-label" for="type">{LANG.User type}:</label>
									<div class="controls">
										<select class="span3" id="type" name="type">
											<option value="" class="disabled">{LANG.Please select}</option>
											<option value="visitor"{OPTION.visitor}>{LANG.Site visitor}</option>
											<option value="business"{OPTION.business}>{LANG.Local business}</option>
										</select>{ERROR.type}
									</div>
								</div>
								<div class="pin control-group{ERROR.Cpin}" style="margin-top: 20px; margin-bottom: 10px; {PIN.show}">
									<label class="control-label" for="pin">{LANG.PIN Code}:</label>
									<div class="controls">
										<input class="span2" id="pin" name="pin" type="text" value="{_SAFE_POST.pin}" />{ERROR.pin}
									</div>
								</div>
								<div class="control-group" style="margin-top: 10px;">
									<div class="controls">
										<span class="help-block"><small>{LANG.Please select your user type.} {LANG.Local businesses should acquire a PIN code from their professional association to access their business information.} {LANG.You can enter the PIN code later, in your account settings.}</small></span>
									</div>
								</div>
							</fieldset>
							<fieldset>
								<legend>{LANG.Visual confirmation}</legend>
								<div class="control-group{ERROR.Crecaptcha}" style="min-height: 129px; text-align: center;">
									{ERROR.recaptcha}
									{RECAPTCHA}
								</div>
							</fieldset>
							<fieldset>
								<legend></legend>
								<div class="control-group{ERROR.Cagree}">
									<div class="controls">
										<label class="checkbox">
											<input id="agree" name="agree" type="checkbox"{OPTION.agree}> {LANG.I agree with the} "<a class="blue" href="{MARKET.LWebDir}/terms.html" data-modal="modal" data-title="{LANG.Terms}">{LANG.Terms of use}</a>"{ERROR.agree}
										</label>
									</div>
								</div>
							</fieldset>
							<div class="form-actions">
								<button class="btn btn-primary" type="submit" id="user_submit">{LANG.Create account}</button>
							</div>
						</form>
					</template>
				</div>
			</div>
		</div>
	</div>
	
</template>