// FIXME - This is a shitty JS proof of concept.
var Grumble = {
  urlTemplates: {
    getTarget: new Template('http://grumble.annealer.org/targets/#{target}?callback=true&ts=#{ts}'),
    getGrumbles: new Template('http://grumble.annealer.org/targets/#{target}/grumbles?callback=true&ts=#{ts}'),
    grumblePoster: 'http://grumble.annealer.org/javascripts/grumbler/poster.html'
  },

  getTarget: Prototype.K,
  getGrumbles: Prototype.K,
  grumbleCreated: Prototype.K,

  fetchTarget: function() {
    var targetAt = this.urlTemplates.getTarget.evaluate({target: this.currentUri(), ts: this.currentTime()});
    $('target_loader').src = targetAt;
  },
  
  fetchGrumbles: function() {
    var grumblesAt = this.urlTemplates.getGrumbles.evaluate({target: this.currentUri(), ts: this.currentTime()});
    $('grumble_loader').src = grumblesAt;
  },
  
  postGrumble: function(grumbleData) {
    var iframeTransport = $H({grumble_data: grumbleData, target: this.currentUri(), status: 'loading'})
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
  var targetLoader = new Element('script', {'type': 'text/javascript', 'id': 'target_loader'});
  var grumbleLoader = new Element('script', {'type': 'text/javascript', 'id': 'grumble_loader'});
  $$('head')[0].appendChild(targetLoader);
  $$('head')[0].appendChild(grumbleLoader);
  Grumble.fetchTarget();
  Grumble.fetchGrumbles();
})