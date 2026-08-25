package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import menus.MainMenu;

class PreloadState extends FlxState
{
	override function create()
	{
		super.create();
		
		var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
		diamond.persist = true;
		diamond.destroyOnNoUse = false;

		var screenRegion = new FlxRect(0, 0, FlxG.width, FlxG.height);

		FlxTransitionableState.defaultTransIn = new TransitionData(TILES, FlxColor.BLACK, 0.5, FlxPoint.get(1,0), {asset: diamond, width: 32, height: 32}, screenRegion);
		FlxTransitionableState.defaultTransOut = new TransitionData(TILES, FlxColor.BLACK, 0.5, FlxPoint.get(1,0), {asset: diamond, width: 32, height: 32}, screenRegion);
		
		// do not comment this line out, for some reason the first transition is always weird
		FlxTransitionableState.skipNextTransIn = true;

		// If you want the transition to play when opening the game on the main menu uncomment the line below
		//FlxTransitionableState.skipNextTransOut = true;

		FlxG.switchState(() -> new MainMenu());
	}
}