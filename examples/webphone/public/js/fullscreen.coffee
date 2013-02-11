jQuery.fn.fullscreen = (bool) ->
	cancelFullScreen = document.webkitExitFullscreen or document.mozCancelFullScreen or document.exitFullscreen
	@each () ->
		@enterFullscreen = @webkitEnterFullScreen or @mozRequestFullScreen or @requestFullscreen
	if bool 
		@each () -> @enterFullscreen()
	else
		cancelFullScreen()
