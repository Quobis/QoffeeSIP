##
# Copyright (C) Quobis
# Project site: https://github.com/Quobis/QoffeeSIP
# 
# Licensed under GNU-LGPL-3.0-or-later (http://www.gnu.org/licenses/lgpl-3.0.html)
##


# This class contain all variables needed in one transaction.
class SipTransaction
	# Next variables are unique for each transaction.
	#
	# - meth
	# - cseq
	# - callId
	# - realm
	# - nonce
	# - fromTag
	# - toTag
	# - ext
	# - ext2
	# - route
	# - contact
	# - expires
	# - vias

	# The argument must be a dicionary. All keys of this dictionary will be attributes of the object.
	constructor: (args) ->
		@set args

		# This variables are common for all transactions.
		# If domainName or IP or branch does not exist, create them.
		@domainName ?= "#{@randomString 12}.invalid"
		# IP is used when SipStack.hackViaTCP is true.
		@IP         ?= @randomIP()
		@branch 	?= "z9hG4bK" + @randomString(30)

		# Some variables must be asgined to random values
		# if they are not filled yet.
		if not @cseq?
			@cseq         = {}
			@cseq.number ?= _.random 0, 1000
			@cseq.meth   ?= @meth
			@cseq.meth   ?= ""

		@fromTag ?= @randomString 20
		@toTag ?= @randomString 20
		@callId ?= @randomString 16
		@regid = 1
		SipTransaction::uuid ?= @getUuid()
		@tupleId ?= @randomString 8
		@cnonce ?= ""
		@nc ?= 0
		@ncHex ?= "00000000"

	# It receives a dictionary and set all key-value pairs
	# as pairs of instance variable - value.
	set: (args) => @[key] = value for key,value of args

	# random alphanumeric string generator.
	randomString: (n, hex = false) ->
		if hex
			string = Math.random().toString(16)[2..]
		else
			string = Math.random().toString(32)[2..]
			string = string.concat Math.random().toString(32).toUpperCase()[2..]

		array  = _.shuffle string.split("")
		string = ""
		string += character for character in array
		limit  = Math.min string.length, n
		string = string[0...limit]
		# Recursiveness.
		string += @randomString n-string.length, hex while string.length < n
		return string[0...n]

	# http://tools.ietf.org/html/draft-ietf-sipcore-sip-websocket-02#appendix-A.1
	# Persistence in uuid is needed (we prefer LocalStorage over a Cookie as proposed)
	getUuid: () ->
		if localStorage["uuid"] is null or localStorage["uuid"] is undefined
			localStorage["uuid"] = "#{@randomString 3, true}-#{@randomString 4, true}-#{@randomString 8, true}"
		@uuid = localStorage["uuid"]
		@getUuid = -> @uuid
		@uuid

	randomIP: () ->
		array = []
		array.push  _.random 1, 255 for i in [0..3]
		return array.join('.')
	
	updateCnonceNcHex: () ->
		@cnonce = @randomString 8
		@nc += 1
		hex = Number(@nc).toString(16)
		@ncHex = "00000000".substr(0, 8 - hex.length) + hex
					
		if @nc is 4294967296
			@nc = 1
			@ncHex = "00000001"

# Exports the SipTransaction class.
window.SipTransaction = SipTransaction
