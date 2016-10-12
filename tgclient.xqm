xquery version "3.0";

module namespace tgclient="http://textgrid.info/namespaces/xquery/tgclient";
import module namespace config="http://exist-db.org/xquery/apps/config" at "../SADE/core/config.xqm";

declare namespace sparql-results="http://www.w3.org/2005/sparql-results#";
declare namespace http="http://expath.org/ns/http-client"; 
declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace tgmd="http://textgrid.info/namespaces/metadata/core/2010";

(:declare namespace config="http://bla"; :)

(: 
Function to get the result for a query as evaluated on a given sesame triple-store

@param $query sparql query to be evaluated
@param $repository repository to evaluate query against
@param $openrdf-sesame-uri URI locating the openrdf-sesame REST interface
@return The response body of the query, that is a <sparql-results:sparql> element
:)
declare function tgclient:getConfig($project as xs:string) {
    map { "config" := config:config($project) }
(:    map{}:)
};

declare function tgclient:config-param-value($config as map(*), $key as xs:string) as xs:string {
    config:param-value($config, $key)
(:"hu":)
};

declare function tgclient:sparql($query as xs:string, $openrdf-sesame-uri as xs:string) as node() {

    let $urlEncQuery := encode-for-uri($query)
    let $reqUrl := string-join(($openrdf-sesame-uri, "?query=", $urlEncQuery),"")
    
    let $req := <http:request href="{$reqUrl}" method="get">
                    <http:header name="Accept" value="text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"/>
                    <http:header name="Connection" value="close"/>
                </http:request>
    return http:send-request($req)[2]
};


declare function tgclient:getMeta($id as xs:string, $sid as xs:string, $tgcrud-url as xs:string) as node() {
    
    let $reqUrl := xs:anyURI(string-join(($tgcrud-url,"/",$id,"/metadata?sessionId=", $sid),""))
    let $req := <http:request href="{$reqUrl}" method="get">
                    <http:header name="Connection" value="close"/>
                </http:request>
    return http:send-request($req)[2]
    
};

declare function tgclient:getData($id as xs:string, $sid as xs:string, $tgcrud-url as xs:string)  {
    
    let $reqUrl := string-join(($tgcrud-url,"/",$id,"/data?sessionId=", $sid),"")
    let $req := <http:request href="{$reqUrl}" method="get">
                    <http:header name="Connection" value="close"/>
                </http:request>
    return http:send-request($req)[2]

};

