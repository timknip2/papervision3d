package org.papervision3d.core.render.pipeline
{
	import org.papervision3d.cameras.Camera3D;
	
	public interface IRenderPipeline
	{
		function render(camera:Camera3D):void;
	}
}