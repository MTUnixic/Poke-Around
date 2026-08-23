package menus;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import objects.Card;
import util.CardUtil.CardData;

class CardsRevealScreen extends FlxSubState
{
	static inline var CARD_W = 88 * 2;
	static inline var CARD_H = 124 * 2;
	static inline var CARD_GAP = 24;

	static inline var WAVE_STRENGTH = 5;
	static inline var WAVE_FADE_TIME = 0.6;

	var bg:FlxSprite;
	var cardSprites:Array<Card> = [];
	var cards:Array<CardData>;

	public function new(cards:Array<CardData>)
	{
		super();
		this.cards = cards;
	}

	override function create()
	{
		super.create();

		bg = new FlxSprite(0, 0);
		bg.makeGraphic(1, 1, 0xFF000000);
		bg.setGraphicSize(1280*2, 720*2);
		bg.screenCenter();
		bg.alpha = 0;
		add(bg);

		FlxTween.tween(bg, {alpha: 0.8}, 0.5);

		var totalWidth = cards.length * CARD_W + (cards.length - 1) * CARD_GAP;
		var startX = (FlxG.width - totalWidth) / 2;
		var y = (FlxG.height - CARD_H) / 2;

		for (i in 0...cards.length)
		{
			var card = new Card();
			card.x = startX + i * (CARD_W + CARD_GAP);
			card.y = y;
			card.setGraphicSize(CARD_W, CARD_H);
			card.alpha = 0;
			add(card);
			cardSprites.push(card);

			FlxTween.tween(card, {alpha: 1}, 0.5);

			var data = cards[i];
			new FlxTimer().start(0.2 + i * 0.15, (_) -> card.reveal(data, true));
			new FlxTimer().start(4, (_) -> {
				FlxTween.tween(card, {alpha: 0}, 0.5, { onComplete: (_) -> {
					card.kill();
				}});
			});
		}

		FlxG.sound.play("assets/sounds/Sonic.exe Ding SFX2.wav").play();

		FlxTimer.wait(4.1, () -> {
			FlxTween.tween(bg, {alpha: 0}, 0.5, { onComplete: (_) -> {
				close();
			}});
		});
	}
}
