package objects;

import backend.CardManager.CardData;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class Card extends FlxThreeSprite
{
	public var data:CardData;

	public function new()
	{
		super();

		loadGraphic("assets/images/cards/card-back.png", true, 88, 124);
		animation.add("back-a", [0]);
		animation.add("back-b", [1]);

		animation.play("back-a");
		centerOrigin();
		centerOffsets();
	}

	public function reveal(?data:CardData, animate:Bool = true)
	{
		this.data = this.data ?? data;

		if (animate)
		{
			FlxTween.tween(this, { angleY: 90 }, 0.5, { ease: FlxEase.quadIn, onComplete: function(tween:FlxTween)
			{
				loadSuitSprite(this.data);
				this.angleY = -90;
				FlxTween.tween(this, { angleY: 0 }, 0.5, { ease: FlxEase.quadOut });
			}});
		}
		else 
			loadSuitSprite(this.data);
	}

	function loadSuitSprite(data:CardData)
	{
		var suitName = switch (data.suit)
		{
			case 0: "clubs";
			case 1: "diamonds";
			case 2: "hearts";
			case 3: "spades";
			default: throw 'Invalid suit ${data.suit}';
		};

		loadGraphic('assets/images/cards/card-$suitName.png', true, 88, 124);
		animation.add("card", [data.num - 1]);
		animation.play("card");
	}
}