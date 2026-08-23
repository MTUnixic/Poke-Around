package menus;

import backend.MusicManager;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.util.FlxColor;
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

		menu = new MenuUtil(['Play', 'Credits', #if !web'Quit Game'#end]);
	
		buttonGroup = new FlxTypedGroup<FlxText>();

		menu.makeButtonGroup(buttonGroup);
		menu.addConfirmOption('Play', () -> {
			MusicManager.switchToGameMusic();
			FlxG.switchState(() -> new PlayState());
		});
		menu.addConfirmOption('Credits', () -> FlxG.switchState(() -> new CreditsMenu()));
		#if !web menu.addConfirmOption('Quit Game', () -> Sys.exit(0)); #end
		add(buttonGroup);

		for (text in buttonGroup)
			text.scrollFactor.y = .9;

		final titleSprite = new FlxSprite();
		titleSprite.loadGraphic('assets/images/game/pokuhtitle.png');
		titleSprite.setGraphicSize(titleSprite.width*2, titleSprite.height*2);
		titleSprite.screenCenter();
		titleSprite.y -= 110;
		titleSprite.scrollFactor.setXY(1.4);
		add(titleSprite);

		MusicManager.ensureMenuMusic();
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
