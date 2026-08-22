package objects;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteContainer.FlxTypedSpriteContainer;

using flixel.graphics.FlxAsepriteUtil;

class PlayerSprite extends FlxTypedSpriteContainer<FlxSprite>
{
	var playerSprite:FlxSprite;
	var idleTimer:Float = 0;

	public function new(?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);

		playerSprite = new FlxSprite();
		playerSprite.loadAseAtlasAndTagsByIndex("assets/images/pokah-dealer.png", "assets/images/pokah-dealer.json");
		playerSprite.animation.getByName("ToThink").looped = false;
		playerSprite.animation.getByName("ToLook").looped = false;
		playerSprite.animation.getByName("GrabCard").looped = false;
		playerSprite.animation.getByName("SlamAllIn").looped = false;
		playerSprite.animation.getByName("TossRaise").looped = false;
		playerSprite.animation.play("Idle");
		add(playerSprite);
	}

	override function update(elapsed:Float)
	{
		idleTimer -= elapsed;
		if (idleTimer <= 0)
			playerSprite.animation.play("Idle");

		super.update(elapsed);
	}
}