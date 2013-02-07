testBrowser = ->
		# browser.safari is deprecated, here a trick, NOT TESTED
		$.browser.safari = $.browser.webkit and not(/chrome/.test(navigator.userAgent.toLowerCase()));
		# We need the major version of the browser to compare
		majorVersion= parseInt($.browser.version, 10);
		supported = $.browser.chrome and majorVersion >= 23 or $.browser.mozilla and majorVersion >= 21
		if supported
			# $( "Browser: Google Chrome \(" + $.browser.version + "\)" ).append($('.footer'));
			msg = "Browser: Google Chrome (" + $.browser.version + ")"
		else if $.browser.chrome
			msg = "Browser not supported for now!: Google Chrome ( #{$.browser.version})"
		else if $.browser.safari
			msg = "Browser not supported for now!: Safari (#{$.browser.version})"
		else if $.browser.msie
			msg = "Browser not supported for now!: Internet Explorer (#{$.browser.version})"
		else if $.browser.mozilla
			msg = "Browser not supported for now!: Mozilla Firefox (#{$.browser.version})"
		else if $.browser.opera
			msg = "Browser not supported for now!: Opera (#{$.browser.version})"
		else 
			msg = "Browser not supported: (#{$.browser.version})"

		args = message: {text: msg}
		
		if not supported
			_.extend args, {type: "danger"}, {fadeOut: {enabled: false}}
		
		$('#notifications').notify(args).show()

window.testBrowser = testBrowser