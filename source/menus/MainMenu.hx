package menus;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import lime.system.System;
import util.MenuUtil;
import util.MouseUtil;

class MainMenu extends BackgrndState
{
	var buttonGroup:FlxTypedGroup<FlxText>;
	var menu:MenuUtil;

	override function create()
	{
		super.create();

		remove(glow, true);
		remove(frame, true);
		remove(pokerTable, true);

		menu = new MenuUtil(['Play', 'Test Pause', 'Quit Game']);
	
		buttonGroup = new FlxTypedGroup<FlxText>();

		menu.makeButtonGroup(buttonGroup);
		menu.addConfirmOption('Play', () -> FlxG.switchState(PlayState.new));
		menu.addConfirmOption('Test Pause', () -> openSubState(new PauseMenu()));
		menu.addConfirmOption('Quit Game', () -> System.exit(0));
		add(buttonGroup);

		for (text in buttonGroup)
			text.scrollFactor.y = .9;

		final titleText:FlxText = new FlxText(0, 0, 0, 'John\nHaxe\nJam');
		titleText.size = 50;
		titleText.screenCenter();
		titleText.y -= 110;
		titleText.scrollFactor.setXY(1.4);
		add(titleText);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (FlxG.keys.justPressed.NINE)
			FlxG.switchState(CharacterTestState.new);
		
		menu.updateLoop();
		MouseUtil.mouseCamera(24, 1.1);
	}
}
