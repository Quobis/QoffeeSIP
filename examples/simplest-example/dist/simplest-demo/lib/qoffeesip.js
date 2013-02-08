/*
@source: https://github.com/Quobis/QoffeeSIP
Copyright (C) Quobis
Licensed under GNU-LGPL-3.0-or-later (http://www.gnu.org/licenses/lgpl-3.0.html)
*/
/*
CryptoJS v3.0.2
code.google.com/p/crypto-js
(c) 2009-2012 by Jeff Mott. All rights reserved.
code.google.com/p/crypto-js/wiki/License
*/
var CryptoJS=CryptoJS||function(o,q){var l={},m=l.lib={},n=m.Base=function(){function a(){}return{extend:function(e){a.prototype=this;var c=new a;e&&c.mixIn(e);c.$super=this;return c},create:function(){var a=this.extend();a.init.apply(a,arguments);return a},init:function(){},mixIn:function(a){for(var c in a)a.hasOwnProperty(c)&&(this[c]=a[c]);a.hasOwnProperty("toString")&&(this.toString=a.toString)},clone:function(){return this.$super.extend(this)}}}(),j=m.WordArray=n.extend({init:function(a,e){a=
this.words=a||[];this.sigBytes=e!=q?e:4*a.length},toString:function(a){return(a||r).stringify(this)},concat:function(a){var e=this.words,c=a.words,d=this.sigBytes,a=a.sigBytes;this.clamp();if(d%4)for(var b=0;b<a;b++)e[d+b>>>2]|=(c[b>>>2]>>>24-8*(b%4)&255)<<24-8*((d+b)%4);else if(65535<c.length)for(b=0;b<a;b+=4)e[d+b>>>2]=c[b>>>2];else e.push.apply(e,c);this.sigBytes+=a;return this},clamp:function(){var a=this.words,e=this.sigBytes;a[e>>>2]&=4294967295<<32-8*(e%4);a.length=o.ceil(e/4)},clone:function(){var a=
n.clone.call(this);a.words=this.words.slice(0);return a},random:function(a){for(var e=[],c=0;c<a;c+=4)e.push(4294967296*o.random()|0);return j.create(e,a)}}),k=l.enc={},r=k.Hex={stringify:function(a){for(var e=a.words,a=a.sigBytes,c=[],d=0;d<a;d++){var b=e[d>>>2]>>>24-8*(d%4)&255;c.push((b>>>4).toString(16));c.push((b&15).toString(16))}return c.join("")},parse:function(a){for(var b=a.length,c=[],d=0;d<b;d+=2)c[d>>>3]|=parseInt(a.substr(d,2),16)<<24-4*(d%8);return j.create(c,b/2)}},p=k.Latin1={stringify:function(a){for(var b=
a.words,a=a.sigBytes,c=[],d=0;d<a;d++)c.push(String.fromCharCode(b[d>>>2]>>>24-8*(d%4)&255));return c.join("")},parse:function(a){for(var b=a.length,c=[],d=0;d<b;d++)c[d>>>2]|=(a.charCodeAt(d)&255)<<24-8*(d%4);return j.create(c,b)}},h=k.Utf8={stringify:function(a){try{return decodeURIComponent(escape(p.stringify(a)))}catch(b){throw Error("Malformed UTF-8 data");}},parse:function(a){return p.parse(unescape(encodeURIComponent(a)))}},b=m.BufferedBlockAlgorithm=n.extend({reset:function(){this._data=j.create();
this._nDataBytes=0},_append:function(a){"string"==typeof a&&(a=h.parse(a));this._data.concat(a);this._nDataBytes+=a.sigBytes},_process:function(a){var b=this._data,c=b.words,d=b.sigBytes,f=this.blockSize,i=d/(4*f),i=a?o.ceil(i):o.max((i|0)-this._minBufferSize,0),a=i*f,d=o.min(4*a,d);if(a){for(var h=0;h<a;h+=f)this._doProcessBlock(c,h);h=c.splice(0,a);b.sigBytes-=d}return j.create(h,d)},clone:function(){var a=n.clone.call(this);a._data=this._data.clone();return a},_minBufferSize:0});m.Hasher=b.extend({init:function(){this.reset()},
reset:function(){b.reset.call(this);this._doReset()},update:function(a){this._append(a);this._process();return this},finalize:function(a){a&&this._append(a);this._doFinalize();return this._hash},clone:function(){var a=b.clone.call(this);a._hash=this._hash.clone();return a},blockSize:16,_createHelper:function(a){return function(b,c){return a.create(c).finalize(b)}},_createHmacHelper:function(a){return function(b,c){return f.HMAC.create(a,c).finalize(b)}}});var f=l.algo={};return l}(Math);
(function(o){function q(b,f,a,e,c,d,g){b=b+(f&a|~f&e)+c+g;return(b<<d|b>>>32-d)+f}function l(b,f,a,e,c,d,g){b=b+(f&e|a&~e)+c+g;return(b<<d|b>>>32-d)+f}function m(b,f,a,e,c,d,g){b=b+(f^a^e)+c+g;return(b<<d|b>>>32-d)+f}function n(b,f,a,e,c,d,g){b=b+(a^(f|~e))+c+g;return(b<<d|b>>>32-d)+f}var j=CryptoJS,k=j.lib,r=k.WordArray,k=k.Hasher,p=j.algo,h=[];(function(){for(var b=0;64>b;b++)h[b]=4294967296*o.abs(o.sin(b+1))|0})();p=p.MD5=k.extend({_doReset:function(){this._hash=r.create([1732584193,4023233417,
2562383102,271733878])},_doProcessBlock:function(b,f){for(var a=0;16>a;a++){var e=f+a,c=b[e];b[e]=(c<<8|c>>>24)&16711935|(c<<24|c>>>8)&4278255360}for(var e=this._hash.words,c=e[0],d=e[1],g=e[2],i=e[3],a=0;64>a;a+=4)16>a?(c=q(c,d,g,i,b[f+a],7,h[a]),i=q(i,c,d,g,b[f+a+1],12,h[a+1]),g=q(g,i,c,d,b[f+a+2],17,h[a+2]),d=q(d,g,i,c,b[f+a+3],22,h[a+3])):32>a?(c=l(c,d,g,i,b[f+(a+1)%16],5,h[a]),i=l(i,c,d,g,b[f+(a+6)%16],9,h[a+1]),g=l(g,i,c,d,b[f+(a+11)%16],14,h[a+2]),d=l(d,g,i,c,b[f+a%16],20,h[a+3])):48>a?(c=
m(c,d,g,i,b[f+(3*a+5)%16],4,h[a]),i=m(i,c,d,g,b[f+(3*a+8)%16],11,h[a+1]),g=m(g,i,c,d,b[f+(3*a+11)%16],16,h[a+2]),d=m(d,g,i,c,b[f+(3*a+14)%16],23,h[a+3])):(c=n(c,d,g,i,b[f+3*a%16],6,h[a]),i=n(i,c,d,g,b[f+(3*a+7)%16],10,h[a+1]),g=n(g,i,c,d,b[f+(3*a+14)%16],15,h[a+2]),d=n(d,g,i,c,b[f+(3*a+5)%16],21,h[a+3]));e[0]=e[0]+c|0;e[1]=e[1]+d|0;e[2]=e[2]+g|0;e[3]=e[3]+i|0},_doFinalize:function(){var b=this._data,f=b.words,a=8*this._nDataBytes,e=8*b.sigBytes;f[e>>>5]|=128<<24-e%32;f[(e+64>>>9<<4)+14]=(a<<8|a>>>
24)&16711935|(a<<24|a>>>8)&4278255360;b.sigBytes=4*(f.length+1);this._process();b=this._hash.words;for(f=0;4>f;f++)a=b[f],b[f]=(a<<8|a>>>24)&16711935|(a<<24|a>>>8)&4278255360}});j.MD5=k._createHelper(p);j.HmacMD5=k._createHmacHelper(p)})(Math);
// Generated by CoffeeScript 1.4.0
(function() {
  var RTC,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  RTC = (function(_super) {

    __extends(RTC, _super);

    function RTC() {
      this.close = __bind(this.close, this);

      this.receiveAnswer = __bind(this.receiveAnswer, this);

      this.receiveOffer = __bind(this.receiveOffer, this);

      this.receive = __bind(this.receive, this);

      this.createAnswer = __bind(this.createAnswer, this);

      this.createOffer = __bind(this.createOffer, this);

      this.setLocalDescription = __bind(this.setLocalDescription, this);

      this.triggerSDP = __bind(this.triggerSDP, this);

      this.createStream = __bind(this.createStream, this);

      this.createPeerConnection = __bind(this.createPeerConnection, this);

      this.start = __bind(this.start, this);

      this.browserSupport = __bind(this.browserSupport, this);

      var _ref;
      RTC.__super__.constructor.apply(this, arguments);
      console.log("[INFO] RTC constructor");
      if (this.mediaElements != null) {
        this.$dom1 = this.mediaElements.localMedia;
        this.$dom2 = this.mediaElements.remoteMedia;
      } else {
        this.$dom1 = this.$dom2 = null;
      }
      if ((_ref = this.mediaConstraints) == null) {
        this.mediaConstraints = {
          audio: true,
          video: true
        };
      }
      this.browserSupport();
      this.start();
    }

    RTC.prototype.browserSupport = function() {
      var _this = this;
      if (navigator.mozGetUserMedia) {
        this.browser = "firefox";
        this.getUserMedia = navigator.mozGetUserMedia.bind(navigator);
        this.PeerConnection = mozRTCPeerConnection;
        this.RTCSessionDescription = mozRTCSessionDescription;
        this.attachStream = function($dom, stream) {
          var $d;
          if (!($dom != null)) {
            return;
          }
          console.log("[INFO] attachStream");
          $d = $($dom.find("video")[0]);
          $d.attr('src', window.URL.createObjectURL(stream));
          $d.get(0).play();
          return $d.parent().css({
            opacity: 1
          });
        };
        MediaStream.prototype.getVideoTracks = function() {
          return [];
        };
        MediaStream.prototype.getAudioTracks = function() {
          return [];
        };
      }
      if (navigator.webkitGetUserMedia) {
        this.browser = "chrome";
        this.getUserMedia = navigator.webkitGetUserMedia.bind(navigator);
        this.PeerConnection = webkitRTCPeerConnection;
        this.RTCSessionDescription = RTCSessionDescription;
        this.attachStream = function($dom, stream) {
          var $d, url;
          if (!($dom != null)) {
            return;
          }
          console.log("[INFO] attachStream");
          $d = $($dom.find("video")[0]);
          url = webkitURL.createObjectURL(stream);
          $d.attr('src', url);
          $d.parent().css({
            opacity: 1
          });
          if (!webkitMediaStream.prototype.getVideoTracks) {
            webkitMediaStream.prototype.getVideoTracks = function() {
              return this.videoTracks;
            };
          }
          if (!webkitMediaStream.prototype.getAudioTracks) {
            return webkitMediaStream.prototype.getAudioTracks = function() {
              return this.audioTracks;
            };
          }
        };
        if (!webkitRTCPeerConnection.prototype.getLocalStreams) {
          webkitRTCPeerConnection.prototype.getLocalStreams = function() {
            return this.localStreams;
          };
          return webkitRTCPeerConnection.prototype.getRemoteStreams = function() {
            return this.remoteStreams;
          };
        }
      }
    };

    RTC.prototype.start = function() {
      this.noMoreCandidates = false || (this.browser === "firefox");
      return this.createPeerConnection();
    };

    RTC.prototype.createPeerConnection = function() {
      var _this = this;
      console.log("[INFO] createPeerConnection");
      this.pc = new this.PeerConnection({
        "iceServers": [
          {
            "url": "stun:74.125.132.127:19302"
          }
        ]
      });
      this.pc.onaddstream = function(event) {
        console.log("[MEDIA] Stream added");
        _this.trigger("info", "remotestream");
        return _this.attachStream(_this.$dom2, event.stream);
      };
      this.pc.onicecandidate = function(evt, moreToFollow) {
        var candidate;
        console.log("[INFO] onicecandidate");
        console.log(_this.pc.iceState);
        if (evt.candidate) {
          console.log("[INFO] New ICE candidate:");
          candidate = {
            type: 'candidate',
            label: evt.candidate.sdpMLineIndex,
            id: evt.candidate.sdpMid,
            candidate: evt.candidate.candidate
          };
          return console.log("" + candidate.candidate);
        } else {
          console.log("[INFO] No more ice candidates");
          _this.noMoreCandidates = true;
          if (_this.pc.localDescription != null) {
            return _this.triggerSDP();
          }
        }
      };
      if (this.browser === "chrome") {
        this.pc.onicechange = function(event) {
          return console.log("[INFO] icestate changed -> " + _this.pc.iceState);
        };
        this.pc.onstatechange = function(event) {
          return console.log("[INFO] peerconnectionstate changed -> " + _this.pc.readyState);
        };
        this.pc.onopen = function() {
          return console.log("[MEDIA] peerconnection opened");
        };
        this.pc.onclose = function() {
          return console.log("[INFO] peerconnection closed");
        };
      }
      return this.createStream();
    };

    RTC.prototype.createStream = function() {
      var gumFail, gumSuccess,
        _this = this;
      console.log("[INFO] createStream");
      if (this.localstream != null) {
        console.log("[INFO] Using media previously getted.");
        this.pc.addStream(this.localstream);
        return this.attachStream(this.$dom1, this.localstream);
      } else {
        gumSuccess = function(stream) {
          _this.localstream = stream;
          console.log("[INFO] getUserMedia successed");
          console.log(stream);
          _this.pc.addStream(_this.localstream);
          _this.attachStream(_this.$dom1, _this.localstream);
          return _this.trigger("info", "localstream");
        };
        gumFail = function(error) {
          console.log(error);
          console.log("GetUserMedia error");
          return _this.trigger("error", "getUserMedia");
        };
        return this.getUserMedia(this.mediaConstraints, gumSuccess, gumFail);
      }
    };

    RTC.prototype.triggerSDP = function() {
      var sdp;
      console.log("[MEDIA]");
      sdp = this.pc.localDescription.sdp;
      return this.trigger("sdp", sdp);
    };

    RTC.prototype.setLocalDescription = function(sessionDescription, callback) {
      var fail, success,
        _this = this;
      success = function() {
        console.log("[INFO] setLocalDescription successed");
        if (_this.noMoreCandidates) {
          return _this.triggerSDP();
        }
      };
      fail = function() {
        return _this.trigger("error", "setLocalDescription", sessionDescription);
      };
      return this.pc.setLocalDescription(sessionDescription, success, fail);
    };

    RTC.prototype.createOffer = function() {
      var error,
        _this = this;
      console.log("[INFO] createOffer");
      error = function(e) {
        return _this.trigger("error", "createOffer", e);
      };
      return this.pc.createOffer(this.setLocalDescription, error, {});
    };

    RTC.prototype.createAnswer = function() {
      var error,
        _this = this;
      console.log("[INFO] createAnswer");
      error = function(e) {
        return _this.trigger("error", "createAnswer", e);
      };
      return this.pc.createAnswer(this.setLocalDescription, error, {});
    };

    RTC.prototype.receive = function(sdp, type, callback) {
      var description, success,
        _this = this;
      if (callback == null) {
        callback = function() {
          return null;
        };
      }
      success = function() {
        console.log("[INFO] Remote description setted.");
        console.log("[INFO] localDescription:");
        console.log(_this.pc.localDescription);
        console.log("[INFO] remotelocalDescription:");
        console.log(_this.pc.remoteDescription);
        return callback();
      };
      description = new this.RTCSessionDescription({
        type: type,
        sdp: sdp
      });
      return this.pc.setRemoteDescription(description, success, function() {
        return _this.trigger("error", "setRemoteDescription", description);
      });
    };

    RTC.prototype.receiveOffer = function(sdp, callback) {
      if (callback == null) {
        callback = null;
      }
      console.log("[INFO] Received offer");
      return this.receive(sdp, "offer", callback);
    };

    RTC.prototype.receiveAnswer = function(sdp) {
      console.log("[INFO] Received answer");
      return this.receive(sdp, "answer");
    };

    RTC.prototype.close = function() {
      if (this.$dom2 != null) {
        this.$dom2.animate({
          opacity: 0
        });
      }
      try {
        return this.pc.close();
      } catch (e) {
        console.log("[ERROR] Error closing peerconnection");
        return console.log(e);
      } finally {
        this.pc = null;
        this.start();
      }
    };

    return RTC;

  })(Spine.Controller);

  window.RTC = RTC;

}).call(this);
// Generated by CoffeeScript 1.4.0
(function() {
  var Parser;

  Parser = (function() {

    function Parser() {}

    Parser.getRegExprResult = function(pkt, re, indexes) {
      var index, key, line, result, _i, _len, _ref;
      result = {};
      _ref = _.keys(indexes);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        key = _ref[_i];
        result[key] = void 0;
      }
      line = re.exec(pkt);
      if (line != null) {
        for (key in indexes) {
          index = indexes[key];
          if (index < line.length) {
            result[key] = line[index];
          }
        }
      }
      return result;
    };

    Parser.parse = function(pkt) {
      var message;
      console.log("[INFO] Parsing");
      console.log(pkt);
      message = {};
      _.extend(message, {
        frame: pkt
      });
      _.extend(message, this.parseFirstLine(pkt));
      _.extend(message, this.parseVias(pkt));
      _.extend(message, this.parseFrom(pkt));
      _.extend(message, this.parseTo(pkt));
      _.extend(message, this.parseRecordRoutes(pkt));
      _.extend(message, this.parseRoute(pkt));
      _.extend(message, this.parseContact(pkt));
      _.extend(message, this.parseCallId(pkt));
      _.extend(message, this.parseCSeq(pkt));
      _.extend(message, this.parseChallenge(pkt));
      _.extend(message, this.parseExpires(pkt));
      _.extend(message, this.parseContentType(pkt));
      _.extend(message, this.parseContent(pkt));
      console.log("[INFO] Parsed");
      console.log(message);
      return message;
    };

    Parser.parseFirstLine = function(pkt) {
      var code, firstLine, meth, methodRE, requestUri, responseRE, tmp;
      firstLine = pkt.split("\r\n")[0];
      responseRE = /^SIP\/2\.0 \d+/;
      if (responseRE.test(firstLine)) {
        tmp = firstLine.split(" ");
        tmp = _.rest(tmp);
        code = parseInt(tmp[0]);
        tmp = _.rest(tmp);
        meth = tmp.join(" ");
        return {
          responseCode: code,
          meth: meth,
          type: "response"
        };
      } else {
        methodRE = /(\w+)/;
        meth = methodRE.exec(firstLine)[0];
        requestUri = firstLine.split(" ")[1].split(";")[0];
        console.log("!!!!!!!!" + requestUri);
        return {
          meth: meth,
          type: "request"
        };
      }
      console.log("[WARNING] Bad request ");
      return {};
    };

    Parser.parseVias = function(pkt) {
      var via, viaRE, vias, viasWithReceived, _i, _len;
      viaRE = /Via\:/i;
      viasWithReceived = _.filter(pkt.split("\r\n"), function(line) {
        return viaRE.test(line);
      });
      vias = [];
      for (_i = 0, _len = viasWithReceived.length; _i < _len; _i++) {
        via = viasWithReceived[_i];
        vias.push(via.replace(/;received=.+/, ""));
      }
      return {
        vias: vias
      };
    };

    Parser.parseRecordRoutes = function(pkt) {
      var recordRouteRE, recordRoutes;
      recordRouteRE = /Record-Route\:/i;
      recordRoutes = _.filter(pkt.split("\r\n"), function(line) {
        return recordRouteRE.test(line);
      });
      return {
        recordRoutes: recordRoutes
      };
    };

    Parser.parseFrom = function(pkt) {
      var lineFromRE;
      lineFromRE = /From:(\s?".+"\s?)?\s<?sips?:((.+)@[A-z0-9\.]+)>?(;tag=(.+))?/i;
      return this.getRegExprResult(pkt, lineFromRE, {
        from: 2,
        ext: 3,
        fromTag: 5
      });
    };

    Parser.parseTo = function(pkt) {
      var lineToRE;
      lineToRE = /To:(\s?".+"\s?)?\s<?sips?:((.+)@[A-z0-9\.]+)>?(;tag=(.+))?/i;
      return this.getRegExprResult(pkt, lineToRE, {
        to: 2,
        ext2: 3,
        toTag: 5
      });
    };

    Parser.parseCallId = function(pkt) {
      var lineCallIdRE;
      lineCallIdRE = /Call-ID:\s(.+)/i;
      return this.getRegExprResult(pkt, lineCallIdRE, {
        callId: 1
      });
    };

    Parser.parseRoute = function(pkt) {
      var line, lineRoute, route, tmp, _i, _len, _ref;
      lineRoute = /Route\:/i;
      route = "";
      _ref = pkt.split('\r\n');
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        line = _ref[_i];
        if (lineRoute.test(line)) {
          tmp = line.split(': ');
          route += tmp[1] + "\r\nRoute: ";
        }
      }
      route = route.slice(0, -9);
      return {
        route: route
      };
    };

    Parser.parseContact = function(pkt) {
      var contactRE, gruuRE, result;
      contactRE = /Contact\:\s<(.*)>/g;
      gruuRE = /pub\-gruu=\"(.+?)\"/;
      result = this.getRegExprResult(pkt, contactRE, {
        contact: 1
      });
      return _.extend(result, this.getRegExprResult(pkt, gruuRE, {
        gruu: 1
      }));
    };

    Parser.parseCSeq = function(pkt) {
      var CSeqRE, cseq;
      CSeqRE = /CSeq\:\s(\d+)\s(.+)/gi;
      cseq = this.getRegExprResult(pkt, CSeqRE, {
        number: 1,
        meth: 2
      });
      cseq.number = parseInt(cseq.number);
      return {
        cseq: cseq
      };
    };

    Parser.parseChallenge = function(pkt) {
      var line, lineRe, nonce, nonceRe, realm, realmRe;
      lineRe = /^WWW-Authenticate\:.+$|^Proxy-Authenticate\:.+$/m;
      realmRe = /realm="(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}|(([a-z]+\.)+[a-z]{2,3})|(\w+))"/;
      nonceRe = /nonce="(.{4,})"/;
      line = lineRe.exec(pkt);
      if (line != null) {
        line = line[0];
        realm = realmRe.exec(line)[1];
        nonce = nonceRe.exec(line)[1];
      }
      return {
        realm: realm,
        nonce: nonce
      };
    };

    Parser.parseExpires = function(pkt) {
      var expiresRE;
      expiresRE = /expires=(\d{1,4})/;
      return this.getRegExprResult(pkt, expiresRE, {
        proposedExpires: 1
      });
    };

    Parser.parseContentType = function(pkt) {
      var contentTypeRE;
      contentTypeRE = /Content-Type: (.*)/i;
      return this.getRegExprResult(pkt, contentTypeRE, {
        contentType: 1
      });
    };

    Parser.parseContent = function(pkt) {
      return {
        content: (pkt.split("\r\n\r\n"))[1]
      };
    };

    return Parser;

  })();

  window.Parser = Parser;

}).call(this);
// Generated by CoffeeScript 1.4.0
(function() {
  var SipTransaction,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  SipTransaction = (function() {

    function SipTransaction(args) {
      this.set = __bind(this.set, this);

      var _base, _base1, _base2, _base3, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9;
      this.set(args);
      if ((_ref = this.domainName) == null) {
        this.domainName = "" + (this.randomString(12)) + ".invalid";
      }
      if ((_ref1 = this.IP) == null) {
        this.IP = this.randomIP();
      }
      if ((_ref2 = this.branchPad) == null) {
        this.branchPad = this.randomString(30);
      }
      if (!(this.cseq != null)) {
        this.cseq = {};
        if ((_ref3 = (_base = this.cseq).number) == null) {
          _base.number = _.random(0, 1000);
        }
        if ((_ref4 = (_base1 = this.cseq).meth) == null) {
          _base1.meth = this.meth;
        }
        if ((_ref5 = (_base2 = this.cseq).meth) == null) {
          _base2.meth = "";
        }
      }
      if ((_ref6 = this.fromTag) == null) {
        this.fromTag = this.randomString(20);
      }
      if ((_ref7 = this.toTag) == null) {
        this.toTag = this.randomString(20);
      }
      if ((_ref8 = this.callId) == null) {
        this.callId = this.randomString(16);
      }
      this.regid = 1;
      if ((_ref9 = (_base3 = SipTransaction.prototype).uuid) == null) {
        _base3.uuid = this.getUuid();
      }
    }

    SipTransaction.prototype.set = function(args) {
      var key, value, _results;
      _results = [];
      for (key in args) {
        value = args[key];
        _results.push(this[key] = value);
      }
      return _results;
    };

    SipTransaction.prototype.randomString = function(n, hex) {
      var array, char, limit, string, _i, _len;
      if (hex == null) {
        hex = false;
      }
      if (hex) {
        string = Math.random().toString(16).slice(2);
      } else {
        string = Math.random().toString(32).slice(2);
        string = string.concat(Math.random().toString(32).toUpperCase().slice(2));
      }
      array = _.shuffle(string.split(""));
      string = "";
      for (_i = 0, _len = array.length; _i < _len; _i++) {
        char = array[_i];
        string += char;
      }
      limit = Math.min(string.length, n);
      string = string.slice(0, limit);
      while (string.length < n) {
        string += this.randomString(n - string.length, hex);
      }
      return string.slice(0, n);
    };

    SipTransaction.prototype.getUuid = function() {
      if (localStorage["uuid"] === null || localStorage["uuid"] === void 0) {
        localStorage["uuid"] = "" + (this.randomString(3, true)) + "-" + (this.randomString(4, true)) + "-" + (this.randomString(8, true));
      }
      this.uuid = localStorage["uuid"];
      this.getUuid = function() {
        return this.uuid;
      };
      return this.uuid;
    };

    SipTransaction.prototype.randomIP = function() {
      var array, i, _i;
      array = [];
      for (i = _i = 0; _i <= 3; i = ++_i) {
        array.push(_.random(1, 255));
      }
      return array.join('.');
    };

    return SipTransaction;

  })();

  window.SipTransaction = SipTransaction;

}).call(this);
// Generated by CoffeeScript 1.4.0
(function() {
  var SipStack,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  SipStack = (function(_super) {

    __extends(SipStack, _super);

    SipStack.prototype.addTransaction = function(transaction) {
      return this._transactions[transaction.meth] = transaction;
    };

    SipStack.prototype.getTransaction = function(meth) {
      return this._transactions[meth];
    };

    SipStack.prototype.addInstantMessage = function(message) {
      return this._instantMessages[message.cseq] = message;
    };

    SipStack.prototype.getInstantMessage = function(cseq) {
      return this._instantMessages[cseq];
    };

    SipStack.prototype.info = function() {
      var message, others;
      message = arguments[0], others = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      console.log("[INFO]" + message);
      return this.trigger("info", message, others);
    };

    SipStack.prototype.warning = function() {
      var message, others;
      message = arguments[0], others = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      console.log("[WARNING] " + message);
      return this.trigger("warning", message, others);
    };

    SipStack.prototype.error = function() {
      var message, others;
      message = arguments[0], others = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      console.log("[ERROR] " + message);
      return this.trigger("error", message, others);
    };

    SipStack.prototype.states = ["OFFLINE", "REGISTERING (before challenge)", "REGISTERING (after challenge)", "REGISTERED", "INCOMING CALL", "CALLING", "RINGING", "CALL STABLISHED (caller)", "CALL STABLISHED (callee)", "HANGING", "CANCELLING"];

    SipStack.prototype.responsePhrases = {
      100: "Trying",
      180: "Ringing",
      200: "OK",
      202: "Accepted",
      400: "Bad Request",
      401: "Unauthorized",
      403: "Forbidden",
      404: "Not Found (User not found)",
      407: "Proxy Authentication Required",
      408: "Request Time Out",
      481: "Call/Transaction Does Not Exists",
      486: "Busy Here",
      488: "Not acceptable here",
      500: "Server Internal Error",
      503: "Service Unavaliable"
    };

    function SipStack() {
      this.setState = __bind(this.setState, this);

      this.sendInstantMessage = __bind(this.sendInstantMessage, this);

      this.sendWithSDP = __bind(this.sendWithSDP, this);

      this.send = __bind(this.send, this);

      this.unRegister = __bind(this.unRegister, this);

      this.reRegister = __bind(this.reRegister, this);

      this.hangup = __bind(this.hangup, this);

      this.answer = __bind(this.answer, this);

      this.call = __bind(this.call, this);

      this.register = __bind(this.register, this);

      this.createMessage = __bind(this.createMessage, this);

      this.getDigest = __bind(this.getDigest, this);

      this.getInstantMessage = __bind(this.getInstantMessage, this);

      this.addInstantMessage = __bind(this.addInstantMessage, this);

      this.getTransaction = __bind(this.getTransaction, this);

      this.addTransaction = __bind(this.addTransaction, this);

      var _ref, _ref1,
        _this = this;
      SipStack.__super__.constructor.apply(this, arguments);
      this.rtc = new RTC({
        mediaElements: this.mediaElements,
        mediaConstraints: this.mediaConstraints
      });
      this.sipServer = this.server.ip;
      this.port = this.server.port;
      this.path = this.server.path || "";
      this.transport = this.server.transport || "ws";
      this._transactions = {};
      this._instantMessages = {};
      this.setState(0);
      if ((_ref = this.hackViaTCP) == null) {
        this.hackViaTCP = false;
      }
      if ((_ref1 = this.hackIpContact) == null) {
        this.hackIpContact = false;
      }
      this.websocket = new WebSocket("" + this.transport + "://" + this.sipServer + ":" + this.port + this.path, "sip");
      console.log("" + this.transport + "://" + this.sipServer + ":" + this.port + this.path);
      this.info("websocket created");
      this.websocket.onopen = function(evt) {
        _this.info("websocket opened");
        return _this.onopen();
      };
      this.websocket.onmessage = function(evt) {
        var ack, busy, instantMessage, message, ok, register, ringing, transaction, _ref2;
        message = Parser.parse(evt.data);
        _this.info("Input message", message);
        if ((_this.state > 2) && (message.cseq.meth === "REGISTER")) {
          switch (message.responseCode) {
            case 200:
              _this.info("RE-REGISTER answer", message);
              return;
            case 401:
              register = _this.getTransaction("REGISTER");
              register.vias = message.vias;
              _.extend(register, _.pick(message, "realm", "nonce", "toTag"));
              register.auth = true;
              _this.send(_this.createMessage(register));
              return;
          }
        }
        if (_this.state > 2 && message.cseq.meth === "MESSAGE") {
          switch (message.meth) {
            case "MESSAGE":
              console.log("[MESSAGE] " + message.content);
              instantMessage = {
                from: message.ext,
                to: message.ext2,
                content: message.content
              };
              _this.trigger("instant-message", instantMessage);
              _this.send(_this.createMessage(new SipTransaction(_.extend(message, {
                meth: "OK"
              }))));
              break;
            case "OK":
              console.log("[MESSAGE] OK");
              delete _this.getInstantMessage(message.cseq);
              break;
            default:
              instantMessage = _this.getInstantMessage(message.cseq);
              _.extend(instantMessage, _.pick(message, "realm", "nonce", "toTag"));
              instantMessage.proxyAuth = message.responseCode === 407;
              instantMessage.auth = message.responseCode === 401;
              _this.send(_this.createMessage(instantMessage));
          }
          return;
        }
        if ((3 < (_ref2 = _this.state) && _ref2 < 9)) {
          if (message.meth === "INVITE") {
            _this.info("Another incoming call (BUSY)", message);
            busy = _.clone(message);
            _.extend(busy, {
              meth: "Busy here"
            });
            _this.send(_this.createMessage(busy));
            return;
          }
        }
        switch (_this.state) {
          case 1:
            transaction = _this.getTransaction("REGISTER");
            transaction.vias = message.vias;
            switch (message.responseCode) {
              case 200:
                _this.info("Register successful", message);
                _this.setState(3, message);
                transaction.expires = message.proposedExpires / 2;
                _this.t = setInterval(_this.reRegister, transaction.expires * 1000);
                return _this.gruu = message.gruu;
              case 401:
                _this.setState(2, message);
                _.extend(transaction, _.pick(message, "realm", "nonce", "toTag"));
                transaction.cseq.number += 1;
                transaction.auth = true;
                return _this.send(_this.createMessage(transaction));
              default:
                return _this.warning("Unexpected message", message);
            }
            break;
          case 2:
            transaction = _this.getTransaction("REGISTER");
            transaction.vias = message.vias;
            switch (message.responseCode) {
              case 200:
                _this.info("Successful register", message);
                _this.setState(3, message);
                transaction.expires = message.proposedExpires / 2;
                _this.t = setInterval(_this.reRegister, transaction.expires * 1000);
                return _this.gruu = message.gruu;
              case 401:
                _this.info("Unsusccessful register", message);
                return _this.setState(0, message);
              default:
                _this.warning("Unexpected message", message);
                return _this.setState(0, message);
            }
            break;
          case 3:
            switch (message.type) {
              case "request":
                switch (message.meth) {
                  case "INVITE":
                    transaction = new SipTransaction(message);
                    _this.addTransaction(transaction);
                    ringing = _.clone(transaction);
                    ringing.meth = "Ringing";
                    _this.send(_this.createMessage(ringing));
                    return _this.setState(6, message);
                  default:
                    return _this.warning("Unexpected request", message);
                }
                break;
              case "response":
                return _this.warning("Unexpected response", message);
              default:
                return _this.warning("Unexpected message", message);
            }
            break;
          case 4:
            switch (message.meth) {
              case "CANCEL":
                _this.info("Call ended");
                return _this.setState(3, message);
              case "ACK":
                return _this.setState(8, message);
              default:
                return _this.warning("Unexpected message", message);
            }
            break;
          case 5:
            switch (message.type) {
              case "response":
                if (_this.responsePhrases[message.responseCode]) {
                  _this.info(_this.responsePhrases[message.responseCode], message);
                } else {
                  _this.warning("Unexpected response", message);
                  return;
                }
                switch (message.responseCode) {
                  case 180:
                    return _this.getTransaction("INVITE").contact = message.contact;
                  case 200:
                    _this.info("Establishing call", message);
                    _this.rtc.receiveAnswer(message.content);
                    _.extend(_this.getTransaction("INVITE"), _.pick(message, "from", "to", "fromTag", "toTag"));
                    ack = new SipTransaction(message);
                    ack.meth = "ACK";
                    _this.send(_this.createMessage(ack));
                    return _this.setState(7, message);
                  case 401:
                  case 407:
                    if (message.responseCode === 401) {
                      _this.info("AUTH", message);
                    }
                    if (message.responseCode === 407) {
                      _this.info("PROXY-AUTH", message);
                    }
                    ack = new SipTransaction(_.omit(message, "nonce"));
                    ack.meth = "ACK";
                    ack.vias = message.vias;
                    _this.send(_this.createMessage(ack));
                    transaction = _this.getTransaction("INVITE");
                    transaction.vias = message.vias;
                    transaction.cseq.number += 1;
                    _.extend(transaction, _.pick(message, "realm", "nonce", "toTag"));
                    transaction.auth = message.responseCode === 401;
                    transaction.proxyAuth = message.responseCode === 407;
                    console.log(transaction);
                    message = _this.createMessage(transaction);
                    return _this.sendWithSDP(message, "offer", null);
                  default:
                    if (400 <= message.responseCode) {
                      ack = new SipTransaction(_.omit(message, "nonce"));
                      ack.meth = "ACK";
                      ack.vias = message.vias;
                      _this.send(_this.createMessage(ack));
                      _this.setState(3);
                      return delete _this.getTransaction("INVITE");
                    }
                }
                break;
              case "request":
                switch (message.meth) {
                  case "BYE":
                    _this.info("Call ended", message);
                    ok = new SipTransaction(message);
                    ok.meth = "OK";
                    _this.send(_this.createMessage(ok));
                    return _this.setState(3, message);
                  default:
                    return _this.warning("Unexpected request", message);
                }
            }
            break;
          case 6:
            _this.info("RINGING", message);
            switch (message.meth) {
              case "CANCEL":
                _this.info("Call ended", message);
                ok = new SipTransaction(message);
                ok.meth = "OK";
                _this.send(_this.createMessage(ok));
                return _this.setState(3, message);
            }
            break;
          case 7:
          case 8:
            _this.info("CALL ESTABLISHED", message);
            switch (message.meth) {
              case "BYE":
                _this.info("Call ended", message);
                transaction = new SipTransaction(message);
                transaction.vias = message.vias;
                transaction.meth = "OK";
                ok = _.clone(transaction);
                _this.send(_this.createMessage(ok));
                _this.rtc.close();
                return _this.setState(3, message);
            }
            break;
          case 9:
            _this.info("HANGING UP", message);
            _this.info("Call ended", message);
            _this.rtc.close();
            return _this.setState(3, message);
          case 10:
            _this.info("HANGING UP", message);
            _this.info("Call ended", message);
            return _this.setState(3, message);
        }
      };
      this.websocket.onclose = function(evt) {
        return _this.info("websocket closed");
      };
    }

    SipStack.prototype.getDigest = function(transaction) {
      var ha1, ha2, sol;
      console.log(transaction);
      ha1 = CryptoJS.MD5("" + transaction.ext + ":" + transaction.realm + ":" + transaction.pass);
      ha2 = CryptoJS.MD5("" + transaction.meth + ":" + transaction.requestUri);
      sol = CryptoJS.MD5("" + ha1 + ":" + transaction.nonce + ":" + ha2);
      return sol;
    };

    SipStack.prototype.createMessage = function(transaction) {
      var address, authUri, data, opaque, rr, _i, _len, _ref;
      transaction = new SipTransaction(transaction);
      transaction.uri = "sip:" + transaction.ext + "@" + (this.domain || this.sipServer);
      transaction.uri2 = "sip:" + transaction.ext2 + "@" + (transaction.domain2 || this.sipServer);
      transaction.targetUri = "sip:" + this.sipServer;
      if (transaction.meth === "BYE") {
        transaction.cseq.number += 1;
      }
      switch (transaction.meth) {
        case "REGISTER":
          transaction.requestUri = transaction.targetUri;
          data = "" + transaction.meth + " " + transaction.requestUri + " SIP/2.0\r\n";
          break;
        case "INVITE":
        case "MESSAGE":
        case "CANCEL":
          transaction.requestUri = transaction.uri2;
          data = "" + transaction.meth + " " + transaction.requestUri + " SIP/2.0\r\n";
          break;
        case "ACK":
        case "BYE":
          transaction.requestUri = transaction.contact || transaction.uri2;
          data = "" + transaction.meth + " " + transaction.requestUri + " SIP/2.0\r\n";
          break;
        case "OK":
          data = "SIP/2.0 200 OK\r\n";
          break;
        case "Ringing":
          data = "SIP/2.0 180 Ringing\r\n";
          break;
        case "Busy here":
          data = "SIP/2.0 486 Busy Here\r\n";
      }
      if ((transaction.cseq.meth === "INVITE" && transaction.meth !== "ACK") && (_.isArray(transaction.recordRoutes))) {
        _ref = transaction.recordRoutes;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          rr = _ref[_i];
          data += rr + "\r\n";
        }
      } else {
        switch (transaction.meth) {
          case "REGISTER":
          case "INVITE":
          case "MESSAGE":
          case "CANCEL":
            data += "Route: <sip:" + this.sipServer + ":" + this.port + ";transport=ws;lr>\r\n";
            break;
          case "ACK":
          case "OK":
          case "BYE":
            if (transaction.cseq.meth !== "MESSAGE") {
              data += "Route: <sip:" + this.sipServer + ":" + this.port + ";transport=ws;lr=on>\r\n";
            }
        }
      }
      if (_.isArray(transaction.vias)) {
        data += (transaction.vias.join("\r\n")) + "\r\n";
      } else {
        data += "Via: SIP/2.0/" + ((this.hackViaTCP && "TCP") || this.transport.toUpperCase()) + " " + transaction.domainName + ";branch=z9hG4bK" + transaction.branchPad + "\r\n";
      }
      data += "From: " + transaction.uri + ";tag=" + transaction.fromTag + "\r\n";
      switch (transaction.meth) {
        case "REGISTER":
          data += "To: " + transaction.uri + "\r\n";
          break;
        case "INVITE":
        case "MESSAGE":
        case "CANCEL":
          data += "To: " + transaction.uri2 + "\r\n";
          break;
        default:
          data += "To: " + transaction.uri2 + ";tag=" + transaction.toTag + "\r\n";
      }
      data += "Call-ID: " + transaction.callId + "\r\n";
      switch (transaction.meth) {
        case "OK":
          data += "CSeq: " + transaction.cseq.number + " " + (transaction.cseq.meth || transaction.meth) + "\r\n";
          break;
        case "Ringing":
          data += "CSeq: " + transaction.cseq.number + " " + transaction.cseq.meth + "\r\n";
          break;
        case "ACK":
          data += "CSeq: " + transaction.cseq.number + " ACK\r\n";
          break;
        case "Busy here":
          data += "CSeq: " + transaction.cseq.number + " INVITE\r\n";
          break;
        default:
          data += "CSeq: " + transaction.cseq.number + " " + transaction.meth + "\r\n";
      }
      data += "Max-Forwards: 70\r\n";
      if (transaction.meth === "REGISTER" || transaction.meth === "INVITE") {
        data += "Allow: INVITE, ACK, CANCEL, BYE, MESSAGE\r\n";
      }
      data += "Supported: path, outbound, gruu\r\n";
      data += "User-Agent: QoffeeSIP 0.4\r\n";
      address = (this.hackIpContact && transaction.IP) || transaction.domainName;
      switch (transaction.meth) {
        case "Ringing":
          if (this.gruu) {
            data += "Contact: <sip:" + transaction.ext2 + "@" + address + ";gr=urn:uuid:" + transaction.uuid + ">\r\n";
          } else {
            data += "Contact: <sip:" + transaction.ext2 + "@" + address + ";transport=ws>\r\n";
          }
          break;
        case "OK":
          if (transaction.cseq.meth === "INVITE") {
            if (this.gruu) {
              data += "Contact: <sip:" + transaction.ext2 + "@" + address + ";gr=urn:uuid:" + transaction.uuid + ">\r\n";
            } else {
              data += "Contact: <sip:" + transaction.ext2 + "@" + address + ";transport=ws>\r\n";
            }
          }
          break;
        case "REGISTER":
          data += "Contact: <sip:" + transaction.ext + "@" + address + ";transport=ws>";
          break;
        case "INVITE":
          if (this.gruu) {
            data += "Contact: <" + this.gruu + ";ob>\r\n";
          } else {
            data += "Contact: <sip:" + transaction.ext + "@" + address + ";transport=ws;ob>\r\n";
          }
      }
      switch (transaction.meth) {
        case "REGISTER":
          data += ";reg-id=" + transaction.regid;
          data += ";+sip.instance=\"<urn:uuid:" + transaction.uuid + ">\"";
          if (transaction.exp) {
            data += ";expires=\"" + transaction.exp + "\"";
          }
          data += "\r\n";
      }
      if (transaction.nonce != null) {
        opaque = "";
        if (transaction.opaque != null) {
          opaque = "opaque=\"" + transaction.opaque + "\", ";
        }
        if (transaction.auth === true) {
          if (transaction.cseq.meth === "REGISTER") {
            authUri = transaction.targetUri;
          } else {
            authUri = transaction.uri2;
          }
          data += "Authorization:";
        }
        if (transaction.proxyAuth === true) {
          authUri = transaction.uri2;
          data += "Proxy-Authorization:";
        }
        transaction.response = this.getDigest(transaction);
        data += " Digest username=\"" + transaction.ext + "\",realm=\"" + transaction.realm + "\",";
        data += "nonce=\"" + transaction.nonce + "\"," + opaque + "uri=\"" + authUri + "\",response=\"" + transaction.response + "\",algorithm=MD5\r\n";
      }
      switch (transaction.meth) {
        case "INVITE":
        case "OK":
          if (transaction.cseq.meth === "INVITE") {
            data += "Content-Type: application/sdp\r\n";
          } else {
            data += "Content-Length: 0\r\n\r\n";
          }
          break;
        case "MESSAGE":
          data += "Content-Length: " + (transaction.content.length || 0) + "\r\n";
          data += "Content-Type: text/plain\r\n\r\n";
          data += transaction.content;
          break;
        default:
          data += "Content-Length: 0\r\n\r\n";
      }
      return data;
    };

    SipStack.prototype.register = function(ext, pass, domain) {
      var message, transaction;
      this.ext = ext;
      this.pass = pass;
      this.domain = domain;
      transaction = new SipTransaction({
        meth: "REGISTER",
        ext: this.ext,
        domain: this.domain,
        pass: this.pass || ""
      });
      this.addTransaction(transaction);
      this.setState(1, transaction);
      message = this.createMessage(transaction);
      return this.send(message);
    };

    SipStack.prototype.call = function(ext2, domain2) {
      var message, register, transaction;
      register = this.getTransaction("REGISTER");
      transaction = new SipTransaction({
        meth: "INVITE",
        ext: register.ext,
        pass: register.pass,
        ext2: ext2,
        domain2: domain2
      });
      this.addTransaction(transaction);
      this.setState(5, transaction);
      message = this.createMessage(transaction);
      return this.sendWithSDP(message, "offer", null);
    };

    SipStack.prototype.answer = function() {
      var ok;
      ok = _.clone(this.getTransaction("INVITE"));
      ok.meth = "OK";
      this.sendWithSDP(this.createMessage(ok), "answer", this.getTransaction("INVITE").content);
      return this.setState(4, ok);
    };

    SipStack.prototype.hangup = function() {
      var busy, bye, cancel, invite, swap;
      swap = function(d, p1, p2) {
        var _ref;
        return _ref = [d[p2], d[p1]], d[p1] = _ref[0], d[p2] = _ref[1], _ref;
      };
      invite = this.getTransaction("INVITE");
      switch (this.state) {
        case 5:
          cancel = new SipTransaction({
            meth: "CANCEL",
            ext: (this.getTransaction("REGISTER")).ext,
            ext2: invite.ext2
          });
          _.extend(cancel, _.pick(invite, "callId", "fromTag", "from", "to", "cseq", "domainName", "branchPad"));
          this.send(this.createMessage(cancel));
          return this.setState(10);
        case 6:
          busy = new SipTransaction({
            meth: "Busy here",
            ext: (this.getTransaction("REGISTER")).ext,
            ext2: invite.ext
          });
          _.extend(busy, _.pick(invite, "callId", "fromTag", "from", "to", "cseq", "domainName", "branchPad", "vias"));
          this.send(this.createMessage(busy));
          return this.setState(9, busy);
        case 7:
          bye = new SipTransaction({
            meth: "BYE",
            ext: (this.getTransaction("REGISTER")).ext,
            ext2: invite.ext2
          });
          _.extend(bye, _.pick(invite, "callId", "contact", "fromTag", "toTag", "from", "to", "cseq"));
          this.send(this.createMessage(bye));
          this.addTransaction(bye);
          this.setState(9, bye);
          return this.rtc.close();
        case 8:
          bye = new SipTransaction({
            meth: "BYE",
            ext: (this.getTransaction("REGISTER")).ext,
            ext2: invite.ext
          });
          _.extend(bye, _.pick(invite, "callId", "contact", "fromTag", "toTag", "from", "to", "cseq", "vias"));
          swap(bye, "fromTag", "toTag");
          swap(bye, "from", "to");
          this.send(this.createMessage(bye));
          this.addTransaction(bye);
          this.setState(9, bye);
          return this.rtc.close();
      }
    };

    SipStack.prototype.reRegister = function() {
      return this.send(this.createMessage(this.getTransaction("REGISTER")));
    };

    SipStack.prototype.unRegister = function() {
      var message, transaction;
      transaction = this.getTransaction("REGISTER");
      transaction.expires = 0;
      clearInterval(t);
      message = this.createMessage(transaction);
      this.send(message);
      return this.setState(0, message);
    };

    SipStack.prototype.send = function(data) {
      if (data != null) {
        console.log("[INFO] Sending data", data);
        try {
          return this.websocket.send(data);
        } catch (e) {
          return this.error("websocket", e);
        }
      } else {
        return console.log("[INFO] Not sending data");
      }
    };

    SipStack.prototype.sendWithSDP = function(data, type, sdp) {
      var _this = this;
      this.rtc.bind("sdp", function(sdp) {
        data += "Content-Length: " + sdp.length + "\r\n\r\n";
        data += sdp;
        _this.send(data);
        return _this.rtc.unbind("sdp");
      });
      if (type === "offer") {
        this.rtc.createOffer();
      }
      if (type === "answer") {
        return this.rtc.receiveOffer(sdp, function() {
          return _this.rtc.createAnswer();
        });
      }
    };

    SipStack.prototype.sendInstantMessage = function(ext2, text) {
      var message;
      message = new SipTransaction({
        meth: "MESSAGE",
        ext: this.ext,
        pass: (this.getTransaction("REGISTER")).pass,
        ext2: ext2,
        content: text
      });
      this.addInstantMessage(message);
      return this.send(this.createMessage(message));
    };

    SipStack.prototype.setState = function(state, data) {
      this.state = state;
      console.log("[INFO] New state  " + this.states[this.state] + ("(" + this.state + ")"));
      return this.trigger("new-state", this.state, data);
    };

    return SipStack;

  })(Spine.Controller);

  window.SipStack = SipStack;

}).call(this);
// Generated by CoffeeScript 1.4.0
(function() {
  var API,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  API = (function(_super) {

    __extends(API, _super);

    function API(options) {
      this.off = __bind(this.off, this);

      this.on = __bind(this.on, this);

      this.chat = __bind(this.chat, this);

      this.unregister = __bind(this.unregister, this);

      this.hangup = __bind(this.hangup, this);

      this.answer = __bind(this.answer, this);

      this.call = __bind(this.call, this);

      this.register = __bind(this.register, this);

      var args;
      API.__super__.constructor.apply(this, arguments);
      args = {
        server: this.server,
        hackViaTCP: this.hackViaTCP,
        hackIpContact: this.hackIpContact,
        mediaConstraints: this.mediaConstraints,
        mediaElements: this.mediaElements,
        onopen: this.onopen || function() {
          return false;
        }
      };
      this.sipStack = new SipStack(args);
    }

    API.prototype.register = function(ext, pass, domain) {
      return this.sipStack.register(ext, pass, domain);
    };

    API.prototype.call = function(ext, domain) {
      return this.sipStack.call(ext, domain);
    };

    API.prototype.answer = function() {
      return this.sipStack.answer();
    };

    API.prototype.hangup = function() {
      return this.sipStack.hangup();
    };

    API.prototype.unregister = function() {
      return this.sipStack.hangup();
    };

    API.prototype.chat = function(ext, content) {
      return this.sipStack.sendInstantMessage(ext, content);
    };

    API.prototype.on = function(eventName, callback) {
      return this.sipStack.bind(eventName, callback);
    };

    API.prototype.off = function(eventName, callback) {
      if (callback != null) {
        this.sipStack.unbind(eventName, callback);
      }
      if (!(callback != null)) {
        return this.sipStack.unbind(eventName, callback);
      }
    };

    return API;

  })(Spine.Controller);

  window.API = API;

}).call(this);
;
