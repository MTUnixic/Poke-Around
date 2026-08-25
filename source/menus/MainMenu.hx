package menus;

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
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import openfl.display.BlendMode;
import util.AudioUtil;
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

		persistentUpdate = true;

		super.create();

		AudioUtil.initMenuMusic();

		addVisualizer(AudioUtil.menuMusic);
		tweenBarColorsTo(0xFF242234, 0.1);

		visualizer.alphaMax = visualizer.alphaMin = 1.0;

		remove(glow, true);
		remove(frame, true);
		remove(pokerTable, true);

		menu = new MenuUtil(['Play', 'Credits', 'Guide (WIP)', #if !web'Quit Game'#end]);
	
		buttonGroup = new FlxTypedGroup<FlxText>();

		menu.makeButtonGroup(buttonGroup);
		menu.addConfirmOption('Play', () -> {
			AudioUtil.switchToGameMusic();
			FlxG.switchState(() -> new PlayState());
		});
		menu.addConfirmOption('Credits', () -> FlxG.switchState(() -> new CreditsMenu()));
		//menu.addConfirmOption('Guide', () -> FlxG.switchState(() -> new GuideMenu()));
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

		final version = Application.current.meta.get("version");
		final versionSuffix = #if debug '\nDEBUG' #else '' #end;

		var versionText = new FlxText(0, 0, 86, 'v$version$versionSuffix', 12);
		versionText.alignment = CENTER;
		versionText.color = 0xFF242234; // fits the bg color -MT
		versionText.y = 64;
		versionText.x = FlxG.width - versionText.width - 64;
		versionText.scrollFactor.setXY(0.2);
		add(versionText);

		final BPM = 140;

		function bumpTextVersion(right:Bool)
		{
			FlxTween.completeTweensOf(versionText);

			versionText.angle = right ? -5 : 5;
			FlxTween.tween(versionText, {angle:0}, 60/BPM, {ease: FlxEase.linear, onComplete: (_) -> bumpTextVersion(!right)});

			versionText.scale.setXY(1.1);
			FlxTween.tween(versionText.scale, {x:1, y:1}, 60/BPM, {ease: FlxEase.linear});
		}
		bumpTextVersion(false);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		#if (debug && FLX_KEYBOARD)
		if (FlxG.keys.justPressed.NINE)
			FlxG.switchState(() -> new CharacterTestState());
		#end
		
		menu.updateLoop();
		MouseUtil.mouseCamera(24, 1.1);
	}
}
