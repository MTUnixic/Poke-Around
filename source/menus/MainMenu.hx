package menus;

import flixel.FlxG;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.system.System;
import util.MenuUtil;
import util.MouseUtil;

class MainMenu extends BackgrndState
{
	var buttonGroup:FlxTypedGroup<FlxText>;
	var menu:MenuUtil;

	override function create()
	{

		var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
		diamond.persist = true;
		diamond.destroyOnNoUse = false;

		var screenRegion = new FlxRect(0, 0, FlxG.width, FlxG.height);

		FlxTransitionableState.defaultTransIn = new TransitionData(TILES, FlxColor.BLACK, 0.5, FlxPoint.get(1,0), {asset: diamond, width: 32, height: 32}, screenRegion);
		FlxTransitionableState.defaultTransOut = new TransitionData(TILES, FlxColor.BLACK, 0.5, FlxPoint.get(1,0), {asset: diamond, width: 32, height: 32}, screenRegion);

		super.create();

		remove(glow, true);
		remove(frame, true);
		remove(pokerTable, true);

		menu = new MenuUtil(['Play', #if !web'Quit Game'#end]);
	
		buttonGroup = new FlxTypedGroup<FlxText>();

		menu.makeButtonGroup(buttonGroup);
		menu.addConfirmOption('Play', () -> FlxG.switchState(() -> new PlayState()));
		#if !web
		menu.addConfirmOption('Quit Game', () -> System.exit(0));
		#end
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
			FlxG.switchState(() -> new CharacterTestState());
		
		menu.updateLoop();
		MouseUtil.mouseCamera(24, 1.1);
	}
}
