Juke is the best way to show off your mixtapes.

It runs on [jQuery](http://jquery.com/) and [SoundManager 2](http://www.schillmania.com/projects/soundmanager2/). The sound goes through Flash 8+ or &lt;audio&gt;, and SoundManager handles all of that (it's *amazing*), so it works on almost any device.

How to use Juke
---------------

<pre>
&lt;link rel=&quot;stylesheet&quot; href=&quot;juke.css&quot; type=&quot;text/css&quot; &gt;
&lt;script type=&quot;text/javascript&quot; src=&quot;jquery.js&quot;&gt;&lt;/script&gt;
&lt;script type=&quot;text/javascript&quot; src=&quot;soundmanager2.js&quot;&gt;&lt;/script&gt;
&lt;script type=&quot;text/javascript&quot; src=&quot;juke.js&quot;&gt;&lt;/script&gt;

&lt;div id=&quot;juke&quot;&gt;
	&lt;ul&gt;
		&lt;li&gt;&lt;img src=&quot;album art goes here&quot;&gt;&lt;/li&gt;
	&lt;/ul&gt;
&lt;/div&gt;

&lt;script type=&quot;text/javascript&quot;&gt;
	$(function(){
		$(&quot;#juke&quot;).juke({
			title: 				&quot;Mixtape&quot;,
			imagesFolder: 		&quot;public/images/juke/&quot;, 	
			soundmanagerFolder: &quot;public/swf/&quot;,			 
			placeholder: 		&quot;images/juke/default.jpg&quot;,
			trackinfo: 			&quot;trackinfo.json&quot;,			 
			audio: 				&quot;mix.mp3&quot;,				 
			tooltips: 			false,								 
			animationSpeed: 	400,								 
			debug: 				false								 
		});
	});
&lt;/script&gt;
</pre>

Configuration Options
---------------------

- **title** Name of the mixtape, it gets shown in window title when playing
- **imagesFolder** Folder of Juke's images (e.g. background, overlays)
- **soundmanagerFolder** Folder of SoundManager2 SWFs
- **placeholder** Image for mixtape (shown before album art)
- **trackinfo** JSON-formatted string or URL to file
- **audio** URL to audio file (MP3, M4A or WAV)
- **tooltips** Hover over playhead for track metadata
- **animationSpeed** Speed of album art animation (in milliseconds)
- **debug** Spits out lots of stuff to the console

Juke uses a JSON object to store global and track metadata. This includes a start marker, artist name and track name for each track. The JSON object can be passed to Juke as a string or as a URL to a file with this information. You can format the markers as raw seconds or "mm:ss".

<pre>
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
}
</pre>