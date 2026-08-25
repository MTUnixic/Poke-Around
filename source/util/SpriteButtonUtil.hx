package util;

import flixel.FlxG;
import flixel.FlxSprite;
import util.AudioUtil;
import util.MouseUtil;

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

		if (MouseUtil.justClicked(this))
		{
			AudioUtil.playSound('assets/sounds/click.wav');
			onClick();
		}
	}
}