package objects;

import PlayState;
import backend.flixel.FlxThreeSprite;
import flixel.FlxG;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import haxe.EnumTools.EnumValueTools;
import util.AudioUtil;

class ItemCard extends FlxThreeSprite
{
	public var value:Null<PlayerItem>;

	public function new(?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);

		loadGraphic("assets/images/pokuhcaards.png", true, 64, 80);
		animation.add("empty", [0]);
		animation.add("DesignManual", [1]);
		animation.add("Calculator", [2]);
		animation.add("Marker", [3]);
		animation.add("GoldenBullet", [4]);
		animation.add("Intimidation", [5]);
		animation.add("Profit", [6]);
		animation.play("empty");
		setGraphicSize(width / 1.5, height / 1.5);
		updateHitbox();
	}

	public function setItem(item:PlayerItem)
	{
		value = item;

		var restOffsetY = offset.y;

		AudioUtil.playSound("assets/sounds/Sonic.exe Ding SFX.wav");

		FlxTween.tween(offset, { y: restOffsetY + 125 }, 0.5, { ease: FlxEase.quadInOut });
		FlxTween.tween(this, { angleY: 270 }, 0.5, { ease: FlxEase.quadIn, onComplete: function(tween:FlxTween) {
			animation.play(EnumValueTools.getName(item));
			this.angleY = -270;
			FlxTween.tween(this, { angleY: 0 }, 1, { ease: FlxEase.quadOut });
			FlxTween.tween(this.offset, { y: restOffsetY }, 1, { ease: FlxEase.quintIn });
		}});
	}

	public function use()
	{
		value = null;
		animation.play("empty");
	}
}