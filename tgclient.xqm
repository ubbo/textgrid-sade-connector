xquery version "3.0";

module namespace tgclient="http://textgrid.info/namespaces/xquery/tgclient";
declare namespace sparql-results="http://www.w3.org/2005/sparql-results#";
declare namespace http="http://expath.org/ns/http-client"; 

(: 
Function to get the result for a query as evaluated on a given sesame triple-store

@param $query sparql query to be evaluated
@param $repository repository to evaluate query against
@param $openrdf-sesame-uri URI locating the openrdf-sesame REST interface
@return The response body of the query, that is a <sparql-results:sparql> element
:)
declare function tgclient:sparql($query as xs:string, $openrdf-sesame-uri as xs:string) as node() {

    let $urlEncQuery := encode-for-uri($query)
    let $reqUrl := string-join(($openrdf-sesame-uri, "?query=", $urlEncQuery),"")
    
    let $req := <http:request href="{$reqUrl}" method="get">
                    <http:header name="Accept" value="text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"/>
                </http:request>
                        
    return http:send-request($req)[2]
};


declare function tgclient:getMeta($id as xs:string, $sid as xs:string, $tgcrud-url as xs:string) as node() {
    
    let $reqUrl := xs:anyURI(string-join(($tgcrud-url,"/",$id,"/metadata?sessionId=", $sid),""))
    let $req := <http:request href="{$reqUrl}" method="get"/>
    return http:send-request($req)[2]
    
};

declare function tgclient:getData($id as xs:string, $sid as xs:string, $tgcrud-url as xs:string) as node()* {
    
    let $reqUrl := string-join(($tgcrud-url,"/",$id,"/data?sessionId=", $sid),"")
    let $req := <http:request href="{$reqUrl}" method="get"/>
    return http:send-request($req)[2]

};

declare function tgclient:getAggregatedUris($tguri as xs:string, $rdfstore as xs:string) as item()* {

    let $query := concat("
                    PREFIX ore:<http://www.openarchives.org/ore/terms/>
                    PREFIX tg:<http://textgrid.info/relation-ns#>
                    
                    SELECT ?s WHERE {
                        <",$tguri,"> ore:aggregates* ?s.
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
