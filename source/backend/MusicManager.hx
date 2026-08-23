package backend;

import flixel.FlxG;
import flixel.sound.FlxSound;
import flixel.tweens.FlxTween;

class MusicManager
{
	public static var menuMusic:FlxSound;
	public static var gameMusic:FlxSound;

	static var hasInit:Bool = false;
	static var tweenManager:FlxTweenManager;

	static final MENU_MUSIC_VOLUME:Float = 0.75;
	static final GAME_MUSIC_VOLUME:Float = 0.5;

	public static function init()
	{
		if (hasInit) return;
		hasInit = true;

		tweenManager = new FlxTweenManager();
		FlxG.signals.preStateSwitch.remove(tweenManager.clear);

		menuMusic = FlxG.sound.create("assets/music/buckshot-mt-piano.ogg", null, false);
		menuMusic.looped = true;
		menuMusic.volume = 0;
		menuMusic.persist = true;

		gameMusic = FlxG.sound.create("assets/music/buckshot-mt.ogg", null, false);
		gameMusic.looped = true;
		gameMusic.volume = 0;
		gameMusic.persist = true;

		menuMusic.play();
		gameMusic.play();

		FlxG.signals.postUpdate.add(() -> {
			tweenManager.update(FlxG.elapsed);
		});
	}

	public static function ensureMenuMusic()
	{
		if (!hasInit) init();

		tweenManager.tween(menuMusic, {volume: MENU_MUSIC_VOLUME}, 1);
		tweenManager.tween(gameMusic, {volume: 0}, 1);
	}

	public static function ensureGameMusic()
	{
		if (!hasInit) init();

		tweenManager.tween(menuMusic, {volume: 0}, 1);
		tweenManager.tween(gameMusic, {volume: GAME_MUSIC_VOLUME}, 1);
	}

	public static function switchToGameMusic()
	{
		if (!hasInit) init();

		tweenManager.tween(menuMusic, {volume: 0}, 1, {onComplete: (_) -> {
			tweenManager.tween(gameMusic, {volume: GAME_MUSIC_VOLUME}, 1);
		}});
	}

	public static function switchToMenuMusic()
	{
		if (!hasInit) init();

		tweenManager.tween(gameMusic, {volume: 0}, 1, {onComplete: (_) -> {
			tweenManager.tween(menuMusic, {volume: MENU_MUSIC_VOLUME}, 1);
		}});
	}
}