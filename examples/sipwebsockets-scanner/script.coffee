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
            onopen: =>
                api.register "qoffeesip", "anonymous"
        api = new API options
        api.on "new-state", (state, message) ->
            switch state
                when 2,3
                    userAgentRE =  /User-Agent:(.*)/i
                    serverRE =  /Server:(.*)/i
                    organizationRE =  /Organization:(.*)/i

                    matchUa = userAgentRE.exec message.frame
                    matchServer = serverRE.exec message.frame
                    matchOrganization = organizationRE.exec message.frame

                    output = matchUa or matchServer or matchOrganization
                    $("#output").text(output[0])