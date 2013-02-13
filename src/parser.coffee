##
# Copyright (C) Quobis
# Project site: https://github.com/Quobis/QoffeeSIP
# 
# Licensed under GNU-LGPL-3.0-or-later (http://www.gnu.org/licenses/lgpl-3.0.html)
##


# Abtract class. It contains abstract methods that receives SIP
# packages and extract some data from them.
class Parser
	# Receives a SIP message, a RegExpr and a dictionary of keys and indexes of the RegExpr.
	@getRegExprResult: (pkt, re, indexes) ->
		# Create a dictionary of indexes keys setted to undefined.
		result = {}
		result[key] = undefined for key in _.keys(indexes)
		# Exec de RE
		line = re.exec pkt
		if line?
			result[key] = line[index]  for key, index of indexes when index < line.length					
		return result

	@parse: (pkt) ->
		console.log "[INFO] Parsing"
		console.log pkt

		message = {}
		# Every message content the frame inside 
		# to allow parsering in the upper layers.
		_.extend message, {frame: pkt}
		_.extend message, @parseFirstLine pkt		
		_.extend message, @parseVias pkt
		_.extend message, @parseFrom pkt
		_.extend message, @parseTo pkt
		_.extend message, @parseRecordRoutes pkt
		_.extend message, @parseRoute pkt
		_.extend message, @parseContact pkt
		_.extend message, @parseCallId pkt
		_.extend message, @parseCSeq pkt
		_.extend message, @parseChallenge pkt
		_.extend message, @parseExpires pkt
		_.extend message, @parseContentType pkt
		_.extend message, @parseContent pkt

		console.log "[INFO] Parsed"
		console.log message
		
		return message     

	@parseFirstLine: (pkt) ->
		firstLine = pkt.split("\r\n")[0]
		responseRE = /^SIP\/2\.0 \d+/

		# If it is a response
		# SIP/2.0 code phrase
		if responseRE.test firstLine
			tmp  = firstLine.split " "
			# code phrase
			tmp  = _.rest tmp
			code = parseInt tmp[0]
			# phrase
			tmp  = _.rest tmp
			# We put the phrase as method to simplify the creation of messages.
			meth = tmp.join " "
			# TODO: Meth and reason phrase should be separeted.
			return {responseCode: code, meth: meth, type: "response"}

		# else, it is a request
		else
			methodRE   = /(\w+)/
			meth       = methodRE.exec(firstLine)[0]
			requestUri = firstLine.split(" ")[1].split(";")[0]
			return {meth: meth, type: "request"}

	@parseVias: (pkt) ->
		viaRE = /Via\:/i
		viasWithReceived  = _.filter pkt.split("\r\n"), (line) -> viaRE.test line
		vias = []
		vias.push via.replace /;received=.+/, "" for via in viasWithReceived
		return {vias}

	@parseRecordRoutes: (pkt) ->
		recordRouteRE = /Record-Route\:/i
		recordRoutes  = _.filter pkt.split("\r\n"), (line) -> recordRouteRE.test line
		return {recordRoutes}

	@parseFrom: (pkt) ->
		# TODO: We must check domains and IPs correctly. This RE is too much permisive.
		lineFromRE = ///
			From:
				(\s?".+"\s?)?
				\s
				<?sips?:((.+)@[A-z0-9\.]+)>?(;tag=(.+))?
			///i
		return @getRegExprResult pkt, lineFromRE, {from: 2, ext: 3, fromTag: 5}

	@parseTo: (pkt) ->
		# TODO: We must check domains and IPs correctly. This RE is too much permisive.
		lineToRE = /To:(\s?".+"\s?)?\s<?sips?:((.+)@[A-z0-9\.]+)>?(;tag=(.+))?/i
		return @getRegExprResult pkt, lineToRE, {to: 2, ext2: 3, toTag: 5}

	@parseCallId: (pkt) ->
		lineCallIdRE = /Call-ID:\s(.+)/i
		return @getRegExprResult pkt, lineCallIdRE, {callId: 1}

	# Challenge parser, it gets Route values.
	# It is not used by the sipstack so it can be deleted in futured releases.
	@parseRoute: (pkt) ->
		lineRoute = /Route\:/i
		route = ""
		for line in pkt.split '\r\n'
			if lineRoute.test line
				tmp = line.split ': '
				route += tmp[1] + "\r\nRoute: "
		# Taking care about last "\r\nRoute: ""
		route = route[0...-9]
		return {route}

	# Challenge parser, it gets Contact values.
	@parseContact: (pkt) ->
		contactRE = /Contact\:\s<(.*)>/g
		gruuRE = /pub\-gruu=\"(.+?)\"/
		result = @getRegExprResult pkt, contactRE, {contact: 1}
		return _.extend result, @getRegExprResult pkt, gruuRE, {gruu: 1}

	# Challenge parser, it gets method from CSeq values.
	@parseCSeq: (pkt) ->
		CSeqRE = /CSeq\:\s(\d+)\s(.+)/gi
		cseq =  @getRegExprResult  pkt, CSeqRE, number: 1, meth: 2
		cseq.number = parseInt cseq.number
		return {cseq}

	# Challenge parser, it gets realm and nonce values.
	@parseChallenge: (pkt) ->
		lineRe   = /^WWW-Authenticate\:.+$|^Proxy-Authenticate\:.+$/m
		# security checks
		realmRe  = 
			///
			realm="(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}|(([a-z]+\.)+[a-z]{2,3})|(\w+))"
			///
		# Too much restrictive, Kamailio includes reserverd characters
		# like "/" or "+" in nonces. :|
		nonceRe  = /nonce="(.{4,})"/
		line = (lineRe.exec pkt)
		if line?
			line = line[0]
			realm = realmRe.exec(line)[1]
			nonce = nonceRe.exec(line)[1]
		return {realm, nonce}

	# Expires parser
	@parseExpires: (pkt) ->
		expiresRE       = /expires=(\d{1,4})/
		return @getRegExprResult pkt, expiresRE, {proposedExpires: 1}

	@parseContentType: (pkt) ->
		contentTypeRE = /Content-Type: (.*)/i
		return @getRegExprResult pkt, contentTypeRE, {contentType: 1}

	@parseContent: (pkt) ->
		# A blank line separates header and body (content).
		return content: (pkt.split "\r\n\r\n")[1]

# Exporting the Parser
window.Parser = Parser