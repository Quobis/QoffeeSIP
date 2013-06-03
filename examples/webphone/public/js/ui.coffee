##
# Copyright (C) Quobis
# Project site: https://github.com/Quobis/QoffeeSIP
# 
# Licensed under GNU-LGPL-3.0-or-later (http://www.gnu.org/licenses/lgpl-3.0.html)
##

class User extends Spine.Model
	@configure "User", "user", "password", "sipServer", "userAuthName", "turnServer", "turnCredential", "stunServer", "audioSession"
	@extend Spine.Model.Local

# Class to manage UI.
class UI extends Spine.Controller
	events:
		"submit form": "submitForm"
		"submit #form-register": "registerSubmit"
		"submit #form-call": "callSubmit"
		"click #answer": "answerClick"
		"click #answer": "answerClick"
		"click #cancel": "hangupClick"
		"click #hangup-established": "hangupClick"
		"click #hangup": "hangupClick"
		"click #fullscreen": "fullscreen"
		"click .toggleMuteAudio": "toggleMuteAudio"
		"click .toggleMuteVideo": "toggleMuteVideo"
		"click #expert": "toggleExpertMode"
		"dragenter .dropbox": "dragEnter"
		"dragleave .dropbox": "toggleActiveClass"
		"drop .dropbox": "onDrop"

	elements:
		"#status": "$status"

		"#form-register": "$formRegister"
		"#form-call": "$formCall"
		"#form-calling": "$formCalling"
		"#form-incoming-call": "$formIncomingCall"
		"#form-established-call": "$formEstablishedCall"

		"#answer": "$answerButton"
		"#hangup": "$hangupButton"

		"#notifications": "$notifications"

		"video": "$videos"
		"#media-local": "$mediaLocal"
		"#media-remote": "$mediaRemote"

		"#register": "$registerButton"
		"#call": "$callButton"
		"#chat": "$chat"
		".messages": "$messages"
		".dropbox": "$dropbox"
		"#timer": "$timer"

		".slide": "$slides"
		".media": "$media"

		"#sound-ringing": "$soundRinging"
		"#sound-calling": "$soundCalling"

		"#expert": "$expert"
		"#expert-options": "$expertOptions"


	dragEnter: (e) =>
		e.dataTransfer.effectAllowed = "copy"
		@toggleActiveClass()
		false

	toggleActiveClass: (e) ->
		# Prevent browser behaviour.
		e.stopPropagation()
		$(e.target).toggleClass "active"
		false

	onDrop: (e) =>
		# Prevent browser behaviour.
		e.stopPropagation()
		e.preventDefault()
		console.log e
		for file in e.originalEvent.dataTransfer.files
			url = URL.createObjectURL file
			message =
				from: @register.ext
				to: @ext2
				content: $("#chat > .messages").append("<img src=#{url}>")
			@renderInstantMessage message
		@toggleActiveClass(e)
		false

	templates:
		message: (message, type) ->
			console.log message
			"""
			<p class="chat-message">
				<span class="label #{type}">#{message.from} says</span> #{message.content}
			</p>
			"""

	constructor: () ->
		super
		# Object to store data bout register.
		@register = {}
		User.fetch()
		user = User.last()
		if user
			$("#user-reg").val user.user
			$("#pass-reg").val user.password
			$("#server-reg").val user.sipServer
			$("#user-auth-name").val user.userAuthName
			$("#only-audio").attr("checked", true) if user.audioSession
			$("#stun-server").val user.stunServer
			$("#turn-server").val user.turnServer
			$("#turn-server-credential").val user.turnCredential


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
			.animate {scrollTop: @$messages[0].scrollHeight}, 0

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
		$("#media-remote").fullscreen true

	toggleMuteAudio: () =>
		console.log "[MEDIA] toggleMuteAudio"
		@qs.toggleMuteAudio()

	toggleMuteVideo: () =>
		console.log "[MEDIA] toggleMuteVideo"
		@qs.toggleMuteVideo()

	# Prevent page reloading on form submits.
	submitForm: (e) =>
		e.preventDefault()
		false

	toggleExpertMode: () =>
		tmp = @$expert.text()
		@$expert.text @$expert.data "toggle-text"
		@$expert.data "toggle-text", tmp
		@$expertOptions.toggleClass "hidden"

	registerSubmit: (e) =>

		# Save user in local storage.
		User.create
			user: $("#user-reg").val()
			password: $("#pass-reg").val()
			sipServer: $("#server-reg").val()
			userAuthName: $("#user-auth-name").val()
			audioSession: $("#only-audio").is(":checked")
			stunServer: $("#stun-server").val()
			turnServer: $("#stun-server").val()
			turnCredential: $("#turn-server-credential").val()

		[@register.ext, @register.domain] = $("#user-reg").val().split "@"
		# Trick to speed up tests.
		@register.pass = $("#pass-reg").val() or @register.ext
		server         = $("#server-reg").val()
		@register.userAuthName = $("#user-auth-name").val()
		onlyAudio      = $("#only-audio").is(":checked")
		stunServer     = url: "stun:" + $("#stun-server").val()
		turnServer     = 
			url: "turn:" + $("#turn-server").val()
			credential: $("#turn-server-credential").val()

		# If there is not a STUN server defined, use the google's STUN server.
		if stunServer.url is "stun:"
			stunServer = {"url": "stun:74.125.132.127:19302"}

		serverRE = ///
			(wss?)://
			(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})	# IP
			(\:(\d{2,5}))?							# Port
			((/\w+)*)								# Path
			///

		line = serverRE.exec server
		sipServer        = {}
		if line?
			sipServer.transport = line[1]
			sipServer.ip        = line[2]
			sipServer.port      = line[4]
			sipServer.path      = line[5] or ""
		else
			sipServer.ip        = "212.145.159.109"
			sipServer.port      = "80"
			sipServer.path      = ""
			sipServer.transport = "ws"

		onopen = =>
			@qs.on "qs-ringing", @cbRinging
			@qs.on "qs-calling", @cbCalling
			@qs.on "qs-end-call", @cbEndCall
			@qs.on "qs-lost-call", @cbEndCall
			@qs.on "qs-established", @cbEstablished
			@qs.on "qs-instant-message", @renderInstantMessage
			@qs.on "qs-presence-update", @presenceUpdate
			@qs.on "qs-mediastate-update", @mediastateUpdate
			@qs.on "qs-register-success", @cbRegisterSuccess

			@qs.register @register.ext, @register.pass, @register.domain, @register.userAuthName
			@$registerButton.addClass "disabled"
			@$registerButton.addClass "disabled"

		# Both video and audio on, let to true what you need
		@qs = new QS
			server: sipServer
			turnServer: turnServer
			stunServer: stunServer
			mediaElements: @mediaElements
			onopen: onopen
			mediaConstraints: {audio: true, video: not onlyAudio}

		@qs.on "qs-localstream", =>
			@$mediaLocal.removeClass "hidden" 	 # if @api.mediaConstraints.video
		# @api.on "remotestream", => @$mediaRemote.removeClass "hidden" if @api.mediaConstraints.video


	callSubmit: (e) =>
		# Get extension and domain to call.
		[@ext2, @domain2] = $("#ext-call").val().split "@"
		@qs.call @ext2, @domain2
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
		@answer()
		false

	hangupClick: (e) =>
		e.preventDefault()
		@$answerButton.addClass "disabled"
		@$hangupButton.addClass "disabled"
		@hangup()
		false

	stopSounds: () =>
		@$soundRinging?.get(0)?.pause()
		@$soundCalling?.get(0)?.pause()
		@$soundRinging?.get(0)?.currentTime = 0
		@$soundCalling?.get(0)?.currentTime = 0

	nextForm: ($el) =>
		$(".disabled").removeClass "disabled"
		@$slides.addClass "hidden"
		$el.removeClass "hidden"
		$el.children(" > input:first").focus()

	startTimer: () =>
		s = seconds = minutes = hours = 0
		time = =>
			s += 1
			seconds = s % 60
			minutes = parseInt(s / 60) % 60
			hours   = parseInt(s / 3600) % 24
			seconds += ""
			minutes += ""
			hours   += ""
			seconds = "0" + seconds if seconds.length is 1
			minutes = "0" + minutes if minutes.length is 1
			hours   = "0" +  hours if hours.length is 1
			@$timer.text("#{hours}:#{minutes}:#{seconds}") 
		@timer = setInterval time, 1000

	stopTimer: () => clearInterval(@timer) if @timer?

	updateStatus: (msg) => @$status.text msg

	cbEstablished: (message) =>
		@updateStatus "Call established with #{@ext2}"
		$("#remote-legend").text "Remote extension is #{@ext2}"
		@stopSounds()
		@startTimer()
		@nextForm @$formEstablishedCall
		if window.autoanswering
			setTimeout (-> $("#hangup-established").click()), 15000
		@$chat.show()
		@$chat.find("form").submit =>
			message =
				from: @register.ext
				to: @ext2
				content: @$chat.find("input:first").val()
			@$chat.find("input:first").val ""
			@qs.chat @ext2, message.content
			@renderInstantMessage message
		@previousState = @state
	
		callback = => 
			@$mediaRemote.removeClass "hidden"
			@$videos.addClass "active"
			h = @$mediaLocal.height()
			@$mediaLocal.css {marginTop: "-#{h}px"}

		_.delay callback, 200



	cbRegisterSuccess: () =>
		@stopSounds() if @previousState > 3
		callback = => 
			@stopTimer()
			@$videos.removeClass "active"
			@$mediaRemote.addClass "hidden"
			@$mediaLocal.css {marginTop: "0px"}
		callback()
		# Unregister on closing.
		$(window).bind "beforeunload", => @qs.unregister()
	
		@$messages.children().remove()
		@$chat.hide()
	
		@updateStatus "Registered"

		@nextForm @$formCall
	
		$("#register-info")
			.html("<p>Your extension number is <strong>#{@register.ext}</strong>, share this URL to a friend and tell him to call you. If you want to connect to our demo webcam, just dial extension 1234.</p>")
			.fadeIn(200)
		$("#local-legend").text "Local extension is #{@register.ext}"
		@previousState = @state


	cbCalling: (message) =>
		@updateStatus "Calling #{@ext2}"
		document.getElementById("sound-calling").play()
		@hangup = => @qs.hangup message.branch
		@previousState = @state

	cbRinging: (message) =>
		@ext2 = data.ext
		@updateStatus "Incoming call from #{@ext2}"
		@answer = => @qs.answer data.branch
		@hangup = => @qs.hangup data.branch
		@nextForm @$formIncomingCall
		document.getElementById("sound-ringing").play()
		if window.autoanswering
			setTimeout (-> $("#answer").click()), 1000
		@previousState = @state


	cbEndCall: (message) =>
		@updateStatus "Hanging up"
		@stopTimer()
		@stopSounds() if @previousState > 3
		callback = => 
			@stopTimer()
			@$videos.removeClass "active"
			@$mediaRemote.addClass "hidden"
			@$mediaLocal.css {marginTop: "0px"}
		callback()
		# Unregister on closing.
		$(window).bind "beforeunload", => @qs.unregister()

		@$messages.children().remove()
		@$chat.hide()
		@updateStatus "Registered"
		@nextForm @$formCall
		@previousState = @state


window.UI = UI
