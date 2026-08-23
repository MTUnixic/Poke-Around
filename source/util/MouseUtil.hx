package util;

import flixel.FlxBasic;
import flixel.FlxG;

class MouseUtil
{
    public static inline function mouseCamera(power:Int = 24, ?zoom:Float)
	{
		FlxG.camera.scroll.x = (FlxG.mouse.x - FlxG.width / 2) / power;
		FlxG.camera.scroll.y = (FlxG.mouse.y - FlxG.height / 2) / power;

        if (zoom != null) FlxG.camera.zoom = zoom;
	}

    public static inline function isClicked(object:FlxBasic):Bool
		return FlxG.mouse.overlaps(object) && FlxG.mouse.pressed;

    public static inline function justClicked(object:FlxBasic):Bool
		return FlxG.mouse.overlaps(object) && FlxG.mouse.justPressed;
}