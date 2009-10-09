package org.papervision3d.render
{
	import org.papervision3d.core.render.data.RenderData;
	import org.papervision3d.core.render.engine.AbstractRenderEngine;
	import org.papervision3d.core.render.pipeline.BasicPipeline;

	public class BasicRenderEngine extends AbstractRenderEngine
	{
		public function BasicRenderEngine()
		{
			super();
			init();
		}
		
		protected function init():void
		{
			pipeline = new BasicPipeline();
		}
		
		override public function renderScene(renderData:RenderData):void
		{
			pipeline.execute(renderData);
		}
	}
}