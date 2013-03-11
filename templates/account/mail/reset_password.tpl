<template>
<!DOCTYPE html>
<html lang="{MARKET.Lang}">
	<head>
		<meta charset="utf-8">
		<title>{LANG.Reset your password at} "{LANG.Virtual City Market}"</title>
		<style>
			body { background: #ffffff; color: #333; font-size: 13px; font-family: "Segoe UI", "Lucida Grande", ​Verdana, ​Arial, ​Helvetica, ​sans-serif; }
			h1 {font-size: 26px; font-family: "Segoe UI Light", "Segoe UI", "Lucida Grande", ​Verdana, ​Arial, ​Helvetica, ​sans-serif; font-weight: normal;}
			.alert-info { padding: 8px 14px; margin: 20px; text-shadow: 0 1px 0 rgba(255, 255, 255, 0.5); border: 1px solid #fbeed5; -webkit-border-radius: 4px; -moz-border-radius: 4px; border-radius: 4px; color: #3a87ad; background-color: #d9edf7; border-color: #bce8f1; }
			.margin { margin: 20px 40px; }
			hr { margin: 40px 0 0 0; border: 0; border-top: 1px solid #eeeeee; border-bottom: 1px solid #ffffff; }
			.small { font-size: 12px; color: #999; }
		</style>
	</head>
	<body>
		<div class="alert-info">{MESSAGE} "{LANG.Virtual City Market}"</div>
		<div class="margin">
			<h1>{LANG.Reset your password at} "{LANG.Virtual City Market}"</h1>
			
			<p>{LANG.Dear} {USER.name} {USER.surname},<p>
			
			<p>{LANG.Please click on the provided link to reset your password.}</p>
			
			<p>{LANG.If the below link does not work, you can paste the following url into your browser}:</p>
			<p><a href="http://{MARKET.Server}{MARKET.LWebDir}/account/reset.html?code={RESET_CODE}">http://{MARKET.Server}{MARKET.LWebDir}/account/reset.html?code={RESET_CODE}</a></p>
			<p>{LANG.The link is valid for two hours and one time use only.}</p>
			
			<p>{LANG.If you are encountering any technical or other problems, please contact us at} <a href="mailto:{SUPPORT_EMAIL}">{SUPPORT_EMAIL}</a></p>
			<hr>
			<p>{LANG.Best regards}</p>
			<p>{LANG.The Administration Team}
			<p></p>
			<p class="small">{LANG.Information in this email including any attachments may be privileged, confidential and is intended exclusively for the addressee. If you are not the intended recipient please notify the sender by return email and delete all copies from your system. You should not reproduce, distribute, store, retransmit, use or disclose its contents to anyone.}</p>
		</div>
	</body>
</html>
</template>