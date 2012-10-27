jQuery(document).ready(function($) {
	
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
	query = (query) ? '?' + query : '';
	
	document.location =  url.attr('base') + url.attr('path') + query;
	
	return false;
}