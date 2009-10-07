package org.papervision3d.objects
{
	import flash.geom.Matrix3D;
	
	/**
	 * 
	 */ 
	public class DisplayObject3D
	{
		/** */
		public var name :String;
		
		/** */
		public var transform :Matrix3D;
		
		/** */
		public var worldTransform :Matrix3D;
		
		/** */
		public var viewTransform :Matrix3D;
		
		/** */
		public var children :Vector.<DisplayObject3D>;
		 
		/** */
		private static var _newID :int = 0;
		
		/**
		 * 
		 */ 
		public function DisplayObject3D(name:String=null)
		{
			this.name = name || "Object" + (_newID++);
			this.transform = new Matrix3D();
			this.worldTransform = new Matrix3D();
			this.viewTransform = new Matrix3D();
			this.children = new Vector.<DisplayObject3D>();
		}
	}
}