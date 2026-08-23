package backend.flixel;

import flixel.FlxStrip;
import flixel.graphics.tile.FlxDrawTrianglesItem;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;

inline private function deg2rad(degrees:Float):Float
	return (degrees * Math.PI / 180);

/**
 * A `FlxStrip`-based sprite that can be rotated in 3D and rendered with real perspective.
 *
 * The quad is rotated around its origin using `angleX`/`angleY`/`angleZ`, then each vertex
 * is projected using its own depth, so rotated edges foreshorten correctly instead of just
 * scaling uniformly like an orthographic projection would.
 */
class FlxThreeSprite extends FlxStrip
{
	/**
		Rotation in degrees around the X axis (tilts the sprite vertically).
	**/
	public var angleX(default, set):Float = 0;

	/**
		Rotation in degrees around the Y axis (tilts the sprite horizontally).
	**/
	public var angleY(default, set):Float = 0;

	/**
		Rotation in degrees around the Z axis (rotates the sprite in-plane, like a normal 2D rotation).
	**/
	public var angleZ(default, set):Float = 0;

	/**
		Distance of the sprite from the camera along Z. Higher values move it closer (bigger on screen).
	**/
	public var z(default, set):Float = 0;

	/**
		Distance from the camera to the sprite's origin plane when `z == 0`. Lower values produce stronger perspective distortion.
	**/
	public var focalLength(default, set):Float = 500;

	/**
		Horizontal offset, in pixels, of the camera from the sprite's center. The sprite's own screen
		position doesn't change, but rotation reveals perspective as if it were being viewed from the side.
	**/
	public var cameraOffsetX(default, set):Float = 0;

	/**
		Vertical offset, in pixels, of the camera from the sprite's center. The sprite's own screen
		position doesn't change, but rotation reveals perspective as if it were being viewed from above/below.
	**/
	public var cameraOffsetY(default, set):Float = 0;

	static inline var MIN_DEPTH:Float = 1;

	var _offsetBaselineX:Float = 0;
	var _offsetBaselineY:Float = 0;

	var _cosx:Float = Math.cos(0);
	var _cosy:Float = Math.cos(0);
	var _cosz:Float = Math.cos(0);
	var _sinx:Float = Math.sin(0);
	var _siny:Float = Math.sin(0);
	var _sinz:Float = Math.sin(0);

	function set_angleX(value:Float)
	{
		var rv = deg2rad(value);
		_cosx = Math.cos(rv);
		_sinx = Math.sin(rv);
		updateMesh();
		return angleX = value;
	}
	function set_angleY(value:Float)
	{
		var rv = deg2rad(value);
		_cosy = Math.cos(rv);
		_siny = Math.sin(rv);
		updateMesh();
		return angleY = value;
	}
	function set_angleZ(value:Float)
	{
		var rv = deg2rad(value);
		_cosz = Math.cos(rv);
		_sinz = Math.sin(rv);
		updateMesh();
		return angleZ = value;
	}
	function set_z(value:Float)
	{
		z = value;
		updateMesh();
		return value;
	}
	function set_focalLength(value:Float)
	{
		focalLength = value;
		updateMesh();
		return value;
	}
	function set_cameraOffsetX(value:Float)
	{
		cameraOffsetX = value;
		updateMesh();
		return value;
	}
	function set_cameraOffsetY(value:Float)
	{
		cameraOffsetY = value;
		updateMesh();
		return value;
	}

	
	@:noCompletion
	override function set_width(value:Float):Float
	{
		super.set_width(value);
		updateMesh();
		return value;
	}

	@:noCompletion
	override function set_height(value:Float):Float
	{
		super.set_height(value);
		updateMesh();
		return value;
	}

	public function new(?X:Float = 0, ?Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset)
	{
		super(X, Y, SimpleGraphic);

		indices = new DrawData(6, true, [
			0, 1, 2,
			2, 1, 3
		]);
	
		uvtData = new DrawData(8, true, [
			0.0, 0.0,
			1.0, 0.0,
			0.0, 1.0,
			1.0, 1.0
		]);
	}

