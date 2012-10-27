jQuery(document).ready(function() {

	// --- language dropdown --- //

	// turn select into dl
	createDropDown();
	
	var $dropTrigger = $(".langdrop dt a");
	var $languageList = $(".langdrop dd ul");
	
	// open and close list when button is clicked
	$dropTrigger.toggle(function() {
		$languageList.slideDown(200);
		$dropTrigger.addClass("active");
	}, function() {
		$languageList.slideUp(200);
		$(this).removeAttr("class");
	});

	// close list when anywhere else on the screen is clicked
	$(document).bind('click', function(e) {
		var $clicked = $(e.target);
		if (! $clicked.parents().hasClass("langdrop"))
			$languageList.slideUp(200);
			$dropTrigger.removeAttr("class");
	});

	// when a language is clicked, make the selection and then hide the list
	$(".langdrop dd ul li a").click(function() {
		var clickedValue = $(this).parent().attr("class");
		var clickedTitle = $(this).find("em").html();
		$("#target dt").removeClass().addClass(clickedValue);
		$("#target dt em").html(clickedTitle);
		$languageList.hide();
		$dropTrigger.removeAttr("class");
	});
});

	// actual function to transform select to definition list
	function createDropDown(){
		var $form = $("div#lang-select form");
		$form.hide();
		var source = $("#lang");
		source.removeAttr("autocomplete");
		var selected = source.find("option:selected");
		var options = $("option", source);
		$("#lang-select").append('<dl id="target" class="langdrop"></dl>')
		$("#target").append('<dt class="' + selected.val() + '"><a href="#"><span class="flag"></span><em>' + selected.text() + '</em></a></dt>')
		$("#target").append('<dd><ul></ul></dd>')
		options.each(function(){
			$("#target dd ul").append('<li class="' + $(this).val() + '"><a href="' + $(this).attr("title") + '"><span class="flag"></span><em>' + $(this).text() + '</em></a></li>');
			});
	}
