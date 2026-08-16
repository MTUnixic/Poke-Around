package;

import flixel.FlxState;
import flixel.text.FlxText;

class PlayState extends FlxState
{
	override public function create()
	{
		super.create();
		
		var hello = new FlxText();
		hello.text = 'Hello, HaxeJam!';
		hello.size = 48;
		hello.screenCenter();
		add(hello);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
