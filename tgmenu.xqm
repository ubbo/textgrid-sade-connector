xquery version "3.0";

module namespace tgmenu="http://textgrid.info/namespaces/xquery/tgmenu"; 

declare namespace tgmd="http://textgrid.info/namespaces/metadata/core/2010";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"; 
declare namespace ore="http://www.openarchives.org/ore/terms/";

declare function tgmenu:init($project, $targetPath){

let
    $metacoll := collection($targetPath || '/meta'),
    $navigation :=
        <navigation>
            {tgmenu:getsubeps($metacoll, 'inital', $project)}
        </navigation>
return 
    $navigation
    
};

declare function tgmenu:switch($format, $title, $uri, $metacoll, $project) {
switch ($format)
    case "text/tg.collection+tg.aggregation+xml"
        return <agg type="collection" uri="{$uri}" title="{$title}">{tgmenu:getsubeps($metacoll, $uri, $project)}</agg>
    case "text/tg.edition+tg.aggregation+xml" 
        return <agg type="edition" uri="{$uri}" title="{$title}">{tgmenu:getsubeps($metacoll, $uri, $project)}</agg>
    case "text/tg.aggregation+xml"
        return  <agg type="aggregation" uri="{$uri}" title="{$title}">{tgmenu:getsubeps($metacoll, $uri, $project)}</agg>
    default return <object type="{$format}" uri="{$uri}" title="{$title}"/>
};

declare function tgmenu:getsubeps($metacoll, $ep, $project) {
if ($ep = 'inital') then
    for $uri in $metacoll//entrypoint/text()
    return
        let $format := $metacoll//tgmd:format[following::tgmd:textgridUri[1]/text() = $uri][last()]/text()
        let $title := $metacoll//tgmd:title[following::tgmd:textgridUri[1]/text() =  $uri][last()]/text()
        return
            tgmenu:switch($format, $title, $uri, $metacoll, $project)
else
    for $i in collection('/sade-projects/'|| $project || '/data/xml/agg')//ore:aggregates[parent::rdf:Description/@rdf:about=$ep]/string(@rdf:resource)
        let $format := $metacoll//tgmd:format[following::tgmd:textgridUri[1][starts-with(. ,$i)]][last()]/text()
        let $uri := $metacoll//tgmd:textgridUri[contains(., $i)][last()]/text()
        let $title := $metacoll//tgmd:title[following::tgmd:textgridUri[1]/text() = $uri][last()]/text()
(: $subep creates "format textgrid:uri.latestRevision" :)
return tgmenu:switch($format, $title, $uri, $metacoll, $project)
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
