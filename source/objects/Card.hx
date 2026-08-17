package objects;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

enum CardSuit
{
	Clubs(t:CardType);
	Diamonds(t:CardType);
	Hearts(t:CardType);
	Spades(t:CardType);
}

enum CardType
{
	Numbered(n:Int);
	Ace;
	Jack;
	Queen;
	King;
}

class Card extends FlxThreeSprite
{
	public var suit:CardSuit;

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

	public function reveal(?suit:CardSuit, animate:Bool = true)
	{
		this.suit = this.suit ?? suit;

		if (animate)
		{
			FlxTween.tween(this, { angleY: 90 }, 0.5, { ease: FlxEase.quadIn, onComplete: function(tween:FlxTween)
			{
				loadSuitSprite(this.suit);
				this.angleY = -90;
				FlxTween.tween(this, { angleY: 0 }, 0.5, { ease: FlxEase.quadOut });
			}});
		}
		else 
			loadSuitSprite(this.suit);
	}

	function loadSuitSprite(suit:CardSuit)
	{
		var suitName = switch (suit)
		{
			case CardSuit.Clubs(_): "clubs";
			case CardSuit.Diamonds(_): "diamonds";
			case CardSuit.Hearts(_): "hearts";
			case CardSuit.Spades(_): "spades";
		};

		loadGraphic('assets/images/cards/card-$suitName.png', true, 88, 124);
		animation.add("ace", [0]);
		animation.add("n2", [1]);
		animation.add("n3", [2]);
		animation.add("n4", [3]);
		animation.add("n5", [4]);
		animation.add("n6", [5]);
		animation.add("n7", [6]);
		animation.add("n8", [7]);
		animation.add("n9", [8]);
		animation.add("n10", [9]);
		animation.add("jack", [10]);
		animation.add("queen", [11]);
		animation.add("king", [12]);

		switch (switch (suit)
		{
			case CardSuit.Clubs(t): t;
			case CardSuit.Diamonds(t): t;
			case CardSuit.Hearts(t): t;
			case CardSuit.Spades(t): t;
		})
		{
			case CardType.Numbered(n): animation.play('n$n');
			case CardType.Ace: animation.play("ace");
			case CardType.Jack: animation.play("jack");
			case CardType.Queen: animation.play("queen");
			case CardType.King: animation.play("king");
		}
	}
}