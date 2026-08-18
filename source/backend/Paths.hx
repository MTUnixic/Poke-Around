package backend;

#if FEY_PATHS
import backend.Logging;
import sys.FileSystem;

using StringTools;

#if FEY_FILESYS
import backend.FileSys;
#end
#if FEY_MODDING
import backend.Mod;
#end

private typedef PathAlias =
{
	#if FEY_MODDING
	?modpath:String,
	#end
	path:String,
	defaultExtension:String
}

/**
	Class for path parsing.
	Allows you to save quick shortcuts to specific folders via `register`.
	Example usage:
	```haxe
	Paths.register('images','assets/images/?#','.png'); // '?' get replaced with the file name, and '#' with the file extension.
	Paths.get('images','test'); // returns assets/images/test.png
	```
	Comes with pre-registered aliases.
	Disable this automatic registering via haxedef `FEY_NO_DEFAULT_PATHS`:
	`'images' => 'assets/images'`,`'data' => 'assets/data'`,`'music' => 'assets/music'`,`'sound'=> 'assets/sound'`
	These can be disabled with `FEY_NO_EXTRA_PATHS`(and are also automatically disabled through `FEY_NO_DEFAULT_PATHS`):
	`'fonts' => 'assets/fonts'`, `''=>''`

	Disable class via haxedef `FEY_NO_PATHS`.
**/
class Paths
{
	static var aliases:Map<String, PathAlias> = [
		#if FEY_DEFAULT_PATHS
		'images' => {
			path: 'assets/images/?#',
			#if FEY_MODDING
			modpath: 'mods/*/images/?#',
			#end
			defaultExtension: '.png'
		}, 'data' => {
			path: 'assets/data/?#',
			#if FEY_MODDING
			modpath: 'mods/*/data/?#',
			#end
			defaultExtension: '.json'
		}, 'music' => {
			path: 'assets/music/?#',
			#if FEY_MODDING
			modpath: 'mods/*/music/?#',
			#end
			defaultExtension: '.ogg'
		}, 'sound' => {
			path: 'assets/sound/?#',
			#if FEY_MODDING
			modpath: 'mods/*/sound/?#',
			#end
			defaultExtension: '.ogg'
		}, 'fonts' => {
			path: 'assets/fonts/?#',
			#if FEY_MODDING
			modpath: 'mods/*/fonts/?#',
			#end
			defaultExtension: '.ttf'
		}
		#end
	];

	#if FEY_MODDING
	static function resolveMod(alias:PathAlias, mod:String, file:String, ?extension:String)
		return alias.modpath.replace('*', mod).replace('?', file).replace('#', extension ?? alias.defaultExtension);

	public static function register(name:String, path:String, defaultExtension:String, ?modPath:String)
		aliases.set(name, {path: path, modpath: modPath, defaultExtension: defaultExtension});

	static function getFromMods(alias:PathAlias, file:String, ?extension:String)
	{
		for (mod in Mod.modList)
		{
			var modpath = resolveMod(alias, mod, file, extension);
			if (FileSystem.exists(modpath))
				return modpath;
		}
		return '';
	}

	public static function get(name:String, file:String, ?extension:String, useMods:Bool = true)
	{
		var alias = (aliases.get(name) ?? {Logging.warn('Invalid path alias $name'); {path: '?#', defaultExtension: ''};});
		if (useMods)
			return getFromMods(alias, file, extension);
		return resolve(alias, file, extension);
	}

	// Fetch a path through a registered shortcut.
	#else
	// Register a path shortcut to use later.
	public static function register(name:String, path:String, defaultExtension:String)
		aliases.set(name, {path: path, defaultExtension: defaultExtension});

	public static function get(name:String, file:String, ?extension:String)
	{
		return resolve(aliases.get(name) ?? {Logging.warn('Invalid path alias $name'); {path: '?#', defaultExtension: ''};}, file, extension);
	}

	// Fetch a path through a registered shortcut.
	#end
	static function resolve(alias:PathAlias, file:String, ?extension:String)
		return alias.path.replace('?', file).replace('#', extension ?? alias.defaultExtension);
}
#end
