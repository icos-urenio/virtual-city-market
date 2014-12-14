<?php
	// Categories
	$sql = "SELECT category FROM directory_ml WHERE lang='" . MARKET_LANG . "' AND category <> '' GROUP BY category ORDER BY category";
	if (sqlQuery($sql, $res)) {
		$i = 1;
		while ($row = sqlFetchAssoc($res)) {
			$str = '';
			$sql = "SELECT prof1, prof2, prof3 FROM directory_ml WHERE lang='" . MARKET_LANG . "' AND category='" . sqlEscape($row['category']) . "'";
			if (sqlQuery($sql, $res1)) {
				$tags = array();
				while ($row1 = sqlFetchAssoc($res1)) {
					for ($j = 1; $j <= 3; $j++) {
						if ($row1['prof' . $j] && !in_array($row1['prof' . $j], $tags)) {
							$tags[] = $row1['prof' . $j];
						}
					}
				}
				asort($tags);
				if ($_COOKIE['mplace_menu'] & pow(2, $i - 1)) {
					$str = '<ul id="ul' . $i . '" class="tags in collapse">';
				}
				else {
					$str = '<ul id="ul' . $i . '" class="tags collapse">';
				}
				foreach ($tags as $tag) {
					$str .= '<li><a href="index.html?content=tag&q='.urlencode($tag).'">' . htmlspecialchars($tag) . '</a></li>';
				}
				$str .= '</ul>';
			}
			$this->assignLocal('category', 'ROW', array(
				'ndx' => $i,
				'title' => $row['category'],
				'tags' => $str
			));
			$this->lightParseTemplate('CATEGORY', 'category');
			$i++;
		}
	}
	else {
		$this->disableTemplate('categories');
	}
	
	// Cities
	if (!defined('MARKET_CITIES_MENU') || (defined('MARKET_CITIES_MENU') && MARKET_CITIES_MENU)) {
		$sql = "SELECT city FROM directory_ml WHERE lang='" . MARKET_LANG . "' AND city <> '' GROUP BY city ORDER BY city";
		if (sqlQuery($sql, $res)) {
			$cities = array();
			while ($row = sqlFetchAssoc($res)) {
				$cities[] = $row['city'];
			}
			asort($cities);
			$str = '';
			foreach ($cities as $city) {
				$str .= '<li><a href="index.html?content=city&q='.urlencode($city).'">' . htmlspecialchars($city) . '</a></li>';
			}
			$this->assignGlobal('CATEGORIES.Cities', $str);
		}
	}
	else {
		$this->disableTemplate('cities');
	}
?>