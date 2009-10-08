package org.papervision3d.core.math.utils
{
	import flash.geom.Matrix3D;
	
	public class MatrixUtil
	{
		/**
		 * Creates a projection matrix.
		 * 
		 * @param fovY
		 * @param aspectRatio
		 * @param near
		 * @param far
		 */
		public static function createProjectionMatrix(fovy:Number, aspect:Number, zNear:Number, zFar:Number):Matrix3D 
		{
			var sine :Number, cotangent :Number, deltaZ :Number;
    		var radians :Number = (fovy / 2) * (Math.PI / 180);
			
		    deltaZ = zFar - zNear;
		    sine = Math.sin(radians);
		    if ((deltaZ == 0) || (sine == 0) || (aspect == 0)) 
		    {
				return null;
		    }
		    cotangent = Math.cos(radians) / sine;
		    
			var v:Vector.<Number> = Vector.<Number>([
				cotangent / aspect, 0, 0, 0,
				0, cotangent, 0, 0,
				0, 0, -(zFar + zNear) / deltaZ, -1,
				0, 0, -(2 * zFar * zNear) / deltaZ, 0
			]);
			return new Matrix3D(v);
		}
		
		/**
		 * 
		 */ 
		public static function createOrthoMatrix(left:Number, right:Number, top:Number, bottom:Number, zNear:Number, zFar:Number) : Matrix3D {
			var tx :Number = (right + left) / (right - left);
			var ty :Number = (top + bottom) / (top - bottom);
			var tz :Number = (zFar+zNear) / (zFar-zNear);
			var v:Vector.<Number> = Vector.<Number>([
				2 / (right - left), 0, 0, 0,
				0, 2 / (top - bottom), 0, 0,
				0, 0, -2 / (zFar-zNear), 0,
				tx, ty, tz, 1
			]);
			return new Matrix3D(v);
		}

	}
}