declare function tgclient:getAggregatedUris($tguri as xs:string, $rdfstore as xs:string) as item()* {
    let $query := concat("
                    PREFIX ore:<http://www.openarchives.org/ore/terms/>
                    PREFIX tg:<http://textgrid.info/relation-ns#>
                    
                    SELECT ?s WHERE {
                        <",$tguri,"> (ore:aggregates/tg:isBaseUriOf|ore:aggregates)* ?s.
                    }
                    ")
    
    let $uris := tgclient:sparql($query, $rdfstore)
    let $maxRev :=
 for $u in distinct-values( $uris//sparql-results:uri/substring-before(.,'.'))
        where $u != ''
        return $u || '.' || max( ( $uris//sparql-results:uri[starts-with(., $u)][contains(. , '.')]/number(substring-after(., '.'))) )    let $uris := $uris//sparql-results:uri/string()
    return $uris
    (: use $maxRev instead of $uris to grap only latest revisions! :)
};

declare function tgclient:remove-prefix($tguri as xs:string) as xs:string {
    let $hasPrefix := contains($tguri, ":")
    return
        if ($hasPrefix) then
            let $components := tokenize($tguri, ":")
            let $physicalId := $components[2]
            return $physicalId
        else
            $tguri
};

(: 
 : TODO: authzinstance and reqUrl need to be incoming parameters 
 :)
declare function tgclient:getSid($webauthUrl as xs:string, $authZinstance as xs:string, $user as xs:string, $password as xs:string) as xs:string* {
    let $pw := if(contains($password, '&amp;')) then replace($password, '&amp;', '%26') else $password
    let $req := <http:request href="{$webauthUrl}" method="post">
                    <http:header name="Connection" value="close"/>
                    <http:body media-type="application/x-www-form-urlencoded">loginname={$user}&amp;password={$password}&amp;authZinstance={$authZinstance}</http:body>
                </http:request>
    return http:send-request($req)//html:meta[@name="rbac_sessionid"]/@content

};

(: TODO:
    -  secure cache 
    - if getting sid fails, don't write sid.xml
 :)
declare function tgclient:getSidCached($config as map(*)) as xs:string* {
    
    let $tguser := config:param-value($config, "textgrid.user")
    let $tgpass := config:param-value($config, "textgrid.password")
    let $cache-path := config:param-value($config, "textgrid.sidcachepath")
    let $existuser := config:param-value($config, "textgrid.sidcachepath.user")
    let $existpassword := config:param-value($config, "textgrid.sidcachepath.password")
    let $webauth := config:param-value($config, "textgrid.webauth")
    let $authZinstance := config:param-value($config, "textgrid.authZinstance")
    
    let $status := xmldb:login($cache-path, $existuser, $existpassword)
    
    (: if cached sid older 2 days get new sid :)
    return if( xmldb:last-modified($cache-path, "sid.xml") > (current-dateTime() - xs:dayTimeDuration("P2D")) and doc($cache-path || "/sid.xml")//sid/@user = $tguser ) then
        doc($cache-path || "/sid.xml")//sid/text()
    else
        let $sid := tgclient:getSid($webauth, $authZinstance, $tguser, $tgpass)
        let $login := xmldb:login($cache-path, config:param-value($config, "sade.user"), config:param-value($config, "sade.password"))
        let $status := xmldb:store($cache-path, 'sid.xml', <sid user="{$tguser}">{$sid}</sid>)
        let $chmod := sm:chmod(xs:anyURI($cache-path || "sid.xml"), 'rw-------')
        return $sid
    
};

(: 
 : TextGrid CRUD
 : Store nodes in the TextGrid Repository
 : https://textgridlab.org/doc/services/submodules/tg-crud/docs/index.html#create
 :  :)
declare function tgclient:createData($config as map(*), $title, $format, $data) as node() {
let $sessionId := tgclient:getSid($config)
let $projectId := config:param-value($config, "textgrid.projectId")

let $url := $tgcrudURL || "?sessionId=" || $sessionId || "&amp;projectId=" || $projectId

let $objectMetadata :=    <ns3:tgObjectMetadata
                            xmlns:ns3="http://textgrid.info/namespaces/metadata/core/2010"
                            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                            xsi:schemaLocation="http://textgrid.info/namespaces/metadata/core/2010
                            http://textgridlab.org/schema/textgrid-metadata_2010.xsd">
                                  <ns3:object>
                                     <ns3:generic>
                                        <ns3:provided>
                                           <ns3:title>{$title}</ns3:title>
                                           <ns3:format>{$format}</ns3:format>
                                        </ns3:provided>
                                     </ns3:generic>
                                     <ns3:item />
                                  </ns3:object>
      </ns3:tgObjectMetadata>

let $objectData := $data

let $request :=
    <http:request method="POST" href="{$url}" http-version="1.0">
        <http:multipart media-type="multipart/form-data" boundary="xYzBoundaryzYx">

            <http:header name="Content-Disposition" value='form-data; name="tgObjectMetadata";'/>
            <http:header name="Content-Type" value="text/xml"/>
            <http:body media-type="application/xml">{$objectMetadata}</http:body>

            <http:header name="Content-Disposition" value='form-data; name="tgObjectData";'/>
            <http:header name="Content-Type" value="application/octet-stream"/>
            <http:body media-type="{$format}">{$objectData}</http:body>

        </http:multipart> 
    </http:request>
let $response := http:send-request($request)

return
    if( $response/@status = "200" ) then $response//tgmd:MetadataContainerType
	else <error> <status>{$response/@status}</status> <message>{$response/@message}</message> </error>
