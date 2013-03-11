-- phpMyAdmin SQL Dump
-- version 3.2.5
-- http://www.phpmyadmin.net
--
-- Σύστημα: localhost
-- Χρόνος δημιουργίας: 11 Μάρ 2013, στις 11:19 PM
-- Έκδοση Διακομιστή: 5.5.27
-- Έκδοση PHP: 5.4.3

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Βάση: `virtual-city-market`
--

-- --------------------------------------------------------

--
-- Δομή Πίνακα για τον Πίνακα `directory`
--

CREATE TABLE IF NOT EXISTS `directory` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `path` varchar(255) NOT NULL,
  `category_ids` text NOT NULL,
  `lat` float(10,6) NOT NULL,
  `lng` float(10,6) NOT NULL,
  `pin` varchar(8) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=6 ;

--
-- 'Αδειασμα δεδομένων του πίνακα `directory`
--

INSERT INTO `directory` (`id`, `path`, `category_ids`, `lat`, `lng`, `pin`) VALUES
(1, 'store01', '', 40.550259, 23.021236, '123456'),
(2, 'store02', '', 40.547413, 23.019882, ''),
(3, '', '', 40.495972, 22.986946, ''),
(4, '', '', 40.496822, 22.988342, ''),
(5, '', '', 40.493984, 22.988792, '');

-- --------------------------------------------------------

--
-- Δομή Πίνακα για τον Πίνακα `directory_ml`
--

