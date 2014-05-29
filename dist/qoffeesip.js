/*
  Temasys extended adapter
  version: 0.8.624
*/

var RTCPeerConnection = null;
var getUserMedia = null;
var attachMediaStream = null;
var reattachMediaStream = null;
var webrtcDetectedBrowser = null;
var webrtcDetectedVersion = null;

function trace(text) {
  // This function is used for logging.
  if (text[text.length - 1] == '\n') {
    text = text.substring(0, text.length - 1);
  }
  console.log(/*(performance.now() / 1000).toFixed(3) + ": " + */ text); //performance not available on every browser
}

function maybeFixConfiguration(pcConfig) {
  if (pcConfig === null) {
    return;
  }
  for (var i = 0; i < pcConfig.iceServers.length; i++) {
    if (pcConfig.iceServers[i].hasOwnProperty('urls')){
      pcConfig.iceServers[i]['url'] = pcConfig.iceServers[i]['urls'];
      delete pcConfig.iceServers[i]['urls'];
    }
  }
}

var TemPageId = Math.random().toString(36).slice(2); // Unique identifier of each opened page

TemPrivateWebRTCReadyCb = function() {
  // webRTC readu Cb, should only be called once. 
  // Need to prevent Chrome + plugin form calling WebRTCReadyCb twice
  arguments.callee.StaticWasInit = arguments.callee.StaticWasInit || 1;
  if (arguments.callee.StaticWasInit == 1)
    if (typeof WebRTCReadyCb === 'function')
      WebRTCReadyCb();
  arguments.callee.StaticWasInit++;

  // WebRTCReadyCb is callback function called when the browser is webrtc ready
  // this can be because of the browser or because of the plugin
  // Override WebRTCReadyCb and use it to do whatever you need to do when the
  // page is ready

}; 
function plugin0() {
  return document.getElementById('plugin0');
}
plugin = plugin0; // use this function whenever you want to call the plugin

// !!! DO NOT OVERRIDE THIS FUNCTION !!!
// This function will be called when plugin is ready
// it sends necessary details to the plugin. 
// If you need to do something once the page/plugin is ready, override
// TemPrivateWebRTCReadyCb instead.
// This function is not in the IE/Safari condition brackets so that
// TemPluginLoaded function might be called on Chrome/Firefox
function TemInitPlugin0() {
  trace("plugin loaded");
  plugin().setPluginId(TemPageId, "plugin0");
  plugin().setLogFunction(console);
  TemPrivateWebRTCReadyCb();
}

