// FIXME - This is a shitty JS proof of concept.
var Grumble = {
  urlTemplates: {
    getGrumbleable: new Template('http://grumble.annealer.org/grumbleables/#{grumbleable}?callback=true&ts=#{ts}'),
    getGrumbles: new Template('http://grumble.annealer.org/grumbleables/#{grumbleable}/grumbles?callback=true&ts=#{ts}'),
    grumblePoster: 'http://grumble.annealer.org/javascripts/grumbler/poster.html'
  },

  getGrumbleable: Prototype.K,
  getGrumbles: Prototype.K,
  grumbleCreated: Prototype.K,

  fetchGrumbleable: function() {
    var grumbleableAt = this.urlTemplates.getGrumbleable.evaluate({grumbleable: this.currentUri(), ts: this.currentTime()});
    $('grumbleable_loader').src = grumbleableAt;
  },
  
  fetchGrumbles: function() {
    var grumblesAt = this.urlTemplates.getGrumbles.evaluate({grumbleable: this.currentUri(), ts: this.currentTime()});
    $('grumble_loader').src = grumblesAt;
  },
  
  postGrumble: function(grumbleData) {
    var iframeTransport = $H({grumble_data: grumbleData, grumbleable: this.currentUri(), status: 'loading'})
    var posterFrame = new Element('iframe', {name: iframeTransport.toJSON(), id: 'grumble_poster', 
                                  src: this.urlTemplates.grumblePoster, style: 'display: none;'});
    var that = this;
    var grumbleChecker = function(grumbler) { 
      var doneFrame = $A(window.frames).detect(function(fr){
        try {
          var frameName = fr.name;
          return fr.location.hash == '#grumbleDone';
        } catch(e) {
          return false;
        }
      });

      if (doneFrame) {
        that.grumbleCreated(doneFrame.name.evalJSON().grumble)
        posterFrame.remove()
      } else {
        window.setTimeout(grumbleChecker, 100);
      }
    }
    posterFrame.onload = function() { grumbleChecker(); posterFrame.onload = undefined; }
    document.body.appendChild(posterFrame);
  },
  
  currentUri: function() {
    return encodeURIComponent(window.location.href).gsub('\\.', '%2E');
  },
  
  currentTime: function() {
    return new Date().getTime();
  }
  
}

document.observe('dom:loaded', function(){
  var grumbleableLoader = new Element('script', {'type': 'text/javascript', 'id': 'grumbleable_loader'});
  var grumbleLoader = new Element('script', {'type': 'text/javascript', 'id': 'grumble_loader'});
  $$('head')[0].appendChild(grumbleableLoader);
  $$('head')[0].appendChild(grumbleLoader);
  Grumble.fetchGrumbleable();
  Grumble.fetchGrumbles();
})