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
					api.register $("#register-ext").val(), $("#register-pass").val()
				
				$("#call").submit -> api.call $("#call-ext").val()
				
		api = new API options
		api.on "new-state", (state, message) ->
			switch state
				when 5,8
					$("#hangup").submit -> api.hangup message.branch
				when 6
					api.answer message.branch
				when 9
					# Remove all previous submit handler for hangup.
					$("#hangup").off "submit"