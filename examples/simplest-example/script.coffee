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

    # Declaration of api.
    api = null

    $("#init").submit =>
        options =
            server: {ip: $("#server-ip").val(), port: $("#server-port").val()}
            mediaElements: {localMedia: $("#media-local"), remoteMedia: $("#media-remote")}
            onopen: =>
                $("#register").submit =>
                    api.register $("#register-ext").val(), $("#register-pass").val()
                        # New submit handler for call button.
                $("#call").submit ->
                    api.call $("#call-ext").val()
                
        api = new API options
        api.on "new-state", (state, message) ->
            switch state
                when 6
                    api.answer message.branch

                when 7,8
                    $("#hangup").submit ->
                        api.hangup message.branch
                when 9
                    # Remove all previous submit handler for hangup.
                    $("#hangup").off "submit"