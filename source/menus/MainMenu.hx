package menus;

import flixel.FlxG;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import lime.system.System;
import util.MenuUtil;

class MainMenu extends CoolBG
{
	var buttonGroup:FlxTypedGroup<FlxText>;
	var menu:MenuUtil;

	override function create()
	{
		super.create();
		// remove these from main menu as they are for gameplay... MT told me
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

		for(text in buttonGroup)
			text.scrollFactor.y = .9;

		final titleText:FlxText = new FlxText(0, 0, 0, 'John\nHaxe\nJam');
		titleText.size = 50;
		titleText.screenCenter();
		titleText.y -= 110;
		titleText.scrollFactor.setXY(1.4);
		add(titleText);

		FlxG.camera.zoom = 1.1;
		
	}

	public inline function mouseCamera() // written MT, used to make the menu move and stuff to the mouse - LeonGamerPS1 // TODO: Remove comment if u want lol
	{
		FlxG.camera.scroll.x = (FlxG.mouse.x - FlxG.width / 2) / 24;
		FlxG.camera.scroll.y = (FlxG.mouse.y - FlxG.height / 2) / 24;
	}

	override function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.NINE)
			FlxG.switchState(CharacterTestState.new);
		super.update(elapsed);
		menu.updateLoop();
		mouseCamera();
	}
}
