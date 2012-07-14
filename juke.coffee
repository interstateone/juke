$ = jQuery

class Plugin
  constructor: (elem, options = {}) ->
    @elem = elem
    @$elem = $ elem
    @options = options

  defaults:
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

  load: ->
    # Help out IE a bit with AJAX calls
    $.ajaxSetup
      xhr: -> if window.ActiveXObject then new ActiveXObject("Microsoft.XMLHTTP") else new XMLHttpRequest()

    @settings = $.extend {}, @defaults, @options

    window.SM2_DEFER = true
    $.ajax
      url: @settings.SM2,
      success: =>
        window.soundManager        = new SoundManager()
        soundManager.url           = @settings.soundmanagerFolder + 'soundmanager2_flash_xdomain/'
        soundManager.useHTML5Audio = true
        soundManager.autoLoad      = true
        soundManager.preferFlash   = false
        soundManager.consoleOnly   = true
        soundManager.debugMode     = @settings.debug
        soundManager.wmode         = 'transparent'
        soundManager.beginDelayedInit()
        @init()

  init: ->
    @currentTrack = 1
    @cur = 0
    @title = document.title

    # Set the element to hidden instead of display: none so it has size
    @$elem.css
      "display": "block"
      "visibility": "hidden"

    # load trackinfo JSON as string or from URL
    if @isJSON @settings.trackinfo then @trackInfo = $.parseJSON @settings.trackinfo
    else
      $.ajax
        url: @settings.trackinfo
        async: false
        success: (data) =>
          @trackInfo = data
          @log @trackInfo
          @duration = @parseTime @trackInfo.duration
          @trackInfo = @trackInfo.tracks
          @currentMarker = @getMarker(@currentTrack - 1)
          @nextMarker = @getMarker(@currentTrack)
          @numTracks = parseInt(@trackInfo.length, 10)

    # setup the DOM structure inside empty div
    # wrap the albumart list
    @$elem.children().wrapAll '<ul id="tapebox"/>'
    @tapebox = $ "#tapebox"

    # prepend the placeholder to the list
    @tapebox.wrapAll '<div id="displaybox"/>'
    @tapebox.prepend "<li><img src='#{ @settings.placeholder }' width='125'></li>"

    # prepend the bg image
    $("#displaybox").prepend "<img src='#{ @settings.imagesFolder }bg.png'>"

    # add the other structure around the list
    @$elem.prepend """
      <div id='shadowleft' class='shadow'></div>
      <div id='shadowright' class='shadow'></div>
      <div id='playhead'>
        <img src='#{ @settings.imagesFolder }playhead_overlay.png'>
        <div id='playtoggle' class='hover'></div>
      </div>
      """
    @$elem.append """
      <div id='displaybox_overlay'>
        <img src='#{ @settings.imagesFolder }displaybox_overlay.png' />
      </div>
      """
    if @settings.tooltips
      @$elem.append "<div class='tooltip'>#{ @settings.title }</div>"
      @tooltip = $ ".tooltip"
    if @settings.debug
      @$elem.append '<span id="skipbackward">REV</span>&nbsp;-&nbsp;<span id="skipforward">FWD</span>'

    @shadowleft  = $ "#shadowleft"
    @shadowright = $ "#shadowright"
    @playtoggle  = $ "#playtoggle"

    # SM handles all of the events from here on out
    soundManager.onready =>
      soundManager.createSound
        id: "juke"
        url: $.trim(@settings.audio)
        onplay: =>
          @playtoggle.addClass 'playing'
          document.title = "\u25B6 " + @settings.title + " - " + @title
          if @cur is 0
            @tapeOffset = @tapebox.parent().width() / 2 - 62 - 125
            @tapebox.animate {"left": @tapeOffset}, @settings.animationSpeed, "swing"
            if @settings.tooltips
              @updateInfo @trackInfo[@currentTrack - 1].artist, @trackInfo[@currentTrack - 1].track
        onpause: =>
          @playtoggle.removeClass 'playing'
          document.title = @title
        onfinish: =>
          @playtoggle.removeClass 'playing'
          document.title = @title
        whileplaying: =>
          @cur = parseInt soundManager.getSoundById("juke").position / 1000, 10

          if @cur >= @duration then soundManager.pause("juke")
          if @cur >= @nextMarker
            @currentTrack += 1
            if @currentTrack < @numTracks
              @currentMarker = @nextMarker
              @nextMarker = @getMarker @currentTrack
            else
              @nextMarker = @duration
            @tapebox.animate { "left" : "-=125px" }, @settings.animationSpeed, "swing"
            if @settings.tooltips
              @updateInfo @trackInfo[@currentTrack - 1].artist, @trackInfo[@currentTrack - 1].track

          @log "total: " + @duration + ", currently at: " + @cur + ", next marker: " + @nextMarker

      @playtoggle.click -> soundManager.togglePause "juke"

      if @settings.debug
        $("#skipforward").click ->
          soundManager.getSoundById("juke").setPosition soundManager.getSoundById("juke").position + 5000
        $("#skipbackward").click ->
          soundManager.getSoundById("juke").setPosition soundManager.getSoundById("juke").position - 5000

      @adjustShadows()
      @tapebox.css({left: @tapebox.parent().width() / 2 - 62})
      @$elem.css("visibility", "visible")

      # Update the element alignment if the window is resized
      $(window).resize =>
        @adjustShadows()
        tapeOffset = @tapebox.parent().width() / 2 - 62
        if @cur > 0 then tapeOffset -= @currentTrack * 125
        @tapebox.css {left: tapeOffset}

    @

  log: (msg...) ->
    console?.log msg if @settings.debug

  isJSON: (str) ->
    unless str.length then false
    str = str.replace /\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g, '@'
    str = str.replace /"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g, ']'
    str = str.replace /(?:^|:|,)(?:\s*\[)+/g, ''
    (/^[\],:{}\s]*$/).test str

  adjustShadows: ->
    @shadowleft.css({right: @shadowleft.parent().width() / 2 + 63})
    @shadowright.css({left: @shadowright.parent().width() / 2 + 64})

  parseTime: (time) ->
    testPattern = /:/
    minutePattern = /^\d*(?=:)/
    secondPattern = /[0-5][0-9]$/

    if testPattern.test time
      min = parseInt minutePattern.exec(time), 10
      sec = parseInt secondPattern.exec(time), 10
      min * 60 + sec
    else
      parseInt time, 10

  # Retrieves track markers
  getMarker: (index) ->
    marker = @trackInfo[index].marker
    @parseTime marker

  # Updates the new artist and track info
  # Gets a localized iTunes Store link
  updateInfo: (artist, track) ->
    newString = "#{ artist } - <em class='track'>#{ track }</em>"

    if @settings.itunes
      $.ajax
        url: 'http://api.wipmania.com/jsonp?callback=?'
        dataType: 'jsonp'
        success: (data) =>
          countryCode = data.address.country_code
          term = encodeURIComponent artist + " " + track
          queryString = "http://itunes.apple.com/search?entity=song&country=#{ countryCode }&term=#{ term }&limit=5&callback=?"

          # Search the store
          $.getJSON queryString, (data) =>
            link = result.trackViewUrl if track is result.trackName for result in data.results
            if link? then newString += " (<a href='#{ link }' class='itunes-link'>iTunes</a>)"
            @changeTooltip(newString)
    else
      @changeTooltip(newString)

  changeTooltip: (msg) ->
    @tooltip.fadeOut ->
      $(@).html msg
      $(@).fadeIn()

$.fn.juke = (options) ->
  @each -> new Plugin(@, options).load()