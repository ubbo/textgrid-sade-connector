xquery version "3.0";

module namespace tgconnect="http://textgrid.info/namespaces/xquery/tgconnect"; 

import module namespace tgclient="http://textgrid.info/namespaces/xquery/tgclient" at "tgclient.xqm";

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace http="http://expath.org/ns/http-client"; 
declare namespace tgmd="http://textgrid.info/namespaces/metadata/core/2010";

declare variable $tgconnect:publicRdf := "http://textgridlab.org/1.0/triplestore/textgrid-public";
declare variable $tgconnect:nonpublicRdf := "http://textgridlab.org/1.0/triplestore/textgrid";
declare variable $tgconnect:publicCrud := "http://textgridlab.org/1.0/tgcrud-public/rest";
declare variable $tgconnect:nonpublicCrud := "http://textgridlab.org/1.0/tgcrud/rest";
declare variable $tgconnect:websiteDataPath := "/sade-projects/default/data/website";
declare variable $tgconnect:editionDataPath := "/sade-projects/default/data/xml";

declare 
    %rest:GET
    %rest:path("/publish")
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
                            $password as xs:string) {
    
    let $targetPath :=
        if($target eq "website") then
            $tgconnect:websiteDataPath
        else
            $tgconnect:editionDataPath
    
    return if (xmldb:login($targetPath, $user, $password )) then
        let $rdfstoreUrl := 
            if ($sid) then 
                $tgconnect:nonpublicRdf
            else 
                $tgconnect:publicRdf
        
        let $tgcrudUrl := 
            if ($sid) then 
                $tgconnect:nonpublicCrud
            else 
                $tgconnect:publicCrud
        
        let $tguri := $uri
        
        let $egal := tgconnect:createEntryPoint($uri, concat($targetPath, "/meta"))
         
        let $oks := for $pubUri in tgclient:getAggregatedUris($tguri, $rdfstoreUrl)
            let $meta := tgclient:getMeta($pubUri, $sid, $tgcrudUrl)
            let $targetUri := concat(tgclient:remove-prefix($meta//tgmd:textgridUri/text()), ".xml")
            let $egal := xmldb:store(concat($targetPath, "/meta"), $targetUri, $meta, "text/xml")
            
            let $egal := 
                if ($meta//tgmd:format/text() eq "text/xml") then
                    let $data := tgclient:getData($pubUri, $sid, $tgcrudUrl)
                    return xmldb:store(concat($targetPath, "/data"), $targetUri, $data, "text/xml")
                else 
                    ()
                    
            return "ok"
            
        return <ok>published: {$uri} to {$target}</ok>
    else
        <error>error authenticating for {$user} - {$password} on {$targetPath }</error>
(:        tgconnect:error401:)
};

(: does not work with restxq-xquery impl, wait for restxq-java with tomcat :)
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


declare 
    %rest:GET
    %rest:path("/hello")
    %rest:form-param("sid", "{$sid}", "")
    %rest:form-param("uri", "{$uri}", "")
function tgconnect:hello($sid as xs:string, $uri as xs:string) {
    let $bla := if ($sid) then
        "ja"
        else
            "nein"
    return        
    <huhu>huhu - {$bla} - {$sid} - {$uri} </huhu>
};

declare 
    %rest:GET
    %rest:path("/hello/{$id}")
function tgconnect:helloi($id as xs:string*) {
    <huhu>huhu - {$id}</huhu>
};

