package objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteContainer.FlxTypedSpriteContainer;
import flixel.math.FlxRandom;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

using flixel.graphics.FlxAsepriteUtil;

class PlayerSprite extends FlxTypedSpriteContainer<FlxSprite>
{
	var playerSprite:FlxSprite;
	var idleTimer:Float = 0.0;

	var postAnimTimer:FlxTimer;

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
		playerSprite.setGraphicSize(playerSprite.width * 2.5, playerSprite.height * 2.5);
		add(playerSprite);
	}

	override function update(elapsed:Float)
	{
		idleTimer -= elapsed;
		if (idleTimer <= 0)
			playerSprite.animation.play("Idle");

		super.update(elapsed);
	}

	function cancelTimer()
	{	
		if (postAnimTimer != null && postAnimTimer.active)
		{
			postAnimTimer.cancel();
			postAnimTimer.destroy();
		}
	}

	function postAnim(animName:String)
	{
		cancelTimer();
		postAnimTimer = FlxTimer.wait(playerSprite.animation.curAnim.frameDuration * playerSprite.animation.curAnim.frames.length, () ->
		{
			var anim = playerSprite.animation.getByName(animName);
			if (anim == null)
				return;
		});
	}

	public function spawnHint(hint:String)
	{
		var txt = new FlxText(playerSprite.width + 60, 60, 200, hint, 16);
		/* TODO: doesnt work for some reason
		txt.velocity.x = FlxG.random.float(-90, 90);
		txt.velocity.y = -200;
		txt.acceleration.y = 70;
		*/
		FlxTween.tween(txt, { alpha: 0 }, 1.5, { ease: FlxEase.quintIn, onComplete: (_) ->
		{
			txt.destroy();
		}});
		add(txt);
	}

	public function forceIdle()
	{
		cancelTimer();
		idleTimer = -1;
	}

	public function call()
	{
		cancelTimer();
		idleTimer = 1.5;
		playerSprite.animation.play("Call");
		spawnHint("Called");
	}

	public function raise(target:Int, allIn:Bool = false)
	{
		cancelTimer();
		if (allIn)
		{
			idleTimer = 4;
			playerSprite.animation.play("SlamAllIn");
			postAnim("AllIn");
			spawnHint('ALL IN WITH $$${target}!');
		}
		else
		{
			idleTimer = 0.5;
			playerSprite.animation.play("TossRaise");
			spawnHint('Raised to $$${target}');
		}
	}

	public function fold()
	{
		cancelTimer();
		idleTimer = 1.5;
		playerSprite.animation.play("Fold");
		spawnHint("Folded");
	}

	public function think()
	{
		cancelTimer();
		idleTimer = Math.POSITIVE_INFINITY;
		playerSprite.animation.play("ToThink");
		postAnim("Think");
	}

	public function grabCard()
	{
		cancelTimer();
		idleTimer = 0.7;
		playerSprite.animation.play("GrabCard");
	}

	public function look()
	{
		cancelTimer();
		idleTimer = 1.5;
		playerSprite.animation.play("ToLook");
		postAnim("Look");
	}
}