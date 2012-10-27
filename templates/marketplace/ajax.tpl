<template parent="main">
	
	<php>
		
		$lng =& $this->getRef('Lang');
		
		// {LANG.more}
		
		// Force SQL class load
		sqlQuery('SELECT foo', $res);
		
		$SELECT = "directory.*, directory_ml.*, IF (business_name = '', directory_ml.name, business_name) AS business_title";
		$FROM = "directory STRAIGHT_JOIN directory_ml STRAIGHT_JOIN directory_ps STRAIGHT_JOIN store_data";
		$WHERE = "directory.id=directory_ml.id AND directory.id=directory_ps.id AND directory.id=store_data.directory_id AND store_data.type='text' AND directory_ml.lang='" . MARKET_LANG . "' AND directory_ps.publish='1' ORDER BY business_title";
		
		if ($_GET['q']) {
			$this->assignGlobal('GET.q', htmlspecialchars($_GET['q']));
			$srh =& $this->getRef('Search');
			
			if ($_GET['content'] == 'city') {
				$search_in = 'city';
				$search_as = 'exact';
				$_GET['q'] = '"' . $_GET['q'] . '"';
			}
			else {
				$search_in = 'directory_ml.name, business_name, category, prof1, prof2, prof3, byline, address';
				$search_as = '';
			}
			$cmd = "SEARCH IN " . $search_in . " OF $FROM RETURN $SELECT WHERE " . $WHERE . "";
			$sql = $srh->searchFor($_GET['q'], $cmd, $search_as);
		}
		else {
			$sql = "SELECT $SELECT FROM $FROM WHERE $WHERE";
		}
		
		if (sqlQuery($sql, $res)) {
			while ($row = sqlFetchAssoc($res)) {
				$row['address'] = ($row['address']) ? $row['address'] . ', ' . $row['city'] : $row['city'];
				$row['html'] = '<h3>' . htmlspecialchars($row['business_title']) . '</h2>
								<h4>' . htmlspecialchars($row['byline']) . '</h3>
								<address style="margin-bottom: 0;">
									' . htmlspecialchars($row['address']) . '<br />
									' . $lng->strs['tel'] . '. ' . htmlspecialchars($row['phone']) . '
								</address>
								<p style="margin: 5px 0;"><a class="blue" href="' . MARKET_WEB_DIR . '/' . MARKET_LANG . '/marketplace/show.html?id=' . $row['id'] . '">' . $lng->strs['more'] . '</a></p>';
				
				$markers[] = array(
					'id' => $row['id'],
					'title' => $row['title'],
					'lat' => $row['lat'],
					'lng' => $row['lng'],
					'infoWindow' => array('content' => $row['html'])
				);
			}
			print json_encode($markers);
		}
		exit;
		
	</php>
	
</template>