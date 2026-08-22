package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSprite;
import menus.PauseMenu;
import objects.Table;

class PlayState extends CoolBG
{
	var table:Table;
	var pauseButton:FlxSprite;

	override public function create()
	{
		super.create();

		table = new Table();
		add(table);

		pauseButton = new FlxSprite(0, 0,
			'assets/images/placeholderpause.png'); // TODO: MT can you please draw it if you want to ofc but leave the old one it in incase someone snoops in files
		pauseButton.x = FlxG.width - pauseButton.width;
		add(pauseButton);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (FlxG.mouse.overlaps(pauseButton) && FlxG.mouse.justPressed) // pausing
			openSubState(new PauseMenu());
	}
}
