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
	import org.papervision3d.core.render.data.RenderData;
	import org.papervision3d.core.render.pipeline.BasicPipeline;
	import org.papervision3d.objects.DisplayObject3D;
	import org.papervision3d.objects.primitives.Cube;
	import org.papervision3d.view.Viewport3D;

	[SWF (backgroundColor="#000000")]
	
	public class Main extends Sprite
	{
		use namespace pv3d;
		
		public var container :Sprite;
		public var vertexGeometry :VertexGeometry;
		public var cube :Cube;
		public var camera :Camera3D;
		public var pipeline :BasicPipeline;
		public var viewport :Rectangle;
		public var scene :DisplayObject3D;
		public var renderData :RenderData;
		
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

			addChild(new Stats());

			camera = new Camera3D(50, 1, 10000, aspect, "Camera01");
			pipeline = new BasicPipeline();
			
			cube = new Cube();
			
			var cubeChild0 :Cube = new Cube("red");
			cube.addChild( cubeChild0 );
			cubeChild0.x = 200;
			
			var cubeChild1 :Cube = new Cube("blue");
			cube.addChild( cubeChild1 );
			cubeChild1.z = 200;
			
			var cubeChild2 :Cube = new Cube("green");
			cube.addChild( cubeChild2 );
			cubeChild2.y = 200;
			
			scene = new DisplayObject3D("Scene");
			scene.addChild( camera );
			scene.addChild( cube );
				
			camera.z = 1000;
			
			renderData = new RenderData();
			renderData.camera = camera;
			renderData.scene = scene;
			renderData.viewport = new Viewport3D(0, 0, true);
			
			addChild(renderData.viewport);
			
			render();
			
			addEventListener(Event.ENTER_FRAME, render);
		}
		
		private var _r :Number = 0;
		
		private function render(event:Event=null):void
		{
			// rotation in global frame of reference : append
			//cube.x ++;
			cube.rotationY++;
			
			//cube.getChildByName("blue").x += 0.1;
			//cube.getChildByName("blue").rotationZ--;
			cube.getChildByName("blue").lookAt( cube.getChildByName("green") );
			
			cube.getChildByName("red").rotateAround(_r++, Vector3D.Z_AXIS);
			cube.getChildByName("green").rotateAround(_r++, Vector3D.X_AXIS);
			
			camera.lookAt( cube.getChildByName("green") );
			
			pipeline.execute(renderData);	
			
			renderData.viewport.containerSprite.graphics.clear();	
			
			draw(renderData.viewport.containerSprite.graphics, scene);
		}
		
		private function draw(g:Graphics, object:DisplayObject3D):void
		{
			var child :DisplayObject3D;
			var geometry :TriangleGeometry = object as TriangleGeometry;
			var triangle :Triangle;
			var hw :Number = renderData.viewport.viewportWidth / 2;
			var hh :Number = renderData.viewport.viewportHeight / 2;
			var color :uint = 0xffff00;
			
			switch(object.name)
			{
				case "red":
					color = 0xff0000;
					break;
				case "green":
					color = 0x00ff00;
					break;
				case "blue":
					color = 0x0000ff;
					break;
				default:
					break;	
			}
			
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
					y0 *= -hh;
					x1 *= hw;
					y1 *= -hh;
					x2 *= hw;
					y2 *= -hh;
					
					// Simple draw
					g.lineStyle(0, color);
					g.moveTo(x0, y0);
					g.lineTo(x1, y1);
					g.lineTo(x2, y2);
					g.lineTo(x0, y0);
				}
			}
			
			for each (child in object._children)
			{
				draw(g, child);
			}
		}
	}
}
