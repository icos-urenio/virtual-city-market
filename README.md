# VirtualCityMarket
===================

The application enables the creation of a smart marketplace managed by the local shopping community. It empowers the city local marketplace by bringing together customers and merchants.

VirtualCityMarket has been developed within the European project PEOPLE. Find out more at [http://smartcityapps.urenio.org](http://smartcityapps.urenio.org/improve-my-city_en.html).

## License
VirtualCityMarket's source code is licensed under the [GNU Affero General Public License](https://www.gnu.org/licenses/agpl.html).

## Installation
* Create a database in your mysql server.
* Import data/market.sql to the database.
* Copy the application directory to your web server.
* Edit config.inc.php. Add your mysql credentials and your Google maps api key.
* Make sure that mod_rewrite is enabled.
* If you install the application in a directory different than "virtual-city-market" change the directory name in the following line of the .htaccess file:

    RewriteRule . /virtual-city-market/index.php [L]

## Changelog

### Version 1.0a
* Initial public release
