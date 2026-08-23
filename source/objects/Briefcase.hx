package objects;

import flixel.FlxSprite;
import flixel.group.FlxSpriteContainer.FlxTypedSpriteContainer;

class Briefcase extends FlxTypedSpriteContainer<FlxSprite>
{
	var briefcase:FlxSprite;

	public function new(x:Float, y:Float)
	{
		super(x, y);

		briefcase = new FlxSprite(0, 0);
		briefcase.loadGraphic('assets/images/breifcase.png', false, 240, 120);
		add(briefcase);
	}
}