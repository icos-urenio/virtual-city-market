<template parent="main" permissions="admin">
	<php>
		if (defined('IN_MARKET')) {
			$arr = array();
			if ($_POST['query'] && $_POST['path']) {
				switch ($_POST['path']) {
					case 'directory_ml.prof':
						$sql = "SELECT prof FROM (
									SELECT a.prof1 as prof FROM directory_ml a WHERE a.prof1 LIKE '" . sqlEscape($_POST['query']) . "%' AND a.lang='" . MARKET_LANG . "'
									UNION ALL
									SELECT b.prof2 as prof FROM directory_ml b WHERE b.prof2 LIKE '" . sqlEscape($_POST['query']) . "%' AND b.lang='" . MARKET_LANG . "'
									UNION ALL
									SELECT c.prof3 as prof FROM directory_ml c WHERE c.prof3 LIKE '" . sqlEscape($_POST['query']) . "%' AND c.lang='" . MARKET_LANG . "'
								) d
								GROUP BY prof ORDER BY prof LIMIT 0,8";
						if ($_GET['filter']) {
							$sql1 = "SELECT category FROM directory_ml WHERE category = '" . sqlEscape($_GET['filter']) . "' AND lang='" . MARKET_LANG . "'";
							if (sqlQuery($sql1, $res)) {
								$sql = "SELECT prof FROM (
											SELECT a.prof1 as prof FROM directory_ml a WHERE a.prof1 LIKE '" . sqlEscape($_POST['query']) . "%' AND a.lang='" . MARKET_LANG . "' AND a.category='" . sqlEscape($_GET['filter']) . "'
											UNION ALL
											SELECT b.prof2 as prof FROM directory_ml b WHERE b.prof2 LIKE '" . sqlEscape($_POST['query']) . "%' AND b.lang='" . MARKET_LANG . "' AND b.category='" . sqlEscape($_GET['filter']) . "'
											UNION ALL
											SELECT c.prof3 as prof FROM directory_ml c WHERE c.prof3 LIKE '" . sqlEscape($_POST['query']) . "%' AND c.lang='" . MARKET_LANG . "' AND c.category='" . sqlEscape($_GET['filter']) . "'
										) d
										GROUP BY prof ORDER BY prof LIMIT 0,8";
							}
						}
						if (sqlQuery($sql, $res)) {
							while ($row = sqlFetchAssoc($res)) {
								$arr[] = $row['prof'];
							}
						}
					break;
					default:
						$parts = explode('.', $_POST['path'], 2);
						if ($parts[0] && $parts[1]) {
							$sql = "SELECT `" . sqlEscape($parts[1]) . "` FROM `" . sqlEscape($parts[0]) . "` WHERE `" . sqlEscape($parts[1]) . "` LIKE '" . sqlEscape($_POST['query']) . "%'" . ((preg_match('@_ml$@', $parts[0])) ? " AND lang='" . MARKET_LANG . "' " : ' ') . "GROUP BY `" . sqlEscape($parts[1]) . "` ORDER BY `" . sqlEscape($parts[1]) . "` LIMIT 0,8";
							if (sqlQuery($sql, $res)) {
								while ($row = sqlFetchAssoc($res)) {
									$arr[] = $row[$parts[1]];
								}
							}
						}
				}
			}
			print json_encode($arr); //, JSON_UNESCAPED_UNICODE);
		}
		exit;
	</php>
</template>