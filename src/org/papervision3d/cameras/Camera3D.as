package org.papervision3d.cameras
{
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	
	import org.papervision3d.core.math.Frustum3D;
	import org.papervision3d.core.math.utils.MatrixUtil;
	import org.papervision3d.core.ns.pv3d;
	import org.papervision3d.objects.DisplayObject3D;

	/**
	 * 
	 */ 
	public class Camera3D extends DisplayObject3D
	{
		use namespace pv3d;
		
		public var projectionMatrix :Matrix3D;
		public var viewMatrix :Matrix3D;
		public var frustum :Frustum3D;
		
		private var _dirty:Boolean;
		private var _fov:Number;
		private var _far:Number;
		private var _near:Number;
		private var _ortho:Boolean;
		private var _orthoScale:Number;
		private var _aspectRatio :Number;
		private var _enableCulling :Boolean;
		private var _worldCullingMatrix :Matrix3D;
		
		/**
		 * Constructor.
		 * 
		 * @param 	fov
		 * @param 	near
		 * @param 	far
		 * @param	name
		 */
		public function Camera3D(fov:Number=60, near:Number=1, far:Number=10000, name:String=null)
		{
			super(name);
			
			_fov = fov;
			_near = near;
			_far = far;
			_dirty = true;
			_ortho = false;
			_orthoScale = 1;
			_enableCulling = false;
			_worldCullingMatrix = new Matrix3D();
			
			frustum = new Frustum3D(this);
			viewMatrix = new Matrix3D();
		}
		
		/**
		 * 
		 */
		public function update(viewport:Rectangle) : void 
		{
			var aspect :Number = viewport.width / viewport.height;
			
			viewMatrix.rawData = transform.worldTransform.rawData;
			viewMatrix.invert();
			
			if (_aspectRatio != aspect)
			{
				_aspectRatio = aspect;
				_dirty = true;
			}
			
			if(_dirty) 
			{
				_dirty = false;
				
				if(_ortho) 
				{
					projectionMatrix = MatrixUtil.createOrthoMatrix(-viewport.width, viewport.width, viewport.height, -viewport.height, _far, -_far);
				} 
				else 
				{
					
					projectionMatrix = MatrixUtil.createProjectionMatrix(_fov, _aspectRatio, _near, _far);
					
				}
				
				// extract the view clipping planes
				frustum.extractPlanes(projectionMatrix, frustum.viewClippingPlanes);
			}
			
			// TODO: sniff whether our transform was dirty, no need to calc when can didn't move.
			if (_enableCulling)
			{
				_worldCullingMatrix.rawData = viewMatrix.rawData;
				_worldCullingMatrix.append(projectionMatrix);
				
				// TODO: why this is needed is weird. If we don't the culling / clipping planes don't
				// seem to match. With this hack all ok... 
				// Tim: Think its got to do with a discrepancy between GL viewport and
				// our draw-container sitting at center stage. 
				_worldCullingMatrix.prependScale(0.5, 0.5, 0.5);
				
				// extract the world clipping planes
				frustum.extractPlanes(_worldCullingMatrix, frustum.worldClippingPlanes, false);
			}
		}
		
		/**
		 * 
		 */
		public function get aspectRatio():Number
		{
			return _aspectRatio;
		}  
		
		/**
		 * 
		 */
		public function get enableCulling():Boolean
		{
			return _enableCulling;
		} 
		
		public function set enableCulling(value:Boolean):void
		{
			_enableCulling = value;	
		}
		
		/**
		 * Distance to the far clipping plane.
		 */
		public function get far():Number
		{
			return _far;
		}
		
		public function set far(value:Number):void
		{
			if (value != _far && value > _near)
			{
				_far = value;
				_dirty = true;
			}
		}
		
		/**
		 * Field of view (vertical) in degrees.
		 */
		public function get fov():Number
		{
			return _fov;
		}
		
		public function set fov(value:Number):void
		{
			if (value != _fov)
			{
				_fov = value;
				_dirty = true;
			}	
		}
		
		/**
		 * Distance to the near clipping plane.
		 */
		public function get near():Number
		{
			return _near;
		} 
		
		public function set near(value:Number):void
		{
			if (value != _near && value > 0 && value < _far)
			{
				_near = value;
				_dirty = true;
			}
		}
		
		/**
		 * Whether to use a orthogonal projection.
		 */ 
		public function get ortho():Boolean
		{
			return _ortho;
		} 
		
		public function set ortho(value:Boolean):void
		{
			if (value != _ortho)
			{
				_ortho = value;
				_dirty = true;
			}
		}
		
		/**
		 * Scale of the orthogonal projection.
		 */ 
		public function get orthoScale():Number
		{
			return _orthoScale;
		}
		
		public function set orthoScale(value:Number):void
		{
			if (value != _orthoScale)
			{
				_orthoScale = value;
				_dirty = true;
			}
		}
	}
}