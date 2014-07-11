xquery version "3.0";
module namespace digilib="http://textgrid.info/namespaces/xquery/digilib";
import module namespace tgclient="http://textgrid.info/namespaces/xquery/tgclient" at "/db/apps/textgrid-connect/tgclient.xqm";
import module namespace config="http://exist-db.org/xquery/apps/config" at "../SADE/core/config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace http="http://expath.org/ns/http-client"; 
declare namespace html="http://www.w3.org/1999/xhtml";
(:declare namespace response="http://exist-db.org/xquery/response";:)

(: look at http://en.wikibooks.org/wiki/XQuery/Setting_HTTP_Headers :)

declare 
    %rest:GET
    %rest:path("/digilib/{$project}/{$id}")
function digilib:proxy($project as xs:string, $id as xs:string*) {
    
    let $query := request:get-query-string()
    
    let $config := map { "config" := config:config($project) }
    let $sid := tgclient:getSidCached($config)

    let $reqUrl := config:param-value($config, "textgrid.digilib") || "/"

    let $req := <http:request href="{concat($reqUrl,$id,";sid=",$sid,"?",$query)}" method="get">
                    
                </http:request>
    
    let $result := http:send-request($req)
    let $mime := xs:string($result[1]//http:header[@name="content-type"]/@value)
    return response:stream-binary($result[2], $mime) 

};


