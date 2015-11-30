var sid;
var sadeUser;
var sadePw;

$(document).ready(function(){
    
    $('#sid').change(function() {
        sid=$(this).val();
    });
    $('#user').change(function() {
        sadeUser=$(this).val();
    });
    $('#password').change(function() {
        sadePw=$(this).val();
    });

    log("init");
    $('#droptarget').bind('drop', function(evt) {
		
		// console.log(evt);
		

                log("some drop to dnd");
                var data = evt.originalEvent.dataTransfer.getData('text/html');

                console.log(data);
                /*console.log(stringToCodes(data));
                console.log(stringToBytes(data));
				        console.log('string length: ' + data.length); */
				        
				        var uri = $(data).attr('uri');
				        var title = $(data).text();
				        var type = $(data).attr('type');
				        log(uri + "|" + title + '|' +type);
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

});

function setSid(val) {
    $('#authform').hide();
	sid=val;
	log('sid set to '+sid);
}

function setAuth(user, pw) {
    $('#authform').hide();
    sadeUser = user;
    sadePw = pw;
    log('sade user set to '+user+' - '+pw);
}

function publish() {
	log('<p>starting...</p>');
	
	$('#logbox').show();
	$('#droptarget').find('li').each(function() {
		// console.log(this);
		// log($(this).attr('uri'));
		var uri = $(this).attr('uri')

        if(sadeUser === undefined) {
            sadeUser = $('#user').val();
            sadePw = $('#password').val();
            sid = $('#sid').val();
        }

		// todo: sidreq?
		var sidreq = sid ? "&sid="+sid : "";
        //var target = $("input[name='target']:checked").val();
        var target="data";
        console.log('target:' + target);
		
		$.ajax({
		    type: 'POST',
			url: 'process/',
			data: {'uri': uri,  'target': target, 'user': sadeUser, 'password': sadePw, 'sid': sid },
			cache: false, 
			success: function(xml) {
			    console.log(xml);
			    console.log($(xml).find('ok'));
			    console.log($(xml).find('error').text());
			    
			    if($(xml).find('ok').text()) {
    				log('ok: ' + $(xml).find('ok').text());
    				$('li[uri="'+uri+'"]').append(oksign());
			    } else {
			        errnote = $(xml).find('error').text();
			        log('error: ' + errnote);
			        $('li[uri="'+uri+'"]').append(errorsign(errnote));
			    }
			},
		});
	});
	
}

function oksign() {
    return '<span class="glyphicon glyphicon-ok success"/>';
}

function errorsign(text) {
    return '<span class="glyphicon glyphicon-ban-circle error" title="'+text+'" />';
}


// TODO: should be same like dnd
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
	//$('#note').hide();
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

function reset() {
	$('#droptarget').empty();
}

String.prototype.beginsWith = function (string) {
    return(this.indexOf(string) === 0);
}

function log(string) {
    $('#log').prepend(string + '<br/>');
}
function view(string) {
    $('#view').prepend(string + '<br/>');
}

