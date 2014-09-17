xquery version "3.0";

module namespace tgclient="http://textgrid.info/namespaces/xquery/tgclient";
import module namespace config="http://exist-db.org/xquery/apps/config" at "../SADE/core/config.xqm";

declare namespace sparql-results="http://www.w3.org/2005/sparql-results#";
declare namespace http="http://expath.org/ns/http-client"; 
declare namespace html="http://www.w3.org/1999/xhtml";

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
    return $uris//sparql-results:uri/text()
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
    return if( xmldb:created($cache-path, "sid.xml") > (current-dateTime() - xs:dayTimeDuration("P2D")) ) then
        doc($cache-path || "/sid.xml")//sid/text()
    else
        let $sid := tgclient:getSid($webauth, $authZinstance, $tguser, $tgpass)
        let $status := xmldb:store($cache-path, 'sid.xml', <sid user="{$tguser}">{$sid}</sid>)
        return $sid
    
};