	override public function loadGraphic(graphic:FlxGraphicAsset, animated = false, frameWidth = 0, frameHeight = 0, unique = false, ?key:String):FlxThreeSprite
	{
		super.loadGraphic(graphic, animated, frameWidth, frameHeight, unique, key);
		updateMesh();
		return this;
	}
	
	override public function setGraphicSize(width = 0.0, height = 0.0)
	{
		super.setGraphicSize(width, height);
		this.width = Math.abs(scale.x) * frameWidth;
		this.height = Math.abs(scale.y) * frameHeight;
		updateMesh();
	}

	@:noCompletion
	override public function centerOffsets(AdjustPosition:Bool = false):Void
	{
		super.centerOffsets(AdjustPosition);
		_offsetBaselineX = offset.x;
		_offsetBaselineY = offset.y;
		updateMesh();
	}

	@:noCompletion
	override public function updateHitbox():Void
	{
		super.updateHitbox();
		_offsetBaselineX = offset.x;
		_offsetBaselineY = offset.y;
		updateMesh();
	}

	/** Rotates a point (relative to the origin) in 3D and perspective-projects it back to 2D screen space. **/
	private function rotateAndProject(px:Float, py:Float):FlxPoint
	{
		var vx = px;
		var vy = py;
		var vz = 0.0;

		var tempY = vy * _cosx - vz * _sinx;
		var tempZ = vy * _sinx + vz * _cosx;
		vy = tempY;
		vz = tempZ;

		var tempX = vx * _cosy + vz * _siny;
		tempZ = -vx * _siny + vz * _cosy;
		vx = tempX;
		vz = tempZ;

		tempX = vx * _cosz - vy * _sinz;
		tempY = vx * _sinz + vy * _cosz;
		vx = tempX;
		vy = tempY;

		var depth = focalLength - z + vz;
		if (depth < MIN_DEPTH)
			depth = MIN_DEPTH;

		var scale = focalLength / depth;
		return FlxPoint.get(vx * scale, vy * scale);
	}

	private function updateMesh()
	{
		if (origin == null)
			return;

		var verts:Array<Float> = [
			0.0, 0.0,
			width, 0.0,
			0.0, height,
			width, height
		];

		var originX = origin.x * scale.x;
		var originY = origin.y * scale.y;

		var anchor = rotateAndProject(cameraOffsetX, cameraOffsetY);
		var correctionX = cameraOffsetX - anchor.x + (originX - origin.x) + _offsetBaselineX;
		var correctionY = cameraOffsetY - anchor.y + (originY - origin.y) + _offsetBaselineY;
		anchor.put();

		var updatedVertices:Array<Float> = [];

		for (i in 0...Math.floor(verts.length / 2))
		{
			var projected = rotateAndProject(verts[i * 2] - originX, verts[i * 2 + 1] - originY);
			updatedVertices.push(projected.x + correctionX);
			updatedVertices.push(projected.y + correctionY);
			projected.put();
		}

		vertices = new DrawData(updatedVertices.length, true, updatedVertices);
	}

	override public function draw():Void
	{
		if (alpha == 0 || graphic == null || vertices == null)
			return;

		if (frame != null)
		{
			final uv = frame.uv;
			uvtData[0] = uv.left;
			uvtData[1] = uv.top;
			uvtData[2] = uv.right;
			uvtData[3] = uv.top;
			uvtData[4] = uv.left;
			uvtData[5] = uv.bottom;
			uvtData[6] = uv.right;
			uvtData[7] = uv.bottom;
		}

		final cameras = getCamerasLegacy();
		for (camera in cameras)
		{
			if (!camera.visible || !camera.exists)
				continue;

			getScreenPosition(_point, camera).subtract(offset);
			_point.add(origin.x, origin.y);
			
			#if !flash
			camera.drawTriangles(graphic, vertices, indices, uvtData, colors, _point, blend, repeat, antialiasing, colorTransform, shader);
			#else
			camera.drawTriangles(graphic, vertices, indices, uvtData, colors, _point, blend, repeat, antialiasing);
			#end
		}
	}
}