##
# Copyright (C) Quobis
# Project site: https://github.com/Quobis/QoffeeSIP
# 
# Licensed under GNU-LGPL-3.0-or-later (http://www.gnu.org/licenses/lgpl-3.0.html)
##


# This class contains almost all the SIP logic of QoffeeSIP stack.
# It containts the FSM (Finite State Machine) and manages creation of request and responses.
class SipStack extends Spine.Controller
	# ## Methods to store transactions and instant messages.

	# *Transactions* id is the meth.
	# transaction :: SipTransaction
	addTransaction: (transaction) =>
		@_transactions[transaction.branch] = transaction

	# meth :: String
	getTransaction: (message) =>
		@_transactions[message.branch]

	# branch :: String
	deleteTransaction: (message) =>
		@_transactions = _.omit @_transactions, message.branch


	checkDialog: (transaction) =>
		# Call-ID, tags
		return not _.isEmpty _.find @_transactions, (tr) => 
			check = tr.callId is transaction.callId
			# Here, we just check that one of the tags matches another one.
			# We should check both, taking care of transactions that does not have toTag.
			# check and= not _.isEmpty _.intersection [transaction.fromTag, transaction.toTag], [tr.fromTag, tr.toTag]

	info: (message, data) =>
		console.log   "[INFO]    " + message
		@trigger message, data

	warning: (message, data) =>
		console.warn  "[WARNING] " + message
		@trigger message, data

	error: (message, data) =>
		console.error "[ERROR]   " + message
		@trigger message, data

	# TODO: Use constants instead of number and strings.
	states:
		["OFFLINE",
		"REGISTERING (before challenge)",
		"REGISTERING (after challenge)", 
		"REGISTERED", "INCOMING CALL", 
		"CALLING", "RINGING",
		"CALL STABLISHED (caller)", 
		"CALL STABLISHED (callee)",
		"HANGING", 
		"CANCELLING"]

	responsePhrases:
		100: "Trying"
		180: "Ringing"
		200: "OK"
		202: "Accepted"
		400: "Bad Request"
		401: "Unauthorized"
		403: "Forbidden"
		404: "Not Found (User not found)"
		407: "Proxy Authentication Required"
		408: "Request Time Out"
		481: "Call/Transaction Does Not Exists"
		486: "Busy Here"
		488: "Not acceptable here"
		500: "Server Internal Error"
		503: "Service Unavaliable"

	# Arguments for SipStack constructor:
	# - mediaElements :: {localMedia :: DOM Element, remoteMedia :: DOM Element}
	# - mediaContraints :: {audio: bool, video: bool}
	# - server :: {ip: string, port: number, path:: string, transport :: string}
	# - onopen :: function
	constructor: () ->
		super
		@rtc = new RTC
			mediaElements: @mediaElements
			mediaConstraints: @mediaConstraints
			turnServer: @turnServer
			stunServer: @stunServer

		@rtc.bind "localstream", (localstream) => @trigger "localstream", localstream
		@rtc.bind "remotestream", (remotestream) => @trigger "remotestream", remotestream


		@sipServer = @server.ip
		@port      = @server.port
		@path      = @server.path or ""
		@transport = @server.transport or "ws"


		# Dictionay for transactions.
		@_transactions    = {}
		@_instantMessages = {}

		# Set initial state of the FSM to 0.
		@setState 0

		# Hacks
		# Some SIP servers need TCP as via transport instead of WS/WSS.
		@hackViaTCP    ?= false
		# Some SIP server try to resolve our random domain. Use a random IP.
		@hackIpContact ?= false

		# A new websocket connection is created.
		console.log("#{@transport}://#{@sipServer}:#{@port}#{@path}")
		try
			@websocket = new WebSocket("#{@transport}://#{@sipServer}:#{@port}#{@path}", "sip")
		catch e
			throw "#{@transport}://#{@sipServer}:#{@port}#{@path} not open"
		
		@websocket.onerror = (e) ->
			console.error "Websocket failed."
			console.log e.data

		@info "websocket created"

		# When websocket connection is opened.
		@websocket.onopen = (evt) =>
			@info "websocket opened"
			@onopen()

		# ### Event machine
		# When a message is received.
		@websocket.onmessage = (evt) =>
			# Get data and contructs a message.
			message = Parser.parse evt.data
			@info "Input message", message

			# Here we deal with methods and responses before entering the state machine.
			# This way we avoid replicating code for every status >= 2.

			# Re-register manager. 
			if (@state > 2) and (message.cseq.meth is "REGISTER")
				return if not @getTransaction message
				switch message.responseCode
					# Here we receive a 200 OK for a REGISTER we sent.
					when 200
						@info "RE-REGISTER answer", message
						return
						
					# Here we receive a 401 for a REGISTER we sent.
					# Once processed, we send an authenticated REGISTER.
					when 401
						register      =  @getTransaction message
						register.vias = message.vias
						register.cseq.number += 1
						_.extend register, _.pick message, "realm", "nonce", "toTag"
						register.auth = true
						@send @createMessage register
						return

			# MESSAGE manager
			# We can receive a MESSAGE method in any REGISTERED state (>= 3).
			if @state > 2 and message.cseq.meth is "MESSAGE"
				switch message.meth
					when "MESSAGE"
						console.log "[MESSAGE] #{message.content}"
						instantMessage =
							from: message.ext,
							to: message.ext2,
							content: message.content
						@trigger "instant-message", instantMessage
						@send @createMessage new SipTransaction _.extend message, {meth: "OK"}
					
					when "OK"
						console.log "[MESSAGE] OK"
						# After receiving a 200 OK we don't need the instant message anymore.
						@deleteTransaction message
					
					else
						# return if not @checkTransaction message
						return unless message.responseCode in [401,407]
						return unless @getTransaction message
						instantMessage = @getTransaction message
						_.extend instantMessage, _.pick message, "realm", "nonce", "toTag"
						instantMessage.proxyAuth = message.responseCode is 407
						instantMessage.auth      = message.responseCode is 401
						@send @createMessage instantMessage
				return
				
								
			# Busy manager
			# We can receive a INVITE method in any within-dialog state (>= 3) and answer Busy.
			if 3 < @state < 9
				# TODO: This INVITE could be a RE-INVITE. We don't manage this case yet.
				if message.meth is "INVITE"
					@info "another-incoming-call", message
					busy = _.clone message
					_.extend busy, {meth: "Busy here"}
					@send @createMessage busy
					return


			# # Beginning of Finite State Machine.
			switch @state
				# ### REGISTERING (before challenging).
				when 1
					# Get the original REGISTER which originated the transaction.
					return if not @getTransaction message
					transaction = @getTransaction message

					# Add the vias of the new message to the original REGISTER.
					transaction.vias = message.vias

					switch message.responseCode
						# Successful register.
						when 200
							@info "register-success", message
							@rtc.start()
							@setState 3, message
							# Manage reregisters. Important: @t should be clean on unregistering.
							transaction.expires = message.proposedExpires / 2
							# A re-register petition is created and sent.
							@reRegister = () =>
								newRegister = @getTransaction transaction
								newRegister.cseq.number += 1
								@send @createMessage newRegister
							@t    = setInterval(@reRegister, transaction.expires*1000)
							@unregister = () =>
								console.log "[INFO] unregistering"
								transaction = @getTransaction message
								transaction.expires = 0
								clearInterval @t
								message = @createMessage transaction
								@send message
								@setState 0, message # Offline
							@gruu = message.gruu
							# Store record-routes to use as INVITE's routes.
							@serviceRoutes = message.serviceRoutes if message.serviceRoutes.length

						# Unsusccessful register.
						when 401
							@setState 2, message
							transaction.cseq.number += 1
							_.extend transaction, _.pick message, "realm", "nonce", "toTag", "qop", "opaque"
							transaction.auth = true
							transaction.updateCnonceNcHex() if transaction.qop is "auth"
							@send @createMessage transaction

						else
							@warning "Unexpected message", message

				# ### REGISTERING (after challenging)
				when 2
					return if not @getTransaction message
					transaction = @getTransaction message
					transaction.vias = message.vias

					switch message.responseCode
						# Successful register.
						when 200
							@info "register-success", message
							@rtc.start()
							@setState 3, message
							# Manage reregisters.
							transaction.expires = message.proposedExpires / 2
							@reRegister = () =>
								newRegister = @getTransaction transaction
								newRegister.cseq.number += 1
								@send @createMessage newRegister
							@t    = setInterval(@reRegister, transaction.expires*1000)
							@unregister = () =>
								console.log "[INFO] unregistering"
								transaction = @getTransaction message
								transaction.expires = 0
								clearInterval @t
								message = @createMessage transaction
								@send message
								@setState 0, message # Offline							
							@gruu = message.gruu
							@serviceRoutes = message.serviceRoutes if message.serviceRoutes.length

						# Unsusccessful register.
						when 401
							@info "register-fail", message
							@setState 0, message
						else
							@warning "message-unexpected", message
							@setState 0, message


				# ### REGISTERED
				when 3
					switch message.meth
						# Incoming call
						when "INVITE"
							# Generate 180 RINGING
							transaction = new SipTransaction message
							@addTransaction transaction
							ringing      = _.clone transaction
							ringing.meth = "Ringing"
							@send @createMessage ringing
							@setState 6, message
						else
							@warning "Unexpected message", message

				# ### incoming CALLING
				when 4
					return if not @checkDialog message
					# TODO: Manage CANCELs and 480 (remote user press hang out)
					switch message.meth
						when "CANCEL"
							@info "Call ended"
							@setState 3, message
						when "ACK"
							 # An ACK as response to a 200 OK is a new transaction of the same dialog.
							@setState 8, message
						else
							@warning "Unexpected message", message

				# ### CALLING
				when 5
					return if not @getTransaction message
					transaction = @getTransaction message
					switch message.type
						when "response"
							# If the message is a known response
							if @responsePhrases[message.responseCode]
								@info @responsePhrases[message.responseCode], message
							else
								@warning "Unexpected response", message
								return

							switch message.responseCode
								when 180
									# Update INVITE transaction's contact.
									transaction.contact = message.contact

								when 200
									@info "Establishing call", message
									@rtc.receiveAnswer message.content
									_.extend transaction, _.pick message, "from", "to", "fromTag", "toTag"
									ack      = new SipTransaction message
									ack.meth = "ACK"
									@send @createMessage ack
									@setState 7, message

								when 401, 407
									@info  "AUTH", message 			if message.responseCode is 401
									@info  "PROXY-AUTH", message 	if message.responseCode is 407

									# Send ACK.
									# Omit "nonce" to avoid to put a authentication header in this ACK.
									ack      = new SipTransaction _.omit message, "nonce"
									ack.meth = "ACK"
									ack.vias = message.vias
									@send @createMessage ack

									transaction.vias        = message.vias
									transaction.cseq.number += 1
									_.extend transaction, _.pick message, "realm", "nonce", "toTag"
						
									transaction.auth      = message.responseCode is 401
									transaction.proxyAuth = message.responseCode is 407
									console.log transaction
									# Send INVITE
									message = @createMessage transaction
									@sendWithSDP message, "offer", null
								else
									if 400 <= message.responseCode
										# Send ACK.
										# Omit "nonce" to avoid to put a authentication header in this ACK.
										ack      = new SipTransaction _.omit message, "nonce"
										ack.meth = "ACK"
										ack.vias = message.vias
										@send @createMessage ack
										@setState 3
										# Remove the current invite transaction.
										@deleteTransaction "INVITE"

						when "request"
							switch message.meth
								when "BYE"
									@info "Call ended", message
									ok      = new SipTransaction message
									ok.meth = "OK"
									# Send OK
									@send @createMessage ok
									@setState 3, message
								else
									@warning "Unexpected message", message

				# ### RINGING
				when 6
					return if not @checkDialog message
					@info "RINGING", message
					switch message.meth
						when "CANCEL"
							@info "Call ended", message
							ok      = new SipTransaction message
							ok.meth = "OK"
							@send @createMessage ok
							@setState 3, message

				# ### CALL ESTABLISHED
				# TODO: We don't manage ACKs after BUSYs.
				when 7, 8
					return if not @checkDialog message
					@info "CALL ESTABLISHED", message
					switch message.meth
						when "BYE"
							@info "Call ended", message
							transaction      = new SipTransaction message
							transaction.vias = message.vias
							transaction.meth = "OK"
							# Send OK
							ok = _.clone transaction
							@send @createMessage ok
							@rtc.close()
							@setState 3, message

				# ### HANGING UP
				# TODO: Timers for states 9 and 10.
				when 9
					return if not @getTransaction message
					@info "HANGING UP", message
					@info "Call ended", message
					@rtc.close()
					@setState 3, message # Registered

				when 10
					return if not @getTransaction message
					@info "HANGING UP", message
					@info "Call ended", message
					@rtc.close()
					@setState 3, message # Registered


			# # End of Finite State Machine

		# When websocket connection is closed.
		@websocket.onclose = (evt) =>
			@info "websocket closed"

	# SIP digest calculator as defined is RFC 3261.
	getDigest: (transaction) =>
		authExtension = transaction.ext
		if transaction.qop is "auth"
			ha1 = CryptoJS.MD5 "#{transaction.userAuthName}:#{transaction.realm}:#{transaction.pass}"
			console.log "HA1 = md5(#{transaction.userAuthName}:#{transaction.realm}:#{transaction.pass})"			

		else
			ha1 = CryptoJS.MD5 "#{transaction.ext}:#{transaction.realm}:#{transaction.pass}"
			console.log "HA1 = md5(#{transaction.ext}:#{transaction.realm}:#{transaction.pass})"
		console.log "HA1 = #{ha1}"
		ha2 = CryptoJS.MD5 "#{transaction.meth}:#{transaction.requestUri}"
		console.log "HA2 = md5(#{transaction.meth}:#{transaction.requestUri})"
		console.log "HA2 = #{ha2}"
		if transaction.qop is "auth"
			sol = CryptoJS.MD5 "#{ha1}:#{transaction.nonce}:#{transaction.ncHex}:#{transaction.cnonce}:auth:#{ha2}"
			console.log "response = md5(#{ha1}:#{transaction.nonce}:#{transaction.ncHex}:#{transaction.cnonce}:auth:#{ha2})"
		else
			sol = CryptoJS.MD5 "#{ha1}:#{transaction.nonce}:#{ha2}"
			console.log "response = md5(#{ha1}:#{transaction.nonce}:#{ha2})"
		console.log "response = #{sol}"
		return sol

	# SIP websockets request creator as defined in draft-ietf-sipcore-sip-websocket-06 and XXXX
	# transaction :: SipTransaction
	createMessage: (transaction) =>
		# We create a SipTransaction to make sure that we have populated all the required headers.
		transaction = new SipTransaction transaction

		# TODO: realm should be used just when it is in the transaction because
		# we are gonna response a request.

		# Antón said:
		# In the createMessage method from SipStack class, to build From and To,
		# we shouldn't used the realm value, as it's only valid for authentication.
		# Normally realm value included in WWW-Authenticate header matches the
		# domain name of the server but that's not mandatory, we could have
		# two different realms for the same domain. We should use our SIP Server
		# domain for From, To and R-uri in REGISTERs. IN INVITEs we should use
		# SIP server domain for From, and for To and R-URI the value provided by
		# the user as extension to be called (the upper layer should provide us
		# sth like pericopalotes@domain.com). If domain is not included by the
		# upper layer (the app using our API) we can decide to add our domain.
		# We should be able to accept different domains for the extension to be called.

		transaction.uri         = "sip:#{transaction.ext}@#{@domain or @sipServer}"
		transaction.uri2        = "sip:#{transaction.ext2}@#{transaction.domain2 or @sipServer}"
		transaction.targetUri   = "sip:#{@sipServer}"
		transaction.cseq.number += 1 if transaction.meth is "BYE"
			
		# SIP frame is filled.
		switch transaction.meth
			when "REGISTER"
				transaction.requestUri = "sip:#{@domain or @sipServer}"
				data = "#{transaction.meth} #{transaction.requestUri} SIP/2.0\r\n"
			when "INVITE", "MESSAGE", "CANCEL"
				transaction.requestUri = transaction.uri2
				data = "#{transaction.meth} #{transaction.requestUri} SIP/2.0\r\n"
			when "ACK", "BYE"
				transaction.requestUri = transaction.contact or transaction.uri2
				data = "#{transaction.meth} #{transaction.requestUri} SIP/2.0\r\n"
			when "OK"
				data = "SIP/2.0 200 OK\r\n"
			when "Ringing"
				data = "SIP/2.0 180 Ringing\r\n"
			when "Busy here"
				data = "SIP/2.0 486 Busy Here\r\n"

		# Record-route
		if (transaction.cseq.meth is "INVITE" and transaction.meth isnt "ACK") and (_.isArray transaction.recordRoutes)
			data += rr + "\r\n" for rr in transaction.recordRoutes
		
		# Route
		else switch transaction.meth
			when "REGISTER", "MESSAGE", "CANCEL"
				data += "Route: <sip:#{@sipServer}:#{@port};transport=ws;lr>\r\n"
			when "INVITE"
				if transaction.recordRoutes.length
					data += "Route: #{serviceRoute}\r\n" for serviceRoute in @serviceRoutes
				else
					data += "Route: <sip:#{@sipServer}:#{@port};transport=ws;lr>\r\n"
			when "ACK", "OK", "BYE"
				if transaction.cseq.meth isnt "MESSAGE"
					data += "Route: <sip:#{@sipServer}:#{@port};transport=ws;lr=on>\r\n"

		# Via
		if _.isArray(transaction.vias)# and transaction.meth isnt "ACK"
			data += (transaction.vias.join "\r\n") + "\r\n"
		else
			# If hack for use TCP in via is true, use TCP.
			data += "Via: SIP/2.0/#{(@hackViaTCP and "TCP") or @transport.toUpperCase()} #{transaction.domainName};branch=#{transaction.branch}\r\n"

		# From
		data += "From: #{transaction.uri};tag=#{transaction.fromTag}\r\n"

		# To
		switch transaction.meth
			when "REGISTER"
				data += "To: #{transaction.uri}\r\n"
			when "INVITE", "MESSAGE", "CANCEL"
				data += "To: #{transaction.uri2}\r\n"
			else
				data += "To: #{transaction.uri2};tag=#{transaction.toTag}\r\n"

		# Call-ID
		data += "Call-ID: #{transaction.callId}\r\n"

		# CSeq
		switch transaction.meth
			when "OK"
				data += "CSeq: #{transaction.cseq.number} #{transaction.cseq.meth or transaction.meth}\r\n"
			when "Ringing"
				data += "CSeq: #{transaction.cseq.number} #{transaction.cseq.meth}\r\n"
			when "ACK"
				data += "CSeq: #{transaction.cseq.number} ACK\r\n"
			when "Busy here"
				data += "CSeq: #{transaction.cseq.number} INVITE\r\n"
			else
				data += "CSeq: #{transaction.cseq.number} #{transaction.meth}\r\n"

		# Max-Forwards
		data += "Max-Forwards: 70\r\n"

		# Allow
		if transaction.meth is "REGISTER" or transaction.meth is "INVITE"
			data += "Allow: INVITE, ACK, CANCEL, BYE, MESSAGE\r\n"

		# Supported
		data += "Supported: path, gruu\r\n"

		# User-Agent
		data += "User-Agent: QoffeeSIP 0.7\r\n"

		# Contact
		# Addres is a randomIP when hackIpContact is true, else, a randomDomain.
		address = (@hackIpContact and transaction.IP) or transaction.domainName
		switch transaction.meth
			when "Ringing"
				if @gruu
					data += "Contact: <sip:#{transaction.ext2}@#{address};gr=urn:uuid:#{transaction.uuid}>\r\n"
				else
					data += "Contact: <sip:#{transaction.ext2}@#{address};transport=ws>\r\n"
			when "OK"
				if transaction.cseq.meth is "INVITE"
					if @gruu
						data += "Contact: <sip:#{transaction.ext2}@#{address};gr=urn:uuid:#{transaction.uuid}>\r\n"
					else
						data += "Contact: <sip:#{transaction.ext2}@#{address};transport=ws>\r\n"
			when "REGISTER"
				data += "Contact: <sip:#{transaction.ext}@#{address};transport=ws>"
			when "INVITE"
				if @gruu
					data += "Contact: <#{@gruu};ob>\r\n"
				else
					# !!!!!! ;ob removed
					data += "Contact: <sip:#{transaction.ext}@#{address};transport=ws>\r\n"
		switch transaction.meth
			when "REGISTER"
				data += ";reg-id=#{transaction.regid}"
				data += ";+sip.instance=\"<urn:uuid:#{transaction.uuid}>\""
				if transaction.expires?
					data += ";expires=#{transaction.expires}"
				data +="\r\n"

		# Challenge
		if transaction.nonce?
			opaque = ""
			opaque = ",opaque=\"#{transaction.opaque}\"" if transaction.opaque?
			qop = ""
			qop = ",qop=#{transaction.qop},cnonce=\"#{transaction.cnonce}\",nc=#{transaction.ncHex}" if transaction.qop?

			if transaction.auth is true
				if transaction.cseq.meth is "REGISTER"
					authUri = transaction.requestUri
				else
					authUri = transaction.uri2
				data += "Authorization:"
			if transaction.proxyAuth is true
				authUri = transaction.uri2
				data += "Proxy-Authorization:"
			transaction.response = @getDigest transaction
			authExt = transaction.ext
			# if IMS
			authExt = transaction.userAuthName if transaction.userAuthName
			data += " Digest username=\"#{authExt}\",realm=\"#{transaction.realm}\","
			data += "nonce=\"#{transaction.nonce}\"#{opaque},uri=\"#{authUri}\",response=\"#{transaction.response}\",algorithm=MD5#{qop}\r\n"		
		
					
		# Content-type and content
		switch transaction.meth
			when "INVITE", "OK"
				if transaction.cseq.meth is "INVITE"
					data += "Content-Type: application/sdp\r\n"
				else
					data += "Content-Length: 0\r\n\r\n"		
			when "MESSAGE"
				data += "Content-Length: #{transaction.content.length or 0}\r\n"
				data += "Content-Type: text/plain\r\n\r\n"
				data += transaction.content
			else
				data += "Content-Length: 0\r\n\r\n"	
		return data

	register: (@ext, @pass, @domain, @userAuthName) =>
		transaction = new SipTransaction {meth: "REGISTER", ext: @ext, domain: @domain, pass: @pass or "", userAuthName: @userAuthName or ""}
		@addTransaction transaction
		@setState 1, transaction
		message = @createMessage transaction
		@send message

	call: (ext2, domain2) =>
		transaction = new SipTransaction
			meth: "INVITE",
			ext: @ext,
			pass : @pass,
			ext2 : ext2
			domain2: domain2 or @domain
		@addTransaction transaction
		@setState 5, transaction
		message = @createMessage transaction
		@sendWithSDP message, "offer", null

	answer: (branch) =>
		ok = _.clone @getTransaction {branch}
		# TODO: meth is not the same as reason phrase.
		# Distinguish between meth and reason phrase.
		ok.meth = "OK"
		# Media
		# This function will be executed when API.answer is called.
		@sendWithSDP (@createMessage ok), "answer", @getTransaction({branch}).content
		@setState 4, ok

	hangup: (branch) =>
		# It is possible to call hangup before the INVITE has been sent (PeerConnection 
		# is still getting ICE candidates), so we must unbind "sdp" event to avoid 
		# sending CANCEL before INVITE.
		@rtc.unbind "sdp"

		# If user is the callee, fromTag of "INVITE" belongs to caller, ext2 in this method.
		# Tags must be swapped.
		swap = (d, p1, p2)-> [d[p1], d[p2]] = [d[p2], d[p1]]

		# We need the INVITE request that has originated the dialog.
		invite = @getTransaction {branch}

		switch @state
			when 5
				cancel = new SipTransaction
					meth: "CANCEL",
					ext : @ext
					domain : @domain
					ext2 : invite.ext2
					domain2: invite.domain2

				_.extend cancel, _.pick invite, "callId", "fromTag", "from", "to", "cseq", "domainName", "branch"
				@send @createMessage cancel
				@setState 10

			when 6
				busy = new SipTransaction
					meth: "Busy here"
					ext : @ext
					ext2 : invite.ext

				_.extend busy, _.pick invite, "callId", "fromTag", "from", "to", "cseq", "domainName", "branch", "vias"
				@send @createMessage busy
				@setState 9, busy

			when 7
				bye = new SipTransaction
					meth: "BYE"
					ext : @ext
					ext2 : invite.ext2
				_.extend bye, _.pick invite, "callId", "contact", "fromTag", "toTag", "from", "to", "cseq"
				@send @createMessage bye
				@addTransaction bye
				@setState 9, bye # Hanging
				@rtc.close()

			when 8
				bye = new SipTransaction
					meth: "BYE"
					ext : @ext
					ext2 : invite.ext
				_.extend bye, _.pick invite, "callId", "contact", "fromTag", "toTag", "from", "to", "cseq", "vias"
				swap bye, "fromTag", "toTag"
				swap bye, "from", "to"
				@send @createMessage bye
				@addTransaction bye
				@setState 9, bye # Hanging
				@rtc.close()

	send: (data) =>
		if data?
			console.log "[INFO] Sending data", data
			try
				@websocket.send data
			catch e
				@error "websocket", e
		else
			console.log "[INFO] Not sending data"

	# Async send
	sendWithSDP: (data, type, sdp) =>
		@rtc.bind "sdp", (sdp) =>
			# Temporal sdp modification
			# sdp = sdp.split("m=video")[0]
			# Media
			data += "Content-Length: #{sdp.length}\r\n\r\n"
			data += sdp
			@send data
			@rtc.unbind "sdp"

		if type is "offer"
			@rtc.createOffer()
		if type is "answer"
			@rtc.receiveOffer sdp, => @rtc.createAnswer()

	sendInstantMessage: (ext2, text) =>
		message = new SipTransaction 
			meth: "MESSAGE"
			ext: @ext
			pass: @pass
			ext2: ext2
			content: text
		@addTransaction message
		@send @createMessage message


	# Set @state and trigger the "new-state" event.
	setState: (@state, data) =>
		console.log  "[INFO] New state  " + @states[@state] + "(#{@state})"
		@trigger "new-state", @state, data

window.SipStack = SipStack
