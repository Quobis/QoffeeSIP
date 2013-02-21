##
# Copyright (C) Quobis
# Project site: https://github.com/Quobis/QoffeeSIP
# 
# Licensed under GNU-LGPL-3.0-or-later (http://www.gnu.org/licenses/lgpl-3.0.html)
##


class API extends Spine.Controller
	# Options must be an object with {server, mediaElements, onopen?}
	constructor: (options) ->
		super

		@sipStack = new SipStack
			server: @server
			hackViaTCP: @hackViaTCP
			hackIpContact: @hackIpContact
			mediaConstraints: @mediaConstraints
			mediaElements: @mediaElements
			onopen: @onopen or -> false

	# domain is opcional
	register: (ext, pass, domain) =>
		@sipStack.register ext, pass, domain

	# domain is opcional
	call: (ext, domain) =>
		 @sipStack.call ext, domain

	answer: () =>
		@sipStack.answer()

	hangup: () =>
		@sipStack.hangup()

	unregister: () =>
		@sipStack.unregister()

	chat: (ext, content) =>
		@sipStack.sendInstantMessage ext, content

	on: (eventName, callback) =>
		@sipStack.bind eventName, callback

	off: (eventName, callback) =>
		@sipStack.unbind eventName, callback if callback?
		@sipStack.unbind eventName, callback if not callback?

	toggleMuteVideo: =>
		@sipStack.rtc.toggleMuteVideo()

	toggleMuteAudio: =>
		@sipStack.rtc.toggleMuteAudio()		

window.API = API