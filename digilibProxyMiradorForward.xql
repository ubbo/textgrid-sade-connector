xquery version "3.0";
declare option exist:serialize "method=html5 media-type=text/html omit-xml-declaration=yes indent=yes";
<html>
    <head>
        <meta http-equiv="refresh" content="0; URL={doc('/db/sade-projects/textgrid/images.xml')//object[@type="image/jpeg"][@title = request:get-parameter('image', '')][@m2]/@m2}" />
        </head>
        <body/>
</html>