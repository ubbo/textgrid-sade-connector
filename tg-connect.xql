xquery version "3.0";

module namespace tgconnect="http://textgrid.info/namespaces/xquery/tgconnect"; 

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace tgclient="http://textgrid.info/namespaces/xquery/tgclient" at "tgclient.xqm";
import module namespace req="http://exquery.org/ns/request";
import module namespace tgmenu="http://textgrid.info/namespaces/xquery/tgmenu" at "/db/apps/textgrid-connect/tgmenu.xqm";
import module namespace console="http://exist-db.org/xquery/console";

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http="http://expath.org/ns/http-client"; 
declare namespace tgmd="http://textgrid.info/namespaces/metadata/core/2010";

declare variable $tgconnect:websiteDataPath := "/data/website";
declare variable $tgconnect:editionDataPath := "/data/xml";


(:~
 : show html.
 :)
declare
    %rest:GET
    %rest:path("/publish/{$project}/")
    %output:media-type("text/html")
    %output:method("html5")
function tgconnect:page($project as xs:string*) {
    let $content := doc("publish-gui.html")
    let $config := map {
        (: The following function will be called to look up template parameters :)
        $templates:CONFIG_PARAM_RESOLVER := function($param as xs:string) as xs:string* {
            req:parameter($param)
        }
    }
    let $lookup := function($functionName as xs:string, $arity as xs:int) {
        try {
            function-lookup(xs:QName($functionName), $arity)
        } catch * {
            ()
        }
    }
    return
        templates:apply($content, $lookup, (), $config)
};

(: 
 : publish data to project
 :)
declare 
    %rest:POST
    %rest:path("/publish/{$project}/process/")
    %rest:form-param("sid", "{$sid}", "")
    %rest:form-param("uri", "{$uri}", "")
    %rest:form-param("target", "{$target}", "data")
    %rest:form-param("user", "{$user}", "")
    %rest:form-param("password", "{$password}", "")

(:    %rest:produces("text/plain"):)

