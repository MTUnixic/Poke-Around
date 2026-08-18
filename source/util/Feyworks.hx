package util;

import backend.Controls;
import backend.Controls;
import backend.Logging;
import backend.Logging;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxState;
import flixel.group.FlxContainer;

@:structInit private class FeyworksConfig {
  public var discordInvite(default, null):String = '';
	public var extraLogInfo(default, null):Void->String = () -> '';
	public var initialState(default, null):Class<FlxState>;
}

class Feyworks {
	public static var config(default, null):FeyworksConfig;
	static var initFunc:Void->FlxState;

	public static var overlayGroup:FlxContainer = new FlxContainer();
	public static var overlayCam:FlxCamera;

	/**
				Initializes Feyworks and associated classes. call this **only after** `new FlxGame(...)`. It *will* throw and yell at you if you call it before initializing `FlxGame`.
				Feywork's options and defaults are as follows:
			```haxe
			?discordInvite:String = '';// the link to your discord server, if one exists.
			?extraLogInfo:Void->String = ()->'';// function called during crash logging to provide project-specific info about the game state.
			initialState:Class<FlxState>;// the state to initialize onto. Has no default and is obligatory.
```
	**/
	@:allow(Main)
	static function init(config:FeyworksConfig) {
		Feyworks.config = config;
		initFunc = Type.createInstance.bind(config.initialState, []);

		overlayCam = new FlxCamera();
		overlayCam.bgColor = 0x00000000;

		overlayGroup.camera = overlayCam;

		FlxG.cameras.add(overlayCam, false);
		FlxG.cameras.cameraAdded.add((cam) -> {
			if (cam == overlayCam)
				return;
			if (overlayCam.flashSprite != null)
				FlxG.cameras.remove(overlayCam, false);
			else {
				overlayCam = new FlxCamera();
				overlayCam.bgColor = 0x00000000;
				overlayGroup.camera = overlayCam;
			}
			FlxG.cameras.add(overlayCam);
		});

		FlxG.plugins.addPlugin(overlayGroup);
		FlxG.plugins.drawOnTop = true;

		Logging.init();

		Controls.init();

		restart();
	}

	public static function restart() {
		FlxG.switchState(initFunc);
	}
}
