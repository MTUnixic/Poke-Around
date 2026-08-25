package objects;

import flixel.FlxSprite;
import flixel.group.FlxSpriteContainer.FlxTypedSpriteContainer;
import flixel.util.FlxTimer;

class Briefcase extends FlxTypedSpriteContainer<FlxSprite>
{
	var briefcase:FlxSprite;
	var cards:Array<FlxSprite> = [];

	public function new(x:Float, y:Float)
	{
		super(x, y);

		briefcase = new FlxSprite(0, 0);
		briefcase.loadGraphic('assets/images/pokuhbreifcase.png', true, 240, 120);
		briefcase.animation.add('idle', [0], 0, false);
		briefcase.animation.add('open', [0, 1, 2], 8, false);
		briefcase.animation.add('close', [2, 1, 0], 8, false);
		briefcase.animation.play('idle');
		FlxTimer.wait(0.8, () -> briefcase.animation.play('open'));
		add(briefcase);
	}

	public function addCard(card:FlxSprite)
	{
		cards.push(card);
		add(card);
	}
}