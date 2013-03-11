<template parent="main" assign="PAGE.Body" global="PAGE.Title: `{LANG.Account settings}`" permissions="registered">
	
	<php>
		
		include_once(MARKET_TEMPLATE_DIR . '/account/common.php');
		
		if (defined('IN_MARKET')) {
			
			$this->assignGlobal('CURRENT.settings', 'active');
			$this->assignGlobal('DIV.Class', 'span12');
			$this->assignGlobal('PASSWORD.show', ' display: none;');
			
			if ($_POST && count($_POST)) {
				
				$errors = array();
				
				// Email
				if ($_POST['email'] && $_POST['email'] != $_SESSION['User']['user_email']) {
					if (!validEmail($_POST['email'])) {
						$errors['email'] = __('The email address is not valid.');
					}
					else {
						$sql = "SELECT user_id FROM market_user WHERE user_email='" . sqlEscape($_POST['email']) . "'";
						if (sqlQuery($sql, $res)) {
							$errors['email'] = __('The email address is already registered.');
						}
					}
				}
				
				// Password
				if ($_POST['password']) {
					if (mb_strlen($_POST['password']) >= 8) {
						if (preg_match('@\d+@', $_POST['password'])) {
							if ($_POST['password'] != $_POST['password2']) {
								$this->assignGlobal('PASSWORD.show', ' display: block;');
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
				$role_id = $_SESSION['User']['market_role_id'];
				if ($_POST['type']) {
					$role_id = ($_POST['type'] == 'business') ? 2 : 3;
					if ($role_id == 3) {
						if ($role_id != $_SESSION['User']['market_role_id'] && $_SESSION['User']['store']) {
							$role_id = 2; // Restore
							$errors['type'] = __('Your account is linked to a marketplace store. You cannot change your user type.');
						}
					}
				}
				else if (!$_SESSION['User']['store']) {
					$errors['type'] = __('The user type is required.');
				}
				
				// Required fields
				$required_fields = array(
					'email'		=> __('Your email address is required.'),
					'name'		=> __('Your name is required.'),
					'surname'	=> __('Your surname is required.')
				);
				
				foreach ($required_fields as $required_field => $message) {
					if (!$_POST[$required_field]) {
						$errors[$required_field] = $message;
					}
				}
			
				// Create activation code
				$code = '';
				if ($_POST['email'] && $_POST['email'] != $_SESSION['User']['user_email']) {
					$i = 0;
					while ($i < 10) { // Try at most 10 times to create a unique code
						$code = substr(md5(uniqid(rand(), true)), 0, 16);
						$sql = "SELECT activate_account FROM market_user WHERE activate_account='" . sqlEscape($code) . "'";
						if (sqlQuery($sql, $res)) {
							$i++;
						}
						else {
							// Code OK
							break;
						}
					}
					// 10 times limit reached
					if ($i == 10) {
						$errors['general'] = __('An error occured') . '. ' . __('Please try again later.');
					}
				}
				
				if ($errors) {
					if ($errors['general']) {
						$this->assignGlobal('PERSONAL.Message', '<div class="alert alert-error">' . $errors['general'] . '</div>');
					}
					else {
						$this->assignGlobal('PERSONAL.Message', '<div class="alert alert-error">' . __('There are errors. Please review the form and correct the fields marked in red.') . '</div>');
					}
					foreach ($errors as $key => $error) {
						$this->assignGlobal('ERROR.' . $key, '<span class="help-inline">' . htmlspecialchars($error) . '</span>');
						$this->assignGlobal('ERROR.C' . $key, ' error');
					}
				}
				else {
					$sql = "UPDATE market_user SET market_role_id='" . $role_id . "', " . (($_POST['password']) ? "user_password='" . sqlEscape(md5($_POST['password'])) . "', " : "") . (($code) ? "activate_account='" . sqlEscape($code) . "', activate_account_tstamp=NOW(), user_email='" . sqlEscape($_POST['email']) . "', ": "") . "name='" . sqlEscape($_POST['name']) . "', surname='" . sqlEscape($_POST['surname']) . "'  WHERE user_id='" . sqlEscape($_SESSION['User']['user_id']) . "'";
					if (sqlQuery($sql, $res)) {
						
						// Reload Session
						$auth =& $this->getRef('Auth');
						$sql = "SELECT * FROM market_user WHERE user_id='" . sqlEscape($_SESSION['User']['user_id']) . "'";
						$auth->userLogin($sql);
						
						// Gravatar
						$this->assignGlobal('USER.gravatar', md5(strtolower(trim($_SESSION['User']['user_email']))));
						
						if ($code) {
							if ($_POST['email'] != $_SESSION['User']['username']) {
								// User has an unconfirmed email. Send confirmation email.
								
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
								$mail->Subject  = __('Confirm your new email address at') . ' "' . __('Virtual City Market') . '"';
								
								// Template variables
								$this->assignGlobal('MESSAGE', __('You received this message because you have changed your email address at'));
								$this->assignGlobal('CONFIRMATION_CODE', $code);
								$this->assignGlobal('SUPPORT_EMAIL', SUPPORT_EMAIL);
								
								// Trim final ò from greek names
								if (MARKET_LANG == 'el') {
									$_POST['name'] = preg_replace('@ò$@U', '', $_POST['name']);
									$_POST['name'] = preg_replace('@ï$@U', 'å', $_POST['name']);
									$_POST['surname'] = preg_replace('@ò$@U', '', $_POST['surname']);
									$_POST['surname'] = preg_replace('@ï$@U', 'å', $_POST['surname']);
								}
								$this->assignGlobal('USER', array(
									'name' => $_POST['name'],
									'surname' => $_POST['surname']
								));
								
								// Load the template
								$this->loadTemplate('account/mail/confirm_address');
								$this->parseTemplate('HTML');
								
								$html = $this->getFinalTemplate('HTML');
								$mail->MsgHTML($html);
								
								if ($mail->Send()) {
									// Show success message
									$this->assignGlobal('PERSONAL.Message', '<div class="alert alert-info">' . __('Your personal details were updated successfully.') . ' ' . __('We have send a confirmation message to your new email address. Please read it and follow the instructions to confirm your new email address.') . '</div>');
								}
								else {
									// Show failed message
									$this->assignGlobal('PERSONAL.Message', '<div class="alert alert-info">' . __('Your personal details were updated successfully but we failed to send you the confirmation message. Please check your new email address.') . '</div>');
								}
							}
							else {
								$this->assignGlobal('PERSONAL.Message', '<div class="alert alert-info">' . __('Your personal details were updated successfully.') . '</div>');
							}
						}
						else {
							$this->assignGlobal('PERSONAL.Message', '<div class="alert alert-info">' . __('Your personal details were updated successfully.') . '</div>');
						}
					}
				}
			}
			
			// User type
			if ($_SESSION['User']['market_role_id'] == 2) { // Business
				
				$this->assignGlobal('OPTION.business', ' selected=""');
				$this->assignGlobal('DIV.Class', 'span8 tab-content');
				$this->enableTemplate('menu');
				
				if ($_SESSION['User']['store']) {
					// Disable change of user type
					$this->assignGlobal('TYPE_SELECT.disabled', ' disabled=""');
					$this->assignGlobal('TYPE_SELECT.disabled_help', '<span class="help-block"><small>' . __('Your account is linked to a business. You cannot change your user type.') . '</small></span>');
				}
				else {
					$this->enableTemplate('pin_form');
				}
			}
			else {
				$this->assignGlobal('OPTION.visitor', ' selected=""');
			}
			
			// Email
			if ($_SESSION['User']['username'] != $_SESSION['User']['user_email']) {
				$this->assignGlobal('EMAIL.confirm', '<span class="help-inline"><a class="small blue" href="{DBX.LWebDir}/account/confirm_request.html?email=' . urlencode($_SESSION['User']['user_email']) . '" rel="popover" title="' . __('Email address unconfirmed') . '" data-content="' . __('Click this link to request the confirmation email again.') . '">' . __('Unconfirmed') . '</a></span>');
				$this->enableTemplate('old_address');
			}
			
			// Autocomplete fields
			$_POST['name'] = $_SESSION['User']['name'];
			$_POST['surname'] = $_SESSION['User']['surname'];
			$_POST['email'] = $_SESSION['User']['user_email'];
			$this->assignPHPVars($this->templates['personal_form']['text']);
			
			$_POST['username'] = $_SESSION['User']['username'];
			$this->assignPHPVars($this->templates['old_address']['text']);
			
			$this->assignPHPVars($this->templates['menu']['text']);
			
		}
	</php>
	
	<template name="css" assign="PAGE.Style">
		<style type="text/css">
			legend { font-size: 18px; font-family: 'Ubuntu Condensed', Arial, sans-serif; margin-bottom: 0; }
			.help-inline small { font-size: 12px; }
			.help-block small { font-size: 12px; color: #666; }
			.help-block { margin-top: 10px; }
			option { padding: 0 15px; }
			option.disabled { padding: 0 5px; color: #666; border-bottom: 1px solid #ccc; background: #f5f5f5; }
		</style>
	</template>
	
	<template name="js" assign="PAGE.Javascript">
		<script type="text/javascript">
			jQuery(document).ready(function() {
				$('#password').on('focus', function() {
					$('.password2').fadeIn();
				});
				
				$('#password').on('blur', function() {
					if (!$('#password').val())
						$('.password2').fadeOut();
				});
				
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
			<div class="{DIV.Class}">
				<template name="personal_form">
					<div id="personal" style="border: 1px solid #DFDFDF;">
						<div class="span6" style="float: none; margin: 0 auto; margin-top: 20px;">
							<img src="{MARKET.WebDir}/img/user_account.png" width="128" height="128" alt="" />
							<h2 style="margin-bottom: 20px; border-bottom: 1px solid #ddd;">{LANG.Edit your personal details}</h2>
							{PERSONAL.Message}
							<form class="form-horizontal" action="" method="POST">
								<fieldset>
									<div class="control-group">
										<label class="control-label">&nbsp;</label>
										<div class="controls">
											<img class="img-polaroid" src="http://www.gravatar.com/avatar/{USER.gravatar}.jpg?d=mm&s=80" width="80" height="80" alt="" />
											<span class="help-block"><small>{LANG.Go to} <a class="blue" href="http://www.gravatar.com" target="_blank">gravatar.com</a> {LANG.to attach an image to your email.}</small></span>
										</div>
									</div>
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
									<div class="control-group{ERROR.Cemail}">
										<label class="control-label" for="email">{LANG.Email address}:</label>
										<div class="controls">
											<input class="span3" id="email" name="email" type="text" value="{_SAFE_POST.email}" />{EMAIL.confirm}{ERROR.email}
											<span class="help-block"><small>{LANG.You will have to confirm your new email address before you can use it.}</small></span>
										</div>
									</div>
									<template name="old_address" disabled="true">
										<div class="control-group">
											<label class="control-label" for="username">{LANG.Old email address}:</label>
											<div class="controls">
												<input class="span3" id="username" name="username" type="text" value="{_SAFE_POST.username}" disabled="" />
												<span class="help-block"><small>{LANG.Until you confirm your new email address, we will still use your old address to contact you.}</small></span>
											</div>
										</div>
									</template>
									<div class="control-group{ERROR.Cpassword}">
										<label class="control-label" for="password">{LANG.Password}:</label>
										<div class="controls">
											<input class="span3" id="password" name="password" type="password" value="" autocomplete="off" />{ERROR.password}
											<span class="help-block"><small>{LANG.Leave the field blank, if you do not want to change your password.}</small></span>
										</div>
									</div>
									<div class="password2 control-group{ERROR.Cpassword2}" style="{PASSWORD.show}">
										<label class="control-label" for="password2">{LANG.Repeat password}:</label>
										<div class="controls">
											<input class="span3" id="password2" name="password2" type="password" value="" />{ERROR.password2}
										</div>
									</div>
									<div class="control-group{ERROR.Ctype}" style="margin-bottom: 0;">
										<label class="control-label" for="type">{LANG.User type}:</label>
										<div class="controls">
											<select class="span3" id="type" name="type"{TYPE_SELECT.disabled}>
												<option value="" class="disabled">{LANG.Please select}</option>
												<option value="visitor"{OPTION.visitor}>{LANG.Site visitor}</option>
												<option value="business"{OPTION.business}>{LANG.Local business}</option>
											</select>{ERROR.type}
											{TYPE_SELECT.disabled_help}
										</div>
									</div>
								</fieldset>
								<div class="form-actions white" style="border-top: none;">
									<button class="btn btn-primary" type="submit" id="user_submit" name="personal_form" value="true">{LANG.Update account}</button>
								</div>
							</form>
						</div>
					</div>
				</template>
			</div>
			
			<template name="menu" disabled="true">
				<div class="menu span4">
					<ul class="well nav nav-list">
						<li><h3 style="border-bottom: 1px solid #ccc;">{LANG.Account options}</h3></li>
						<li class="active"><a href="{MARKET.LWebDir}/account/settings/index.html">{LANG.Personal details}</a></li>
						<if expr="'{_SESSION.User.market_role_id}' == 2">
							<li><a href="{MARKET.LWebDir}/account/settings/business.html">{LANG.Business details}</a></li>
						</if>
						<if expr="'{_SESSION.User.store}'">
							<li><a href="{MARKET.LWebDir}/account/settings/offers.html">{LANG.Offers management}</a></li>
						</if>
					</ul>
				</div>
			</template>
		</div>
		
	</div>
</template>