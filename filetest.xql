xquery version "3.0";
import module namespace config="http://exist-db.org/xquery/apps/config" at "/apps/dashboard/modules/config.xqm";
declare namespace file="http://exist-db.org/xquery/file";

(:file:directory-list($path, $pattern)('../../','*'):)

file:list("webapps/digitallibrary/images")

