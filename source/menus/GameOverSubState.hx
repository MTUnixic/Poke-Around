package menus;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

class GameOverSubState extends FlxSubState
{
	var bg:FlxSprite;
	var playerWon:Bool;

	public function new(playerWon:Bool)
	{
		super();
		this.playerWon = playerWon;
	}

	override function create()
	{
		super.create();

		bg = new FlxSprite(0, 0);
		bg.makeGraphic(1, 1, 0x94000000);
		bg.setGraphicSize(1280, 720);
		bg.screenCenter();
		bg.alpha = 0;
		add(bg);
		
		FlxTween.tween(bg, {alpha: 0.8}, 0.3);

		var titleText = new FlxText(0, 0, FlxG.width, playerWon ? "Player Wins!" : "Dealer Wins!");
		titleText.size = 64;
		titleText.alignment = CENTER;
		titleText.color = playerWon ? 0xffffd166 : 0xffe8637a;
		titleText.screenCenter();
		titleText.y -= 40;
		var titleTargetY = titleText.y;
		titleText.y -= 60;
		titleText.alpha = 0;
		add(titleText);

		FlxTween.tween(titleText, {y: titleTargetY, alpha: 1}, 0.6, {ease: FlxEase.backOut});

		var subText = new FlxText(0, 0, FlxG.width, playerWon ? "gg" : "you lost");
		subText.size = 28;
		subText.alignment = CENTER;
		subText.color = 0xffcdf7e2;
		subText.screenCenter();
		subText.y += 40;
		var subTargetY = subText.y;
		subText.y += 20;
		subText.alpha = 0;
		add(subText);

		new FlxTimer().start(0.4, (_) -> FlxTween.tween(subText, {y: subTargetY, alpha: 1}, 0.5, {ease: FlxEase.quadOut}));

		new FlxTimer().start(5.0, (_) -> FlxG.switchState(() -> new MainMenu()));
	}
}
