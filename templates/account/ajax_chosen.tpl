<template parent="main">
	
	<php>
		
		$lng =& $this->getRef('Lang');
		
		// Force SQL class load
		sqlQuery('SELECT foo', $res);
		
		$options = array();
		if ($_GET['category']) {
			$sql = "SELECT prof1, prof2, prof3 FROM directory_ml WHERE lang='" . MARKET_LANG . "' AND category='" . sqlEscape($_GET['category']) . "'";
			if (sqlQuery($sql, $res)) {
				while ($row = sqlFetchAssoc($res)) {
					for ($i = 1; $i <=3; $i++) {
						$options[$row['prof' . $i]] = $row['prof' . $i];
					}
				}
			}
			asort($options);
		}
		
		print json_encode($options);
		
		exit;
		
	</php>
	
</template>