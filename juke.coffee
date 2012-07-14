$ = jQuery
$.fn.extend
  juke: (options) ->

    settings =
      title: "Mixtape"
      imagesFolder: "public/images/juke/"
      soundmanagerFolder: "public/swf/"
      placeholder: "images/juke/default.jpg"
      trackinfo: "trackinfo.json"
      SM2: "public/docs/js/min/soundmanager2.min.js"
      itunes: true
      audio: "mix.mp3"
      tooltips: false
      animationSpeed: 400
      debug: false

    settings = $.extend {}, settings, options

    log = (msg) ->
      console?.log msg if settings.debug

    isJSON = (str) ->
      unless str.length then return false
      str = str.replace /\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g, '@'
      str = str.replace /"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g, ']'
      str = str.replace /(?:^|:|,)(?:\s*\[)+/g, ''
      (/^[\],:{}\s]*$/).test str

    # Help out IE a bit with AJAX calls
    $.ajaxSetup
      xhr: -> if window.ActiveXObject then new ActiveXObject("Microsoft.XMLHTTP") else new XMLHttpRequest()

    return @each ->
      currentTrack = 1
      cur = 0
      title = document.title
      elem = $ @

      # Retrieves track markers
      getMarker = (index) ->
        marker = trackInfo[index].marker
        testPattern = /:/
        minutePattern = /^\d*(?=:)/
        secondPattern = /[0-5][0-9]$/

        if testPattern.test marker
          min = parseInt minutePattern.exec(marker), 10
          sec = parseInt secondPattern.exec(marker), 10
          min * 60 + sec
        else
          parseInt trackInfo[index].marker, 10

      # Updates the new artist and track info
      # Gets a localized iTunes Store link
      updateInfo = (artist, track) ->
        newString = artist + " - <em class='track'>" + track + "</em>"
        countryCode
        queryString
        link

        if settings.itunes
          $.ajax
            url: 'http://api.wipmania.com/jsonp?callback=?'
            dataType: 'jsonp'
            success: (data) ->
              countryCode = data.address.country_code
              queryString = "http://itunes.apple.com/search?entity=song&country=" + countryCode + "&term=" + encodeURIComponent(artist + " " + track) + "&limit=5&callback=?"

              # Search the store
              $.getJSON queryString, (data) ->
                if data.resultCount is 1 then link = data.results[0].trackViewUrl
                else if data.resultCount > 1
                  $.each data.results, -> if this.trackName is track then link = this.trackViewUrl

                if link? then newString += " (<a href='" + link + "' class='itunes-link'>iTunes</a>)"
                tooltip.html newString
        else tooltip.html newString

      # Update the element alignment if the window is resized
      $(window).resize ->
        shadowleft.css {right: shadowleft.parent().width() / 2 + 63}
        shadowright.css {left: shadowright.parent().width() / 2 + 64}
        tapeOffset = tapebox.parent().width() / 2 - 62
        if cur > 0 then tapeOffset -= currentTrack * 125
        tapebox.css {left: tapeOffset}

      setup = ->

        # Set the element to hidden instead of display: none so it has size
        elem.css
          "display": "block"
          "visibility": "hidden"

        # load trackinfo JSON as string or from URL
        if isJSON settings.trackinfo then trackInfo = $.parseJSON settings.trackinfo
        else
          $.ajax
            url: settings.trackinfo
            async: false
            success: (data) ->
              trackInfo = data
              duration = parseInt(trackInfo.duration, 10)
              trackInfo = trackInfo.tracks
              currentMarker = getMarker(currentTrack - 1)
              nextMarker = getMarker(currentTrack)
              numTracks = parseInt(trackInfo.length, 10)

        # setup the DOM structure inside empty div
        # wrap the albumart list
        elem.children().wrapAll '<ul id="tapebox"/>'

        # prepend the placeholder to the list
        $("#tapebox").wrapAll '<div id="displaybox"/>'
        $("#tapebox").prepend '<li><img src="' + settings.placeholder + '" width="125"></li>'

        # prepend the bg image
        $("#displaybox").prepend '<img src="' + settings.imagesFolder + 'bg.png" alt="">'

        # add the other structure around the list
        elem.prepend '<div id="shadowleft" class="shadow"></div><div id="shadowright" class="shadow"></div><div id="playhead"><img src="' + settings.imagesFolder + 'playhead_overlay.png"><div id="playtoggle" class="hover"></div></div>'
        elem.append '<div id="displaybox_overlay"><img src="' + settings.imagesFolder + 'displaybox_overlay.png" /></div>'
        if settings.tooltips
          elem.append '<div class="tooltip">' + settings.title + '</div>'
          tooltip = $ ".tooltip"
        if settings.debug
          elem.append '<span id="skipbackward">REV</span>&nbsp;-&nbsp;<span id="skipforward">FWD</span>'

        shadowleft  = $ "#shadowleft"
        shadowright = $ "#shadowright"
        tapebox     = $ "#tapebox"
        playtoggle  = $ "#playtoggle"

        # SM handles all of the events from here on out
        soundManager.onready ->
          soundManager.createSound
            id: "juke"
            url: $.trim(settings.audio)
            onplay: ->
              playtoggle.addClass 'playing'
              document.title = "\u25B6 " + settings.title + " - " + title
              if cur is 0
                tapeOffset = tapebox.parent().width() / 2 - 62 - 125
                tapebox.animate {"left": tapeOffset}, settings.animationSpeed, "swing"
                if settings.tooltips
                  updateInfo trackInfo[currentTrack - 1].artist, trackInfo[currentTrack - 1].track
            onpause: ->
              playtoggle.removeClass 'playing'
              document.title = title
            onfinish: ->
              playtoggle.removeClass 'playing'
              document.title = title
            whileplaying: ->
              cur = parseInt soundManager.getSoundById("juke").position / 1000, 10

              if cur >= duration then soundManager.pause("juke")
              if cur >= nextMarker
                currentTrack += 1
                if currentTrack < numTracks
                  currentMarker = nextMarker
                  nextMarker = getMarker currentTrack
                else
                  nextMarker = duration
                tapebox.animate { "left" : "-=125px" }, settings.animationSpeed, "swing"
                if settings.tooltips
                  updateInfo trackInfo[currentTrack - 1].artist, trackInfo[currentTrack - 1].track

              log "total: " + duration + ", currently at: " + cur + ", next marker: " + nextMarker

          $("#playtoggle").click -> soundManager.togglePause "juke"

          if settings.debug
            $("#skipforward").click ->
              soundManager.getSoundById("juke").setPosition soundManager.getSoundById("juke").position + 5000
            $("#skipbackward").click ->
              soundManager.getSoundById("juke").setPosition soundManager.getSoundById("juke").position - 5000

          shadowleft.css({right: shadowleft.parent().width() / 2 + 63})
          shadowright.css({left: shadowright.parent().width() / 2 + 64})
          tapebox.css({left: tapebox.parent().width() / 2 - 62})
          elem.css("visibility", "visible")

      window.SM2_DEFER = true
      $.ajax
        url: settings.SM2,
        success: ->
          window.soundManager        = new SoundManager()
          soundManager.url           = settings.soundmanagerFolder + 'soundmanager2_flash_xdomain/'
          soundManager.useHTML5Audio = true
          soundManager.autoLoad      = true
          soundManager.preferFlash   = false
          soundManager.consoleOnly   = true
          soundManager.debugMode     = settings.debug
          soundManager.wmode         = 'transparent'
          soundManager.beginDelayedInit()
          setup()