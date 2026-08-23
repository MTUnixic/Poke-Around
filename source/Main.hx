package;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.graphics.FlxGraphic;
import menus.MainMenu;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();

		addChild(new FlxGame(0, 0, MainMenu));

		FlxG.mouse.load(FlxGraphic.fromAssetKey("assets/images/game/pokeryouhorse.png", true, null, false).bitmap, 1, -11, -3);
	}
}
