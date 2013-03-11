<template parent="main">
	
	<php>
		
		$lng =& $this->getRef('Lang');
		
		// Force SQL class load
		sqlQuery('SELECT foo', $res);
		
		$SELECT = "*, IF (business_name = '', name, business_name) AS business_title";
		$FROM = "directory STRAIGHT_JOIN directory_ml STRAIGHT_JOIN directory_ps";
		$WHERE = "directory.id=directory_ml.id AND directory.id=directory_ps.id AND directory_ml.lang='" . MARKET_LANG . "' AND directory_ps.publish='1'";
		
		$parts = explode('/', $_GET['path']);
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
			if ($_GET['marker'] && preg_match('@^\(([\d\.]+), ([\d\.]+)\)$@', $_GET['marker'], $matches)) {
				if ($_SESSION['User']['market_role_id'] == 1 || $_SESSION['User']['store'] == $row['id']) {
					$sql = "UPDATE directory SET lat='" . sqlEscape($matches[1]) . "', lng='" . sqlEscape($matches[2]) . "' WHERE id='" . $row['id'] . "'";
					sqlQuery($sql, $res);
				}
			}
			else {
				$row['address'] = ($row['address']) ? $row['address'] . ', ' . $row['city'] : $row['city'];
				$row['html'] = '<h3>' . htmlspecialchars($row['business_title']) . '</h2>
								<h4>' . htmlspecialchars($row['byline']) . '</h3>
								<address style="margin-bottom: 0;">
									' . htmlspecialchars($row['address']) . '<br />
									' . $lng->strs['tel'] . '. ' . htmlspecialchars($row['phone']) . '
								</address>';
				if ($row['lat'] > 0 && $row['lng'] > 0) {
					$markers[0] = array(
						'id' => $row['id'],
						'title' => $row['title'],
						'lat' => $row['lat'],
						'lng' => $row['lng'],
						'infoWindow' => array('content' => $row['html'])
					);
					if ($parts[3] == 'edit') {
						$markers[0]['draggable'] = true;
					}
				}
				else {
					// Default
					if ($parts[3] == 'edit') {
						$markers[] = array(
							'id' => $row['id'],
							'title' => $row['title'],
							'lat' => '40.546868',
							'lng' => '23.020292',
							'infoWindow' => array('content' => $row['html']),
							'draggable' => true
						);
					}
				}
			}
		}
		print json_encode($markers);
		
		exit;
		
	</php>
	
</template>