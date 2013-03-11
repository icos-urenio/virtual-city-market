<template parent="main">
	
	<php>
		
		// Force SQL class load
		sqlQuery('SELECT foo', $res);
		
		$SELECT = "*, IF (business_name = '', name, business_name) AS title";
		$FROM = "directory STRAIGHT_JOIN directory_ml STRAIGHT_JOIN directory_ps";
		$WHERE = "directory.id=directory_ml.id AND directory.id=directory_ps.id AND directory_ml.lang='" . MARKET_LANG . "' AND directory_ps.publish='1'";
		
		if ($_GET['id'] && preg_match('@^\d+$@', $_GET['id'])) {
			$WHERE .= " AND directory.id='" . sqlEscape($_GET['id']) . "'";
		}
		else if ($_GET['path']) {
			$parts = explode('/', $_GET['path']);
			if ($parts[3] == 'edit') {
				if ($parts[5]) {
					$WHERE .= " AND (directory.path='" . sqlEscape($parts[5]) . "' OR directory.id='" . sqlEscape($parts[5]) . "')";
				}
			}
			else {
				if ($parts[4]) {
					$WHERE .= " AND (directory.path='" . sqlEscape($parts[4]) . "' OR directory.id='" . sqlEscape($parts[4]) . "')";
				}
			}
		}
		else {
			exit;
		}
		
		$sql = "SELECT $SELECT FROM $FROM WHERE $WHERE";
		
		if (sqlQuery($sql, $res)) {
			$row = sqlFetchAssoc($res);
			if ($row['lat'] > 40 && $row['lng'] < 24) {
				$row['address'] = ($row['address']) ? $row['address'] . ', ' . $row['city'] : $row['city'];
				
				$markers[] = array(
					'id' => $row['id'],
					'title' => $row['title'],
					'lat' => $row['lat'],
					'lng' => $row['lng']
				);
			}
		}
		print json_encode($markers);
		
		exit;
		
	</php>
	
</template>