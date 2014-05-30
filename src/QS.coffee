##
# Copyright (C) Quobis
# Project site: https://github.com/Quobis/QoffeeSIP
#
# Licensed under GNU-LGPL-3.0-or-later (http://www.gnu.org/licenses/lgpl-3.0.html)
##

class QS extends Spine.Controller
	constructor: (options) ->
		super
		@lastState = ""
		@stateflow = []

		# 1 to 1 relation with SipStack's events.
		@mappedEvents = [
			'qs-instant-message'
			'qs-localstream'
			'qs-localstream-screen'
			'qs-remotestream'
			'qs-remotestream-screen'
			'qs-register-error'
			'qs-register-success'
			'qs-unregister-success'
			'qs-another-incoming-call'] # -- !!!


		# 1 to many relation with SipsStack's event.
		@customEvents =
			'qs-ringing'           : {stack:'new-state'       , cb: @cbStateChange}
			'qs-calling'           : {stack:'new-state'       , cb: @cbStateChange}
			'qs-end-call'          : {stack:'new-state'       , cb: @cbStateChange}
			'qs-lost-call'         : {stack:'new-state'       , cb: @cbStateChange}
			'qs-established'       : {stack:'new-state'       , cb: @cbStateChange}
			'qs-instant-message'   : {stack:'instant-message' , cb: @cbInstantMessage}
			'qs-presence-update'   : {stack:'instant-message' , cb: @cbInstantMessage}
			'qs-mediastate-update' : {stack:'instant-message' , cb: @cbInstantMessage}

		@customEventsReverse =
			'new-state'       : {counter: 0}
			'instant-message' : {counter: 0}

		@libEvents =
			'qs-localstream'           : {stack:'localstream'           , cb: @cbLocalstream}
			'qs-localstream-screen'    : {stack:'localstream-screen'    , cb: @cbLocalstreamScreen}
			'qs-remotestream'          : {stack:'remotestream'          , cb: @cbRemotestream}
			'qs-remotestream-screen'   : {stack:'remotestream-screen'   , cb: @cbRemotestreamScreen}
			'qs-register-error'        : {stack:'register-fail'         , cb: @cbRegisterFail}
			'qs-register-success'      : {stack:'register-success'      , cb: @cbRegisterSuccess}
			'qs-unregister-success'    : {stack:'unregister-success'    , cb: @cbUnregisterSuccess}
			'qs-another-incoming-call' : {stack:"another-incoming-call" , cb: @cbAnotherIncomingCall}

		@sipStack = new SipStack

	start: () =>
		@trigger "qs-ready"

	cbInstantMessage: (data) =>
		lines    = data.content.split(/\n/)
		header   = JSON.parse lines[0]
		chattext = lines[1]

		if header.hasOwnProperty "presenceState"
			@trigger 'qs-presence-update',
				userid   : data.from
				state    : header.presenceState
				answerme : header.answerme

		if header.hasOwnProperty "mediaState"
			@trigger 'qs-mediastate-update',
				userid : data.from
				video  : header.mediaState.video

		if chattext.length
			@trigger 'qs-instant-message',
				userid : data.from
				text   : chattext

	cbStateChange: (@state, message) =>
		console.warn @stateflow
		switch @state
			when 3
				if _.isEqual(@stateflow, [5,78,9])
					console.warn "outgoing call, answered, caller hangs up"
					@trigger 'qs-end-call',
						callid : message.callId

				else if _.isEqual(@stateflow, [5,78])
					console.warn "outgoing call, answered, callee hangs up"
					@trigger 'qs-end-call',
						callid : message.callId

				else if _.isEqual(@stateflow, [6,78])
					console.warn "incoming call, answered, caller hangs up"
					@trigger 'qs-end-call',
						callid : message.callId

				else if _.isEqual(@stateflow, [6,78,9])
					console.warn "incoming call, answered, callee hangs up"
					@trigger 'qs-end-call',
						callid : message.callId

				else if _.isEqual(@stateflow, [5,10])
					console.warn "outgoing call, not answered, hangup by caller or callee"
					@trigger 'qs-lost-call',
						callid : message.callId

				else if _.isEqual(@stateflow, [5])
					console.warn "outgoing call, not answered, hangup by callee"
					@trigger 'qs-lost-call',
						callid : message.callId

				else if _.isEqual(@stateflow, [6])
					console.warn "incoming call, not answered, hang it up by caller"
					@trigger 'qs-lost-call',
						callid : message.callId

				else if _.isEqual(@stateflow, [6,9])
					console.warn "incoming call, not answered, hang it up by callee"
					@trigger 'qs-lost-call',
						callid : message.callId

				@stateflow = []

			when 5
				@stateflow.push 5
				@trigger 'qs-calling',
					userid : message.ext2
					callid : message.callId

			when 6
				@stateflow.push 6
				@trigger 'qs-ringing',
					userid : message.ext
					callid : message.callId

			when 7,8
				@stateflow.push 78
				@trigger 'qs-established',
					callid : message.callId

			when 9
				@stateflow.push 9

			when 10
				@stateflow.push 10

	#### register
	# Register the user
	#
	# Params:
	#
	# +   *uri* mandatory `ext@domain` or just `ext`.
	# +   *pass* optional
	# +   *domain* optional
	#
	register: (options, uri, pass = "", userAuthName) =>
		@sipStack.configure
			server                   : options.server
			iceServer                : options.iceServer
			hackViaTCP               : options.hackViaTCP
			hackIpContact            : options.hackIpContact
			hackno_Route_ACK_BYE     : options.hackno_Route_ACK_BYE
			hackContact_ACK_MESSAGES : options.hackContact_ACK_MESSAGES
			hackUserPhone            : options.hackUserPhone
			mediaConstraints         : options.mediaConstraints
			onopen                   : () =>
				@sipStack.register uri, pass, userAuthName
		@sipStack.start()

	#### capabilities
	# Get stack capabilities
	# Returns and array of strings (i.e: ['audio','chat'])
	capabilities: =>
		return ['audio','video','chat','presence']

	#### version
	# Get stack version
	version: () ->
		[{ name : "QoffeeSIP", version : "v0.9.0"}]

	#### call
	# Call to extension *ext*
	call: (uri2, mediaConstraints) =>
		 @sipStack.call uri2, mediaConstraints

	#### answer
	# Answer the call
	answer: (callid, mediaConstraints) =>
		# in the QoffeeSIP world, 'callid' is 'branch'
		@sipStack.answer callid, mediaConstraints

	#### hangup
	hangup: (callid) =>
		# in the QoffeeSIP world, 'callid' is 'branch'
		@sipStack.hangup callid

	#### unregister
	unregister: () =>
		@sipStack.unregister()

	#### updatePresenceState
	updatePresenceState: (uri2, state, answerme = false) =>
		@lastState = state
		content    = JSON.stringify({presenceState: state, answerme: Boolean(answerme)}) + "\n"
		@sipStack.sendInstantMessage uri2, content

	#### updateMediaState
	updateMediaState: (uri2) =>
		content = JSON.stringify({presenceState: @sipStack.rtc.mediaState()}) + "\n"
		@sipStack.sendInstantMessage uri2, content

	#### chat
	chat: (uri2, text) =>
		content =  JSON.stringify({presenceState: @lastState}) + "\n" + text
		@sipStack.sendInstantMessage uri2, content

	cbLocalstream: (evt) =>
		@trigger "qs-localstream", evt

	cbLocalstreamScreen: (evt) =>
		@trigger "qs-localstream-screen", evt

	cbRemotestream: (evt) =>
		@trigger "qs-remotestream", evt

	cbRemotestreamScreen: (evt) =>
		@trigger "qs-remotestream-screen", evt

	cbAnotherIncomingCall: (data) =>
		@trigger "qs-another-incoming-call", userid : data.from

	cbRegisterFail: () =>
		@trigger 'qs-register-error'

	cbRegisterSuccess: () =>
		@trigger 'qs-register-success'

	cbUnregisterSuccess: () =>
		@trigger 'qs-unregister-success'

	#### on
	# Subscribe to *eventName*. *callback* will be called when *eventName* occurs
	#
	# +   qs-instant-message.
	# +   qs-localstream.
	# +   qs-remotestream.
	# +   qs-register-error.
	# +   qs-register-success.
	# +   qs-ringing
	# +   qs-calling
	# +   qs-end-call
	# +   qs-lost-call
	# +   qs-established
	# +   qs-presence-update
	# +   qs-mediastate-update
	#
	on: (eventName, callback) =>
		# check if eventName is a specific event of the API which is not define
		# in the underlying stack
		if @customEvents[eventName]?
			if @customEventsReverse[@customEvents[eventName].stack].counter is 0
				@sipStack.bind @customEvents[eventName].stack, @customEvents[eventName].cb
			@customEventsReverse[@customEvents[eventName].stack].counter += 1
		else if eventName in @mappedEvents
			@sipStack.bind @libEvents[eventName].stack, @libEvents[eventName].cb

		@bind eventName, callback

	#### off
	# Unsubsbribe from event *eventName* with the associated callback *callback*
	off: (eventName, callback) =>
		if @customEvents[eventName]?
			if @customEventsReverse[@customEvents[eventName].stack].counter isnt 0
				@customEventsReverse[@customEvents[eventName].stack].counter -= 1
			if @customEventsReverse[@customEvents[eventName].stack].counter is 0
				@sipStack.unbind @customEvents[eventName].stack, @customEvents[eventName].cb
		else if not eventName in @mappedEvents
			@sipStack.unbind @libEvents[eventName].stack, @libEvents[eventName].cb

		@unbind eventName, callback

	#### toggleMuteVideo
	# Toggle between mute video on and off
	toggleMuteVideo: =>
		@sipStack.rtc.toggleMuteVideo()

	#### toggleMuteAudio
	# Toggle between mute audio on and off
	toggleMuteAudio: =>
		@sipStack.rtc.toggleMuteAudio()

	#### muteVideo
	# Mute video
	muteVideo: =>
		@sipStack.rtc.muteVideo()

	#### unmuteVideo
	# Unmute video
	unmuteVideo: =>
		@sipStack.rtc.unmuteVideo()

	#### muteaudio
	# Mute audio
	muteAudio: =>
		@sipStack.rtc.muteAudio()

	#### unmuteAudio
	# Unmute audio
	unmuteAudio: =>
		@sipStack.rtc.unmuteAudio()

	#### mediaState
	# Retrieve media state
	mediaState: =>
		@sipStack.rtc.mediaState()

	#### attachStream
	# Attach media stream
	attachStream: ($d, stream) =>
		@sipStack.rtc.attachStream $d, stream

	insertDTMF: (callid, tone) =>
		@sipStack.rtc.insertDTMF tone


window.QS            = QS
window.Concretestack = QS