CREATE TABLE IF NOT EXISTS `directory_ml` (
  `id` int(11) NOT NULL,
  `lang` varchar(2) NOT NULL,
  `name` text NOT NULL,
  `business_name` text NOT NULL,
  `category` text NOT NULL,
  `byline` text NOT NULL,
  `prof1` text NOT NULL,
  `prof2` text NOT NULL,
  `prof3` text NOT NULL,
  `address` text NOT NULL,
  `city` text NOT NULL,
  `phone` text NOT NULL,
  `email` text NOT NULL,
  `url` text NOT NULL,
  `facebook` text NOT NULL,
  `twitter` text NOT NULL,
  `google` text NOT NULL,
  `youtube` text NOT NULL,
  UNIQUE KEY `id_lang` (`id`,`lang`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- 'Αδειασμα δεδομένων του πίνακα `directory_ml`
--

INSERT INTO `directory_ml` (`id`, `lang`, `name`, `business_name`, `category`, `byline`, `prof1`, `prof2`, `prof3`, `address`, `city`, `phone`, `email`, `url`, `facebook`, `twitter`, `google`, `youtube`) VALUES
(1, 'en', '', 'Store #1', 'Trade', 'This is the byline', 'tag1', '', '', 'Address 01', 'City 01', '1234 567890', 'store1@marketplace', 'http://store1.marketplace', 'facebook ', 'twitter ', 'google ', 'youtube '),
(2, 'en', '', 'Store #2', 'Trade', 'This is the byline', 'tag1', '', '', 'Address 02', 'City 01', '1234 567891', 'store2@marketplace', '', '', '', '', ''),
(3, 'en', '', 'Store #3', 'Food Services', 'This is the byline', 'tag2', '', '', 'Address 03', 'City 02', '1234 567892', 'store3@marketplace', '', '', '', '', ''),
(4, 'en', '', 'Store #4', 'Food', 'This is the byline', 'tag3', '', '', 'Address 04', 'City 02', '1234 567893', 'store4@marketplace', '', 'facebook', 'twitter', 'google', 'youtube'),
(5, 'en', '', 'Store #5', 'Food', 'This is the byline', 'tag3', '', '', 'Address 05', 'City 02', '1234 567894', 'store5@marketplace', '', '', '', '', ''),
(1, 'el', '', 'Store #1', 'Trade', 'This is the byline', 'tag1', '', '', 'Address 01', 'City 01', '1234 567890', 'store1@marketplace', 'http://store1.marketplace', 'facebook ', 'twitter ', 'google ', 'youtube '),
(2, 'el', '', 'Store #2', 'Trade', 'This is the byline', 'tag1', '', '', 'Address 02', 'City 01', '1234 567891', 'store2@marketplace', '', '', '', '', ''),
(3, 'el', '', 'Store #3', 'Food Services', 'This is the byline', 'tag2', '', '', 'Address 03', 'City 02', '1234 567892', 'store3@marketplace', '', '', '', '', ''),
(4, 'el', '', 'Store #4', 'Food', 'This is the byline', 'tag3', '', '', 'Address 04', 'City 02', '1234 567893', 'store4@marketplace', '', '', '', '', ''),
(5, 'el', '', 'Store #5', 'Food', 'This is the byline', 'tag3', '', '', 'Address 05', 'City 02', '1234 567894', 'store5@marketplace', '', '', '', '', '');

-- --------------------------------------------------------

--
-- Δομή Πίνακα για τον Πίνακα `directory_ps`
--

CREATE TABLE IF NOT EXISTS `directory_ps` (
  `id` int(11) NOT NULL DEFAULT '0',
  `creator` int(11) NOT NULL DEFAULT '0',
  `created` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `owner` int(11) NOT NULL DEFAULT '0',
  `role` tinyint(4) NOT NULL DEFAULT '0',
  `updated` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `ups` int(1) NOT NULL DEFAULT '0',
  `gps` int(1) NOT NULL DEFAULT '0',
  `wps` int(1) NOT NULL DEFAULT '0',
  `forward_ids` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `publish` enum('0','1') COLLATE utf8_unicode_ci NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `owner` (`owner`),
  KEY `role` (`role`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- 'Αδειασμα δεδομένων του πίνακα `directory_ps`
--

INSERT INTO `directory_ps` (`id`, `creator`, `created`, `owner`, `role`, `updated`, `ups`, `gps`, `wps`, `forward_ids`, `publish`) VALUES
(1, 1, '2012-10-26 19:56:43', 1, 1, '2012-10-27 11:12:44', 7, 2, 2, '', '1'),
(2, 1, '2012-10-26 19:56:50', 1, 1, '2012-10-26 19:56:50', 7, 2, 2, '', '1'),
(3, 1, '2012-10-26 19:56:57', 1, 1, '2012-10-26 19:56:57', 7, 2, 2, '', '1'),
(4, 1, '2012-10-26 19:57:03', 1, 1, '2012-10-26 19:57:03', 7, 2, 2, '', '1'),
(5, 1, '2012-10-26 19:57:03', 1, 1, '2012-10-26 19:57:03', 7, 2, 2, '', '1');

-- --------------------------------------------------------

--
-- Δομή Πίνακα για τον Πίνακα `log`
--

CREATE TABLE IF NOT EXISTS `log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `type` varchar(255) NOT NULL,
  `text` text NOT NULL,
  `tstamp` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

--
-- 'Αδειασμα δεδομένων του πίνακα `log`
--


-- --------------------------------------------------------

--
-- Δομή Πίνακα για τον Πίνακα `market_role`
--

CREATE TABLE IF NOT EXISTS `market_role` (
  `id` int(11) NOT NULL,
  `title` varchar(64) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `title` (`title`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- 'Αδειασμα δεδομένων του πίνακα `market_role`
--

INSERT INTO `market_role` (`id`, `title`) VALUES
(0, ''),
(1, 'Administrator'),
(2, 'Business'),
(3, 'User');

-- --------------------------------------------------------

--
-- Δομή Πίνακα για τον Πίνακα `market_session`
--

CREATE TABLE IF NOT EXISTS `market_session` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `session_id` varchar(32) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `expires` int(11) NOT NULL DEFAULT '0',
  `data` text COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `session_id` (`session_id`),
  KEY `expires` (`expires`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=1 ;

--
-- 'Αδειασμα δεδομένων του πίνακα `market_session`
--


-- --------------------------------------------------------

--
-- Δομή Πίνακα για τον Πίνακα `market_user`
--

CREATE TABLE IF NOT EXISTS `market_user` (
  `user_id` int(11) NOT NULL DEFAULT '0',
  `market_role_id` int(11) NOT NULL DEFAULT '0',
  `is_admin` enum('0','1') COLLATE utf8_unicode_ci NOT NULL DEFAULT '0',
  `user_active` enum('0','1') COLLATE utf8_unicode_ci NOT NULL DEFAULT '0',
  `username` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `name` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `surname` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `store` int(11) NOT NULL DEFAULT '0',
  `user_password` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `user_email` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `data` text COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- 'Αδειασμα δεδομένων του πίνακα `market_user`
--

INSERT INTO `market_user` (`user_id`, `market_role_id`, `is_admin`, `user_active`, `username`, `name`, `surname`, `store`, `user_password`, `user_email`, `data`) VALUES
(-1, 0, '0', '0', 'Anonymous', '', '', 0, '', '', ''),
(0, 0, '0', '0', '', 'NoUser', '', 0, '', '', ''),
(1, 1, '1', '1', 'root', 'Administrator', '', 0, '63a9f0ea7bb98050796b649e85481845', 'admin@marketplace', ''),
(2, 2, '0', '1', 'business', 'Business', '', 1, 'f5d7e2532cc9ad16bc2a41222d76f269', 'business1@marketplace', ''),
(3, 3, '0', '1', 'user', 'User', '', 0, 'ee11cbb19052e40b07aac0ca060c23ee', 'user@marketplace', '');

-- --------------------------------------------------------

--
-- Δομή Πίνακα για τον Πίνακα `page`
--

CREATE TABLE IF NOT EXISTS `page` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `page_template_id` int(11) NOT NULL,
  `url` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `ord` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `url` (`url`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=2 ;

--
-- 'Αδειασμα δεδομένων του πίνακα `page`
--

INSERT INTO `page` (`id`, `page_template_id`, `url`, `ord`) VALUES
(1, 0, 'terms.html', 0);

-- --------------------------------------------------------

--
-- Δομή Πίνακα για τον Πίνακα `page_ml`
--

CREATE TABLE IF NOT EXISTS `page_ml` (
  `id` int(11) NOT NULL DEFAULT '0',
  `lang` char(2) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `stitle` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `summary` text COLLATE utf8_unicode_ci NOT NULL,
  `title` text COLLATE utf8_unicode_ci,
  `text` longtext COLLATE utf8_unicode_ci NOT NULL,
  `is_type` enum('passthrough','template') COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id`,`lang`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- 'Αδειασμα δεδομένων του πίνακα `page_ml`
--

INSERT INTO `page_ml` (`id`, `lang`, `stitle`, `summary`, `title`, `text`, `is_type`) VALUES
(1, 'el', '', '', 'Όροι χρήσης', '', 'passthrough'),
(1, 'en', '', '', 'Terms of use', '', 'passthrough');

-- --------------------------------------------------------

--
-- Δομή Πίνακα για τον Πίνακα `page_ps`
--

CREATE TABLE IF NOT EXISTS `page_ps` (
  `id` int(11) NOT NULL DEFAULT '0',
  `creator` int(11) NOT NULL DEFAULT '0',
  `created` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `owner` int(11) NOT NULL DEFAULT '0',
  `role` tinyint(4) NOT NULL DEFAULT '0',
  `updated` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `ups` int(1) NOT NULL DEFAULT '0',
  `gps` int(1) NOT NULL DEFAULT '0',
  `wps` int(1) NOT NULL DEFAULT '0',
  `forward_ids` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `publish` enum('0','1') COLLATE utf8_unicode_ci NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `owner` (`owner`),
  KEY `role` (`role`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- 'Αδειασμα δεδομένων του πίνακα `page_ps`
--

INSERT INTO `page_ps` (`id`, `creator`, `created`, `owner`, `role`, `updated`, `ups`, `gps`, `wps`, `forward_ids`, `publish`) VALUES
(1, 1, '2012-11-14 23:12:30', 1, 1, '2012-11-14 23:12:30', 7, 2, 2, '', '1');

-- --------------------------------------------------------

--
-- Δομή Πίνακα για τον Πίνακα `page_template`
--

CREATE TABLE IF NOT EXISTS `page_template` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

--
-- 'Αδειασμα δεδομένων του πίνακα `page_template`
--


-- --------------------------------------------------------

--
-- Δομή Πίνακα για τον Πίνακα `store_data`
--

CREATE TABLE IF NOT EXISTS `store_data` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `directory_id` int(11) NOT NULL,
  `lang` varchar(2) NOT NULL,
  `date_from` date NOT NULL,
  `date_to` date NOT NULL,
  `type` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `title` varchar(255) NOT NULL,
  `price` varchar(255) NOT NULL,
  `discount` int(11) NOT NULL,
  `rating` float NOT NULL,
  `votes` varchar(255) NOT NULL,
  `data` longtext NOT NULL,
  `ord` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=18 ;

--
-- 'Αδειασμα δεδομένων του πίνακα `store_data`
--

INSERT INTO `store_data` (`id`, `directory_id`, `lang`, `date_from`, `date_to`, `type`, `name`, `title`, `price`, `discount`, `rating`, `votes`, `data`, `ord`) VALUES
(1, 1, 'en', '0000-00-00', '0000-00-00', 'text', 'index', '', '0', 0, 0, '', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris ac lacus sed est eleifend egestas non sed nulla. Sed bibendum rhoncus tincidunt. Phasellus non purus vitae nisl fringilla ultrices. Nam aliquet vehicula eleifend. Curabitur mollis turpis eu orci commodo et varius lacus suscipit. Nunc dapibus erat a leo ultrices dictum. Aenean porttitor mi nec elit dignissim sollicitudin. Duis elit neque, vehicula vel suscipit ac, sagittis non odio. Praesent a lorem sed nibh ornare faucibus et vitae turpis. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla lacus lorem, hendrerit et congue vitae, porta vitae ipsum. Donec eu posuere leo. Donec ut neque ut quam tincidunt blandit vitae vitae sem. Mauris pretium ultricies egestas. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae;', 0),
(2, 1, '', '0000-00-00', '0000-00-00', 'image', 'index', '', '0', 0, 0, '', 'uploads/1/placeholder.jpg', 1),
(3, 1, '', '0000-00-00', '0000-00-00', 'image', 'index', '', '0', 0, 0, '', 'uploads/1/placeholder2.jpg', 2),
(4, 1, 'en', '0000-00-00', '0000-00-00', 'page', 'about', 'About us', '0', 0, 0, '', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris ac lacus sed est eleifend egestas non sed nulla. Sed bibendum rhoncus tincidunt. Phasellus non purus vitae nisl fringilla ultrices. Nam aliquet vehicula eleifend. Curabitur mollis turpis eu orci commodo et varius lacus suscipit. Nunc dapibus erat a leo ultrices dictum. Aenean porttitor mi nec elit dignissim sollicitudin. Duis elit neque, vehicula vel suscipit ac, sagittis non odio. Praesent a lorem sed nibh ornare faucibus et vitae turpis. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla lacus lorem, hendrerit et congue vitae, porta vitae ipsum. Donec eu posuere leo. Donec ut neque ut quam tincidunt blandit vitae vitae sem. Mauris pretium ultricies egestas. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae;', 1),
(5, 1, 'en', '0000-00-00', '0000-00-00', 'page', 'products', 'Products', '0', 0, 0, '', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris ac lacus sed est eleifend egestas non sed nulla. Sed bibendum rhoncus tincidunt. Phasellus non purus vitae nisl fringilla ultrices. Nam aliquet vehicula eleifend. Curabitur mollis turpis eu orci commodo et varius lacus suscipit. Nunc dapibus erat a leo ultrices dictum. Aenean porttitor mi nec elit dignissim sollicitudin. Duis elit neque, vehicula vel suscipit ac, sagittis non odio. Praesent a lorem sed nibh ornare faucibus et vitae turpis. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla lacus lorem, hendrerit et congue vitae, porta vitae ipsum. Donec eu posuere leo. Donec ut neque ut quam tincidunt blandit vitae vitae sem. Mauris pretium ultricies egestas. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; ', 2),
(6, 1, 'en', '0000-00-00', '0000-00-00', 'page', 'projects', 'Projects', '0', 0, 0, '', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris ac lacus sed est eleifend egestas non sed nulla. Sed bibendum rhoncus tincidunt. Phasellus non purus vitae nisl fringilla ultrices. Nam aliquet vehicula eleifend. Curabitur mollis turpis eu orci commodo et varius lacus suscipit. Nunc dapibus erat a leo ultrices dictum. Aenean porttitor mi nec elit dignissim sollicitudin. Duis elit neque, vehicula vel suscipit ac, sagittis non odio. Praesent a lorem sed nibh ornare faucibus et vitae turpis. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla lacus lorem, hendrerit et congue vitae, porta vitae ipsum. Donec eu posuere leo. Donec ut neque ut quam tincidunt blandit vitae vitae sem. Mauris pretium ultricies egestas. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; ', 3),
(7, 1, 'en', '0000-00-00', '0000-00-00', 'page', 'services', 'Services', '0', 0, 0, '', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris ac lacus sed est eleifend egestas non sed nulla. Sed bibendum rhoncus tincidunt. Phasellus non purus vitae nisl fringilla ultrices. Nam aliquet vehicula eleifend. Curabitur mollis turpis eu orci commodo et varius lacus suscipit. Nunc dapibus erat a leo ultrices dictum. Aenean porttitor mi nec elit dignissim sollicitudin. Duis elit neque, vehicula vel suscipit ac, sagittis non odio. Praesent a lorem sed nibh ornare faucibus et vitae turpis. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla lacus lorem, hendrerit et congue vitae, porta vitae ipsum. Donec eu posuere leo. Donec ut neque ut quam tincidunt blandit vitae vitae sem. Mauris pretium ultricies egestas. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; ', 4),
(8, 1, 'en', '0000-00-00', '2013-10-31', 'coupon', 'coupon-001', 'Offer #01', '50€', 40, 0, '', 'Curabitur lorem justo, eleifend ac dapibus mollis, venenatis quis lorem. Fusce varius scelerisque nulla quis mollis. Cras ultrices dapibus massa, vel imperdiet tellus faucibus nec. Proin ac tristique enim. Suspendisse nisi risus, commodo sed ultricies in, venenatis id est. Proin id sagittis mauris. Etiam aliquam lorem ac neque lobortis tempor elementum mi porta.', 1),
(9, 1, '', '0000-00-00', '0000-00-00', 'image', 'coupon-001', '', '0', 0, 0, '', 'uploads/1/placeholder.jpg', 1),
(10, 1, 'en', '0000-00-00', '2013-10-31', 'coupon', 'coupon-002', 'Offer #02', '20€', 30, 0, '', 'Duis suscipit massa sed lorem lobortis fermentum. Sed dui odio, consectetur eu bibendum ultricies, feugiat sit amet dui. Nunc aliquam tempor turpis eu venenatis. Phasellus adipiscing, velit a vulputate lacinia, mauris est rhoncus quam, eget pretium tortor erat sit amet ante. Nam sollicitudin, quam vel porttitor faucibus, nibh lacus aliquam orci, quis commodo orci libero consequat felis. Integer odio diam, tempor nec tristique sed, dictum in libero. Suspendisse eu sem dolor. Nunc tempus rutrum fermentum.', 2),
(11, 1, '', '0000-00-00', '0000-00-00', 'image', 'coupon-002', '', '0', 0, 0, '', 'uploads/1/placeholder.jpg', 1),
(12, 1, 'en', '0000-00-00', '2013-10-31', 'coupon', 'coupon-003', 'Offer #03', '50€', 30, 0, '', 'Curabitur a turpis vel ante elementum porta id eu elit. Mauris tempus orci in nunc feugiat ut fringilla tellus luctus. Vivamus nec vestibulum lorem. Aenean eget lectus sed metus iaculis faucibus nec vitae eros. Nulla a turpis quis tellus vulputate ullamcorper blandit a quam. Aenean congue sollicitudin urna, eget ultrices libero pulvinar ac. Fusce tempor turpis at sem venenatis ut iaculis metus tincidunt.', 3),
(13, 1, '', '0000-00-00', '0000-00-00', 'image', 'coupon-003', '', '0', 0, 0, '', 'uploads/1/placeholder.jpg', 1),
(14, 2, 'en', '0000-00-00', '0000-00-00', 'text', 'index', '', '0', 0, 0, '', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris ac lacus sed est eleifend egestas non sed nulla. Sed bibendum rhoncus tincidunt. Phasellus non purus vitae nisl fringilla ultrices. Nam aliquet vehicula eleifend. Curabitur mollis turpis eu orci commodo et varius lacus suscipit. Nunc dapibus erat a leo ultrices dictum. Aenean porttitor mi nec elit dignissim sollicitudin. Duis elit neque, vehicula vel suscipit ac, sagittis non odio. Praesent a lorem sed nibh ornare faucibus et vitae turpis. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla lacus lorem, hendrerit et congue vitae, porta vitae ipsum. Donec eu posuere leo. Donec ut neque ut quam tincidunt blandit vitae vitae sem. Mauris pretium ultricies egestas. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae;', 0),
(15, 2, '', '0000-00-00', '0000-00-00', 'image', 'index', '', '0', 0, 0, '', 'uploads/2/placeholder.jpg', 1),
(16, 1, 'en', '0000-00-00', '0000-00-00', 'comment', 'index', '', '0', 0, 18, '8|2', 'Duis suscipit massa sed lorem lobortis fermentum. Sed dui odio, consectetur eu bibendum ultricies, feugiat sit amet dui. Nunc aliquam tempor turpis eu venenatis. Phasellus adipiscing, velit a vulputate lacinia, mauris est rhoncus quam, eget pretium tortor erat sit amet ante. Nam sollicitudin, quam vel porttitor faucibus, nibh lacus aliquam orci, quis commodo orci libero consequat felis. Integer odio diam, tempor nec tristique sed, dictum in libero. Suspendisse eu sem dolor. Nunc tempus rutrum fermentum. Pellentesque sapien ligula, viverra pretium eleifend nec, dictum in sem. Ut accumsan sollicitudin suscipit. Nullam eu magna non massa tincidunt rhoncus at et nisl. Ut tristique posuere hendrerit. Praesent sit amet odio ac nulla malesuada pharetra quis sed eros. ', 0),
(17, 1, 'en', '0000-00-00', '0000-00-00', 'comment', 'index', '', '0', 0, 16, '', 'Curabitur lorem justo, eleifend ac dapibus mollis, venenatis quis lorem. Fusce varius scelerisque nulla quis mollis.', 0);

-- --------------------------------------------------------

--
-- Δομή Πίνακα για τον Πίνακα `store_data_ps`
--

CREATE TABLE IF NOT EXISTS `store_data_ps` (
  `id` int(11) NOT NULL DEFAULT '0',
  `creator` int(11) NOT NULL DEFAULT '0',
  `created` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `owner` int(11) NOT NULL DEFAULT '0',
  `role` tinyint(4) NOT NULL DEFAULT '0',
  `updated` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `ups` int(1) NOT NULL DEFAULT '0',
  `gps` int(1) NOT NULL DEFAULT '0',
  `wps` int(1) NOT NULL DEFAULT '0',
  `forward_ids` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `publish` enum('0','1') COLLATE utf8_unicode_ci NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `owner` (`owner`),
  KEY `role` (`role`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- 'Αδειασμα δεδομένων του πίνακα `store_data_ps`
--

INSERT INTO `store_data_ps` (`id`, `creator`, `created`, `owner`, `role`, `updated`, `ups`, `gps`, `wps`, `forward_ids`, `publish`) VALUES
(1, 1, '2012-10-26 20:02:50', 1, 1, '2012-10-27 11:10:14', 7, 2, 2, '', '1'),
(2, 1, '2012-10-26 20:02:50', 1, 1, '2012-10-26 20:02:55', 7, 2, 2, '', '1'),
(3, 1, '2012-10-26 20:02:50', 1, 1, '2012-10-26 20:02:55', 7, 2, 2, '', '1'),
(4, 1, '2012-10-26 20:02:50', 1, 1, '2012-10-26 20:02:55', 7, 2, 2, '', '1'),
(5, 1, '2012-10-26 20:02:50', 1, 1, '2012-10-26 20:02:55', 7, 2, 2, '', '1'),
(6, 1, '2012-10-26 20:02:50', 1, 1, '2012-10-26 20:02:55', 7, 2, 2, '', '1'),
(7, 1, '2012-10-26 20:02:50', 1, 1, '2012-10-26 20:02:55', 7, 2, 2, '', '1'),
(8, 1, '2012-10-26 20:02:50', 1, 1, '2012-10-26 20:02:55', 7, 2, 2, '', '1'),
(9, 1, '2012-10-26 20:02:50', 1, 1, '2012-10-26 20:02:55', 7, 2, 2, '', '1'),
(10, 1, '2012-10-26 20:02:50', 1, 1, '2012-10-26 20:02:55', 7, 2, 2, '', '1'),
(11, 1, '2012-10-26 20:02:50', 1, 1, '2012-10-26 20:02:55', 7, 2, 2, '', '1'),
(12, 1, '2012-10-26 20:02:50', 1, 1, '2012-10-26 20:02:55', 7, 2, 2, '', '1'),
(13, 1, '2012-10-26 20:02:50', 1, 1, '2012-10-26 20:02:55', 7, 2, 2, '', '1'),
(14, 1, '2012-10-26 20:02:50', 1, 1, '2012-10-26 20:02:55', 7, 2, 2, '', '1'),
(15, 1, '2012-10-26 20:02:50', 1, 1, '2012-10-26 20:02:55', 7, 2, 2, '', '1'),
(16, 2, '2012-10-26 20:02:50', 1, 1, '2012-10-26 20:02:55', 7, 2, 2, '', '1'),
(17, 3, '2012-10-26 20:02:50', 1, 1, '2012-10-26 20:02:55', 7, 2, 2, '', '1');
