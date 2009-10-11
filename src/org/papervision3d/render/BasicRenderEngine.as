package org.papervision3d.render
{
	import flash.geom.Utils3D;
	import flash.geom.Vector3D;
	
	import org.papervision3d.cameras.Camera3D;
	import org.papervision3d.core.geom.Triangle;
	import org.papervision3d.core.geom.provider.TriangleGeometry;
	import org.papervision3d.core.math.Frustum3D;
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
	import org.papervision3d.view.Viewport3D;

	public class BasicRenderEngine extends AbstractRenderEngine
	{
		use namespace pv3d;
		
		public var renderList :IDrawableList;
		public var clipper :IPolygonClipper;
		public var viewport :Viewport3D;
		public var geometry :TriangleGeometry;
		
		private var _clipFlags :uint;
		private var _clippedTriangles :int = 0;
		private var _culledTriangles :int = 0;
		private var _totalTriangles :int = 0;
		
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
			
			_clipFlags = ClipFlags.ALL;
		}
		
		override public function renderScene(renderData:RenderData):void
		{
			var scene :DisplayObject3D = renderData.scene;
			var camera :Camera3D = renderData.camera;

			this.viewport = renderData.viewport;
			
			camera.rotationX = camera.rotationX;
			camera.update(renderData.viewport.sizeRectangle);
						
			pipeline.execute(renderData);
 
 			renderList.clear();
 			
 			_totalTriangles = 0;
 			_culledTriangles = 0;
 			_clippedTriangles = 0;
 			
			fillRenderList(camera, scene);
		}
		
		/**
		 * Fills our renderlist.
		 * <p>Get rid of triangles behind the near plane, clip straddling triangles if needed.</p>
		 * 
		 * @param	camera
		 * @param	object
		 */ 
		private function fillRenderList(camera:Camera3D, object:DisplayObject3D):void 
		{
			var child :DisplayObject3D;
			var clipPlanes :Vector.<Plane3D> = camera.frustum.viewClippingPlanes;
			var v0 :Vector3D = new Vector3D();
			var v1 :Vector3D = new Vector3D();
			var v2 :Vector3D = new Vector3D();
			
			if (object is TriangleGeometry)
			{
				var triangle :Triangle;
				var inside :Boolean;
				var flags :int = 0;
				
				geometry = object as TriangleGeometry;
				
				for each (triangle in geometry.triangles)
				{
					triangle.clipFlags = 0;
					triangle.visible = false;
					
					_totalTriangles++;
					
					// get vertices in view / camera space
					v0.x = geometry.viewVertexData[ triangle.v0.vectorIndexX ];	
					v0.y = geometry.viewVertexData[ triangle.v0.vectorIndexY ];
					v0.z = geometry.viewVertexData[ triangle.v0.vectorIndexZ ];
					v1.x = geometry.viewVertexData[ triangle.v1.vectorIndexX ];	
					v1.y = geometry.viewVertexData[ triangle.v1.vectorIndexY ];
					v1.z = geometry.viewVertexData[ triangle.v1.vectorIndexZ ];
					v2.x = geometry.viewVertexData[ triangle.v2.vectorIndexX ];	
					v2.y = geometry.viewVertexData[ triangle.v2.vectorIndexY ];
					v2.z = geometry.viewVertexData[ triangle.v2.vectorIndexZ ];
					
					// setup clipflags
					if (_clipFlags & ClipFlags.NEAR)
					{
						flags = getClipFlags(clipPlanes[Frustum3D.NEAR], v0, v1, v2);
						if (flags == 7 ) { _culledTriangles++; continue; }
						else if (flags) { triangle.clipFlags |= ClipFlags.NEAR; }
					}
					
					if (_clipFlags & ClipFlags.FAR)
					{
						flags = getClipFlags(clipPlanes[Frustum3D.FAR], v0, v1, v2);
						if (flags == 7 ) { _culledTriangles++; continue; }
						else if (flags) { triangle.clipFlags |= ClipFlags.FAR; }
					}
					
					if (_clipFlags & ClipFlags.LEFT)
					{
						flags = getClipFlags(clipPlanes[Frustum3D.LEFT], v0, v1, v2);
						if (flags == 7 ) { _culledTriangles++; continue; }
						else if (flags) { triangle.clipFlags |= ClipFlags.LEFT; }
					}
					
					if (_clipFlags & ClipFlags.RIGHT)
					{
						flags = getClipFlags(clipPlanes[Frustum3D.RIGHT], v0, v1, v2);
						if (flags == 7 ) { _culledTriangles++; continue; }
						else if (flags) { triangle.clipFlags |= ClipFlags.RIGHT; }
					}
					
					if (_clipFlags & ClipFlags.TOP)
					{
						flags = getClipFlags(clipPlanes[Frustum3D.TOP], v0, v1, v2);
						if (flags == 7 ) { _culledTriangles++; continue; }
						else if (flags) { triangle.clipFlags |= ClipFlags.TOP; }
					}
					
					if (_clipFlags & ClipFlags.BOTTOM)
					{
						flags = getClipFlags(clipPlanes[Frustum3D.BOTTOM], v0, v1, v2);
						if (flags == 7 ) { _culledTriangles++; continue; }
						else if (flags) { triangle.clipFlags |= ClipFlags.BOTTOM };
					}
					
					if (triangle.clipFlags == 0)
					{
						// triangle completely in view
						// select screen vertex data
						v0.x = geometry.screenVertexData[ triangle.v0.screenIndexX ];	
						v0.y = geometry.screenVertexData[ triangle.v0.screenIndexY ];
						v1.x = geometry.screenVertexData[ triangle.v1.screenIndexX ];	
						v1.y = geometry.screenVertexData[ triangle.v1.screenIndexY ];
						v2.x = geometry.screenVertexData[ triangle.v2.screenIndexX ];	
						v2.y = geometry.screenVertexData[ triangle.v2.screenIndexY ];
						
						// Simple backface culling.
						if ((v2.x - v0.x) * (v1.y - v0.y) - (v2.y - v0.y) * (v1.x - v0.x) > 0)
						{
							_culledTriangles ++;
							continue;
						}
						
						var drawable :TriangleDrawable = triangle.drawable as TriangleDrawable || new TriangleDrawable();
						drawable.screenZ = (v0.z + v1.z + v2.z) / 3;
						drawable.x0 = v0.x;
						drawable.y0 = v0.y;
						drawable.x1 = v1.x;
						drawable.y1 = v1.y;
						drawable.x2 = v2.x;
						drawable.y2 = v2.y;
		
						renderList.addDrawable(drawable);
					}
					else
					{
						clipViewTriangle(camera, triangle, v0, v1, v2);
					}	
				}
			}
			
			for each (child in object._children)
			{
				fillRenderList(camera, child);
			}
		}
		
		/**
		 * Clips a triangle in view / camera space. Typically used for the near and far planes.
		 * 
		 * @param	camera
		 * @param	triangle
		 * @param	v0
		 * @param	v1
		 * @param 	v2
		 */ 
		private function clipViewTriangle(camera:Camera3D, triangle:Triangle, v0:Vector3D, v1:Vector3D, v2:Vector3D):void
		{
			var plane :Plane3D = camera.frustum.viewClippingPlanes[ Frustum3D.NEAR ];
			var inV :Vector.<Number> = Vector.<Number>([v0.x, v0.y, v0.z, v1.x, v1.y, v1.z, v2.x, v2.y, v2.z]);
			var inUVT :Vector.<Number> = Vector.<Number>([0, 0, 0, 0, 0, 0, 0, 0, 0]);
			var outV :Vector.<Number> = new Vector.<Number>();
			var outUVT :Vector.<Number> = new Vector.<Number>();
			
			_clippedTriangles++;
			
			if (triangle.clipFlags & ClipFlags.NEAR)
			{
				clipper.clipPolygonToPlane(inV, inUVT, outV, outUVT, plane);
				inV = outV;
				inUVT = outUVT;
			}
			
			if (triangle.clipFlags & ClipFlags.FAR)
			{
				plane = camera.frustum.viewClippingPlanes[ Frustum3D.FAR ];
				outV = new Vector.<Number>();
				outUVT = new Vector.<Number>();
				clipper.clipPolygonToPlane(inV, inUVT, outV, outUVT, plane);
				inV = outV;
				inUVT = outUVT;
			}
			
			if (triangle.clipFlags & ClipFlags.LEFT)
			{
				plane = camera.frustum.viewClippingPlanes[ Frustum3D.LEFT ];
				outV = new Vector.<Number>();
				outUVT = new Vector.<Number>();
				clipper.clipPolygonToPlane(inV, inUVT, outV, outUVT, plane);
				inV = outV;
				inUVT = outUVT;
			}
			
			if (triangle.clipFlags & ClipFlags.RIGHT)
			{
				plane = camera.frustum.viewClippingPlanes[ Frustum3D.RIGHT ];
				outV = new Vector.<Number>();
				outUVT = new Vector.<Number>();
				clipper.clipPolygonToPlane(inV, inUVT, outV, outUVT, plane);
				inV = outV;
				inUVT = outUVT;
			}
			
			if (triangle.clipFlags & ClipFlags.TOP)
			{
				plane = camera.frustum.viewClippingPlanes[ Frustum3D.TOP ];
				outV = new Vector.<Number>();
				outUVT = new Vector.<Number>();
				clipper.clipPolygonToPlane(inV, inUVT, outV, outUVT, plane);
				inV = outV;
				inUVT = outUVT;
			}
			
			if (triangle.clipFlags & ClipFlags.BOTTOM)
			{
				plane = camera.frustum.viewClippingPlanes[ Frustum3D.BOTTOM ];
				outV = new Vector.<Number>();
				outUVT = new Vector.<Number>();
				clipper.clipPolygonToPlane(inV, inUVT, outV, outUVT, plane);
				inV = outV;
				inUVT = outUVT;
			}
			
			Utils3D.projectVectors(camera.projectionMatrix, inV, outV, inUVT);
			
			var numTriangles : int = 1 + ((inV.length / 3)-3);
			var i:int, i2 :int, i3 :int;

			_totalTriangles += numTriangles - 1;
			
			for(i = 0; i < numTriangles; i++)
			{
				i2 = i * 2;
				i3 = i * 3; 
				
				v0.x = outV[0];
				v0.y = outV[1];
				v1.x = outV[i2+2];
				v1.y = outV[i2+3];
				v2.x = outV[i2+4];
				v2.y = outV[i2+5];
				
				if ((v2.x - v0.x) * (v1.y - v0.y) - (v2.y - v0.y) * (v1.x - v0.x) > 0)
				{
					_culledTriangles ++;
					continue;
				}
				
				var drawable :TriangleDrawable = new TriangleDrawable();
							
				drawable.x0 = v0.x;
				drawable.y0 = v0.y;
				
				drawable.x1 = v1.x;
				drawable.y1 = v1.y;
				
				drawable.x2 = v2.x;
				drawable.y2 = v2.y;	
				drawable.screenZ = (inV[2]+inV[i3+5]+inV[i3+8])/3;
				
				renderList.addDrawable(drawable);
			}
		}
		
		/**
		 * 
		 */ 
		private function getClipFlags(plane:Plane3D, v0:Vector3D, v1:Vector3D, v2:Vector3D):int
		{
			var flags :int = 0;
			if ( plane.distance(v0) < 0 ) flags |= 1;
			if ( plane.distance(v1) < 0 ) flags |= 2;
			if ( plane.distance(v2) < 0 ) flags |= 4;
			return flags;
		}
		
		/**
		 * 
		 */
		public function get clippedTriangles():int
		{
			return _clippedTriangles;
		} 
		
		/**
		 * 
		 */
		public function get culledTriangles():int
		{
			return _culledTriangles;
		} 
		
		/**
		 * 
		 */
		public function get totalTriangles():int
		{
			return _totalTriangles;
		} 
	}
}