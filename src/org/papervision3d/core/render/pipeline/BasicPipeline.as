package org.papervision3d.core.render.pipeline
{
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	import flash.geom.Utils3D;
	import flash.geom.Vector3D;
	
	import org.papervision3d.cameras.Camera3D;
	import org.papervision3d.core.geom.provider.VertexGeometry;
	import org.papervision3d.core.math.Quaternion;
	import org.papervision3d.core.math.utils.MathUtil;
	import org.papervision3d.core.ns.pv3d;
	import org.papervision3d.core.render.data.RenderData;
	import org.papervision3d.objects.DisplayObject3D;
	
	public class BasicPipeline implements IRenderPipeline
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
		public function BasicPipeline()
		{
			_scheduledLookAt = new Vector.<DisplayObject3D>();
			_lookAtMatrix = new Matrix3D();
			_lookAtFinalMatrix = new Matrix3D();
			_lookAtUp = new Vector3D(0, -1, 0);
			_lookAtPos = new Vector3D();
			_lookAtAt = Vector3D.Z_AXIS;
			_lazyLookAt = true;
		}
		
		/**
		 * 
		 */ 
		public function execute(renderData:RenderData):void
		{
			var scene :DisplayObject3D = renderData.scene;
			var camera :Camera3D = renderData.camera;
			var rect :Rectangle = renderData.viewport.sizeRectangle;
			
			_scheduledLookAt.length = 0;
			
			transformToWorld(scene);	
			
			if (_scheduledLookAt.length)
			{
				handleLookAt();
			}
			
			camera.update(rect);
			
			transformToView(camera, scene);
		}
		
		protected function handleLookAt():void
		{
			while (_scheduledLookAt.length)
			{
				var object :DisplayObject3D = _scheduledLookAt.pop();
				var source :Matrix3D = object.worldTransform;
				//var target :Matrix3D = object._lookAtTarget.worldTransform;
			
				if (object.transform._lookAt)
				{
					object.worldTransform.prepend(object.transform._lookAt);
				}
				//object._lookAtTarget = null;
			///	trace("lookAt: " + object.name);
				
				continue;
					
				// lookat direction vector
				_lookAtPos.x = target.rawData[12] - source.rawData[12];
				_lookAtPos.y = target.rawData[13] - source.rawData[13];
				_lookAtPos.z = target.rawData[14] - source.rawData[14];
				_lookAtPos.normalize();
				
				/*
				// perform lookAt
				_lookAtMatrix.pointAt(_lookAtPos, _lookAtAt, _lookAtUp);
				
				_lookAtFinalMatrix.rawData = object.parent.worldTransform.rawData;
				_lookAtFinalMatrix.invert();
					_lookAtFinalMatrix.prepend(_lookAtMatrix);
*/
				
				var s :Vector3D = _lookAtPos.crossProduct(new Vector3D(0,1,0));
				var u :Vector3D = s.crossProduct(_lookAtPos);
				var v :Vector.<Number> = _lookAtFinalMatrix.rawData;
				
				v[0] = s.x;	v[1] = s.y; v[2] = s.z;
				v[4] = u.x;	v[5] = u.y; v[6] = u.z;
				v[8] = -_lookAtPos.x;	v[9] = -_lookAtPos.y; v[10] = -_lookAtPos.z;
				 
				_lookAtFinalMatrix.rawData = v;
				
				_lookAtMatrix.rawData = object.worldTransform.rawData;
				_lookAtMatrix.invert();
				_lookAtFinalMatrix.prepend(_lookAtMatrix);
				
				//We need to update the do3d's rotations
				var components : Vector.<Vector3D> = _lookAtFinalMatrix.decompose();
				var rotation :Vector3D = components[1];
				
				rotation.x *= MathUtil.TO_DEGREES;
				rotation.y *= MathUtil.TO_DEGREES;
				rotation.z *= MathUtil.TO_DEGREES;
				//object.transform.rotate(rotation, false);
				//object.transform.rotation = Quaternion.createFromMatrix(_lookAtFinalMatrix);
				object.transform.localEulerAngles = rotation;

				object.transform.dirty = true;
				
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
			
			if (processLookAt && object.transform._lookAt )
			{
				_scheduledLookAt.push( object );
			}

			object.worldTransform.rawData = object.transform.localToWorldMatrix.rawData;
		
			if (parent)
			{
				object.worldTransform.append(parent.worldTransform);	
			}
	
			object.transform.position = object.worldTransform.transformVector(object.transform.localPosition);
		
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
			object.screenTransform.rawData = object.viewTransform.rawData;
			object.screenTransform.append(camera.projectionMatrix);
			
			// move the vertices to screen space.
			// NOTE: some vertices may have moved to infinity, we need to check while processing triangles.
			//       IF so we need to check whether we need to clip the triangles or disgard them.
			Utils3D.projectVectors(object.screenTransform, object.vertexData, object.screenVertexData, object.uvtData);
		}
	}
}