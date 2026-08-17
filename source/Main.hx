package;

import backend.CardManager;
import backend.Logging;
import flixel.FlxGame;
import menus.MainMenu;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new FlxGame(0, 0, MainMenu));
    inline function check(vals:Array<CardData>) {
      return CardManager.formatCombo(CardManager.checkCombos(vals));
    }
    Logging.log(check([{num:1,suit:2},{num:7,suit:3},{num:3,suit:0},{num:5,suit:1},{num:2,suit:0}]));//high
    Logging.log(check([{num:1,suit:2},{num:1,suit:3},{num:3,suit:0},{num:5,suit:1},{num:2,suit:0}]));//p
    Logging.log(check([{num:4,suit:0},{num:4,suit:2},{num:4,suit:4},{num:1,suit:0},{num:2,suit:0}]));//three
    Logging.log(check([{num:4,suit:0},{num:4,suit:2},{num:1,suit:4},{num:1,suit:0},{num:2,suit:0}]));//two
    Logging.log(check([{num:2,suit:0},{num:3,suit:2},{num:4,suit:4},{num:5,suit:0},{num:6,suit:0}]));//straight
    Logging.log(check([{num:1,suit:2},{num:7,suit:2},{num:3,suit:2},{num:5,suit:2},{num:2,suit:2}]));//flush
    Logging.log(check([{num:1,suit:2},{num:1,suit:2},{num:1,suit:2},{num:2,suit:2},{num:2,suit:2}]));//fh
    Logging.log(check([{num:1,suit:2},{num:1,suit:2},{num:1,suit:2},{num:1,suit:2},{num:2,suit:2}]));//four
    Logging.log(check([{num:2,suit:2},{num:3,suit:2},{num:4,suit:2},{num:5,suit:2},{num:6,suit:2}]));//straightflush
    Logging.log(check([{num:1,suit:2},{num:10,suit:2},{num:11,suit:2},{num:12,suit:2},{num:13,suit:2}]));//royal
	}
}
