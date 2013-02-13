##
# Copyright (C) Quobis
# Project site: https://github.com/Quobis/QoffeeSIP
# 
# Licensed under GNU-LGPL-3.0-or-later (http://www.gnu.org/licenses/lgpl-3.0.html)
##


# Defines to execute init function when webpage is loaded.
$ ->
    console.log "Ready!"
    window.testBrowser() if window.testBrowser

    conf =
        mediaElements:
            localMedia: $("#media-local")
            remoteMedia: $("#media-remote")
        el: "body"

    new UI conf
    window.autoanswering = false

    if window.autoanswering
        ext = 1234
        $("#user-reg").val ext
        $("#pass-reg").val ext
        $("#register").click()
