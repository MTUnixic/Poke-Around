package objects;

import backend.flixel.FlxThreeSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import util.CardUtil.CardData;

class Card extends FlxThreeSprite
{
	public var data:CardData;

	public function new(?data:CardData)
	{
		super();

    	this.data = data;

		loadGraphic("assets/images/cards/card-back.png", true, 88, 124);
		setGraphicSize(width*0.8, height*0.8);
		animation.add("back-a", [0]);
		animation.add("back-b", [1]);

		animation.play("back-a");
		centerOrigin();
		centerOffsets();
	}

	public function reveal(?data:CardData, animate:Bool = true)
	{
		this.data = data ?? this.data;

		if (!animate) {
			loadSuitSprite(this.data);
			return;
		}

		var pW = width, pH = height;

		FlxTween.tween(this, { angleY: 90 }, 0.5, { ease: FlxEase.quadIn, onComplete: function(tween:FlxTween) {
			loadSuitSprite(this.data);
			setGraphicSize(pW, pH);
			this.angleY = -90;
			FlxTween.tween(this, { angleY: 0 }, 0.5, { ease: FlxEase.quadOut });
		}});
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