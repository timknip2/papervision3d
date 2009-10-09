package org.papervision3d.core.render.data
{
	import org.papervision3d.cameras.Camera3D;
	import org.papervision3d.objects.DisplayObject3D;
	import org.papervision3d.view.Viewport3D;
	
	public class RenderData
	{
		public var scene :DisplayObject3D;
		public var camera :Camera3D;
		public var viewport :Viewport3D;
		
		public function RenderData()
		{
		}
	}
}