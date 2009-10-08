package org.papervision3d.core.render.pipeline
{
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	import flash.geom.Utils3D;
	import flash.geom.Vector3D;
	
	import org.papervision3d.cameras.Camera3D;
	import org.papervision3d.core.geom.provider.VertexGeometry;
	import org.papervision3d.core.ns.pv3d;
	import org.papervision3d.objects.DisplayObject3D;
	
	public class SimplePipeline
	{
		use namespace pv3d;
		
		private var _scheduledLookAt :Vector.<DisplayObject3D>;
		private var _lookAtMatrix :Matrix3D;
		private var _lookAtFinalMatrix :Matrix3D;
		private var _lookAtUp :Vector3D;
		private var _lookAtPos :Vector3D;
		private var _lookAtAt :Vector3D;
		private var _lazyLookAt :Boolean;
		
		/**
		 * Whether lookAt's should be executed immediately, or are scheduled for the next render.
		 * If <code>true</code> we save some cycles, as there's no need to recalculate 
		 * the object's matrices.
		 */
		public function get lazyLookAt():Boolean { return _lazyLookAt; }
		public function set lazyLookAt(value:Boolean):void { _lazyLookAt = value; }
		 
		/**
		 * 
		 */ 
		public function SimplePipeline()
		{
			_scheduledLookAt = new Vector.<DisplayObject3D>();
			_lookAtMatrix = new Matrix3D();
			_lookAtFinalMatrix = new Matrix3D();
			_lookAtUp = new Vector3D(0, -1, 0);
			_lookAtPos = new Vector3D();
			_lookAtAt = Vector3D.Z_AXIS;
			_lazyLookAt = false;
		}
		
		/**
		 * 
		 */ 
		public function execute(camera:Camera3D, viewport:Rectangle, object:DisplayObject3D):void
		{
			_scheduledLookAt.length = 0;
			
			transformToWorld(object);	
			
			if (_scheduledLookAt.length)
			{
				handleLookAt();
			}
			
			camera.update(viewport);
			
			transformToView(camera, object);
		}
		
		protected function handleLookAt():void
		{
			while (_scheduledLookAt.length)
			{
				var object :DisplayObject3D = _scheduledLookAt.pop();
				var source :Matrix3D = object.worldTransform;
				var target :Matrix3D = object._lookAtTarget.worldTransform;
			
				object._lookAtTarget = null;
				
				// lookat direction vector
				_lookAtPos.x = source.rawData[12] - target.rawData[12];
				_lookAtPos.y = source.rawData[13] - target.rawData[13];
				_lookAtPos.z = source.rawData[14] - target.rawData[14];
				
				// perform lookAt
				_lookAtMatrix.pointAt(_lookAtPos, _lookAtAt, _lookAtUp);
				
				_lookAtFinalMatrix.rawData = object.parent.worldTransform.rawData;
				_lookAtFinalMatrix.invert();
				_lookAtFinalMatrix.prepend(_lookAtMatrix);

				//We need to update the do3d's rotations
				var components : Vector.<Vector3D> = _lookAtFinalMatrix.decompose();
				var rotation :Vector3D = components[1];
				
				object._rotation.x = rotation.x;
				object._rotation.y = rotation.y;
				object._rotation.z = rotation.z;
				object._dirty = true;
				
				if (_lazyLookAt)
				{	
				}
				else
				{
					// re-transform the object and its children
					transformToWorld(object, object.parent as DisplayObject3D, false);
				}
			}
		}
		
		protected function transformToWorld(object:DisplayObject3D, parent:DisplayObject3D=null, processLookAt:Boolean=true):void
		{
			var child :DisplayObject3D;
			
			if (processLookAt && object._lookAtTarget )
			{
				_scheduledLookAt.push( object );
			}
			
			object.updateTransform();
			object.worldTransform.rawData = object.transform.rawData;
		
			if (parent)
			{
				object.worldTransform.append(parent.worldTransform);	
			}
	
			for each (child in object._children)
			{
				transformToWorld(child, object, processLookAt);
			}
		}

		protected function transformToView(camera:Camera3D, object:DisplayObject3D):void
		{
			var child :DisplayObject3D;
			
			object.viewTransform.rawData = object.worldTransform.rawData;
			object.viewTransform.append(camera.viewMatrix);
			
			if (object is VertexGeometry)
			{
				projectVertices(camera, object as VertexGeometry);
			}
			
			for each (child in object._children)
			{
				transformToView(camera, child);
			}
		}
		
		protected function projectVertices(camera:Camera3D, object:VertexGeometry):void
		{
			// move the vertices into view / camera space
			// we'll need the vertices in this space to check whether vertices are behind the camera.
			// if we move to screen space in one go, screen vertices could move to infinity.
			object.viewTransform.transformVectors(object.vertexData, object.viewVertexData);
			
			// append the projection matrix
			object.viewTransform.append(camera.projectionMatrix);
			
			// move the vertices to screen space.
			// NOTE: some vertices may have moved to infinity, we need to check while processing triangles.
			//       IF so we need to check whether we need to clip the triangles or disgard them.
			Utils3D.projectVectors(object.viewTransform, object.vertexData, object.screenVertexData, object.uvtData);
		}
	}
}