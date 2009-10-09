package org.papervision3d.core.render.draw.items
{
	public class AbstractDrawable implements IDrawable
	{
		public var material :int;
		
		public function AbstractDrawable()
		{
			this.material = -1;
		}

	}
}