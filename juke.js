(function ($) {
	$.fn.juke = function (option) {
		// override defaults with specified option
		option = $.extend({}, $.fn.juke.option, option);

		// Help out IE a bit with AJAX calls
		$.ajaxSetup({
			'xhr': function() {
				return window.ActiveXObject ? new ActiveXObject("Microsoft.XMLHTTP") : new XMLHttpRequest();
			}
		});

		return this.each(function () {
			var currentTrack = 1,
				currentMarker,
				nextMarker,
				numTracks,
				cur = 0,
				duration,
				title = document.title,
				trackInfo,
				elem = $(this),
				tapebox,
				playtoggle,
				shadowleft,
				shadowright,
				tooltip,
				tapeOffset;

			var isJSON = function (str) {
				if (str.length === 0) {
					return false;
				}
				str = str.replace(/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g, '@');
				str = str.replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g, ']');
				str = str.replace(/(?:^|:|,)(?:\s*\[)+/g, '');
				return (/^[\],:{}\s]*$/).test(str);
			};

			// Retrieves track markers
			var getMarker = function (index) {
				var marker = trackInfo[index].marker,
					testPattern = /:/, // Check for a colon
					minutePattern = /^\d*(?=:)/, // Find the digits at the start and before ':'
					secondPattern = /[0-5][0-9]$/, // Find the two digits at the end (00 - 59)
					min,
					sec;

				// If the marker is formatted as xx:xx then convert it to raw seconds
				if (testPattern.test(marker)) {
					min = parseInt(minutePattern.exec(marker), 10);
					sec = parseInt(secondPattern.exec(marker), 10);
					return min * 60 + sec;
				// Otherwise treat it as raw seconds
				} else {
					return parseInt(trackInfo[index].marker, 10);
				}
			};

			// Updates the new artist and track info
			// Gets a localized iTunes Store link
			var updateInfo = function (artist, track) {
				var newString = artist + " - <em class='track'>" + track + "</em>",
					countryCode,
					queryString,
					link;

				if (option.itunes) {
					$.ajax({
						url: 'http://api.wipmania.com/jsonp?callback=?',
						dataType: 'jsonp',
						success: function (data) {
							countryCode = data.address.country_code;

							queryString = "http://itunes.apple.com/search?entity=song&country=" + countryCode + "&term=" + encodeURIComponent(artist + " " + track) + "&limit=5&callback=?";

							// Search the store
							$.getJSON(queryString, function (data) {
								if (data.resultCount === 1) {
									link = data.results[0].trackViewUrl;
								} else if (data.resultCount > 1) {
									$.each(data.results, function () {
										if (this.trackName === track) {
											link = this.trackViewUrl;
										}
									});			
								} else {
									link = null;
								}

								if (link !== null) {
									newString += " (<a href='" + link + "' class='itunes-link'>iTunes</a>)";
								}

								tooltip.html(newString);
							});
						}
					});
				} else {
					tooltip.html(newString);
				}
			};

			// Update the element alignment if the window is resized
			$(window).resize(function () {
				shadowleft.css({right: shadowleft.parent().width() / 2 + 63});
				shadowright.css({left: shadowright.parent().width() / 2 + 64});
				tapeOffset = tapebox.parent().width() / 2 - 62;
				if (cur > 0) {
					tapeOffset -= currentTrack * 125;
				}
				tapebox.css({left: tapeOffset});
			});

			var setup = function () {

				// Set the element to hidden instead of display: none so it has size
				elem.css({
					"display": "block",
					"visibility": "hidden"
				});

				// load trackinfo JSON as string or from URL
				if (isJSON(option.trackinfo)) {
					trackInfo = $.parseJSON(option.trackinfo);
				} else {
					$.ajax({
						url: option.trackinfo,
						async: false, // I know, but it's a small request
						success: function (data) {
							trackInfo = data;
							duration = parseInt(trackInfo.duration, 10);
							trackInfo = trackInfo.tracks;
							currentMarker = getMarker(currentTrack - 1);
							nextMarker = getMarker(currentTrack);
							numTracks = parseInt(trackInfo.length, 10);
						}
					});
				}

				// setup the DOM structure inside empty div
				// wrap the albumart list
				elem.children().wrapAll('<ul id="tapebox"/>');

				// prepend the placeholder to the list
				$("#tapebox").wrapAll('<div id="displaybox"/>');
				$("#tapebox").prepend('<li><img src="' + option.placeholder + '" width="125"></li>');

				// prepend the bg image
				$("#displaybox").prepend('<img src="' + option.imagesFolder + 'bg.png" alt="">');

				// add the other structure around the list
				elem.prepend('<div id="shadowleft" class="shadow"></div><div id="shadowright" class="shadow"></div><div id="playhead"><img src="' + option.imagesFolder + 'playhead_overlay.png"><div id="playtoggle" class="hover"></div></div>');
				elem.append('<div id="displaybox_overlay"><img src="' + option.imagesFolder + 'displaybox_overlay.png" /></div>');
				if (option.tooltips) {
					elem.append('<div class="tooltip">' + option.title + '</div>');
					tooltip = $(".tooltip");
				}
				if (option.debug) {
					elem.append('<span id="skipbackward">REV</span>&nbsp;-&nbsp;<span id="skipforward">FWD</span>');
				}

				shadowleft  = $("#shadowleft");
				shadowright = $("#shadowright");
				tapebox     = $("#tapebox");
				playtoggle  = $("#playtoggle");

				// SM handles all of the events from here on out
				soundManager.onready(function () {
					soundManager.createSound({
						id: "juke",
						url: $.trim(option.audio),
						onplay: function () {
							playtoggle.addClass('playing');
							document.title = "\u25B6 " + option.title + " - " + title;
							if (cur === 0) {
								tapeOffset = tapebox.parent().width() / 2 - 62 - 125;
								tapebox.animate({"left": tapeOffset}, option.animationSpeed, "swing");

								if (option.tooltips) {
									updateInfo(trackInfo[currentTrack - 1].artist, trackInfo[currentTrack - 1].track);
								}
							}
						},
						onpause: function () {
							playtoggle.removeClass('playing');
							document.title = title;
						},
						onfinish: function () {
							playtoggle.removeClass('playing');
							document.title = title;
						},
						whileplaying: function () {
							cur = parseInt(soundManager.getSoundById("juke").position / 1000, 10);

							// are we done?
							if (cur >= duration) {
								soundManager.pause("juke");
							}

							// check to see if we've changed songs
							if (cur >= nextMarker) {

								// make sure we're up to speed
								currentTrack += 1;
								// are we on the last song?
								// if not then increment the markers
								if (currentTrack < numTracks) {
									currentMarker = nextMarker;
									nextMarker = getMarker(currentTrack);
								} else {
									nextMarker = duration;
								}

								// now need to advance the album art and update the tooltip
								tapebox.animate({ "left" : "-=125px" }, option.animationSpeed, "swing");
								if (option.tooltips) {
									updateInfo(trackInfo[currentTrack - 1].artist, trackInfo[currentTrack - 1].track);
								}
							}

							if (option.debug) {
								console.log("total: " + duration + ", currently at: " + cur + ", next marker: " + nextMarker);
							}
						}
					});

					$("#playtoggle").click(function() {	
						soundManager.togglePause("juke");
					});

					if (option.debug) {
						$("#skipforward").click(function(){
							soundManager.getSoundById("juke").setPosition(soundManager.getSoundById("juke").position + 5000);
						});
						$("#skipbackward").click(function(){
							soundManager.getSoundById("juke").setPosition(soundManager.getSoundById("juke").position - 5000);
						});
					}

					// It's alive!!!
					// Make sure the elements are aligned properly for the width of the div
					// Show the juke <div> once all of the elements are in place
					shadowleft.css({right: shadowleft.parent().width() / 2 + 63});
					shadowright.css({left: shadowright.parent().width() / 2 + 64});
					tapebox.css({left: tapebox.parent().width() / 2 - 62});
					elem.css("visibility", "visible");
				});	
			};

			// Load SM2 and start the setup process
			window.SM2_DEFER = true;
			$.ajax({
				url: option.SM2,
				success: function () {
					window.soundManager        = new SoundManager();
					soundManager.url           = option.soundmanagerFolder + 'soundmanager2_flash_xdomain/';
					soundManager.useHTML5Audio = true;
					soundManager.autoLoad      = true;
					soundManager.preferFlash   = false;
					soundManager.consoleOnly   = true;
					soundManager.debugMode     = option.debug;
					soundManager.wmode         = 'transparent';
					soundManager.beginDelayedInit();
					setup();
				}
			});
		});
	};

	$.fn.juke.option = {
		title: "Mixtape",
		imagesFolder: "public/images/juke/", 
		soundmanagerFolder: "public/swf/",
		placeholder: "images/juke/default.jpg",
		trackinfo: "trackinfo.json",
		SM2: "public/docs/js/min/soundmanager2.min.js",
		itunes: true,
		audio: "mix.mp3",
		tooltips: false,
		animationSpeed: 400,
		debug: false
	};
})(jQuery);