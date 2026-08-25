package util;

import flixel.FlxG;
import flixel.sound.FlxSound;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.tweens.FlxTween;
import openfl.utils.Assets;

using StringTools;

class AudioUtil
{
	public static var menuMusic:FlxSound;
	public static var gameMusic:FlxSound;

	static var hasInit:Bool = false;
	static var tweenManager:FlxTweenManager;

	static final MENU_MUSIC_VOLUME:Float = 0.75;
	static final GAME_MUSIC_VOLUME:Float = 0.5;

	public static function playSound(sound:FlxSoundAsset) {
		FlxG.sound.play(sound);
	}

	public static function initMusic()
	{
		if (hasInit) return;
		hasInit = true;

		tweenManager = new FlxTweenManager();
		FlxG.signals.preStateSwitch.remove(tweenManager.clear);

		menuMusic = FlxG.sound.create("assets/music/buckshot-mt-piano.ogg", null, false);
		menuMusic.looped = menuMusic.persist = true;
		menuMusic.volume = 0;

		gameMusic = FlxG.sound.create("assets/music/buckshot-mt.ogg", null, false);
		gameMusic.looped = gameMusic.persist = true;
		gameMusic.volume = 0;

		menuMusic.play();
		gameMusic.play();

		FlxG.signals.postUpdate.add(() -> {
			tweenManager.update(FlxG.elapsed);
		});
	}

	/** lowers game music volume to 0 and picks up menu music volume to 1 **/
	public static function initMenuMusic()
	{
		if (!hasInit) initMusic();
		tweenManager.tween(menuMusic, {volume: MENU_MUSIC_VOLUME}, 1);
		tweenManager.tween(gameMusic, {volume: 0}, 1);
	}

	/** lowers menu music volume to 0 and picks up game music volume to 1 **/
	public static function initGameMusic()
	{
		if (!hasInit) initMusic();
		tweenManager.tween(menuMusic, {volume: 0}, 1);
		tweenManager.tween(gameMusic, {volume: GAME_MUSIC_VOLUME}, 1);
	}

	/** smoothly tweens volume of menu music to 0 then tweens game music volume sto 1 **/
	public static function switchToGameMusic()
	{
		if (!hasInit) initMusic();
		tweenManager.tween(menuMusic, {volume: 0}, 1, {onComplete: (_) -> {
			tweenManager.tween(gameMusic, {volume: GAME_MUSIC_VOLUME}, 1);
		}});
	}

	/** smoothly tweens volume of game music to 0 then tweens menu music volume to 1 **/
	public static function switchToMenuMusic()
	{
		if (!hasInit) initMusic();
		tweenManager.tween(gameMusic, {volume: 0}, 1, {onComplete: (_) -> {
			tweenManager.tween(menuMusic, {volume: MENU_MUSIC_VOLUME}, 1);
		}});
	}

	/**
	 * Returns an array of song names to use for music list
	 * @param listPath file path to the txt file
	 * @return An array of song names from the txt file
	 */
	public inline static function fillMusicList(listPath:String):Array<String>
	{
		return Assets.getText(listPath).split("\n").map(str -> str.trim());
	}
}