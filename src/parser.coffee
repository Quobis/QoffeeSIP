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
		viaRE = /Via\:\s+SIP\/2\.0\/[A-Z]+\s+([A-z0-9\.\:]+)/
		tmp  = _.filter pkt.split("\r\n"), (line) -> viaRE.test line
		vias = _.map tmp, (via) ->  via.replace /;received=[A-z0-9\.\:]+/, ""
		console.log vias
		if vias.length > 0
			ret = @getRegExprResult vias[0], viaRE, sentBy: 1
			branchRE = /branch=([^;\s]+)/
			ret = @getRegExprResult vias[0], branchRE, branch: 1
			# branchRE = /branch=([^;\r\n]+)/
			# tmp      = branchRE.exec vias[0]
			# branch   = tmp[1] if tmp.length >= 1
			# sentBy   = vias[0].split(/\s|;/)[2]
		console.log _.extend {vias}, ret
		return _.extend {vias}, ret

	@parseRecordRoutes: (pkt) ->
		recordRouteRE = /Record-Route\:/i
		recordRoutes  = _.filter pkt.split("\r\n"), (line) -> recordRouteRE.test line
		return {recordRoutes}

	@parseFrom: (pkt) ->
		# verification URL: http://rubular.com/r/QDAr1fmsfj
		lineFromRE = /(From|^f):\s*(\"[a-zA-Z0-9\-\.\!\%\*\+\`\'\~]*\"|[^<]*)\s*<?((sips?:((.+)@[a-zA-Z0-9\.\-]+(\:[0-9]+)?))([a-zA-Z0-9\-\.\!\%\*\+\`\'\~\;\=]*))>?(;tag=([a-zA-Z0-9\-\.\!\%\*\+\`\'\~]+))?(;.*)*/
		return @getRegExprResult pkt, lineFromRE, {from: 5, ext: 6, fromTag: 10}

	@parseTo: (pkt) ->
		# verification URL: http://rubular.com/r/JbKTIKPTli
		lineToRE = /(To|^t):\s*(\"[a-zA-Z0-9\-\.\!\%\*\+\`\'\~]*\"|[^<]*)\s*<?((sips?:((.+)@[a-zA-Z0-9\.\-]+(\:[0-9]+)?))([a-zA-Z0-9\-\.\!\%\*\+\`\'\~\;\=]*))>?(;tag=([a-zA-Z0-9\-\.\!\%\*\+\`\'\~]+))?(;.*)*/
		return @getRegExprResult pkt, lineToRE, {to: 5, ext2: 6, toTag: 10}

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
	#verification URL: http://rubular.com/r/x46OPwgWBd
	@parseContact: (pkt) ->
		contactRE = /(Contact|^m):\s*(\"[a-zA-Z0-9\-\.\!\%\*\+\`\'\~]*\"|[^<]*)\s*<?((sips?:((.+)@[a-zA-Z0-9\.\-]+(\:[0-9]+)?))([a-zA-Z0-9\-\.\!\%\*\+\`\'\~\;\=]*))>?(.*)/
		gruuRE = /pub\-gruu=\"(.+?)\"/
		result = @getRegExprResult pkt, contactRE, {contact: 3}
		result2= @getRegExprResult pkt, contactRE, {contact: 8}
		console.warn result 	
		console.warn result2	
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
		# We use this RE to check if this fieldas are present in the message (not only in the line)
		# some stacks use different consecutives lines to send Authroization headers.
		realmRe  = /realm="([^\"^\\]+)"/ 
		nonceRe  = /nonce="([^\"^\\]+)"/
		opaqueRe = /opaque="([^\"^\\]+)"/
		qopRe    = /qop=\"(auth|auth-int)\"/

		line     = (lineRe.exec pkt)
		if line?
			realm  = realmRe.exec(pkt)?[1]
			nonce  = nonceRe.exec(pkt)?[1]
			opaque = opaqueRe.exec(pkt)?[1]
			qop    = qopRe.exec(pkt)?[1]

		return {realm, nonce, opaque, qop}

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
