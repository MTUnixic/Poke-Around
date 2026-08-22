package menus;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import objects.PlayerSprite;

class CharacterTestState extends FlxState
{
	var player:PlayerSprite;
	var txt:FlxText;
	var animNames:Array<String> = [];
	var curI:Int = 0;

	override function create() 
	@:privateAccess {
		super.create();

		player = new PlayerSprite(400, 300);
		player.idleTimer = Math.POSITIVE_INFINITY;
		add(player);

		txt = new FlxText(80, 80, 200, "Anim: Idle", 24);
		add(txt);

		animNames = [for (n in player.playerSprite.animation._animations.keys()) n];
	}

	override function update(elapsed:Float)
	@:privateAccess {

		super.update(elapsed);

		if (FlxG.keys.justPressed.SPACE && player.playerSprite.animation.curAnim != null)
			player.playerSprite.animation.curAnim.play(true);
		else if(FlxG.keys.justPressed.RIGHT)
		{
			curI = (curI + 1) % animNames.length;
			player.playerSprite.animation.play(animNames[curI], true);
		}
		else if(FlxG.keys.justPressed.LEFT)
		{
			curI = (curI - 1 + animNames.length) % animNames.length;
			player.playerSprite.animation.play(animNames[curI], true);
		}
		else if(FlxG.keys.justPressed.ESCAPE)
			FlxG.switchState(MainMenu.new);

		txt.text = 'Anim: ${animNames[curI]}';
	}
}