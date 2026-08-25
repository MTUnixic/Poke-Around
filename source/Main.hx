package;

import backend.MusicManager;
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

		addChild(new FlxGame(1280, 720, MainMenu));

		#if FLX_MOUSE
		FlxG.mouse.load(FlxGraphic.fromAssetKey("assets/images/game/pokeryouhorse.png", true, null, false).bitmap, 1, -11, -3);
		#end
	}
}
