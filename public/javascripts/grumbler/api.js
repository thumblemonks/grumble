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
    return encodeURIComponent(this.uri).gsub('\\.', '%2E').gsub('\%', '%25');  
  },
  
  fireCallback: function(callbackName, data) {
    (this.callbacks[callbackName] || Prototype.K).call(this, data);
  },
  
// Private

  _newLoader: function(encloser) {
    var loaderName = this._loaderName.evaluate({instanceNumber: (new Date).getTime()});
    var loader = new Element('script', {'type': 'text/javascript', 'id': loaderName});
    loader.client = this;
    Object.extend(loader, this._loaderWrappers);
    encloser.call(this, loader);
    $$('head')[0].appendChild(loader);
    return loader;
  },
//
// EXPERIMENTAL
  postGrumble: function(grumbleData) {
    var grumbleData = $H(grumbleData).inject($H(), function(collected,pair){
      collected.set('grumble[#{0}]'.interpolate([pair.key]), pair.value);
      return collected;
    });
    var doneName = 'grumble_poster_' + (new Date).getTime();
    
    var iframeTransport = {grumbleData: grumbleData, target: this.escapedURI(), doneName: doneName};
    var posterFrame = new Element('iframe', {style: 'display: none;', src: this._loaderUrls.grumblePoster});
    posterFrame.name = Object.toJSON(iframeTransport);
    
    var here = this;
    var callbackProcessor = function(dataIframe, watchForName) {
      var doneFrame = $A(window.frames).detect(function(fr){
        try { return fr.name.match('//'+watchForName); } catch (e) { return false; }
      })

      if (!doneFrame) {
        window.setTimeout(callbackProcessor.bind(here, dataIframe, watchForName), 100);
      } else {
        var grumbleResponse = doneFrame.name.evalJSON();
        posterFrame.remove();
        this.fireCallback('grumbleCreated', grumbleResponse);
      }
    };
    
    var loadObserver = function(evt){ 
      evt.element().stopObserving('load', loadObserver);
      callbackProcessor(evt.element(), doneName);
    };
    posterFrame.observe('load', loadObserver);

    document.body.appendChild(posterFrame);
  }
// EXPERIMENTAL

});


//   

