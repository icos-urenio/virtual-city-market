jQuery(document).ready(function($) {
	
	// Popovers
	$('body').on('hover', '*[rel="popover"]', function(event) {
		if (event.type === 'mouseenter') {
			$(this).popover({placement: 'top'});
			$(this).popover('show');
		}
		else {
			$(this).popover('hide');
		}
	});
	
	// Tooltips
	$("[rel=tooltip]").not('.disabled').tooltip();
	
	// Show Hide Map on Search Results
	$(".show-on-map").click(function() {
		if($.browser.safari) var animationSelector='body:not(:animated)';
            else var animationSelector='html:not(:animated)';
		$(animationSelector).animate({ scrollTop: $('a[name=top]').offset().top }, 1000, 'swing');
		var marker = getMarketById($(this).attr('href').substring(2));
		if (marker != null) {
			google.maps.event.trigger(marker, "click");
		}
		return false;
	});
	
	$(".mplace_menu a[data-toggle=collapse]").click(function() {
		var el = $(this).attr('href');
		var idx = el[el.length -1] - 1;
		var cookie = parseInt($.cookie("mplace_menu"));
		if (!cookie) cookie = 0;
		idx = Math.pow(2, idx);
		if (cookie & idx) { cookie -= idx; } else { cookie += idx; }
		$.cookie("mplace_menu", cookie);
	});
	
	// Fade opacity on images when hovered
	$("#logo, #topbar img, .social a, .coupons a, #featured-listings a img").hover(function() {
		$(this).stop().animate({opacity: "0.7"}, 'slow');
	},
	function() {
		$(this).stop().animate({opacity: "1"}, 'slow');
	});
	
	$('*[data-modal]').click(function(e) {
		e.preventDefault();
		e.stopPropagation();
		var href = $(e.target).attr('href');
		if (href.indexOf('#') == 0) {
			$(href).modal('show');
		} else {
			var title = ($(e.target).attr('data-title')) ? $(e.target).attr('data-title') : '&nbsp;';
			$.get(href + '?bare=true', function(data) {
				$('<div class="modal hide fade">' +
					'<div class="modal-header">' +
						'<a class="close" data-dismiss="modal">×</a>' +
						'<h2>' + title + '</h2>' +
					'</div>' +
					'<div class="modal-body">' + data + '</div>' +
					'<div class="modal-footer">' +
						'<button class="btn" data-dismiss="modal">' + _('Close') + '</button>' +
					'</div>' +
				  '</div>')
				.modal('show');
			});
		}
	});
	
});

jQuery(window).load(function($){ 
	// Fade status in once images load
	jQuery(".flexslider .snipe").fadeIn("slow");
	jQuery('#map-wrap').animate({opacity: "1"}, 400);
});

function getMarketById(id) {
	for (var i = 0; i < markers.length; i++) {
		if (markers[i].id == id) {
			return markers[i];
		}
	}
	return null;
}

function _(str) {
	if (lang[str]) {
		str = lang[str];
	}
	return str;
}

function rIU(param, val){
	
	var url = $.url();
	var query = url.attr('query');
	
	if (query == '' && val != '') {
		query = param + '=' + val;
	}
	else {
		query = '&' + query + '&';
		var ereg = new RegExp('&' + param + '=.*?&(?!#\d+;)', 'i');
		if (query.match(ereg)) {
			if (val == '') {
				query = query.replace(ereg, '&');
			}
			else {
				query = query.replace(ereg, '&' + param + '=' + val + '&');
			}
		}
		else if (val != '') {
			query = '&' + param + '=' + val + query;
		}
		query = query.substring(1, query.length - 1);
	}
	query = (query && query != '&') ? '?' + query : '';
	fragment = (url.attr('fragment')) ? '#' + url.attr('fragment') : '';
	
	document.location =  url.attr('base') + url.attr('path') + query + fragment;
	
	return false;
}