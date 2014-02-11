xquery version "3.0";

import module namespace restxq="http://exist-db.org/xquery/restxq" at "modules/restxq.xql";
import module namespace tgconnect="http://textgrid.info/namespaces/xquery/tgconnect" at "tg-connect.xql";
import module namespace digilib="http://textgrid.info/namespaces/xquery/digilib" at "digilibProxy.xql";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

(: use shared resources from exist if requested with /$shared/ :)
if (contains($exist:path, "/$shared/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/shared-resources/{substring-after($exist:path, '/$shared/')}">
            <set-header name="Cache-Control" value="max-age=3600, must-revalidate"/>
        </forward>
    </dispatch>  
    
else if ($exist:path = "/") then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="publish/default/"/>
    </dispatch>


else if ($exist:path = "/publish") then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="publish/default/"/>
    </dispatch>

    
else if (contains($exist:path, "/resources/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/{substring-after($exist:path, '/resources/')}">
            <set-header name="Cache-Control" value="max-age=3600, must-revalidate"/>
        </forward>
    </dispatch>   
    
(:  TODO: redirect, fif no second "/" is found, or if uri does not contain a "?", or after post? :)

else if (starts-with($exist:path, ("/publish"))) then
    if (not(ends-with($exist:path, ("/")))) then
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <redirect url="{$exist:resource}/"/>
        </dispatch>  
    else
        let $functions := util:list-functions("http://textgrid.info/namespaces/xquery/tgconnect")
        return
            (: All URL paths are processed by the restxq module :)
            restxq:process($exist:path, $functions)
else if (starts-with($exist:path, ("/digilib"))) then
    let $functions := util:list-functions("http://textgrid.info/namespaces/xquery/digilib")
    return
        restxq:process($exist:path, $functions)

else
(: everything is passed through :)
<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <cache-control cache="yes"/>
</dispatch>

