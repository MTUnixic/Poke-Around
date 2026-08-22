package;

import backend.Logging;
import flixel.FlxGame;
import menus.MainMenu;
import openfl.display.Sprite;
import util.CardUtil;

class Main extends Sprite
{
	public function new()
	{
		super();

		addChild(new FlxGame(0, 0, MainMenu));
	}
}