function tgconnect:publish( $uri as xs:string, 
                            $sid as xs:string, 
                            $target as xs:string, 
                            $user as xs:string, 
                            $password as xs:string,
                            $project as xs:string) {
                                
    let $config := tgclient:getConfig($project)
    
    let $targetPath :=
        if($target eq "website") then
            "/sade-projects/" || $project || $tgconnect:websiteDataPath
        else
            "/sade-projects/" || $project || $tgconnect:editionDataPath
    
    return if (xmldb:login($targetPath, $user, $password )) then
        
        let $tgcrudUrl := tgclient:config-param-value($config, "textgrid.tgcrud")

        (: work around strange bug with publish from public repo
           where a .0 to much is added.
           TODO: research
        :)
        let $tguri := if(ends-with($uri, ".0.0")) then
                substring-before($uri, ".") || ".0"
            else
                $uri

        let $mp := tgclient:getMeta($tguri, $sid, $tgcrudUrl)

        let $rdfstoreUrl := 
            if ($mp//tgmd:generated/tgmd:availability = "public") then 
                tgclient:config-param-value($config, "textgrid.public-triplestore")
            else 
                tgclient:config-param-value($config, "textgrid.nonpublic-triplestore")

        let $egal := tgconnect:createEntryPoint($tguri, concat($targetPath, "/meta")),
            $oks :=
                for $pubUri in tgclient:getAggregatedUris($tguri, $rdfstoreUrl)
                    let $meta := tgclient:getMeta($pubUri, $sid, $tgcrudUrl),
                        $targetUri := concat(tgclient:remove-prefix($meta//tgmd:textgridUri/text()), ".xml"),
                        $egal := xmldb:store(concat($targetPath, "/meta"), $targetUri, $meta, "text/xml")
                    let $egal := 
                        if ($meta//tgmd:format[not(contains(base-uri(), $uri))]/text() eq "text/xml") then
                            let $data := tgclient:getData($pubUri, $sid, $tgcrudUrl)
                            return xmldb:store(concat($targetPath, "/data"), $targetUri, $data, "text/xml")
                        else if($meta//tgmd:format/text() eq "text/linkeditorlinkedfile") then
                            let $data := tgclient:getData($pubUri, $sid, $tgcrudUrl)
                            return xmldb:store(concat($targetPath, "/tile"), $targetUri, $data, "text/xml")
                        else if(starts-with($meta//tgmd:format/text(), "image")) then ' '
                        else if (contains($meta//tgmd:format[not(contains(base-uri(), $tguri))]/text(), "tg.aggregation")) then
                            let $data := tgclient:getData($pubUri, $sid, $tgcrudUrl)
                            return xmldb:store(concat($targetPath, "/agg"), $targetUri, $data, "text/xml")
                        else
                            ()
                return "ok"
        return <ok>published: {$uri} to {$targetPath || tgconnect:buildmenu($project, $targetPath)}</ok>
    else
        <error>error authenticating for {$user} - {$password} on {$targetPath}</error>
(:        tgconnect:error401:)
};

(: does not work with restxq-xquery impl :)
(: declare function tgconnect:error401() {
  <rest:response>
    <http:response status="401" message="wrong user or password">
      <http:header name="Content-Language" value="en"/>
      <http:header name="Content-Type" value="text/html; charset=utf-8"/>
    </http:response>
  </rest:response>
};:)

declare function tgconnect:createEntryPoint($uri as xs:string, $path as xs:string) {
    let $epUri := concat(tgclient:remove-prefix($uri), ".ep.xml")
    return xmldb:store($path, $epUri, <entrypoint>{$uri}</entrypoint>, "text/xml") 
};

declare function tgconnect:buildmenu($project as xs:string, $targetPath as xs:string) {
let 
    $egal :=  xmldb:store('/sade-projects/' || $project, '/navigation-tg.xml', <navigation/>, "text/xml"),
    $metacoll := collection($targetPath || '/meta'),
    $egal := for $ep in $metacoll//entrypoint/text()
            return
                update
                insert tgmenu:entry(string($ep), $metacoll)
                into doc('/sade-projects/' || $project || '/navigation-tg.xml')/navigation,
    
    $step1 :=
        for $i in doc('/sade-projects/' || $project || '/navigation-tg.xml')//agg
        where not($i/*)
        return
            update
                insert
                    tgmenu:getsubeps($metacoll, $i/@uri)
                into
                    doc('/sade-projects/' || $project || '/navigation-tg.xml')//agg[@uri = $i/@uri],
            
    $step2 :=
        for $i in doc('/sade-projects/' || $project || '/navigation-tg.xml')//agg
        where not($i/*)
        return
            update
                insert
                    tgmenu:getsubeps($metacoll, $i/@uri)
                into
                    doc('/sade-projects/' || $project || '/navigation-tg.xml')//agg[@uri = $i/@uri],
    $step3 :=
        for $i in doc('/sade-projects/' || $project || '/navigation-tg.xml')//agg
        where not($i/*)
        return
            update
                insert
                    tgmenu:getsubeps($metacoll, $i/@uri)
                into
                    doc('/sade-projects/' || $project || '/navigation-tg.xml')//agg[@uri = $i/@uri],
    $step4 :=
        for $i in doc('/sade-projects/' || $project || '/navigation-tg.xml')//agg
        where not($i/*)
        return
            update
                insert
                    tgmenu:getsubeps($metacoll, $i/@uri)
                into
                    doc('/sade-projects/' || $project || '/navigation-tg.xml')//agg[@uri = $i/@uri],
    $step5 :=
        for $i in doc('/sade-projects/' || $project || '/navigation-tg.xml')//agg
        where not($i/*)
        return
        update
            insert
                tgmenu:getsubeps($metacoll, $i/@uri)
            into
                doc('/sade-projects/' || $project || '/navigation-tg.xml')//agg[@uri = $i/@uri],
    $last := transform:transform(doc('/sade-projects/' || $project || '/navigation-tg.xml'), doc('/sade-projects/' || $project || '/xslt/tg-menu.xslt'), ()),
    $egal := xmldb:store('/sade-projects/' || $project, '/navigation-bootstrap3.xml', $last, "text/xml")
return "ok"
};
