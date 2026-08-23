package objects;

import PlayState;
import backend.flixel.FlxThreeSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import haxe.EnumTools.EnumValueTools;

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
		animation.play("empty");
		setGraphicSize(width / 1.5, height / 1.5);
		updateHitbox();
	}

	public function setItem(item:PlayerItem)
	{
		value = item;

		var restOffsetY = offset.y;

		FlxTween.tween(offset, { y: restOffsetY + 100 }, 0.5, { ease: FlxEase.quadInOut });
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