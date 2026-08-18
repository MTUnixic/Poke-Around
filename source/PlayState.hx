package;

import flixel.FlxState;
import objects.Table;

class PlayState extends FlxState
{
	var table:Table;

	override public function create()
	{
		super.create();

		table = new Table();
		add(table);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
