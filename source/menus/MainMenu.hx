package menus;

import flixel.FlxG;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import lime.system.System;

class MainMenu extends FlxState
{
	static var buttonList:Array<String> = ['Play', 'Test Pause', 'Quit Game']; // Names of the buttons to click, static because i think this is good -LeonGamerPS1

	// item related stuff
	var buttonGroup:FlxTypedGroup<FlxText>;

	override function create()
	{
		buttonGroup = new FlxTypedGroup<FlxText>();
		add(buttonGroup);

		for (buttonName in buttonList)
		{
			var button:FlxText = new FlxText(0, 0, 0, buttonName);
			button.size = 20;
			button.screenCenter();
			button.y += button.height * buttonGroup.length * 1.25 - 50;
			buttonGroup.add(button);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		for (item in buttonGroup)
		{
			if (FlxG.mouse.overlaps(item) && FlxG.mouse.justPressed)
				confirm(item.text);
		}
	}

	function confirm(buttonName:String)
	{
		switch (buttonName)
		{
			case 'Play':
				FlxG.switchState(PlayState.new);
			case 'Test Pause':
				openSubState(new PauseMenu());
			case 'Quit Game':
				System.exit(0);
		}
	}
}
