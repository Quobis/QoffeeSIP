##
# Copyright (C) Quobis
# Project site: https://github.com/Quobis/QoffeeSIP
# 
# Licensed under GNU-LGPL-3.0-or-later (http://www.gnu.org/licenses/lgpl-3.0.html)
##


# Class to manage UI.
class UI extends Spine.Controller
	events:
		"submit form": "submitForm"
		"submit #form-register": "registerSubmit"
		"submit #form-call": "callSubmit"
		"click #answer": "answerClick"
		"click #cancel": "hangupClick"
		"click #hangup-established": "hangupClick"
		"click #hangup": "hangupClick"
		"click #fullscreen": "fullscreen"
		"click .toggleMuteAudio": "toggleMuteAudio"
		"click .toggleMuteVideo": "toggleMuteVideo"

	elements:
		"#form-register": "$formRegister"
		"#form-call": "formCall"
		"#form-incoming-call": "$formincomingCall"
		"#form-established-call": "$formEstablishedCall"
		"#answer": "$answerButton"
		"#hangup": "$hangupButton"
		"#flags-media": "$flagsMedia"
		"#notifications": "$notifications"
		"video": "$videos"
		"#flag-audio": "$flagAudio"
		"#flag-video": "$flagVideo"
		"#register": "$registerButton"
		"#call": "$callButton"
		"#chat": "$chat"
		".messages": "$messages"
		"#timer": "$timer"
		"#status": "$status"
		".slide": "$slides"
		".media": "$media"

	templates:
		message: (message, type) ->
			console.log message
			"""
			<p class="chat-m">
				<span class="label #{type}">#{message.from} says</span> #{message.content}
			</p>
			"""

	constructor: () ->
		super
		# Object to store data bout register.
		@register = {}

	# Converts urls inside a text in html limks.
	linkify: (inputText) ->
		# URLs starting with http://, https://, or ftp://
		replacePattern1 = /(\b(https?|ftp):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/gim
		replacedText = inputText.replace replacePattern1, '<a href="$1" target="_blank">$1</a>'

		# URLs starting with www. (without // before it, or it'd re-link the ones done above)
		replacePattern2 = /(^|[^\/])(www\.[\S]+(\b|$))/gim
		replacedText = replacedText.replace replacePattern2, '$1<a href="http://$2" target="_blank">$2</a>'

		# # Change email addresses to mailto:: links
		replacePattern3 = /(\w+@[a-zA-Z_]+?\.[a-zA-Z]{2,6})/gim
		replacedText = replacedText.replace replacePattern3, '<a href="mailto:$1">$1</a>'

		return replacedText

	emoticonify: (inputText) ->
		substitutions =
			angry:		/X\-?\(/gim				# :(
			blink:		/;-?\)/gim				# ;)
			blush:		/:-?\$/gim				# :$
			cheerful:	/(:-?D)|(\^\^)/gim		# :D ^^
			confused:	/:-?S/gim				# :S
			cry:		/;-?\(/gim				# ;)
			happy: 		/:-?\)/gim				# :)
			laugh:		/X-?D/gim				# XD
			sad: 		/:-?\(/gim				# :(
			serious:	/:-?\|/gim				# :|
			sunglasses: /B-?\)/gim				# B)
			surprised:	/:-?O/gim				# :O
			tongue: 	/:-?P/gim				# :P

		replacedText = inputText
		for key, pattern of substitutions
			replacedText = replacedText.replace pattern, "<img class='emoticon' src='img/emoticons/#{key}.svg'/>"

		console.log replacedText
		replacedText


	# Put a chat message in the chat and scroll to the bottom.
	# TODO: We should take care of HTML content in the message, for example a script tag.
	renderInstantMessage: (message) =>
		message.content = @linkify message.content
		message.content = @emoticonify message.content
		# If sending message...
		if message.from is @register.ext
			contact = message.to
			type = "label-success"
		# If receive message...
		else
			contact = message.from
			type = "label-info"

		@$messages
			.append(@templates.message message, type)
			.animate {scrollTop: @$messages[0].scrollHeight}, 300;

	notify: (msg, type = "success") ->
		# Avoid [Object object] notifications.
		return if typeof(msg) isnt "string"
		args =
			message: {text: msg}
			type: type
		@$notifications.notify(args).show()

	infoManager: (info, data) =>
		@notify info

	warningManager: (warn, message) =>
		@notify warn, "warning"

	warningManager: (error, message) =>
		@notify error, "danger"

	fullscreen: () =>
		$("#remote").fullscreen(true)

	toggleMuteAudio: () =>
		console.log "[MEDIA] toggleMuteAudio"
		@api.toggleMuteAudio()

	toggleMuteVideo: () =>
		console.log "[MEDIA] toggleMuteVideo"
		@api.toggleMuteVideo()

	# Prevent page reloading on form submits.
	submitForm: (e) =>
		e.preventDefault()
		false
	   
	registerSubmit: (e) =>
		[@register.ext, @register.domain] = $("#user-reg").val().split "@"
		# Trick to speed up tests.
		@register.pass = $("#pass-reg").val() or @register.ext
		server         = $("#server-reg").val()
		@server        = {}
		
		serverRE = ///
			(wss?)://
			(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})	# IP
			(\:(\d{2,5}))?							# Port
			((/\w+)*)								# Path
			///

		line = serverRE.exec server
		if line?
			@server.transport = line[1]
			@server.ip        = line[2]
			@server.port      = line[4]
			@server.path      = line[5] or ""
		else
			@server.ip   = "212.145.159.109"
			@server.port = "80"
			@server.path = ""
			@server.transport = "ws"

		onopen = =>
			@api.on "new-state", @newState
			@api.on "info", @infoManager
			@api.on "warning", @warningManager
			@api.on "error", @errorManager
			@api.on "instant-message", @renderInstantMessage
			@api.register @register.ext, @register.pass, @register.domain
			@$registerButton.addClass "disabled"

		# Both video and audio on, let to true what you need
		@api = new API {server: @server, mediaElements: @mediaElements, onopen: onopen, mediaConstraints: {audio: true, video: true}}
		# Non-compliant parameters needed to work with Asterisk, at this moment only audio is supported (still problems)
		#@api = new API {server: @server, hackViaTCP: false, hackIpContact: true, @mediaElements, onopen: onopen, mediaConstraints: {audio: true, video: false}}
		false

	callSubmit: (e) =>
		# Get extension and domain to call.
		[@ext2, @domain2] = $("#ext-call").val().split "@"
		@api.call @ext2, @domain2
		@$callButton.addClass "disabled"
		false

	establishedCallSubmit: (e) =>
		@hangupClick e
		false

	answerClick: (e) =>
		e.preventDefault()
		@$answerButton.addClass "disabled"
		@$hangupButton.addClass "disabled"
		@stopSounds()
		@api.answer()
		false

	hangupClick: (e) =>
		e.preventDefault()
		@$answerButton.addClass "disabled"
		@$hangupButton.addClass "disabled"
		@api.hangup @ext2
		false

	stopSounds: () ->
		$("#sound-ringing").get(0).pause()
		$("#sound-calling").get(0).pause()

	nextForm: (id) =>
		$(".disabled").removeClass "disabled"
		@$slides.hide()
		$("##{id}").fadeIn 200, =>
			$("##{id} > input:first").focus()

	startTimer: () =>
		seconds = minutes = hours = 0
		time = =>
			seconds += 1
			minutes += seconds is 60
			seconds %= 60
			hours += minutes is 60
			minutes %= 60
			s = seconds + ""
			s = "0" + s if s.length is 1
			m = minutes + ""
			m = "0" + m if m.length is 1
			h = hours + ""
			h = "0" +  h if h.length is 1
			@$timer.text("#{h}:#{m}:#{s}") 
		@timer = setInterval time, 1000

	stopTimer: () => clearInterval(@timer) if @timer?

	updateStatus: (msg) => @$status.text msg

	newState: (@state, data) =>
		console.log "[STATE] #{@state}"
		switch @state
			when 3
				# Unregister on closing.
				$(window).bind "beforeunload", => 
					@api.unregister()
					return
				@stopTimer()
				@$media.css opacity: 1
				if 7 <= @previousState <= 9
					$("#media-local").css {top: "-196px", width: "100%", opacity: 1, display: "block", zIndex: "1000"}
				$("#media-remote").css {opacity: 0}
				# Remove .message to clear all previous messages.
				@$messages.children().remove()
				@$chat.hide()

				@stopSounds()
				@updateStatus "Registered"
				@nextForm "form-call"
				$("#register-info")
					.html("<p>Your extension number is <strong>#{@register.ext}</strong>, share this URL to a friend and tell him to call you. If you want to connect to our demo webcam, just dial extension 1234.</p>")
					.fadeIn(200)
				$("#local-legend").text "Local extension is #{@register.ext}"

			when 5
				@updateStatus "Calling #{@ext2}"
				@nextForm "form-calling"
				document.getElementById("sound-calling").play()
			
			when 6
				@ext2 = data.ext
				@updateStatus "Incoming call from #{@ext2}"
				@nextForm("form-incoming-call")
				document.getElementById("sound-ringing").play()
				if window.autoanswering
					setTimeout (-> $("#answer").click()), 1000

			when 7, 8
				console.log @api.sipStack.rtc.pc
				console.log @api.sipStack.rtc.mediaConstraints
				$("#media-local").css {top: "0", width: "25%", opacity: 0.8}
				$("#media-remote").css {opacity: 1}

				@updateStatus "Call established with #{@ext2}"
				$("#remote-legend").text "Remote extension is #{@ext2}"
				@stopSounds()
				@startTimer()
				@nextForm "form-established-call"
				if window.autoanswering
					setTimeout (-> $("#hangup-established").click()), 15000
				@$chat.show()
				@$chat.find("form").submit =>
					message =
						from: @register.ext
						to: @ext2
						content: $("#chat").find("input:first").val()
					@$chat.find("input:first").val ""
					@api.chat @ext2, message.content
					@renderInstantMessage message
				@previousState = @state
			
			when 9
				@updateStatus "Hanging up"
				@stopTimer()

			when 10
				@updateStatus "Cancelling"

window.UI = UI