JUKE
====

Juke is the best way to show off your mixtapes.

It supports `<audio>` and Flash 8+, so it works on almost any device. It even provides a link to your visitors' regional iTunes Store to purchase each track. It runs on [jQuery](http://jquery.com/) and [SoundManager 2](http://www.schillmania.com/projects/soundmanager2/).

How to use Juke
---------------

Put this with the rest of your stylesheets and script tags.

	<link rel="stylesheet" href="juke.css" type="text/css">
	<script type="text/javascript" src="jquery.js"></script>
	<script type="text/javascript" src="juke.js"></script>

Include this where you want Juke to shop on the page.

	<div id="juke">
		<ul>
			<li><img src="album art goes here"></li>
	    </ul>
	</div>

Initialize Juke and override these defaults if you need to.
	
	<script type="text/javascript">
	    $(function(){
	        $("#juke").juke({
	            title:              "Mixtape",
	            imagesFolder:       "public/images/juke/",    
	            soundmanagerFolder: "public/swf/",             
	            placeholder:        "images/juke/default.jpg",
	            trackinfo:          "trackinfo.json",
	            SM2:                "public/docs/js/min/soundmanager2.min.js",
	            itunes:             true,
	            audio:              "mix.mp3",                 
	            tooltips:           false,                               
	            animationSpeed:     400,                                 
	            debug:              false                                
	        });
	    });
	</script>

Configuration Options
---------------------

- **title** Name of the mixtape, it gets shown in window title when playing
- **imagesFolder** Folder of Juke's images (e.g. background, overlays)
- **soundmanagerFolder** Folder of SoundManager2 SWFs
- **placeholder** Image for mixtape (shown before album art)
- **trackinfo** JSON-formatted string or URL to file
- **SM2** URL to the SoundManager2 library so that Juke can load it
- **itunes** Place a localized iTunes Store link beside the track info
- **audio** URL to audio file (MP3, M4A or WAV)
- **tooltips** Hover over playhead for track metadata
- **animationSpeed** Speed of album art animation (in milliseconds)
- **debug** Spits out lots of stuff to the console

Juke uses JSON to get its global and track metadata. This includes a start marker and the artist name and track name for each track. The JSON object can be passed to Juke as a string or a URL to this information. Time markers can be formatted as raw seconds or "mm:ss".

	{
		"duration": "8:20",
		"tracks":
		[
			{
				"marker": "0",
				"artist": "Geotic/Virtual Boy",
				"track": "Through the Lush and Undiscovered/Thrust"
			},
			{
				"marker": "78",
				"artist": "Caribou",
				"track": "Jamelia (Gold Panda Remix)"
			},
			{
				"marker": "5:10",
				"artist": "Gil Scott-Heron and Jamie XX",
				"track": "Running"
			}
		]
	}
