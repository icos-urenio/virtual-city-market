<template name="http_error">
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html>
	<head>
		<title>{ERROR.number} {ERROR.title}</title>
	</head>
	<body>
		<h1>{ERROR.title}</h1>
		<p>{ERROR.description}</p>
		<hr />
		{ADDRESS}
	</body>
</html>
</template>