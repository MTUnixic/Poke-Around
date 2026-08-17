package menus;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import lime.system.System;

// Basically MainMenu but cloned to be the Pause Menu
class PauseMenu extends FlxSubState
{
	static var buttonList:Array<String> = ['Resume', 'Restart', 'Exit To Menu', 'Close Game'];

	var buttonGroup:FlxTypedGroup<FlxText>;
	var bg:FlxSprite;

	override function create()
	{
		add(bg = new FlxSprite(0, 0).makeGraphic(1, 1, 0x94242424));
		bg.screenCenter();
		bg.setGraphicSize(1280, 720);
		bg.alpha = 0;

		FlxTween.tween(bg, {alpha: 1}, 0.3);

		buttonGroup = new FlxTypedGroup<FlxText>();
		add(buttonGroup);

		for (buttonName in buttonList)
		{
			var button:FlxText = new FlxText(0, 0, 0, buttonName);
			button.size = 20;
			button.color = 0xEEFF00;
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
			case 'Resume':
				close();
			case 'Restart':
				FlxG.resetState();
			case 'Close Game':
				System.exit(0);
			case 'Exit To Menu':
				FlxG.switchState(MainMenu.new);
		}
	}
}
