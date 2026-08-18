package backend;

import flixel.FlxG;
import flixel.math.FlxPoint;
import haxe.PosInfos;

using StringTools;

#if !mobile
import flixel.input.keyboard.FlxKey;
import flixel.input.keyboard.FlxKeyList;

private abstract InputListChecker(FlxKeyList)
{
	public inline function new(list:FlxKeyList)
		this = list;

	@:from static inline function fromFlxKeyList(list:FlxKeyList)
		return new InputListChecker(list);

	private inline function check(bleh:Int)
		return @:privateAccess this.check(bleh);

	@:op([]) function read(k:String, ?pos:PosInfos)
	{
		var i = k.toUpperCase();

		var key = FlxKey.fromString(i);
		if (key != NONE)
			return check(key);
		var bind = Controls.binds.get(i);
		if (bind != null)
		{
			for (key in bind)
				if (read(key))
					return true;
			return false;
		}
		if (k.length == 2 && k.charAt(0) == 'm')
		{
			return switch (@:privateAccess this.status)
			{
				case JUST_RELEASED:
					switch (k.charAt(1))
					{
						default:
							FlxG.mouse.justReleased;
						case '2':
							FlxG.mouse.justReleasedRight;
						case '3':
							FlxG.mouse.justReleasedMiddle;
					}
				case PRESSED:
					switch (k.charAt(1))
					{
						default:
							FlxG.mouse.pressed;
						case '2':
							FlxG.mouse.pressedRight;
						case '3':
							FlxG.mouse.pressedMiddle;
					}
				case RELEASED:
					switch (k.charAt(1))
					{
						default:
							!FlxG.mouse.pressed;
						case '2':
							!FlxG.mouse.pressedRight;
						case '3':
							!FlxG.mouse.pressedMiddle;
					}
				default:
					switch (k.charAt(1))
					{
						default:
							FlxG.mouse.justPressed;
						case '2':
							FlxG.mouse.justPressedRight;
						case '3':
							FlxG.mouse.justPressedMiddle;
					}
			}
		}
		Logging.warn('Unable to parse key code or keybind $i: Does not exist', pos);
		return false;
	}

	@:op(a.b) inline function fieldRead(k:String)
		return read(k);
}
#end

/**
	Class for easy access to keyboard controls.
	Disable using haxedef `FEY_NO_CONTROLS`
**/
class Controls
{
	#if !mobile
	@:allow(backend.Controls)
	static var binds:Map<String, Array<String>> = new Map();

	public static var pressed:InputListChecker;
	public static var justPressed:InputListChecker;
	public static var justReleased:InputListChecker;

	@:allow(Feyworks)
	public static function init()
	{
		pressed = FlxG.keys.pressed;
		justPressed = FlxG.keys.justPressed;
		justReleased = FlxG.keys.justReleased;

		FlxG.console.registerClass(Controls);
	}

	overload public static inline extern function setBind(name:String, key:String, ?pos:PosInfos)
	{
		// even if I let them bind to a key, it checks for the key first so the bind would be shadowed and useless anyways.
		if (FlxKey.fromString(name) != NONE)
			return Logging.warn('Cannot bind keys to name $name: Protected name', pos);
		binds.set(name.toUpperCase(), [key.toUpperCase()]);
	}

	overload public static inline extern function setBind(name:String, keys:Array<String>, ?pos:PosInfos)
	{
		if (FlxKey.fromString(name) != NONE)
			return Logging.warn('Cannot bind keys to name $name: Protected name', pos);
		binds.set(name.toUpperCase(), keys.map(k -> k.toUpperCase()));
	}

	overload public static inline extern function setAxis(name:String, neg:String, pos:String)
	{
		setBind('$name.NEG', neg);
		setBind('$name.POS', pos);
	}

	overload public static inline extern function setAxis(name:String, neg:Array<String>, pos:Array<String>)
	{
		setBind('$name.NEG', neg);
		setBind('$name.POS', pos);
	}

	public static inline function getAnalog(x:String, y:String, ?point:FlxPoint = null, normalize:Bool = true)
	{
		var p = point == null ? FlxPoint.weak(getAxis(x), getAxis(y)) : point.set(getAxis(x), getAxis(y));
		if (normalize)
			p.normalize();
		return p;
	}

	public static inline function getAxis(name:String)
	{
		return (pressed['$name.POS'] ? 1 : 0) - (pressed['$name.NEG'] ? 1 : 0);
	}

	public static inline function getJustPressedAxis(name:String)
	{
		return (justPressed['$name.POS'] ? 1 : 0) - (justPressed['$name.NEG'] ? 1 : 0);
	}
	#else
	@:allow(Feyworks)
	static function init() {}
	#end
}
