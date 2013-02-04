##
# @source: https://github.com/Quobis/QoffeeSIP
# Copyright (C) Quobis
# Licensed under GNU-LGPL-3.0-or-later (http://www.gnu.org/licenses/lgpl-3.0.html)
##


class API extends Spine.Controller
	# Options must be an object with {server, mediaElements, onopen?}
	constructor: (options) ->
		super
		args = 
			server: @server
			mediaConstraints: @mediaConstraints
			mediaElements: @mediaElements
			onopen: @onopen or -> false
		@sipStack = new SipStack args

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
		@sipStack.hangup()

	chat: (ext, content) =>
		@sipStack.sendInstantMessage ext, content

	on: (eventName, callback) =>
		@sipStack.bind eventName, callback

	off: (eventName, callback) =>
		@sipStack.unbind eventName, callback if callback?
		@sipStack.unbind eventName, callback if not callback?

window.API = API