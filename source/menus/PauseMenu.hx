package menus;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import lime.system.System;
import util.MenuUtil;
import util.MouseUtil;

// Basically MainMenu but cloned to be the Pause Menu
class PauseMenu extends FlxSubState
{
	var buttonGroup:FlxTypedGroup<FlxText>;
	var bg:FlxSprite;
	var menu:MenuUtil;

	override function create()
	{
		menu = new MenuUtil(['Resume', 'Restart', 'Exit To Menu', #if !web'Close Game'#end], 0xEEFF00);
		
		bg = new FlxSprite(0, 0);
		bg.makeGraphic(1, 1, 0x94000000);
		bg.setGraphicSize(1280, 720);
		bg.screenCenter();
		bg.alpha = 0;

		FlxTween.tween(bg, {alpha: 0.8}, 0.3);

		buttonGroup = new FlxTypedGroup<FlxText>();
		menu.makeButtonGroup(buttonGroup);

		menu.addConfirmOption('Resume', () -> close());
		menu.addConfirmOption('Restart', () -> FlxG.resetState());
		menu.addConfirmOption('Exit To Menu', () -> FlxG.switchState(() -> new MainMenu()));
		#if !web
		menu.addConfirmOption('Close Game', () -> System.exit(0));
		#end

		FlxTween.tween(FlxG.camera, { zoom: 1.0 }, 0.5, {
			ease: FlxEase.quadOut,
			type: PERSIST
		});

		add(bg);
		add(buttonGroup);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		menu.updateLoop();
		MouseUtil.mouseCamera(48);
	}
}
