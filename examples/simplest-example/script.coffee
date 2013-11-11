##
# Copyright (C) Quobis
# Project site: https://github.com/Quobis/QoffeeSIP
# 
# Licensed under GNU-LGPL-3.0-or-later (http://www.gnu.org/licenses/lgpl-3.0.html)
##


# On document ready...
$ ->
	# Avoid page "reloading" on submit.
	$("form").submit (e) ->
		e.preventDefault()
		false

	$("#init").submit =>
		options =
			server:
				ip: $("#server-ip").val()
				port: $("#server-port").val()
			mediaElements:
				localMedia: $("#local")
				remoteMedia: $("#remote")
			
			onopen: ->
				$("#register").submit ->
					qs.register $("#register-ext").val(), $("#register-pass").val()
				
				$("#call").submit -> qs.call $("#call-ext").val()

		qs = new QS options

		qs.on "qs-established", (message) ->
			$("#hangup").submit -> qs.hangup message.branch
		
		qs.on "qs-end-call", () ->
			$("#hangup").off "submit"

		qs.on "qs-ringing", (message) ->
			qs.answer message.branch
