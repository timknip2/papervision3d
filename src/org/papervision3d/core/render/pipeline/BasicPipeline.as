package org.papervision3d.core.render.pipeline
{
	import __AS3__.vec.Vector;
	
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	import flash.geom.Utils3D;
	import flash.geom.Vector3D;
	
	import org.papervision3d.cameras.Camera3D;
	import org.papervision3d.core.geom.provider.VertexGeometry;
	import org.papervision3d.core.math.BoundingSphere3D;
	import org.papervision3d.core.math.Plane3D;
	import org.papervision3d.core.math.Quaternion;
	import org.papervision3d.core.math.utils.MathUtil;
	import org.papervision3d.core.math.utils.MatrixUtil;
	import org.papervision3d.core.ns.pv3d;
	import org.papervision3d.core.proto.Transform3D;
	import org.papervision3d.core.render.data.RenderData;
	import org.papervision3d.objects.DisplayObject3D;
	
	public class BasicPipeline implements IRenderPipeline
	{
		use namespace pv3d;
		
		private var _scheduledLookAt :Vector.<DisplayObject3D>;
		private var _lookAtMatrix :Matrix3D;
		private var _invWorldMatrix :Matrix3D;
		
		public var culledObjects :int;
		
		/**
		 * 
		 */ 
		public function BasicPipeline()
		{
			_scheduledLookAt = new Vector.<DisplayObject3D>();
			_lookAtMatrix = new Matrix3D();
			_invWorldMatrix = new Matrix3D();
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
			
			culledObjects = 0;
			
			transformToWorld(scene);	
			
			// handle lookAt
			if (_scheduledLookAt.length)
			{
				handleLookAt();
			}
			
			camera.update(rect);
			
			transformToView(camera, scene);
		}
		
		/**
		 * Processes all scheduled lookAt's.
		 */ 
		protected function handleLookAt():void
		{
			while (_scheduledLookAt.length)
			{
				var object :DisplayObject3D = _scheduledLookAt.pop();
				var transform :Transform3D = object.transform;
				var eye :Vector3D = transform.position;
				var tgt :Vector3D = transform.scheduledLookAt.position;
				var up :Vector3D = transform.scheduledLookAtUp;
					
				// create the lookAt matrix
				MatrixUtil.createLookAtMatrix(eye, tgt, up, _lookAtMatrix);
				
				_lookAtMatrix.appendTranslation(-eye.x, -eye.y, -eye.z);
				
				var q:Quaternion = Quaternion.createFromMatrix(_lookAtMatrix);
				
				// need to cancel out the parent transform
				if (object.parent)
				{
					_invWorldMatrix.rawData = object.parent.transform.worldTransform.rawData;
					_invWorldMatrix.invert();
					
					q.mult( Quaternion.createFromMatrix(_invWorldMatrix) );	
				}
				
				//q.mult(object.transform.localRotation);
				
				object.transform.localRotation = q;
			//	object.transform.localRotation.normalize();
				object.transform.dirty = false;
				
				// clear
				object.transform.scheduledLookAt = null;
				
				transformToWorld(object, object.parent as DisplayObject3D);
			}
		}
		
		/**
		 * Processes all scheduled lookAt's.
		 */ 
		protected function handleLookAt2():void
		{
			while (_scheduledLookAt.length)
			{
				var object :DisplayObject3D = _scheduledLookAt.pop();
				var transform :Transform3D = object.transform;
				var eye :Vector3D = transform.position;
				var tgt :Vector3D = transform.scheduledLookAt.position;
				var up :Vector3D = transform.scheduledLookAtUp;
					
				// create the lookAt matrix
				MatrixUtil.createLookAtMatrix(eye, tgt, up, _lookAtMatrix);
				
				// prepend it to the world matrix
				object.transform.worldTransform.prepend(_lookAtMatrix);

				// TODO: the lookAt does not persist, we need to feed the transform new eulers.
			
				// need to cancel out the parent transform
				if (object.parent)
				{
					_invWorldMatrix.rawData = object.parent.transform.worldTransform.rawData;
					_invWorldMatrix.invert();
					object.transform.worldTransform.append(_invWorldMatrix);	
				}
				
				var q :Quaternion = Quaternion.createFromMatrix(object.transform.worldTransform);
				
				object.transform.eulerAngles = q.toEuler();
				object.transform.eulerAngles.x *= MathUtil.TO_DEGREES;
				object.transform.eulerAngles.y *= MathUtil.TO_DEGREES;
				object.transform.eulerAngles.z *= MathUtil.TO_DEGREES;
				object.transform.dirty = true;
				
				object.transform.position = object.transform.worldTransform.transformVector(object.transform.localPosition);
				
				object.transform.forward.x = -object.transform.worldTransform.rawData[2];
				object.transform.forward.y = -object.transform.worldTransform.rawData[6];
				object.transform.forward.z = -object.transform.worldTransform.rawData[10];
			
				// clear
				object.transform.scheduledLookAt = null;
			}
		}
		
		/**
		 * 
		 */ 
		protected function transformToWorld(object:DisplayObject3D, parent:DisplayObject3D=null):void
		{
			var child :DisplayObject3D;
			var wt :Matrix3D = object.transform.worldTransform;
			
			if (object.transform.scheduledLookAt)
			{
				_scheduledLookAt.push( object );
			}

			// setup world matrix
			wt.rawData = object.transform.localToWorldMatrix.rawData;
			if (parent)
			{
				wt.append(parent.transform.worldTransform);	
			}
	
			// setup world position
			object.transform.position = wt.transformVector(object.transform.localPosition);
			
			object.transform.forward.x = -wt.rawData[8];
			object.transform.forward.y = -wt.rawData[9];
			object.transform.forward.z = -wt.rawData[10];
			
			// bounding sphere
			if (!object.boundingSphere)
			{
				object.boundingSphere = new BoundingSphere3D();
				
				if (object is VertexGeometry)
				{
					object.boundingSphere.setFromVertices( VertexGeometry(object).vertices );
				}
				else
				{
					object.boundingSphere.origin.x = object.x;
					object.boundingSphere.origin.y = object.y;
					object.boundingSphere.origin.z = object.z;
				}
			}
			
			// update bounding sphere
			object.boundingSphere.worldOrigin = wt.transformVector(object.transform.localPosition);
			object.boundingSphere.worldRadius = object.boundingSphere.radius * Math.max(object.scaleX, Math.max(object.scaleY, object.scaleZ));

			// recurse
			for each (child in object._children)
			{
				transformToWorld(child, object);
			}
		}

		/**
		 * 
		 */ 
		protected function transformToView(camera:Camera3D, object:DisplayObject3D):void
		{
			var child :DisplayObject3D;
			var wt :Matrix3D = object.transform.worldTransform;
			var vt :Matrix3D = object.transform.viewTransform;
			var planes :Vector.<Plane3D> = camera.frustum.worldClippingPlanes;
			var pos :Vector3D = object.transform.position; //object.boundingSphere.worldOrigin;
			var radius :Number = object.boundingSphere.worldRadius;
			var plane :Plane3D;
		//	var mp :Matrix3D = vt.clone();
			
		//	mp.append(camera.projectionMatrix);
			
			object.cullingState = 0;

			if (camera.enableCulling)
			{
				for each (plane in planes)
				{
					if (plane.distance(pos) < -radius)
					{
						object.cullingState = 1;
						culledObjects++;
						break;
					}
				}
			}
			
			if (object.cullingState == 0)
			{
				vt.rawData = wt.rawData;
				vt.append(camera.viewMatrix);
				
				if (object is VertexGeometry)
				{
					projectVertices(camera, object as VertexGeometry);
				}
			}
			
			for each (child in object._children)
			{
				transformToView(camera, child);
			}
		}
		
		/**
		 * 
		 */ 
		protected function projectVertices(camera:Camera3D, object:VertexGeometry):void
		{
			var vt :Matrix3D = object.transform.viewTransform;
			var st :Matrix3D = object.transform.screenTransform;
			
			// move the vertices into view / camera space
			// we'll need the vertices in this space to check whether vertices are behind the camera.
			// if we move to screen space in one go, screen vertices could move to infinity.
			vt.transformVectors(object.vertexData, object.viewVertexData);
			
			// append the projection matrix to the object's view matrix
			st.rawData = vt.rawData;
			st.append(camera.projectionMatrix);
			
			// move the vertices to screen space.
			// AKA: the perspective divide
			// NOTE: some vertices may have moved to infinity, we need to check while processing triangles.
			//       IF so we need to check whether we need to clip the triangles or disgard them.
			Utils3D.projectVectors(st, object.vertexData, object.screenVertexData, object.uvtData);
		}
	}
}