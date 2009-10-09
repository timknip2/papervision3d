package org.papervision3d.render
{
	import flash.geom.Vector3D;
	
	import org.papervision3d.cameras.Camera3D;
	import org.papervision3d.core.geom.Triangle;
	import org.papervision3d.core.geom.provider.TriangleGeometry;
	import org.papervision3d.core.math.Plane3D;
	import org.papervision3d.core.ns.pv3d;
	import org.papervision3d.core.render.clipping.ClipFlags;
	import org.papervision3d.core.render.clipping.IPolygonClipper;
	import org.papervision3d.core.render.clipping.SutherlandHodgmanClipper;
	import org.papervision3d.core.render.data.RenderData;
	import org.papervision3d.core.render.draw.items.TriangleDrawable;
	import org.papervision3d.core.render.draw.list.DrawableList;
	import org.papervision3d.core.render.draw.list.IDrawableList;
	import org.papervision3d.core.render.engine.AbstractRenderEngine;
	import org.papervision3d.core.render.pipeline.BasicPipeline;
	import org.papervision3d.objects.DisplayObject3D;
	import org.papervision3d.objects.Frustum3D;

	public class BasicRenderEngine extends AbstractRenderEngine
	{
		use namespace pv3d;
		
		public var renderList :IDrawableList;
		public var clipper :IPolygonClipper;
		
		public function BasicRenderEngine()
		{
			super();
			init();
		}
		
		protected function init():void
		{
			pipeline = new BasicPipeline();
			renderList = new DrawableList();
			clipper = new SutherlandHodgmanClipper();
		}
		
		override public function renderScene(renderData:RenderData):void
		{
			var scene :DisplayObject3D = renderData.scene;
			var camera :Camera3D = renderData.camera;
			
			pipeline.execute(renderData);
 
 			renderList.clear();
			test(camera, scene);
		}
		
		/**
		 * Get rid of triangles behind the near plane, clip straddling triangles if needed.
		 * 
		 * @param	camera
		 * @param	object
		 */ 
		private function test(camera:Camera3D, object:DisplayObject3D):void 
		{
			var child :DisplayObject3D;
			var v0 :Vector3D = new Vector3D();
			var v1 :Vector3D = new Vector3D();
			var v2 :Vector3D = new Vector3D();
			
			if (object is TriangleGeometry)
			{
				var frustum :Frustum3D = camera._frustum;
				var near :Plane3D = frustum.worldPlanes[0];
				var far :Plane3D = frustum.worldPlanes[1];
				var geom :TriangleGeometry = object as TriangleGeometry;
				var triangle :Triangle;
				var inside :Boolean;
				var flags :int = 0;
				
				for each (triangle in geom.triangles)
				{
					triangle.clipFlags = 0;
					triangle.visible = false;
					
					// get vertices in view / camera space
					v0.x = geom.viewVertexData[ triangle.v0.vectorIndexX ];	
					v0.y = geom.viewVertexData[ triangle.v0.vectorIndexY ];
					v0.z = geom.viewVertexData[ triangle.v0.vectorIndexZ ];
					v1.x = geom.viewVertexData[ triangle.v1.vectorIndexX ];	
					v1.y = geom.viewVertexData[ triangle.v1.vectorIndexY ];
					v1.z = geom.viewVertexData[ triangle.v1.vectorIndexZ ];
					v2.x = geom.viewVertexData[ triangle.v2.vectorIndexX ];	
					v2.y = geom.viewVertexData[ triangle.v2.vectorIndexY ];
					v2.z = geom.viewVertexData[ triangle.v2.vectorIndexZ ];
					
					flags = 0;
					if (near.distance(v0) < 0) flags |= 1;
					if (near.distance(v1) < 0) flags |= 2;
					if (near.distance(v2) < 0) flags |= 4;

					if (flags == 7 )
					{
						// behind near plane
						//continue;
					}
					else if (flags)
					{
						// clip candidate
						triangle.clipFlags |= ClipFlags.NEAR;
					}
					
					flags = 0;
					if (far.distance(v0) < 0) flags |= 1;
					if (far.distance(v1) < 0) flags |= 2;
					if (far.distance(v2) < 0) flags |= 4;
					
					if (flags == 7 )
					{
						// behind far plane
						//continue;
					}
					else if (flags)
					{
						// clip candidate
						triangle.clipFlags |= ClipFlags.FAR;
					}
					
					triangle.visible = true;// (triangle.clipFlags == 0);
					
					if (triangle.visible)
					{	
						// select screen vertex data
						v0.x = geom.screenVertexData[ triangle.v0.screenIndexX ];	
						v0.y = geom.screenVertexData[ triangle.v0.screenIndexY ];
						v1.x = geom.screenVertexData[ triangle.v1.screenIndexX ];	
						v1.y = geom.screenVertexData[ triangle.v1.screenIndexY ];
						v2.x = geom.screenVertexData[ triangle.v2.screenIndexX ];	
						v2.y = geom.screenVertexData[ triangle.v2.screenIndexY ];
					
						if (v0.x > -1 && v0.x < 1 && v1.x > -1 && v1.x < 1 && v2.x > -1 && v2.x < 1 &&
							v0.y > -1 && v0.y < 1 && v1.y > -1 && v1.y < 1 && v2.y > -1 && v2.y < 1)
						{
							var drawable :TriangleDrawable = triangle.drawable as TriangleDrawable || new TriangleDrawable();
							drawable.screenZ = (v0.z + v1.z + v2.z) / 3;
							drawable.x0 = v0.x;
							drawable.y0 = v0.y;
							drawable.x1 = v1.x;
							drawable.y1 = v1.y;
							drawable.x2 = v2.x;
							drawable.y2 = v2.y;
							
							if (object.name == "red")
							{
								drawable.material = 0;
							}
							else if (object.name == "green")
							{
								drawable.material = 1;
							}
							else if (object.name == "blue")
							{
								drawable.material = 2;
							}
							else if (object.name == "Cube")
							{
								drawable.material = 3;
							}
						//	trace ("" + drawable.material);
							renderList.addDrawable(drawable);
						}
						else
						{
							triangle.visible = false;
						}
					}
				}
			}
			
			for each (child in object._children)
			{
				test(camera, child);
			}
		}
	}
}