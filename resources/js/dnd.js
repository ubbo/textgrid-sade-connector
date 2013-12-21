var sid;

function setSid(val) {
	sid=val;
}

function publish() {
	$('#log').append('<p>starting...</p>');
	
	$('#logbox').show();
	$('#droptarget').find('li').each(function() {
		//console.log(this);
		//$('#log').append($(this).attr('uri'));
		var uri = $(this).attr('uri')

		var sidreq = sid ? "&sid="+sid : "";
		
		//$('#log').append('try with url: publish?uri='+uri+sidreq+ '<br/>');
		
		$.ajax({
			url: 'publish?uri='+uri+sidreq,
			cache: false, 
			success: function(xml) {
				$('#log').append('published ' + uri + '<br/>');
			},
		});
	});
	
}

function reset() {
	$('#droptarget').empty();
}

String.prototype.beginsWith = function (string) {
    return(this.indexOf(string) === 0);
};

function addTGObject(uri, title, contentType) {
	
	var shortUri = uri;
	if(uri.beginsWith('textgrid:')) {
		var shortUri = uri.substring(9);
	} 
	
	/* if element id already there, do not add again, blink instead */

	if($('#'+shortUri).length > 0) {
			/* jquery ui
			$('#'+shortUri).effect("highlight", {}, 1000); */
			
			$('#'+shortUri).addClass('blink');
			setTimeout(function() { $('#'+shortUri).removeClass('blink'); }, 800);
			return;
	}
	
	
	var removeButton = '<img style="width:12px; height:12px;" src="resources/img/remove_grey.gif" alt="remove" onclick="$(this).parent().remove();" onmouseover="this.src=\'resources/img/remove.gif\'" onmouseout="this.src=\'resources/img/remove_grey.gif\'"/>';
	var mimeClass=getMimeClass(contentType);
	$('#note').hide();
	$('#droptarget').append('<li title="URI: '+uri+' \nContent-Type: '+contentType+'" id="'+shortUri+'" uri="'+uri+'" class="mime '+mimeClass+'">'+removeButton + '&nbsp;' + title+' </li>');
}

function getMimeClass(contentType) {

	if(contentType.beginsWith('text/tg.collection+tg.aggregation')) {
		return 'mime_collection';
	} else if (contentType.beginsWith('text/tg.edition+tg.aggregation')) {
		return 'mime_edition';
	} else if(contentType.indexOf('tg.aggregation') != -1) {
		return 'mime_aggregation';		
	} else if (contentType.beginsWith('text/tg.work+xml')) {
		return 'mime_work';	
	} else if (contentType.beginsWith('text/xml')) {
		return 'mime_xml';
	} else if (contentType.beginsWith('text/linkeditorlinkedfile')) {
		return 'mime_tble';		
	} else if (contentType.beginsWith('image')) {
		return 'mime_image';
	} else {
		return 'mime_unknown';
	}
}

function stringToCodes(string) {
 var codes = '';

 for(i=0; i<=string.length; i++) {
   codes += '['+string.charCodeAt(i)+']';
 }
 return codes;
}

function stringToBytes ( str ) {
  var ch, st, re = [];
  for (var i = 0; i < str.length; i++ ) {
    ch = str.charCodeAt(i);  // get char 
    st = [];                 // set up "stack"
    do {
      st.push( ch & 0xFF );  // push byte to stack
      ch = ch >> 8;          // shift value down by 1 byte
    }  
    while ( ch );
    // add stack contents to result
    // done because chars have "wrong" endianness
    re = re.concat( st.reverse() );
  }
  // return an array of bytes
  return re;
}


$(document).ready(function(){

    // console.log("init");
    $('#droptarget').bind('drop', function(evt) {
		
		// console.log(evt);
		

                //$('#log').append("some drop to dnd");
                var data = evt.originalEvent.dataTransfer.getData('text/html');

                console.log(data);
                /*console.log(stringToCodes(data));
                console.log(stringToBytes(data));
				        console.log('string length: ' + data.length); */
				        
				        var uri = $(data).attr('uri');
				        var title = $(data).text();
				        var type = $(data).attr('type');
				        console.log(uri + "|" + title + '|' +type);
                //$(this).append(data)
                addTGObject(uri, title, type);
				        $(this).removeClass('dragover');
				      $('#note').hide();
        	    evt.preventDefault();
	            evt.stopPropagation();
            }).bind('dragenter', function(evt) {
                $(this).addClass('dragover');
        	    evt.preventDefault();
	            evt.stopPropagation();
            }).bind('dragover', function(evt) {
        	    evt.preventDefault();
	            evt.stopPropagation();
            }).bind('dragleave', function(evt) {
                $(this).removeClass('dragover');
        	    evt.preventDefault();
	            evt.stopPropagation();

            });
            
     $('#ajaxLoadIndicator')
    .hide()  // hide it initially
    .ajaxStart(function() {
        $(this).show();
    })
    .ajaxStop(function() {
        $(this).hide();
    });
    
    $('#help').hide();
    $('#logbox').hide();

});

var tsc=0;
function test() {
	tsc++;
	if (tsc%4 == 0)
		addTGObject('textgrid:1234', 'some object', 'unknwn')
	else if (tsc%4 == 1)
		addTGObject('textgrid:1235', 'Reise zum Mittelpunkt der Erde', 'text/xml')
	else if (tsc%4 == 2)
		addTGObject('textgrid:1236', 'the image', 'image/png')
	else 
		addTGObject('textgrid:1237', 'Eine Aggregation', 'text/tg.aggregation+xml')
	
}

