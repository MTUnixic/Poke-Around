package objects;

import backend.flixel.vis.dsp.SpectralAnalyzer;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import lime.media.AudioSource;

/** modified from FunkinCrew/funkin.vis/examples **/
class AudioVisualizer extends FlxGroup
{
	public var barGroup:FlxTypedGroup<FlxSprite>;
	public var peakLines:FlxTypedGroup<FlxSprite>;

	public var barColor:FlxColor;
	public var peakColor:Null<FlxColor>;

	public var alphaMin = 0.0;
	public var alphaMax = 1.0;

	public var showPeak:Bool;
	public var barHeightScale:Float = 1.0;
	public var barScaleYOrigin:Float = /*0*/ FlxG.height; // bottom to top
	public var peakLineWidth = 1;
	public var barCount = 48;

	var analyzer:SpectralAnalyzer;

	/**
		creates a group that renders a real-time audio spectrum visualiser using vertical bars
		@param audioSource audio source to visualise (from `FlxG.sound.music` or `FlxSound`)
		@param barCount how many frequency bands are made and shown (default 48)
		@param showPeak toggles visibily of bars' peak (default false)
		@param barColor color of the bars (default FlxColor.WHITE)
		@param peakColor color of the bars' peak (default FlxColor.CYAN)
		@param barScaleYOrigin (optional) the y origin the bar scales at (FlxG.height for bottom-to-top, and 0 for top-to-bottom)
	**/
	public function new(audioSource:AudioSource, barCount = 48, showPeak = false, barColor = FlxColor.WHITE, peakColor = FlxColor.CYAN, ?barScaleYOrigin:Int)
	{
		super();

		if (barScaleYOrigin != null)
			this.barScaleYOrigin = barScaleYOrigin;

		this.barColor = barColor;
		this.peakColor = peakColor;
		this.showPeak = showPeak;
		this.barCount = barCount;

		analyzer = new SpectralAnalyzer(audioSource, barCount, 0.5, 10);

		initBars(barCount);

		add(barGroup);
		add(peakLines);
	}

	/**
		(re)creates the visualiser
		@param barCount how many frequency bands are made and shown (default 48)

	**/
	public function initBars(barCount = 48)
	{
		this.barCount = barCount;

		barGroup = new FlxTypedGroup<FlxSprite>();
		peakLines = new FlxTypedGroup<FlxSprite>();

		for (i in 0...barCount)
		{
			var spr = new FlxSprite((i / barCount) * FlxG.width, 0);
			spr.makeGraphic(Std.int((1 / barCount) * FlxG.width) - 4, FlxG.height, barColor);
			spr.origin.set(0, barScaleYOrigin);
			barGroup.add(spr);

			if (!showPeak)
				continue;

			spr = new FlxSprite((i / barCount) * FlxG.width, 0);
			spr.makeGraphic(Std.int((1 / barCount) * FlxG.width) - 4, peakLineWidth, peakColor);
			peakLines.add(spr);
		}
	}

	override function draw()
	{
		var levels = analyzer.getLevels();

		for (i in 0...Std.int(Math.min(barGroup.members.length, levels.length)))
		{
			var bar = barGroup.members[i];
			bar.scale.y = levels[i].value * barHeightScale;

			bar.alpha = FlxMath.bound(levels[i].value / 2, alphaMin, alphaMax);

			if (peakLines.members.length > 0)
			{
				final peakY = (barScaleYOrigin >= FlxG.height/2)
					? barScaleYOrigin - barScaleYOrigin * levels[i].peak // top
					: barScaleYOrigin - peakLineWidth + (FlxG.height - barScaleYOrigin) * levels[i].peak; // bottom
				
				peakLines.members[i].y = peakY;
			}
		}

		super.draw();
	}
}
