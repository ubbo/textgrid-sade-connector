xquery version "3.0";
module namespace digilib="http://textgrid.info/namespaces/xquery/digilib";
import module namespace tgclient="http://textgrid.info/namespaces/xquery/tgclient" at "/db/apps/textgrid-connect/tgclient.xqm";
import module namespace config="http://exist-db.org/xquery/apps/config" at "../SADE/core/config.xqm";
import module namespace datetime = "http://exist-db.org/xquery/datetime" at "java:org.exist.xquery.modules.datetime.DateTimeModule";

declare namespace http="http://expath.org/ns/http-client"; 
declare namespace tg="http://textgrid.info/namespaces/metadata/core/2010";


declare 
    %rest:GET
    %rest:path("/digilib/{$project}/{$id}")
    %rest:header-param("if-modified-since", "{$if-modified-since}")
function digilib:proxy($project as xs:string, $id as xs:string*, $if-modified-since as xs:string*) {
    
    let $query := request:get-query-string()
    
    let $config := map { "config" := config:config($project) }
    let $data-dir := config:param-value($config, 'data-dir')

    (: check if 301 could be send, comparing textgrid-metadata with if-modified-since :)
    (: this only works if local LANG is en :)
(:
    return if (
        (fn:string-length($if-modified-since) > 0) and
        (datetime:parse-dateTime( $if-modified-since, 'EEE, d MMM yyyy HH:mm:ss Z' ) <=
            xs:dateTime(collection($data-dir)//*[starts-with(tg:textgridUri/text(), $id)]/tg:lastModified/text()))
    ) then
        let $tmp := response:set-status-code( 304 )
        return <ok/>
    else
:)

        let $sid := tgclient:getSidCached($config)
        let $reqUrl := config:param-value($config, "textgrid.digilib") || "/"
    
        let $req := <http:request href="{concat($reqUrl,$id,";sid=",$sid,"?",$query)}" method="get">
                        <http:header name="Connection" value="close"/>
                    </http:request>

        let $result := http:send-request($req)

        let $mime := xs:string($result[1]//http:header[@name="content-type"]/@value)
        let $last-modified := xs:string($result[1]//http:header[@name="last-modified"]/@value)
        let $cache-control := xs:string($result[1]//http:header[@name="cache-control"]/@value)
        let $tmp := response:set-header("Last-Modified", $last-modified)
        let $tmp := response:set-header("Cache-Control", $cache-control)

        return
            response:stream-binary($result[2], $mime)

};

