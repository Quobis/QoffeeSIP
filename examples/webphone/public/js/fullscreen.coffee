##
# Copyright (C) Quobis
# Project site: https://github.com/Quobis/QoffeeSIP
# 
# Licensed under GNU-LGPL-3.0-or-later (http://www.gnu.org/licenses/lgpl-3.0.html)
##


jQuery.fn.fullscreen = (bool) ->
	cancelFullScreen = document.webkitExitFullscreen or document.mozCancelFullScreen or document.exitFullscreen
	@each () ->
		@enterFullscreen = @webkitEnterFullScreen or @mozRequestFullScreen or @requestFullscreen
	if bool 
		@each () -> @enterFullscreen()
	else
		cancelFullScreen()
