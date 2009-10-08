package org.papervision3d.core.render.pipeline
{
	import flash.geom.Rectangle;
	import flash.geom.Utils3D;
	
	import org.papervision3d.cameras.Camera3D;
	import org.papervision3d.core.geom.provider.VertexGeometry;
	import org.papervision3d.core.ns.pv3d;
	import org.papervision3d.objects.DisplayObject3D;
	
	public class SimplePipeline
	{
		use namespace pv3d;
		
		/**
		 * 
		 */ 
		public function SimplePipeline()
		{
		}
		
		/**
		 * 
		 */ 
		public function execute(camera:Camera3D, viewport:Rectangle, object:DisplayObject3D):void
		{
			transformToWorld(object);	
			
			camera.update(viewport);
			
			transformToView(camera, object);
		}
		
		protected function transformToWorld(object:DisplayObject3D, parent:DisplayObject3D=null):void
		{
			var child :DisplayObject3D;
			
			object.worldTransform.rawData = object.transform.rawData;
			
			if (parent)
			{
				object.worldTransform.append(parent.worldTransform);	
			}
			
			for each (child in object.children)
			{
				transformToWorld(child, object);
			}
		}

		protected function transformToView(camera:Camera3D, object:DisplayObject3D):void
		{
			var child :DisplayObject3D;
			
			object.viewTransform.rawData = object.worldTransform.rawData;
			object.viewTransform.append(camera.viewMatrix);
			
			if (object is VertexGeometry)
			{
				object.viewTransform.append(camera.projectionMatrix);
				projectVertices(object as VertexGeometry);
			}
			
			for each (child in object.children)
			{
				transformToView(camera, child);
			}
		}
		
		protected function projectVertices(object:VertexGeometry):void
		{
			Utils3D.projectVectors(object.viewTransform, object.vertexData, object.screenVertexData, object.uvtData);
			
			//trace(object.screenVertexData);
		}
	}
}