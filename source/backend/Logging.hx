package backend;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxContainer;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import haxe.Exception;
import haxe.Log;
import haxe.PosInfos;
import util.Feyworks;

private class FeyLogMessage extends FlxContainer
{
	public var x(default, set):Float = 0;
	public var y(default, set):Float = 0;
	public var width(get, null):Float;
	public var height(get, null):Float;

	function get_width()
		return body.width;

	function get_height()
		return body.height;

	function set_x(v:Float)
	{
		if (x == v)
			return v;
		x = v;
		updatePos();
		return v;
	}

	function set_y(v:Float)
	{
		if (y == v)
			return v;
		y = v;
		updatePos();
		return v;
	}

	public var body:FlxSprite;
	public var flair:FlxSprite;
	public var title:FlxText;
	public var text:FlxText;
	public var lifetime:Float;

	public function new(titleStr:String, message:String, time:Float = 3, color:FlxColor = 0xFF888888, detail:FlxColor = 0xFF666666)
	{
		super();
		title = new FlxText(0, 0, 0, titleStr, 14);
		text = new FlxText(0, 0, title.textField.textWidth * 2, message, 12);
		body = new FlxSprite().makeGraphic(Std.int(text.width) + 60, Std.int(text.textField.textHeight) + 50, color);
		flair = new FlxSprite().makeGraphic(10, Std.int(body.height), detail);
		#if FLX_DEBUG
		title.ignoreDrawDebug = true;
		text.ignoreDrawDebug = true;
		flair.ignoreDrawDebug = true;
		body.ignoreDrawDebug = true;
		#end
		add(body);
		add(flair);
		add(title);
		add(text);
		body.scrollFactor.set();
		flair.scrollFactor.set();
		title.scrollFactor.set();
		text.scrollFactor.set();

		lifetime = time;
		updatePos();
		Logging.loggingGroup.insert(0, this);
		Logging.positionMessages();
	}

	override public function update(e:Float)
	{
		lifetime -= e;
		if (lifetime <= 0)
		{
			if (lifetime < -1)
			{
				Logging.loggingGroup.remove(this, true);
				Logging.positionMessages();
				destroy();
				return;
			}
			var alpha = 1 - Math.abs(lifetime);
			body.alpha = alpha;
			flair.alpha = alpha;
			title.alpha = alpha;
			text.alpha = alpha;
		}
	}

	function updatePos()
	{
		body.setPosition(x, y);
		flair.setPosition(x, y);
		title.setPosition(x + 20, y + 4);
		text.setPosition(x + 20, y + 25);
	}
}

/**
	Class for logging and displaying quick info messages. Cannot be disabled.
	If `debug` is off, only traces instead of displaying the message onscreen, unless haxedef `FEY_ALWAYS_LOG` is on.
**/
class Logging
{
	@:allow(backend.Logging)
	static var loggingGroup:FlxTypedGroup<FeyLogMessage> = new FlxTypedGroup();

	@:allow(Feyworks)
	public static function init()
	{
		FlxG.console.registerClass(Logging);
		Feyworks.overlayGroup.add(loggingGroup);
	}

	@:allow(backend.Logging)
	static function positionMessages()
	{
		var curY:Float = 0;
		loggingGroup.forEach(msg ->
		{
			msg.y = curY;
			curY += msg.height + 5;
		});
	}

	public static function write(data:Dynamic, color:FlxColor, ?subcolor:FlxColor, prefix:String = '', time:Float = 3, ?pos:PosInfos):Void
	{
		var msg = prefix + Std.string(data);
		Log.trace(msg, pos);
		new FeyLogMessage('${pos.className}(${pos.methodName}::${pos.lineNumber})', msg, time, color, subcolor ?? color.getDarkened(0.2));
	}

	public static inline function log(data:Dynamic, time:Float = 3, ?pos:PosInfos):Void
	{
		write(data, 0xFF4488FF, pos);
	}

	public static inline function warn(data:Dynamic, time:Float = 3, ?pos:PosInfos):Void
	{
		write(data, 0xFFFF8800, 'Warning - ', pos);
	}

	public static inline function error(data:Exception, time:Float = 3, ?pos:PosInfos):Void
	{
		write(data, 0xFFFF0000, 'Error - ', pos);
	}
}
