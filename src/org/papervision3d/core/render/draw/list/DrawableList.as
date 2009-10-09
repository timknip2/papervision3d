package org.papervision3d.core.render.draw.list
{
	import org.papervision3d.core.render.draw.items.IDrawable;
	
	public class DrawableList implements IDrawableList
	{
		private var _drawables :Vector.<IDrawable>;
		
		public function DrawableList()
		{
			_drawables = new Vector.<IDrawable>();
		}

		public function addDrawable(drawable:IDrawable):void
		{
			_drawables.push(drawable);
		}
		
		public function clear():void
		{
			_drawables.length = 0;
		}
		
		public function get drawables():Vector.<IDrawable>
		{
			return _drawables;
		}
	}
}