var Grumble = {}

Grumble.Client = Class.create({

  _loaderName: new Template('grumble_loader_#{instanceNumber}'),
  _loaderUrls: {
    getTarget:      new Template('http://grumble.annealer.org/targets/#{target}?callback=#{id}'),
    getGrumbles:    new Template('http://grumble.annealer.org/targets/#{target}/grumbles?callback=#{id}'),
    grumblePoster: 'http://grumble.annealer.org/javascripts/grumbler/poster.html'
  }, // _loaderUrls
  
  _loaderWrappers: {
    targetFetched: function(targetData) {
      this._removeThyself(function(){ this.client.fireCallback('targetFetched', targetData); })
    },
    
    grumblesFetched: function(targetData) {
      this._removeThyself(function(){ this.client.fireCallback('grumblesFetched', targetData); })
    },
    
    _removeThyself: function(func) {
      try { func.call(this); } finally { this.remove(); };
    }
  }, // _loaderWrappers
  
  initialize: function(uri, options) {
    this.uri = uri;
    this.callbacks = (options && options.callbacks) || {};
  },

  fetchTarget: function() {
    var loader = this._newLoader(function(l){
      var loaderSrc = this._loaderUrls.getTarget.evaluate({target: this.escapedURI(), id: l.id});
      l.src = loaderSrc;
    });
    return loader;
  },

  fetchGrumbles: function() {
    var loader = this._newLoader(function(l){
      var loaderSrc = this._loaderUrls.getGrumbles.evaluate({target: this.escapedURI(), id: l.id});
      l.src = loaderSrc;
    });
    return loader;
  },
  
  escapedURI: function() {
    return encodeURIComponent(this.uri).gsub('\\.', '%2E');  
  },
  
  fireCallback: function(callbackName, data) {
    (this.callbacks[callbackName] || Prototype.K).call(this, data);
  },
  
// Private

  _newLoader: function(encloser) {
    var now = new Date;
    var loaderName = this._loaderName.evaluate({instanceNumber: now.getTime()});
    var loader = new Element('script', {'type': 'text/javascript', 'id': loaderName});
    loader.client = this;
    Object.extend(loader, this._loaderWrappers);
    encloser.call(this, loader);
    $$('head')[0].appendChild(loader);
    return loader;
  }
  
});


//   
//   postGrumble: function(grumbleData) {
//     var iframeTransport = $H({grumble_data: grumbleData, target: this.currentUri(), status: 'loading'})
//     var posterFrame = new Element('iframe', {name: iframeTransport.toJSON(), id: 'grumble_poster', 
//                                   src: this.urlTemplates.grumblePoster, style: 'display: none;'});
//     var that = this;
//     var grumbleChecker = function(grumbler) { 
//       var doneFrame = $A(window.frames).detect(function(fr){
//         try {
//           var frameName = fr.name;
//           return fr.location.hash == '#grumbleDone';
//         } catch(e) {
//           return false;
//         }
//       });
// 
//       if (doneFrame) {
//         that.grumbleCreated(doneFrame.name.evalJSON().grumble)
//         posterFrame.remove()
//       } else {
//         window.setTimeout(grumbleChecker, 100);
//       }
//     }
//     posterFrame.onload = function() { grumbleChecker(); posterFrame.onload = undefined; }
//     document.body.appendChild(posterFrame);
//   },

