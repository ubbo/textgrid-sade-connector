xquery version "3.0";

module namespace tgmenu="http://textgrid.info/namespaces/xquery/tgmenu"; 
import module namespace console="http://exist-db.org/xquery/console";

declare namespace tgmd="http://textgrid.info/namespaces/metadata/core/2010";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"; 
declare namespace ore="http://www.openarchives.org/ore/terms/";

declare function tgmenu:entry($ep, $metacoll) {
for $uri in $ep
                let $format := $metacoll//tgmd:format[following::tgmd:textgridUri[1]/contains(. ,$uri)][last()]/string()
                let $title := $metacoll//tgmd:title[following::tgmd:textgridUri[1]/contains(. ,$uri)][last()]/string()
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
                return $metacoll//tgmd:format[following::tgmd:textgridUri[1]/contains(. ,$i)][last()]/string() ||  ' ' || $metacoll//tgmd:textgridUri[contains(., $i)][last()]/substring-after(., 'textgrid:') || '.xml'
(: $subep creates "format uri.xml" :)
return tgmenu:getobjects($metacoll, $subep)
};
declare function tgmenu:getobjects($metacoll, $subep) {
let $items :=   for $i in $subep
                let $format := substring-before($i, ' ')
                let $uri := substring-before(substring-after($i, ' '), '.xml')
                let $title := $metacoll//tgmd:title[following::tgmd:textgridUri[1]/contains(. ,$uri)][last()]/string()
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
(:declare function tgconnect:updateMenu($project as xs:string, $title as xs:string, $format as xs:string?) {:)
(:    if (doc("/sade-projects/" || $project ||"/navigation-textgrid.xml")//label/text() = string($title)):)
(:    then '':)
(:    else:)
(:        update insert   <li><!-- Bootstrap 3 -->:)
(:                            <label class="tree-toggle nav-header">:)
(:                                {switch ($format):)
(:                                      case "text/tg.collection+tg.aggregation+xml" return <img src="/exist/rest/sade-projects/textgrid/data/img/Collection.gif" style="padding-right: 5px;"/>:)
(:                                      case "text/tg.edition+tg.aggregation+xml" return <img src="/exist/rest/sade-projects/textgrid/data/img/Edition.gif" style="padding-right: 5px;"/>:)
(:                                      case "text/tg.aggregation+xml" return <img src="/exist/rest/sade-projects/textgrid/data/img/Aggregation.gif" style="padding-right: 5px;"/>:)
(:                                      case "Text-Image-Links" return <img src="/exist/rest/sade-projects/textgrid/data/img/TILE.png" style="padding-right: 5px;"/>:)
(:                                      default return "":)
(:                                }:)
(:                                {$title}:)
(:                            </label>:)
(:                            <ul class="nav nav-list tree"><li class="divider"></li></ul>:)
(:                        </li>:)
(:        into doc("/sade-projects/" || $project ||"/navigation-textgrid.xml")//div[@id="nav-textgrid"]/ul:)
(:};:)
(:declare function tgconnect:updateMenuItem($title, $project as xs:string, $entryTitle as xs:string, $uri, $format) {:)
(:(:Why we run two times in this function?:):)
(:if (doc("/sade-projects/" || $project ||"/navigation-textgrid.xml")//a[contains(@href, substring-before($uri, '.xml'))]) :)
(:then '':)
(:else:)
(:    update:)
(:        insert:)
(:            if ($format = 'text/xml'):)
(:            then <li><label><a href="index.html?id=/xml/data/{$uri}">{$title}</a></label><!-- Bootstrap 3 --></li>:)
(:            else if(starts-with($format, 'image')) then <li><label><a href="/exist/apps/textgrid-connect/digilib/textgrid/textgrid:{substring-before($uri, '.xml')}?dw=600">{$title || console:log('format: ' || $format || '; uri: ' || $uri|| '; entry: ' || $entryTitle)}</a></label></li>:)
(:            else <li><label><a href="index.html?id=/xml/tile/{$uri}">{$title}</a></label></li>:)
(:        into :)
(:            if ($format = 'text/xml'):)
(:            then doc("/sade-projects/"|| $project ||"/navigation-textgrid.xml")//ul[preceding-sibling::label/text() = $entryTitle]:)
(:            else if(starts-with($format, 'image')) then doc("/sade-projects/"|| $project ||"/navigation-textgrid.xml")//ul[preceding-sibling::label/text() = $entryTitle]:)
(:            else doc("/sade-projects/"|| $project ||"/navigation-textgrid.xml")//ul[preceding-sibling::label/text() = 'Text-Image-Links']:)
(:};:)
