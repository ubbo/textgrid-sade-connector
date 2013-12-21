xquery version "3.0";

import module namespace restxq="http://exist-db.org/xquery/restxq" at "modules/restxq.xql";
import module namespace tgconnect="http://textgrid.info/namespaces/xquery/tgconnect" at "tg-connect.xql";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

if ($exist:path = "/") then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="index.html"/>
    </dispatch>
    
else if (ends-with($exist:resource, ".html")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <view>
            <forward url="{$exist:controller}/modules/view.xql">
                <set-attribute name="$exist:prefix" value="{$exist:prefix}"/>
                <set-attribute name="$exist:controller" value="{$exist:controller}"/>
            </forward>
        </view>
        <error-handler>
            <forward url="{$exist:controller}/error-page.html" method="get"/>
            <forward url="{$exist:controller}/modules/view.xql"/>
        </error-handler>
    </dispatch>    
    
else if (starts-with($exist:path, ("/publish", "/hello"))) then
    let $functions := util:list-functions("http://textgrid.info/namespaces/xquery/tgconnect")
    return
        (: All URL paths are processed by the restxq module :)
        restxq:process($exist:path, $functions)
else

(: everything is passed through :)
<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <cache-control cache="yes"/>
</dispatch>

