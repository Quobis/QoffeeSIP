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
			'qs-remotestream'
			'qs-register-fail'
			'qs-register-success'
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
			'qs-remotestream'          : {stack:'remotestream'          , cb: @cbRemotestream}
			'qs-register-fail'         : {stack:'register-fail'         , cb: @cbRegisterFail}
			'qs-register-success'      : {stack:'register-success'      , cb: @cbRegisterSuccess}
			'qs-another-incoming-call' : {stack:"another-incoming-call" , cb: @cbAnotherIncomingCall}

		
		@sipStack = new SipStack
			server                   : @server
			stunServer               : @stunServer
			turnServer               : @turnServer
			hackViaTCP               : @hackViaTCP
			hackIpContact            : @hackIpContact
			hackno_Route_ACK_BYE     : @hackno_Route_ACK_BYE
			hackContact_ACK_MESSAGES : @hackContact_ACK_MESSAGES
			hackUserPhone            : @hackUserPhone
			mediaConstraints         : @mediaConstraints
			mediaElements            : @mediaElements
			onopen                   : @onopen

	start: () =>
		@sipStack.start()

	onopen: () =>
		@trigger "qs-ready"


	cbInstantMessage: (data) =>
		lines    = data.content.split(/\n/)
		header   = JSON.parse lines[0]
		chattext = lines[1]

		if header.hasOwnProperty "presenceState"
			@trigger 'qs-presence-update', data.from, header.presenceState, header.answerme

		if header.hasOwnProperty "mediaState"
			@trigger 'qs-mediastate-update', header.mediaState.video

		if chattext.length
			@trigger 'qs-instant-message', data.from, chattext

	cbStateChange: (@state, message) =>
		console.warn @stateflow
		switch @state
			when 3
				if _.isEqual(@stateflow, [5,78,9])
					console.warn "outgoing call, answered, caller hangs up"
					@trigger 'qs-end-call', message
				else if _.isEqual(@stateflow, [5,78])
					console.warn "outgoing call, answered, callee hangs up"
					@trigger 'qs-end-call', message
					
				else if _.isEqual(@stateflow, [6,78])
					console.warn "incoming call, answered, caller hangs up"
					@trigger 'qs-end-call', message

				else if _.isEqual(@stateflow, [6,78,9])
					console.warn "incoming call, answered, callee hangs up"
					@trigger 'qs-end-call', message

				else if _.isEqual(@stateflow, [5,10])
					console.warn "outgoing call, not answered, hangup by caller or callee"
					@trigger 'qs-lost-call', message

				else if _.isEqual(@stateflow, [5])
					console.warn "outgoing call, not answered, hangup by callee"
					@trigger 'qs-lost-call', message

				else if _.isEqual(@stateflow, [6])
					console.warn "incoming call, not answered, hang it up by caller"
					@trigger 'qs-lost-call', message

				else if _.isEqual(@stateflow, [6,9])
					console.warn "incoming call, not answered, hang it up by callee"
					@trigger 'qs-lost-call', message

				@stateflow = []

			when 5
				@stateflow.push 5
				@trigger 'qs-calling', message

			when 6
				@stateflow.push 6
				@trigger 'qs-ringing', message

			when 7,8
				@stateflow.push 78
				@trigger 'qs-established', message

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
	register: (uri, pass = "", userAuthName) =>
		@sipStack.register uri, pass, userAuthName

	#### capabilities
	# Get stack capabilities
	# Returns and array of strings (i.e: ['audio','chat'])
	capabilities: =>
		return ['audio','video','chat','presence']

	#### call
	# Call to extension *ext*
	call: (uri2) =>
		 @sipStack.call uri2

	#### answer
	# Answer the call
	answer: (callid) =>
		# in the QoffeeSIP world, 'callid' is 'branch'
		@sipStack.answer callid

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

	cbLocalstream: (localstream) =>
		@trigger "qs-localstream", localstream

	cbRemotestream: (remotestream) =>
		@trigger "qs-remotestream", remotestream

	cbAnotherIncomingCall: (data) =>
		@trigger "qs-another-incoming-call", data

	cbRegisterFail: () =>
		@trigger 'qs-register-fail'

	cbRegisterSuccess: () =>
		@trigger 'qs-register-success'

	#### on
	# Subscribe to *eventName*. *callback* will be called when *eventName* occurs
	# 
	# +   qs-instant-message.
	# +   qs-localstream.
	# +   qs-remotestream.
	# +   qs-register-fail.
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
				@customEventsReverse[@customEvents[eventName].stack].counter += 1
				@sipStack.bind @customEvents[eventName].stack, @customEvents[eventName].cb
		else if eventName in @mappedEvents
			@sipStack.bind @libEvents[eventName].stack, @libEvents[eventName].cb

		@bind eventName, callback

	#### off
	# Unsubsbribe from event *eventName* with the associated callback *callback*
	off: (eventName, callback) =>
		if @customEvents[eventName]?
			if @customEventsReverse[@customEvents[eventName].stack].counter isnt 0
				@customEventsReverse[@customEvents[eventName].stack].counter -= 1
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
