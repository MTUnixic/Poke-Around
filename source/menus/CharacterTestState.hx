package menus;

import flixel.FlxG;
import flixel.addons.transition.FlxTransitionableState;
import flixel.text.FlxText;
import objects.DealerSprite;

class CharacterTestState extends FlxTransitionableState
{
	var dealer:DealerSprite;
	var txt:FlxText;
	var animNames:Array<String> = [];
	var curI:Int = 0;

	override function create() 
	@:privateAccess {
		super.create();

		dealer = new DealerSprite(400, 300);
		dealer.idleTimer = Math.POSITIVE_INFINITY;
		add(dealer);

		txt = new FlxText(80, 80, 200, "Anim: Idle", 24);
		add(txt);

		animNames = [for (n in dealer.sprite.animation._animations.keys()) n];
	}

	override function update(elapsed:Float)
	@:privateAccess {
		super.update(elapsed);

		if (FlxG.keys.justPressed.SPACE && dealer.sprite.animation.curAnim != null)
			dealer.sprite.animation.curAnim.play(true);
		else if(FlxG.keys.justPressed.RIGHT)
		{
			curI = (curI + 1) % animNames.length;
			dealer.sprite.animation.play(animNames[curI], true);
		}
		else if(FlxG.keys.justPressed.LEFT)
		{
			curI = (curI - 1 + animNames.length) % animNames.length;
			dealer.sprite.animation.play(animNames[curI], true);
		}
		else if(FlxG.keys.justPressed.ESCAPE)
			FlxG.switchState(() -> new MainMenu());

		txt.text = 'Anim: ${animNames[curI]}';
	}
}