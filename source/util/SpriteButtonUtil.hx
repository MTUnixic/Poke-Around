package util;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxTimer;

class SpriteButtonUtil extends FlxSprite
{
	public var onClick:Void->Void;

	public function new(?x:Float = 0, ?y:Float = 0, ?graphic:Dynamic = null, onClick:Void->Void)
	{
		super(x, y, graphic);

		this.onClick = onClick;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (FlxG.mouse.overlaps(this) && FlxG.mouse.justPressed)
			onClick();
	}
}