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
		public var parent :DisplayObject3D;
		
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
		
		/**
		 * 
		 */ 
		public function addChild(child:DisplayObject3D):DisplayObject3D
		{
			var root :DisplayObject3D = this;
			while( root.parent ) root = root.parent;
			
			if (root.findChild(child, true) )
			{
				throw new Error("This child was already added to the scene!");
			}
			
			this.children.push(child);
			
			return child;	
		}
		
		/**
		 * Find a child.
		 * 
		 * @param	child	The child to find.
		 * @param	deep	Whether to search recursivelly
		 * 
		 * @return The found child or null on failure.
		 */ 
		public function findChild(child:DisplayObject3D, deep:Boolean=true):DisplayObject3D
		{
			var index :int = this.children.indexOf(child);
			
			if (index < 0)
			{
				if (deep)
				{
					var object :DisplayObject3D;
					for each (object in this.children)
					{
						var c :DisplayObject3D = object.findChild(child, true);
						if (c) return c;
					}
				}
			}
			else
			{
				return this.children[index];
			}
			
			return null;
		}
		
		/**
		 * 
		 */ 
		public function getChildAt(index:uint):DisplayObject3D
		{
			if (index < this.children.length)
			{
				return this.children[index];
			}
			else
			{
				return null;
			}
		}
		
		/**
		 * Gets a child by name.
		 * 
		 * @param	name	Name of the DisplayObject3D to find.
		 * @param	deep	Whether to perform a recursive search
		 * 
		 * @return	The found DisplayObject3D or null on failure.
		 */ 
		public function getChildByName(name:String, deep:Boolean=true):DisplayObject3D
		{
			var child :DisplayObject3D;
			
			for each (child in this.children)
			{
				if (child.name == name)
				{
					return child;
				}
				
				if (deep)
				{
					var c :DisplayObject3D = child.getChildByName(name, true);
					if (c) return c;
				}
			}
			
			return null;
		}
	}
}