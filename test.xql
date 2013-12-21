xquery version "3.0";

import module namespace tgconnect="http://textgrid.info/namespaces/xquery/tgconnect" at "tg-connect.xql"; 
import module namespace tgclient="http://textgrid.info/namespaces/xquery/tgclient" at "tgclient.xqm";
import module namespace http = "http://expath.org/ns/http-client";

(:  :let $user := "admin"
let $password := ""
let $targetPath := "/sade-projects/default/data"

return
xmldb:login($targetPath, $user, $password ):)

let $tguri := "textgrid:20btc.0"

let $sid := ""
let $tgcrud-url := xs:anyURI($tgconnect:nonpublicCrud)

return
(:tgconnect:publish($tguri,$sid,"data","sade","test"):)

tgclient:getAggregatedUris($tguri , $tgconnect:nonpublicRdf)

(:  :tgclient:getData("textgrid:20bt6", $sid, xs:anyURI($tgconnect:nonpublicCrud))[2] :)
(:let $id := "textgrid:20bt6":)
(::)
(:let $requrl :=   string-join(($tgcrud-url,"/",$id,"/data?sessionId=", $sid))  :)
(:let $requrl := "http://localhost:8080/exist/rest/sade-projects/default/data/browse_abw.xml":)
 


(:    let $response := httpclient:get(xs:anyURI($requrl), false(), ()):)
(:    return $response/httpclient:body/node():)


(:     let $req := <http:request href="{$requrl}":)
(:                            method="get"/>:)
(:            let $data := http:send-request($req)[2]:)
(:    return:)
(:        xmldb:store("/sade-projects/default/data", "test2.xml", $data, "text/xml"):)

(:    let $query := concat(":)
(:                    PREFIX ore:<http://www.openarchives.org/ore/terms/>:)
(:                    PREFIX tg:<http://textgrid.info/relation-ns#>:)
(:                    :)
(:                    SELECT ?s WHERE {:)
(:                        <",$tguri,"> ore:aggregates* ?s.:)
(:                    }:)
(:                    "):)
(:                    :)
(:    let $urlEncQuery := encode-for-uri($query):)
(:    let $reqUrl := string-join(($tgconnect:nonpublicRdf, "?query=", $urlEncQuery),""):)
(::)
(:    let $req := <http:request href="{$reqUrl}" method="get">:)
(:                    <http:header name="Accept" value="text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"/>:)
(:                </http:request>:)
(:                        :)
(:    return http:send-request($req)[2]      :)
      
