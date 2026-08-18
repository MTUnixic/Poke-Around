package menus;

import flixel.FlxG;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import lime.system.System;
import util.MenuUtil;

class MainMenu extends FlxState
{
	var buttonGroup:FlxTypedGroup<FlxText>;
	var menu:MenuUtil;

	override function create()
	{
		menu = new MenuUtil(['Play', 'Test Pause', 'Quit Game']);

		buttonGroup = new FlxTypedGroup<FlxText>();
		menu.makeButtonGroup(buttonGroup);

		menu.addConfirmOption('Play', () -> FlxG.switchState(PlayState.new));
		menu.addConfirmOption('Test Pause', () -> openSubState(new PauseMenu()));
		menu.addConfirmOption('Quit Game', () -> System.exit(0));

		add(buttonGroup);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		menu.updateLoop();
	}
}
