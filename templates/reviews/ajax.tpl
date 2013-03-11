<template parent="main">
	
	<php>
		
		switch ($_POST['action']) {
			case 'rating':
				print json_encode(array('rate' => floatval($_POST['rate'])));
			break;
		}
		
		exit;
		
	</php>
	
</template>