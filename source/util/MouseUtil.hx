package util;

import flixel.FlxBasic;
import flixel.FlxG;

class MouseUtil
{
	#if FLX_MOUSE
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

	public static inline function isHovering(object:FlxBasic):Bool
		return FlxG.mouse.overlaps(object);

	#else
    public static inline function mouseCamera(power:Int = 24, ?zoom:Float)
	{
        if (zoom != null) FlxG.camera.zoom = zoom;
	}

    public static inline function isClicked(object:FlxBasic):Bool
		return isHovering(object);

    public static inline function justClicked(object:FlxBasic):Bool
	{
		var touches = FlxG.touches.justStarted();
		if (touches.length != 1)
			return false;
		return touches[0].overlaps(object);
	}

	public static inline function isHovering(object:FlxBasic):Bool
	{
		var touches = FlxG.touches.list;
		if (touches.length != 1)
			return false;
		return touches[0].overlaps(object);
	}
	#end
}