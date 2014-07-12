xquery version "3.0";

module namespace tgmenu="http://textgrid.info/namespaces/xquery/tgmenu"; 

declare namespace tgmd="http://textgrid.info/namespaces/metadata/core/2010";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"; 
declare namespace ore="http://www.openarchives.org/ore/terms/";

declare function tgmenu:entry($uri as xs:string, $metacoll) as node() {
let $format := $metacoll//tgmd:format[following::tgmd:textgridUri[1]/text() = $uri][last()]/text()
let $title := $metacoll//tgmd:title[following::tgmd:textgridUri[1]/text() =  $uri][last()]/text()
return
    switch ($format)
        case "text/tg.collection+tg.aggregation+xml"
            return <agg type="collection" uri="{$uri}" title="{$title}"/>
        case "text/tg.edition+tg.aggregation+xml" 
            return <agg type="edition" uri="{$uri}" title="{$title}"/>
        case "text/tg.aggregation+xml"
            return  <agg type="aggregation" uri="{$uri}" title="{$title}"/>
        default return <object type="{$format}" uri="{$uri}" title="{$title}"/>
};
declare function tgmenu:getsubeps($metacoll, $ep) {
let $subep := for $i in collection('/sade-projects/textgrid/data/xml/agg')//ore:aggregates[parent::rdf:Description/@rdf:about = $ep]/@rdf:resource
                return $metacoll//tgmd:format[following::tgmd:textgridUri[1]/contains(. ,$i)][last()]/string() ||  ' ' || $metacoll//tgmd:textgridUri[contains(., $i)][last()]/text()
(: $subep creates "format textgrid:uri.latestRevision" :)
return tgmenu:getobjects($metacoll, $subep)
};
declare function tgmenu:getobjects($metacoll, $subep) {
let $items :=   for $i in $subep
                let $format := substring-before($i, ' ')
                let $uri := substring-after($i, ' ')
                let $title := $metacoll//tgmd:title[following::tgmd:textgridUri[1]/text() = $uri][last()]/text()
                return
                    switch ($format)
                        case "text/tg.collection+tg.aggregation+xml"
                            return <agg type="collection" uri="{$uri}" title="{$title}"/>
                        case "text/tg.edition+tg.aggregation+xml" 
                            return <agg type="edition" uri="{$uri}" title="{$title}"/>
                        case "text/tg.aggregation+xml"
                            return  <agg type="aggregation" uri="{$uri}" title="{$title}"/>
                        default return <object type="{$format}" uri="{$uri}" title="{$title}"/>
return $items
};