if (navigator.mozGetUserMedia) {
  console.log("This appears to be Firefox");

  webrtcDetectedBrowser = "firefox";

  webrtcDetectedVersion =
  parseInt(navigator.userAgent.match(/Firefox\/([0-9]+)\./)[1], 10);

  // The RTCPeerConnection object.
  var RTCPeerConnection = function(pcConfig, pcConstraints) {
    // .urls is not supported in FF yet.
    maybeFixConfiguration(pcConfig);
    return new mozRTCPeerConnection(pcConfig, pcConstraints);
  }

  // The RTCSessionDescription object.
  RTCSessionDescription = mozRTCSessionDescription;

  // The RTCIceCandidate object.
  RTCIceCandidate = mozRTCIceCandidate;

  // Get UserMedia (only difference is the prefix).
  // Code from Adam Barth.
  getUserMedia = navigator.mozGetUserMedia.bind(navigator);
  navigator.getUserMedia = getUserMedia;

  // Creates iceServer from the url for FF.
  createIceServer = function(url, username, password) {
    var iceServer = null;
    var url_parts = url.split(':');
    if (url_parts[0].indexOf('stun') === 0) {
      // Create iceServer with stun url.
      iceServer = { 'url': url };
    } else if (url_parts[0].indexOf('turn') === 0) {
      if (webrtcDetectedVersion < 27) {
        // Create iceServer with turn url.
        // Ignore the transport parameter from TURN url for FF version <=27.
        var turn_url_parts = url.split("?");
        // Return null for createIceServer if transport=tcp.
        if (turn_url_parts.length === 1 ||
          turn_url_parts[1].indexOf('transport=udp') === 0) {
          iceServer = {'url': turn_url_parts[0],
        'credential': password,
        'username': username};
      }
    } else {
        // FF 27 and above supports transport parameters in TURN url,
        // So passing in the full url to create iceServer.
        iceServer = {'url': url,
        'credential': password,
        'username': username};
      }
    }
    return iceServer;
  };

  createIceServers = function(urls, username, password) {
    var iceServers = [];
    // Use .url for FireFox.
    for (i = 0; i < urls.length; i++) {
      var iceServer = createIceServer(urls[i],
        username,
        password);
      if (iceServer !== null) {
        iceServers.push(iceServer);
      }
    }
    return iceServers;
  }

  // Attach a media stream to an element.
  attachMediaStream = function(element, stream) {
    console.log("Attaching media stream");
    element.mozSrcObject = stream;
    element.play();

    return element;
  };

  reattachMediaStream = function(to, from) {
    console.log("Reattaching media stream");
    to.mozSrcObject = from.mozSrcObject;
    to.play();

    return to;
  };

  // Fake get{Video,Audio}Tracks
  if (!MediaStream.prototype.getVideoTracks) {
    MediaStream.prototype.getVideoTracks = function() {
      return [];
    };
  }

  if (!MediaStream.prototype.getAudioTracks) {
    MediaStream.prototype.getAudioTracks = function() {
      return [];
    };
  }

  TemPrivateWebRTCReadyCb();
} else if (navigator.webkitGetUserMedia) {
  console.log("This appears to be Chrome");

  webrtcDetectedBrowser = "chrome";
  webrtcDetectedVersion =
  parseInt(navigator.userAgent.match(/Chrom(e|ium)\/([0-9]+)\./)[2], 10);

  // Creates iceServer from the url for Chrome M33 and earlier.
  createIceServer = function(url, username, password) {
    var iceServer = null;
    var url_parts = url.split(':');
    if (url_parts[0].indexOf('stun') === 0) {
      // Create iceServer with stun url.
      iceServer = { 'url': url };
    } else if (url_parts[0].indexOf('turn') === 0) {
      // Chrome M28 & above uses below TURN format.
      iceServer = {'url': url,
      'credential': password,
      'username': username};
    }
    return iceServer;
  };

  // Creates iceServers from the urls for Chrome M34 and above.
  createIceServers = function(urls, username, password) {
    var iceServers = [];
    if (webrtcDetectedVersion >= 34) {
      // .urls is supported since Chrome M34.
      iceServers = {'urls': urls,
      'credential': password,
      'username': username };
    } else {
      for (i = 0; i < urls.length; i++) {
        var iceServer = createIceServer(urls[i],
          username,
          password);
        if (iceServer !== null) {
          iceServers.push(iceServer);
        }
      }
    }
    return iceServers;
  };

  // The RTCPeerConnection object.
  var RTCPeerConnection = function(pcConfig, pcConstraints) {
    // .urls is supported since Chrome M34.
    if (webrtcDetectedVersion < 34) {
      maybeFixConfiguration(pcConfig);
    }
    return new webkitRTCPeerConnection(pcConfig, pcConstraints);
  }

  // Get UserMedia (only difference is the prefix).
  // Code from Adam Barth.
  getUserMedia = navigator.webkitGetUserMedia.bind(navigator);
  navigator.getUserMedia = getUserMedia;

  // Attach a media stream to an element.
  attachMediaStream = function(element, stream) {
    if (typeof element.srcObject !== 'undefined') {
      element.srcObject = stream;
    } else if (typeof element.mozSrcObject !== 'undefined') {
      element.mozSrcObject = stream;
    } else if (typeof element.src !== 'undefined') {
      element.src = URL.createObjectURL(stream);
    } else {
      console.log('Error attaching stream to element.');
    }

    return element;
  };

  reattachMediaStream = function(to, from) {
    to.src = from.src;

    return to;
  };

  TemPrivateWebRTCReadyCb();
} else if (navigator.userAgent.indexOf("Safari")) { ////////////////////////////////////////////////////////////////////////
  // Note: IE is detected as Safari...
  console.log("This appears to be either Safari or IE");
  webrtcDetectedBrowser = "Safari";

  // Browser identification // TODO: move this up and use it for implementation choice
  var isOpera = !!window.opera || navigator.userAgent.indexOf(' OPR/') >= 0;
    // Opera 8.0+ (UA detection to detect Blink/v8-powered Opera)
  var isFirefox = typeof InstallTrigger !== 'undefined';   // Firefox 1.0+
  var isSafari = Object.prototype.toString.call(window.HTMLElement).indexOf('Constructor') > 0;
    // At least Safari 3+: "[object HTMLElementConstructor]"
  var isChrome = !!window.chrome && !isOpera;              // Chrome 1+
  var isIE = /*@cc_on!@*/false || !!document.documentMode; // At least IE6


  // This function detects whether or not a plugin is installed
  // Com name : the company name,
  // plugName : the plugin name
  // installedCb : callback if the plugin is detected (no argument)
  // notInstalledCb : callback if the plugin is not detected (no argument)
  function isPluginInstalled(comName, plugName, installedCb, notInstalledCb) {
    if (isChrome || isSafari || isFirefox) { // Not IE (firefox, for example)
      var pluginArray = navigator.plugins;
      for (var i = 0; i < pluginArray.length; i++) {
        if (pluginArray[i].name.indexOf(plugName) >= 0) {
          installedCb();
          return;
        }
      }
      notInstalledCb(); 
    } else if (isIE) { // We're running IE
      try {
        new ActiveXObject(comName+"."+plugName);
      } catch(e) {
        notInstalledCb();
        return;
      }
      installedCb();
    } else {
      // Unsupported
      return;
    }
  }

  // defines webrtc's JS interface according to the plugin's implementation
  function defineWebRTCInterface() { 
    // ==== UTIL FUNCTIONS ===
    function isDefined(variable) {
      return variable != null && variable != undefined;
    }

    injectPlugin = function() {
      var frag = document.createDocumentFragment();
      var temp = document.createElement('div');
      temp.innerHTML = '<object id="plugin0" type="application/x-temwebrtcplugin" width="0" height="0">'
      + '<param name="pluginId" value="plugin0" /> '
      + '<param name="onload" value="TemInitPlugin0" />'
      + '</object>';
      while (temp.firstChild) {
        frag.appendChild(temp.firstChild);
      }
      document.body.appendChild(frag);
    }
    injectPlugin();

    // END OF UTIL FUNCTIONS

    // === WEBRTC INTERFACE ===
    createIceServer = function(url, username, password) {
      var iceServer = null;
      var url_parts = url.split(':');
      if (url_parts[0].indexOf('stun') === 0) {
          // Create iceServer with stun url.
          iceServer = { 'url': url, 'hasCredentials': false};
        } else if (url_parts[0].indexOf('turn') === 0) {
          iceServer = { 'url': url,
          'hasCredentials': true,
          'credential': password,
          'username': username };
        }
        return iceServer;
      };

    createIceServers = function(urls, username, password) {  
      var iceServers = new Array();
      for (var i = 0; i < urls.length; ++i) {
        iceServers.push(createIceServer(urls[i], username, password));
      }
      return iceServers;
    }

    // The RTCSessionDescription object.
    RTCSessionDescription = function(info) {
      return plugin().ConstructSessionDescription(info.type, info.sdp);
    }

    // PEER CONNECTION
    RTCPeerConnection = function(servers, constraints) {
      var iceServers = null;
      if (servers) {
        iceServers = servers.iceServers;
        for (var i = 0; i < iceServers.length; i++) {
          if (iceServers[i].urls && !iceServers[i].url)
            iceServers[i].url = iceServers[i].urls;
          iceServers[i].hasCredentials = isDefined(iceServers[i].username) && isDefined(iceServers[i].credential);
        }
      }
      var mandatory = (constraints && constraints.mandatory) ? constraints.mandatory : null;
      var optional = (constraints && constraints.optional) ? constraints.optional : null;
      return plugin().PeerConnection(TemPageId, iceServers, mandatory, optional);
    }

    MediaStreamTrack = {};
    MediaStreamTrack.getSources = function(callback) {
      plugin().GetSources(callback);
    };

    getUserMedia = function(constraints, successCallback, failureCallback) {
      if (!constraints.audio)
        constraints.audio = false;

      plugin().getUserMedia(constraints, successCallback, failureCallback);
    };
    navigator.getUserMedia = getUserMedia;

    // Attach a media stream to an element.
    attachMediaStream = function(element, stream) {
      stream.enableSoundTracks(true);
      if (element.nodeName.toLowerCase() != "audio") {
        var elementId = element.id.length == 0 ? Math.random().toString(36).slice(2) : element.id;
        if (!element.isTemWebRTCPlugin || !element.isTemWebRTCPlugin()) {
          var frag = document.createDocumentFragment();
          var temp = document.createElement('div');
          var classHTML = element.className ? 'class="' + element.className + '" ' :  "";
          temp.innerHTML = '<object id="' + elementId + '" '
          + classHTML
          + 'type="application/x-temwebrtcplugin">'
          + '<param name="pluginId" value="' + elementId + '" /> '
          + '<param name="pageId" value="' + TemPageId + '" /> '
          + '<param name="streamId" value="' + stream.id + '" /> '
          + '</object>';
          while (temp.firstChild) {
            frag.appendChild(temp.firstChild);
          }

          var rectObject = element.getBoundingClientRect();
          element.parentNode.insertBefore(frag, element);
          frag = document.getElementById(elementId);
          frag.width = rectObject.width + "px"; 
          frag.height = rectObject.height + "px";
          element.parentNode.removeChild(element);

        } else {
          var children = element.children;
          for (var i = 0; i != children.length; ++i) {
            if (children[i].name == "streamId") {
              children[i].value = stream.id;
              break;
            }
          }
          element.setStreamId(stream.id);
        }

        var newElement = document.getElementById(elementId)
        newElement.onclick = element.onclick ? element.onclick : function(arg) {};
        newElement._TemOnClick = function(id) {
          var arg = {srcElement: document.getElementById(id)};
          newElement.onclick(arg);
        }
        return newElement;
      } else { // is audio element
        // The sound was enabled, there is nothing to do here
        return element;
      }
    };


    reattachMediaStream = function(to, from) {
      var stream = null;
      var children = from.children;
      for (var i = 0; i != children.length; ++i) {
        if (children[i].name == "streamId") {
          stream = plugin().getStreamWithId(TemPageId, children[i].value);
          break;
        }
      }

      if (stream != null) 
        return attachMediaStream(to, stream);
      else
        alert("Could not find the stream associated with this element");
    };

    RTCIceCandidate = function(candidate) {
      if (!candidate.sdpMid)
        candidate.sdpMid = "";
      return plugin().ConstructIceCandidate(candidate.sdpMid, candidate.sdpMLineIndex, candidate.candidate);
    };
    // END OF WEBRTC INTERFACE 
  };


  function pluginNeededButNotInstalledCb() {
    // This function will be called if the plugin is needed 
    // (browser different from Chrome or Firefox), 
    // but the plugin is not installed
    // Override it according to your application logic.

    alert("Your browser is not webrtc ready and Temasys plugin is not installed");
  }

  // Try to detect the plugin and act accordingly
  isPluginInstalled("Tem", "TemWebRTCPlugin", defineWebRTCInterface, pluginNeededButNotInstalledCb);
} else {
  console.log("Browser does not appear to be WebRTC-capable");
}
(function() {
  var AugumentedStatsResponse, RTC,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  window.RTCAdapter = {
    RTCPeerConnection: RTCPeerConnection,
    RTCSessionDescription: RTCSessionDescription,
    RTCIceCandidate: RTCIceCandidate,
    getUserMedia: getUserMedia,
    attachMediaStream: attachMediaStream,
    createIceServer: createIceServer,
    webrtcDetectedBrowser: webrtcDetectedBrowser,
    webrtcDetectedVersion: webrtcDetectedVersion
  };

  Promise.of = function(value) {
    return new Promise(function(resolve, reject) {
      return resolve(value);
    });
  };

  Promise.prototype.map = function(f) {
    return new Promise((function(_this) {
      return function(resolve, _) {
        return _this.then(function(a) {
          return resolve(f(a));
        });
      };
    })(this));
  };

  Promise.prototype.rejectedMap = function(f) {
    return new Promise((function(_this) {
      return function(_, reject) {
        return _this.then(function(a) {
          return reject(f(a));
        });
      };
    })(this));
  };

  AugumentedStatsResponse = (function() {
    function AugumentedStatsResponse(response) {
      this.response = response;
      this.get = __bind(this.get, this);
      this.result = __bind(this.result, this);
      this.collectAddressPairs = __bind(this.collectAddressPairs, this);
    }

    AugumentedStatsResponse.prototype.addressPairMap = [];

    AugumentedStatsResponse.prototype.collectAddressPairs = function(componentId) {
      var res, results, _i, _len;
      if (!this.addressPairMap[componentId]) {
        this.addressPairMap[componentId] = [];
        results = this.response.result();
        for (_i = 0, _len = results.length; _i < _len; _i++) {
          res = results[_i];
          if (res.type === 'googCandidatePair' && res.stat('googChannelId') === componentId) {
            this.addressPairMap[componentId].push(res);
          }
        }
      }
      return this.addressPairMap[componentId];
    };

    AugumentedStatsResponse.prototype.result = function() {
      return this.response.result();
    };

    AugumentedStatsResponse.prototype.get = function(key) {
      return this.response[key];
    };

    return AugumentedStatsResponse;

  })();

  RTC = (function(_super) {
    __extends(RTC, _super);

    RTC.include(Spine.Events);

    function RTC(args) {
      this.insertDTMF = __bind(this.insertDTMF, this);
      this.mediaState = __bind(this.mediaState, this);
      this.toggleMuteVideo = __bind(this.toggleMuteVideo, this);
      this.unmuteVideo = __bind(this.unmuteVideo, this);
      this.muteVideo = __bind(this.muteVideo, this);
      this.unmuteAudio = __bind(this.unmuteAudio, this);
      this.muteAudio = __bind(this.muteAudio, this);
      this.toggleMuteAudio = __bind(this.toggleMuteAudio, this);
      this.close = __bind(this.close, this);
      this.receiveAnswer = __bind(this.receiveAnswer, this);
      this.receiveOffer = __bind(this.receiveOffer, this);
      this.receive = __bind(this.receive, this);
      this.createAnswer = __bind(this.createAnswer, this);
      this.createOffer = __bind(this.createOffer, this);
      this.setLocalDescription = __bind(this.setLocalDescription, this);
      this.triggerSDP = __bind(this.triggerSDP, this);
      this.createScreenStream = __bind(this.createScreenStream, this);
      this.createStream = __bind(this.createStream, this);
      this.createPeerConnection = __bind(this.createPeerConnection, this);
      this.addIceServer = __bind(this.addIceServer, this);
      this.getStats = __bind(this.getStats, this);
      this.getRemoteStreamEventName = __bind(this.getRemoteStreamEventName, this);
      this.start = __bind(this.start, this);
      var key, value;
      console.log("[INFO] RTC constructor");
      for (key in args) {
        value = args[key];
        this[key] = value;
      }
      if (this.mediaConstraints == null) {
        this.mediaConstraints = {
          audio: true,
          video: true,
          screensharing: false
        };
      }
      this.isVideoActive = true;
      this.isAudioActive = true;
      this.iceServers = [];
      if ((this.iceServer != null) && (this.iceServer !== "")) {
        this.iceServers.push(this.iceServer);
      }
    }

    RTC.prototype.pcOptions = {
      optional: [
        {
          DtlsSrtpKeyAgreement: true
        }, {
          RtpDataChannels: true
        }
      ]
    };

    RTC.prototype.screenConstraints = {
      audio: false,
      video: {
        mandatory: {
          chromeMediaSource: 'screen',
          maxWidth: 1280,
          maxHeight: 720
        },
        optional: []
      }
    };

    RTC.prototype.start = function() {
      if (this.pc != null) {
        return Promise.of(this.pc);
      }
      return new Promise((function(_this) {
        return function(resolve, reject) {
          var localStreamPromise, pc;
          pc = _this.createPeerConnection();
          console.log("PeerConnection starting");
          _this.noMoreCandidates = navigator.mozGetUserMedia != null;
          _this.dtmfSender = null;
          localStreamPromise = _this.createStream();
          return localStreamPromise.then(function(stream) {
            pc.addStream(stream);
            resolve(pc);
            return _this.pc = pc;
          });
        };
      })(this));
    };

    RTC.prototype.dumpStats = function(obj) {
      var dict, names, properties, values;
      dict = {};
      dict = _.pick(obj, "timestamp", "id", "type");
      properties = {};
      if (obj.names) {
        names = obj.names();
        values = _.map(names, function(x) {
          return obj.stat(x);
        });
        properties = _.object(names, values);
      } else if (obj.stat("audioOutputLevel")) {
        properties = {
          audioOutputLevel: obj.stat("audioOutputLevel")
        };
      }
      return _.extend(dict, properties);
    };

    RTC.prototype.getRemoteStreamEventName = function(stream) {
      if (stream.getAudioTracks().length) {
        return "remotestream";
      } else {
        return "remotestream-screen";
      }
    };

    RTC.prototype.getStats = function(pc, cb) {
      var _ref;
      if (!((pc != null) && ((_ref = pc.readyState) === "stable" || _ref === "active") && (cb != null))) {
        return;
      }
      return pc.getStats((function(_this) {
        return function(rawStats) {
          var results, stats;
          stats = new AugumentedStatsResponse(rawStats);
          results = stats.result();
          return cb(_.compact(_.map(results, function(result) {
            var local, remote, report;
            report = null;
            if (!result.local || result.local === result) {
              report = _this.dumpStats(result);
              if (result.local && result.local !== result) {
                local = {
                  local: _this.dumpStats(result.local)
                };
              }
              if (result.remote && result.remote !== result) {
                remote = {
                  remote: _this.dumpStats(result.remote)
                };
              }
              return _.extend(report, local || {}, remote || {});
            }
            return null;
          })));
        };
      })(this));
    };

    RTC.prototype.addIceServer = function(url, username, password) {
      return this.iceServers.push(RTCAdapter.createIceServer(url, username, password));
    };

    RTC.prototype.createPeerConnection = function(locastream) {
      var iceGatheringEndCb, pc;
      console.log("[INFO] createPeerConnection");
      console.log("[MEDIA] ICE servers");
      console.log(this.iceServers);
      pc = new RTCAdapter.RTCPeerConnection({
        "iceServers": this.iceServers
      }, this.pcOptions);
      pc.onaddstream = (function(_this) {
        return function(event) {
          var remotestream;
          console.log("[MEDIA] Stream added");
          remotestream = event.stream;
          return _this.trigger(_this.getRemoteStreamEventName(remotestream), remotestream);
        };
      })(this);
      iceGatheringEndCb = (function(_this) {
        return function() {
          console.log("[INFO] No more ice candidates");
          _this.noMoreCandidates = true;
          if (pc.localDescription != null) {
            return _this.triggerSDP(pc);
          }
        };
      })(this);
      pc.onicecandidate = (function(_this) {
        return function(evt) {
          var candidate;
          console.log("[INFO] onicecandidate");
          if (evt.candidate) {
            console.log("[INFO] New ICE candidate:");
            console.log("" + evt.candidate.candidate);
            return candidate = {
              type: 'candidate',
              label: evt.candidate.sdpMLineIndex,
              id: evt.candidate.sdpMid,
              candidate: evt.candidate.candidate
            };
          } else {
            return iceGatheringEndCb();
          }
        };
      })(this);
      pc.oniceconnectionstatechange = (function(_this) {
        return function(evt) {
          if (evt.currentTarget.iceGatheringState === 'complete' && pc.iceConnectionState !== 'closed') {
            console.log("[INFO] iceGatheringState -> " + evt.currentTarget.iceGatheringState);
            return iceGatheringEndCb();
          }
        };
      })(this);
      pc.onicechange = (function(_this) {
        return function() {
          return console.log("[INFO] icestate changed -> " + pc.iceState);
        };
      })(this);
      pc.onstatechange = (function(_this) {
        return function() {
          return console.log("[INFO] peerconnectionstate changed -> " + pc.readyState);
        };
      })(this);
      pc.onopen = function() {
        return console.log("[MEDIA] peerconnection opened");
      };
      pc.onclose = function() {
        return console.log("[INFO] peerconnection closed");
      };
      return pc;
    };

    RTC.prototype.createStream = function() {
      return new Promise((function(_this) {
        return function(resolve, reject) {
          var gumFail, gumSuccess;
          console.log("[INFO] createStream");
          if (_this.localstream != null) {
            console.log("[INFO] Using media previously got.");
            return resolve(_this.localstream);
          } else {
            gumSuccess = function(localstream) {
              var _ref;
              _this.localstream = localstream;
              console.log("[INFO] getUserMedia successed");
              resolve(_this.localstream);
              _this.trigger("localstream", _this.localstream);
              console.log("localstream", _this.localstream);
              return _ref = [_this.localstream.getVideoTracks().length > 0, _this.localstream.getAudioTracks().length > 0], _this.isVideoActive = _ref[0], _this.isAudioActive = _ref[1], _ref;
            };
            gumFail = function(error) {
              reject(error);
              console.error(error);
              console.error("GetUserMedia error");
              return _this.trigger("error", "getUserMedia");
            };
            return RTCAdapter.getUserMedia(_this.mediaConstraints, gumSuccess, gumFail);
          }
        };
      })(this));
    };

    RTC.prototype.createScreenStream = function() {
      return new Promise((function(_this) {
        return function(resolve, reject) {
          var gumFail, gumSuccess;
          if (webrtcDetectedBrowser !== 'chrome') {
            reject();
          }
          console.log("[INFO] createScreenStream");
          if (_this.localScreenStream != null) {
            console.log("[INFO] Using media previously got.");
            return resolve(localScreenStream);
          } else {
            gumSuccess = function(localScreenStream) {
              _this.localScreenStream = localScreenStream;
              console.log("[INFO] getUserMedia successed");
              resolve(_this.localScreenStream);
              _this.trigger("localstream-screen", _this.localScreenStream);
              return console.log("localstream-screen", _this.localScreenStream);
            };
            gumFail = function(error) {
              reject(error);
              console.error(error);
              console.error("GetUserMedia error");
              return _this.trigger("error", "getUserMedia");
            };
            return RTCAdapter.getUserMedia(_this.screenConstraints, gumSuccess, gumFail);
          }
        };
      })(this));
    };

    RTC.prototype.triggerSDP = function(pc) {
      var sdp;
      console.log("[SDP]");
      sdp = pc.localDescription.sdp;
      console.log(sdp);
      return this.trigger("sdp", sdp);
    };

    RTC.prototype.setLocalDescription = function(pc) {
      return (function(_this) {
        return function(sessionDescription) {
          var fail, success;
          success = function() {
            console.log("[INFO] setLocalDescription successed");
            if (_this.noMoreCandidates) {
              return _this.triggerSDP(pc);
            }
          };
          fail = function() {
            return _this.trigger("error", "setLocalDescription", sessionDescription);
          };
          return pc.setLocalDescription(sessionDescription, success, fail);
        };
      })(this);
    };

    RTC.prototype.createOffer = function() {
      console.log("[INFO] createOffer");
      return this.start().then((function(_this) {
        return function(pc) {
          var error;
          error = function(e) {
            return _this.trigger("error", "createOffer", e);
          };
          return pc.createOffer(_this.setLocalDescription(pc), error, {});
        };
      })(this));
    };

    RTC.prototype.createAnswer = function() {
      return this.start().then((function(_this) {
        return function(pc) {
          var error;
          console.log("[INFO] Answer");
          error = function(e) {
            return _this.trigger("error", "createOffer", e);
          };
          return pc.createAnswer(_this.setLocalDescription(pc), error, {});
        };
      })(this));
    };

    RTC.prototype.receive = function(sdp, type, callback) {
      return this.start().then((function(_this) {
        return function(pc) {
          var description, success;
          console.log("[INFO] receive!");
          console.log(sdp, type, callback);
          success = function() {
            console.log("[INFO] Remote description setted.");
            console.log("[INFO] localDescription:");
            console.log(pc.localDescription);
            console.log("[INFO] remotelocalDescription:");
            console.log(pc.remoteDescription);
            return typeof callback === "function" ? callback() : void 0;
          };
          description = new RTCAdapter.RTCSessionDescription({
            type: type,
            sdp: sdp
          });
          console.log(description);
          return pc.setRemoteDescription(description, success, function() {
            return _this.trigger("error", "setRemoteDescription", description);
          });
        };
      })(this));
    };

    RTC.prototype.receiveOffer = function(sdp, callback) {
      if (callback == null) {
        callback = null;
      }
      console.log("[INFO] Received offer");
      return this.receive(sdp, "offer", callback);
    };

    RTC.prototype.receiveAnswer = function(sdp, callback) {
      if (callback == null) {
        callback = null;
      }
      console.log("[INFO] Received answer");
      return this.receive(sdp, "answer", callback);
    };

    RTC.prototype.close = function() {
      var e, _ref;
      try {
        if ((_ref = this.pc) != null) {
          _ref.close();
        }
        return this.dtmfSender = null;
      } catch (_error) {
        e = _error;
        console.error("[ERROR] Error closing peerconnection");
        return console.error(e);
      } finally {
        this.pc = null;
      }
    };

    RTC.prototype.toggleMuteAudio = function() {
      var audioTracks;
      audioTracks = this.localstream.getAudioTracks();
      if (audioTracks.length === 0) {
        console.log("[MEDIA] No local audio available.");
        return;
      }
      if (this.isAudioActive) {
        return this.muteAudio();
      } else {
        return this.unmuteAudio();
      }
    };

    RTC.prototype.muteAudio = function() {
      var audioTrack, audioTracks, _i, _len;
      audioTracks = this.localstream.getAudioTracks();
      for (_i = 0, _len = audioTracks.length; _i < _len; _i++) {
        audioTrack = audioTracks[_i];
        audioTrack.enabled = false;
      }
      return this.isAudioActive = false;
    };

    RTC.prototype.unmuteAudio = function() {
      var audioTrack, audioTracks, _i, _len;
      audioTracks = this.localstream.getAudioTracks();
      for (_i = 0, _len = audioTracks.length; _i < _len; _i++) {
        audioTrack = audioTracks[_i];
        audioTrack.enabled = true;
      }
      return this.isAudioActive = true;
    };

    RTC.prototype.muteVideo = function() {
      var videoTrack, videoTracks, _i, _len;
      videoTracks = this.localstream.getVideoTracks();
      for (_i = 0, _len = videoTracks.length; _i < _len; _i++) {
        videoTrack = videoTracks[_i];
        videoTrack.enabled = false;
      }
      return this.isVideoActive = false;
    };

    RTC.prototype.unmuteVideo = function() {
      var videoTrack, videoTracks, _i, _len;
      videoTracks = this.localstream.getVideoTracks();
      for (_i = 0, _len = videoTracks.length; _i < _len; _i++) {
        videoTrack = videoTracks[_i];
        videoTrack.enabled = true;
      }
      return this.isVideoActive = true;
    };

    RTC.prototype.toggleMuteVideo = function() {
      var videoTracks;
      videoTracks = this.localstream.getVideoTracks();
      if (videoTracks.length === 0) {
        console.log("[MEDIA] No local audio available.");
        return;
      }
      if (this.isVideoActive) {
        return this.muteVideo();
      } else {
        return this.unmuteVideo();
      }
    };

    RTC.prototype.mediaState = function() {
      return {
        video: Boolean(this.isVideoActive),
        audio: Boolean(this.isAudioActive)
      };
    };

    RTC.prototype.insertDTMF = function(tone) {
      if (this.dtmfSender != null) {
        return this.dtmfSender.insertDTMF(tone, 500, 50);
      }
    };

    RTC.attachStream = function($d, stream) {
      return RTCAdapter.attachMediaStream($d[0], stream);
    };

    return RTC;

  })(Spine.Module);

  window.RTC = RTC;

}).call(this);
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
        return {
          meth: meth,
          type: "request"
        };
      }
    };

    Parser.parseVias = function(pkt) {
      var branchRE, ret, tmp, viaRE, vias;
      viaRE = /Via\:\s+SIP\/2\.0\/[A-Z]+\s+([A-z0-9\.\:]+)/;
      tmp = _.filter(pkt.split("\r\n"), function(line) {
        return viaRE.test(line);
      });
      vias = _.map(tmp, function(via) {
        return via.replace(/;received=[A-z0-9\.\:]+/, "");
      });
      console.log(vias);
      if (vias.length > 0) {
        ret = this.getRegExprResult(vias[0], viaRE, {
          sentBy: 1
        });
        branchRE = /branch=([^;\s]+)/;
        ret = this.getRegExprResult(vias[0], branchRE, {
          branch: 1
        });
      }
      console.log(_.extend({
        vias: vias
      }, ret));
      return _.extend({
        vias: vias
      }, ret);
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
      var displayName, lineFrom, lineFromRE, tag, user, useruri;
      lineFromRE = /(From|^f):\s*(((\"[a-zA-Z0-9\-\.\!\%\*\+\`\'\~\s]+\"|[a-zA-Z0-9\-\.\!\%\*\+\`\'\~]+)\s*<([^>]*)>)|<([^>]*)>|([^;\r\n]*))(;.*)?/;
      if (!((lineFrom = lineFromRE.exec(pkt)) != null)) {
        console.error("Error parsing From!!");
      } else {
        useruri = lineFrom[5] || lineFrom[6] || lineFrom[7];
        displayName = lineFrom[4];
        tag = lineFrom[8];
        user = /sips?:((.+)@[a-zA-Z0-9\.\-]+(\:[0-9]+)?)/.exec(useruri)[2];
      }
      return {
        from: useruri,
        ext: user,
        fromTag: tag,
        displayNameFrom: displayName
      };
    };

    Parser.parseTo = function(pkt) {
      var displayName, lineTo, lineToRE, tag, user, useruri;
      lineToRE = /(To|^t):\s*(((\"[a-zA-Z0-9\-\.\!\%\*\+\`\'\~\s]+\"|[a-zA-Z0-9\-\.\!\%\*\+\`\'\~]+)\s*<([^>]*)>)|<([^>]*)>|([^;\r\n]*))(;.*)?/;
      if (!((lineTo = lineToRE.exec(pkt)) != null)) {
        console.error("Error parsing To!!");
      } else {
        useruri = lineTo[5] || lineTo[6] || lineTo[7];
        displayName = lineTo[4];
        tag = lineTo[8];
        user = /sips?:((.+)@[a-zA-Z0-9\.\-]+(\:[0-9]+)?)/.exec(useruri)[2];
      }
      return {
        to: useruri,
        ext2: user,
        toTag: tag,
        displayNameTo: displayName
      };
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
      var contactRE, gruuRE, result, result2;
      contactRE = /(Contact|^m):\s*(\"[a-zA-Z0-9\-\.\!\%\*\+\`\'\~]*\"|[^<]*)\s*<?((sips?:((.+)@[a-zA-Z0-9\.\-]+(\:[0-9]+)?))([a-zA-Z0-9\-\.\!\%\*\+\`\'\~\;\=]*))>?(.*)/;
      gruuRE = /pub\-gruu=\"(.+?)\"/;
      result = this.getRegExprResult(pkt, contactRE, {
        contact: 3
      });
      result2 = this.getRegExprResult(pkt, contactRE, {
        contact: 8
      });
      console.warn(result);
      console.warn(result2);
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
      var line, lineRe, nonce, nonceRe, opaque, opaqueRe, qop, qopRe, realm, realmRe, _ref, _ref1, _ref2, _ref3;
      lineRe = /^WWW-Authenticate\:.+$|^Proxy-Authenticate\:.+$/m;
      realmRe = /realm="([^\"^\\]+)"/;
      nonceRe = /nonce="([^\"^\\]+)"/;
      opaqueRe = /opaque="([^\"^\\]+)"/;
      qopRe = /qop=\"(auth|auth-int)\"/;
      line = lineRe.exec(pkt);
      if (line != null) {
        realm = (_ref = realmRe.exec(pkt)) != null ? _ref[1] : void 0;
        nonce = (_ref1 = nonceRe.exec(pkt)) != null ? _ref1[1] : void 0;
        opaque = (_ref2 = opaqueRe.exec(pkt)) != null ? _ref2[1] : void 0;
        qop = (_ref3 = qopRe.exec(pkt)) != null ? _ref3[1] : void 0;
      }
      return {
        realm: realm,
        nonce: nonce,
        opaque: opaque,
        qop: qop
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
