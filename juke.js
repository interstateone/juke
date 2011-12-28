(function($) {
	$.fn.juke = function(option) {
		// override defaults with specified option
		option = $.extend({}, $.fn.juke.option, option);

		return this.each(function() {    
			var loadingIndicator, positionIndicator, timeleft, manualSeek = false, currentTrack = 1, currentMarker, nextMarker, numTracks, currentArt, rem, pos, mins, secs, cur, percentLoaded, duration, title = document.title, artList, trackinfo, elem = $(this);

			function isJSON(str) {
				if (str.length === 0) return false;
				str = str.replace(/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g, '@');
				str = str.replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g, ']');
				str = str.replace(/(?:^|:|,)(?:\s*\[)+/g, '');
				return (/^[\],:{}\s]*$/).test(str);
			}

			function isTouchDevice() {
			    return "ontouchstart" in window;
			}

			// load trackinfo JSON as string or from URL
			if(isJSON(option.trackinfo)){
			trackInfo = $.parseJSON(option.trackinfo);
			} else {
				trackInfo = (function () {
					var json = null;
					$.ajax({
						'async': false,
						'global': false,
						'url': option.trackinfo,
						'dataType': "json",
						'success': function (data) {
							json = data;
						}
					});
					return json;
				})();
			}

			duration = trackInfo.duration;
			trackInfo = trackInfo.tracks;
			currentMarker = trackInfo[currentTrack - 1].marker;
			nextMarker = trackInfo[currentTrack].marker;
			numTracks = trackInfo.length;

			// setup the DOM structure inside empty div
			// wrap the albumart list
			elem.children().wrapAll('<ul id="tapebox"/>');
			// prepend the placeholder to the list
			$("#tapebox").wrapAll('<div id="displaybox"/>');
			$("#tapebox").prepend('<li><img src="'+ option.placeholder +'" width="125"></li><li class="filler">&nbsp;</li><li class="filler">&nbsp;</li>');
			// prepend the bg image
			$("#displaybox").prepend('<img src="'+ option.imagesFolder +'bg.png" alt="">');
			// add the other structure around the list
			elem.prepend('<div id="shadowleft" class="shadow"></div><div id="shadowright" class="shadow"></div><div id="playhead"><img src="'+ option.imagesFolder +'playhead_overlay.png"><div id="playtoggle" class="hover"></div></div>');
			elem.append('<div id="displaybox_overlay"><img src="'+ option.imagesFolder +'displaybox_overlay.png" /></div>');

			if(option.tooltips){
				$("#playhead").append('<div class="tooltip">'+ option.title +'</div>');
			}

			// Soundmanager stuff
			// Make sure that SM2 is included and initialized
			if(soundManager){
				soundManager.url 			= option.soundmanagerFolder + 'soundmanager2_flash_xdomain/';
				soundManager.useHTML5Audio 	= true;
				soundManager.useFlashBlock 	= true;
				soundManager.consoleOnly	= true;
				soundManager.debugMode 		= option.debug;
				soundManager.wmode 			= 'transparent';

				soundManager.onready(function(){
					sm = soundManager.createSound({
						id: "juke",
						url: $.trim(option.audio),
						autoLoad: true,
						onplay: function(){
							$("#playtoggle").addClass('playing');
							document.title = "\u25B6 "+ option.title +" - " + title;
							$("#tapebox").animate({"left":"-175px"}, option.animationSpeed, "swing");
						
							if(option.tooltips) $(".tooltip").html("<p>"+ trackInfo[currentTrack-1].artist +"</p><p class='track'>"+ trackInfo[currentTrack-1].track +"</p>");
						},
						onresume: function(){
							$("#playtoggle").addClass('playing');
							document.title = "\u25B6 "+ option.title +" - " + title;
						},
						onpause: function(){
							$("#playtoggle").removeClass('playing');
							document.title = title;
						},
						onfinish: function(){
							$("#playtoggle").removeClass('playing');
							document.title = title;
						},
						whileplaying: function(){
							//rem = parseInt(duration - soundManager.getSoundById("juke").position/1000, 10);
							//pos = ((soundManager.getSoundById("juke").position/1000) / duration) * 100;
							//mins = Math.floor(rem/60,10);
							//secs = rem - mins*60;
							cur = parseInt(soundManager.getSoundById("juke").position/1000, 10);
						
							//console.log("total: "+duration+", currently at: "+cur+", next marker: "+nextMarker);

							// are we done?
							if(cur >= duration){
								soundManager.pause("juke");
							}

							// check to see if we've changed songs
							if(cur >= nextMarker){

								// make sure we're up to speed
								while(cur >= nextMarker){

									currentTrack++;

									// are we on the last song?
									// if not then increment the markers
									if(currentTrack < numTracks){
										currentMarker = nextMarker;
										nextMarker = trackInfo[currentTrack].marker;
									} else {
										nextMarker = duration;
										break;
									}
								}

								// now need to advance the album art and update the tooltip
								if(currentTrack <= numTracks){
									$("#tapebox").animate({ "left" : "-=125px" }, option.animationSpeed, "swing");
									if(option.tooltips) $(".tooltip").html("<p>"+ trackInfo[currentTrack-1].artist +"</p><p class='track'>"+ trackInfo[currentTrack-1].track +"</p>");
								}
							}
						}
					});

					$("#playtoggle").click(function() {	
						soundManager.togglePause("juke");
					});

					if(option.tooltips && !isTouchDevice()){
						$("#playhead").hover(function(){
							$(".tooltip").fadeIn(100);
						}, function(){
							$(".tooltip").fadeOut(100);
						});
					}
				});
			} else {
				if (option.debug){
					console.log("Juke can't see the required SoundManager 2 object.");
				}
			}
		});
	};

	$.fn.juke.option = {
		title: 				"Mixtape",
		imagesFolder: 		"public/images/juke/", 
		soundmanagerFolder: "public/swf/",
		placeholder: 		"images/juke/default.jpg",
		trackinfo: 			"trackinfo.json",
		audio: 				"mix.mp3",
		tooltips: 			false,
		animationSpeed: 	400,
		debug: 				false
	};
})(jQuery);