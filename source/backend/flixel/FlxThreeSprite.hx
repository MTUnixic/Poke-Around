package backend.flixel;

import flixel.FlxStrip;
import flixel.graphics.tile.FlxDrawTrianglesItem;
import flixel.system.FlxAssets.FlxGraphicAsset;

inline private function deg2rad(degrees:Float):Float
	return (degrees * Math.PI / 180);

class FlxThreeSprite extends FlxStrip
{
	public var angleX(default, set):Float = 0;
	public var angleY(default, set):Float = 0;
	public var angleZ(default, set):Float = 0;
	public var z(default, set):Float = 1;

	public var _cosx:Float = Math.cos(0);
	public var _cosy:Float = Math.cos(0);
	public var _cosz:Float = Math.cos(0);
	public var _sinx:Float = Math.sin(0);
	public var _siny:Float = Math.sin(0);
	public var _sinz:Float = Math.sin(0);

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

	// TODO: Add all other graphic manipulation functions like makeGraphic
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

		var updatedVertices:Array<Float> = [];

		for (i in 0...Math.floor(verts.length / 2))
		{
			// shift to be relative to the origin (pivot) so rotation happens around it
			var vx = verts[i * 2] - origin.x;
			var vy = verts[i * 2 + 1] - origin.y;
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

			vx *= 1 + (z / 100);
			vy *= 1 + (z / 100);

			updatedVertices.push(vx);
			updatedVertices.push(vy);
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