package objects;

import flixel.FlxSprite;
import flixel.group.FlxSpriteContainer.FlxTypedSpriteContainer;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

using flixel.graphics.FlxAsepriteUtil;

class DealerSprite extends FlxTypedSpriteContainer<FlxSprite>
{
	var sprite:FlxSprite;
	var idleTimer:Float = 0.0;

	var postAnimTimer:FlxTimer;

	public function new(?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);

		sprite = new FlxSprite();
		sprite.loadAseAtlasAndTagsByIndex("assets/images/pokah-dealer.png", "assets/images/pokah-dealer.json");
		sprite.animation.getByName("ToThink").looped = false;
		sprite.animation.getByName("ToLook").looped = false;
		sprite.animation.getByName("GrabCard").looped = false;
		sprite.animation.getByName("SlamAllIn").looped = false;
		sprite.animation.getByName("TossRaise").looped = false;
		sprite.animation.play("Idle");
		sprite.setGraphicSize(sprite.width * 2.5, sprite.height * 2.5);
		add(sprite);
	}

	override function update(elapsed:Float)
	{
		idleTimer -= elapsed;
		if (idleTimer <= 0)
			sprite.animation.play("Idle");

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
		postAnimTimer = FlxTimer.wait(sprite.animation.curAnim.frameDuration * sprite.animation.curAnim.frames.length, () ->
		{
			var anim = sprite.animation.getByName(animName);
			if (anim == null)
				return;
		});
	}

	public function spawnHint(hint:String)
	{
		var txt = new FlxText(sprite.width + 100, 80, 200, hint, 16);
		txt.color = 0xff6d758d;
		/* TODO: doesnt work for some reason:
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
		sprite.animation.play("Call");
		spawnHint("Called");
	}

	public function raise(target:Int, allIn:Bool = false)
	{
		cancelTimer();
		if (allIn)
		{
			idleTimer = 20;
			sprite.animation.play("SlamAllIn");
			postAnim("AllIn");
			spawnHint('ALL IN WITH $$${target}!');
		}
		else
		{
			idleTimer = 0.5;
			sprite.animation.play("TossRaise");
			spawnHint('Raised to $$${target}');
		}
	}

	public function fold()
	{
		cancelTimer();
		idleTimer = 1.5;
		sprite.animation.play("Fold");
		spawnHint("Folded");
	}

	public function think()
	{
		cancelTimer();
		idleTimer = Math.POSITIVE_INFINITY;
		sprite.animation.play("ToThink");
		postAnim("Think");
	}

	public function grabCard()
	{
		cancelTimer();
		idleTimer = 0.7;
		sprite.animation.play("GrabCard");
	}

	public function look()
	{
		cancelTimer();
		idleTimer = 1.5;
		sprite.animation.play("ToLook");
		postAnim("Look");
	}
}