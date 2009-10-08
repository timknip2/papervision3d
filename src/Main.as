package {
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	
	import net.hires.debug.Stats;
	
	import org.papervision3d.cameras.Camera3D;
	import org.papervision3d.core.geom.Triangle;
	import org.papervision3d.core.geom.provider.TriangleGeometry;
	import org.papervision3d.core.geom.provider.VertexGeometry;
	import org.papervision3d.core.ns.pv3d;
	import org.papervision3d.core.render.pipeline.SimplePipeline;
	import org.papervision3d.objects.DisplayObject3D;
	import org.papervision3d.objects.primitives.Cube;

	public class Main extends Sprite
	{
		use namespace pv3d;
		
		public var container :Sprite;
		public var vertexGeometry :VertexGeometry;
		public var cube :Cube;
		public var camera :Camera3D;
		public var pipeline :SimplePipeline;
		public var viewport :Rectangle;
		public var scene :DisplayObject3D;
		
		public function Main()
		{
			init();
		}
		
		private function init():void
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.frameRate = 60;
			
			var aspect :Number = stage.stageWidth / stage.stageHeight;
		
			container = new Sprite();
			addChild(container);
			container.x = stage.stageWidth / 2;
			container.y = stage.stageHeight / 2;
			container.scaleY = -1;
			
			addChild(new Stats());
			
			viewport = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
			camera = new Camera3D(60, 1, 10000, aspect, "Camera01");
			pipeline = new SimplePipeline();
			cube = new Cube();
		
			scene = new DisplayObject3D("Scene");
			scene.children.push( camera );
			scene.children.push( cube );
				
			camera.transform.appendTranslation(0, 0, 500);
			
			render();
			
			addEventListener(Event.ENTER_FRAME, render);
		}
		
		private function render(event:Event=null):void
		{
			//camera.transform.appendTranslation(0, 0, 1);
			//cube.transform.appendTranslation(0, 0, -1);
			cube.transform.appendRotation(1, Vector3D.Y_AXIS);
			
			
			pipeline.execute(camera, viewport, scene);	
			
			container.graphics.clear();	
			
			draw(container.graphics, scene);
		}
		
		private function draw(g:Graphics, object:DisplayObject3D):void
		{
			var child :DisplayObject3D;
			var geometry :TriangleGeometry = object as TriangleGeometry;
			var triangle :Triangle;
			var hw :Number = viewport.width / 2;
			var hh :Number = viewport.height / 2;
			
			if (geometry)
			{
				for each (triangle in geometry.triangles)
				{
					var x0 :Number = geometry.screenVertexData[triangle.v0.screenIndexX];
					var y0 :Number = geometry.screenVertexData[triangle.v0.screenIndexY];
					var x1 :Number = geometry.screenVertexData[triangle.v1.screenIndexX];
					var y1 :Number = geometry.screenVertexData[triangle.v1.screenIndexY];
					var x2 :Number = geometry.screenVertexData[triangle.v2.screenIndexX];
					var y2 :Number = geometry.screenVertexData[triangle.v2.screenIndexY];
					
					// Simple backface culling.
					if ((x2 - x0) * (y1 - y0) - (y2 - y0) * (x1 - x0) > 0)
					{
						continue;
					}
					
					// Our projection matrix moves vertices into the range [-1,-1,-1] to [1,1,1]
					// so we need to scale up to match the viewport.
					// @see Camera3D, MatrixUtils and SimplePipeline
					x0 *= hw;
					y0 *= hh;
					x1 *= hw;
					y1 *= hh;
					x2 *= hw;
					y2 *= hh;
					
					// Simple draw
					g.lineStyle(0, 0xff0000);
					g.moveTo(x0, y0);
					g.lineTo(x1, y1);
					g.lineTo(x2, y2);
					g.lineTo(x0, y0);
				}
			}
			
			for each (child in object.children)
			{
				draw(g, child);
			}
		}
	}
}
