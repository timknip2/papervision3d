package org.papervision3d.core.proto
{
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	import org.papervision3d.core.math.utils.MathUtil;
	import org.papervision3d.core.ns.pv3d;
	import org.papervision3d.objects.DisplayObject3D;
	
	public class DisplayObjectContainer3D
	{
		use namespace pv3d;
		
		/** */
		public var name :String;
		
		/** */
		public var transform :Matrix3D;
		
		/** */
		public var worldTransform :Matrix3D;
		
		/** */
		public var viewTransform :Matrix3D;
		
		/** */
		pv3d var _children :Vector.<DisplayObject3D>;
		
		/** */
		pv3d var _translation :Vector3D;
		
		/** */
		pv3d var _rotation :Vector3D;
		
		/** */
		pv3d var _scale :Vector3D;
		
		/** */
		pv3d var _transformComponents :Vector.<Vector3D>;
		 
		/** */
		pv3d var _dirty :Boolean;
		
		/** */
		pv3d var _lookAtUp :Vector3D;
		
		/** */
		public var parent :DisplayObjectContainer3D;
		
		/** */
		private static var _newID :int = 0;
		
		/**
		 * 
		 */ 
		public function DisplayObjectContainer3D(name:String=null)
		{
			this.name = name || "Object" + (_newID++);
			
			this.transform = new Matrix3D();
			this.worldTransform = new Matrix3D();
			this.viewTransform = new Matrix3D();
			
			_translation = new Vector3D();
			_rotation = new Vector3D();
			_scale = new Vector3D(1, 1, 1);
			
			_transformComponents = new Vector.<Vector3D>(3, true);
			_transformComponents[0] = _translation;
			_transformComponents[1] = _rotation;
			_transformComponents[2] = _scale;
			
			_dirty = true;
			
			_children = new Vector.<DisplayObject3D>();
		}

		/**
		 * 
		 */ 
		public function addChild(child:DisplayObject3D):DisplayObject3D
		{
			var root :DisplayObjectContainer3D = this;
			while( root.parent ) root = root.parent;
			
			if (root.findChild(child, true) )
			{
				throw new Error("This child was already added to the scene!");
			}
			
			child.parent = this;
			
			_children.push(child);
			
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
			var index :int = _children.indexOf(child);
			
			if (index < 0)
			{
				if (deep)
				{
					var object :DisplayObject3D;
					for each (object in _children)
					{
						var c :DisplayObject3D = object.findChild(child, true);
						if (c) return c;
					}
				}
			}
			else
			{
				return _children[index];
			}
			
			return null;
		}
		
		/**
		 * 
		 */ 
		public function getChildAt(index:uint):DisplayObject3D
		{
			if (index < _children.length)
			{
				return _children[index];
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
		public function getChildByName(name:String, deep:Boolean=false):DisplayObject3D
		{
			var child :DisplayObject3D;
			
			for each (child in _children)
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
		
		/**
		 * Removes a child.
		 * 
		 * @param	child	The child to remove.
		 * @param	deep	Whether to perform a recursive search.
		 * 
		 * @return	The removed child or null on failure.
		 */ 
		public function removeChild(child:DisplayObject3D, deep:Boolean=false):DisplayObject3D
		{
			var index :int = _children.indexOf(child);
			if (index < 0)
			{
				if (deep)
				{
					var object :DisplayObject3D;
					for each (object in _children)
					{
						var c :DisplayObject3D = object.removeChild(object, true);
						if (c) 
						{
							c.parent = null;
							return c;
						}
					}
				}
				return null;	
			}
			else
			{
				child = _children.splice(index, 1)[0];
				child.parent = null;
				return child;
			}
		}
		
		/**
		 * 
		 */ 
		public function removeChildAt(index:int):DisplayObject3D
		{
			if (index < _children.length)
			{
				return _children.splice(index, 1)[0];
			}
			else
			{
				return null;
			}
		}
		
		pv3d var _lookAtTarget :DisplayObject3D;
		
		/**
		 * 
		 */
		public function lookAt(object:DisplayObject3D):void
		{
			_lookAtTarget = object;
		}
		
		/**
		 * 
		 */
		public function rotateAround(degrees:Number, axis:Vector3D, pivot:*=null):void
		{
			pivot = pivot || this.parent;
			
			var pivotPoint :Vector3D;
			
			if (pivot === this.parent)
			{
				pivotPoint = this.parent._translation;
			}
			else if (pivot is Vector3D)
			{
				pivotPoint = pivot as Vector3D;	
			}
			
			_globalRotation.identity();
			
			if (pivotPoint)
			{
				_globalRotation.prependRotation(degrees, axis, pivotPoint);
				_dirty = true;
			}
		}
		
		private var _globalRotation :Matrix3D = new Matrix3D();
		
		/**
		 * Updates the local transform.
		 * 
		 * @return	Boolean indicating success.
		 */ 
		public function updateTransform():Boolean
		{
			var result :Boolean = true;
			if (_dirty)
			{
				result = transform.recompose( _transformComponents );
				
				if (_globalRotation )
				{
					transform.append(_globalRotation);
				}
				
				_dirty = false;
			}
			return result;
		}
		
		/**
		 * 
		 */
		public function get dirty():Boolean
		{
			return _dirty;
		} 
		
		public function set dirty(value:Boolean):void
		{
			_dirty = value;	
		}
		
		/**
		 * 
		 */
		public function get rotation():Vector3D
		{
			return _rotation;
		} 
		
		public function set rotation(value:Vector3D):void
		{
			_rotation = value;
			_transformComponents[1] = _rotation;
			_dirty = true;
		}
		
		/**
		 * 
		 */
		public function get scale():Vector3D
		{
			return _scale;
		} 
		
		public function set scale(value:Vector3D):void
		{
			_scale = value;
			_transformComponents[2] = _scale;
			_dirty = true;
		}
		
		/**
		 * 
		 */
		public function get translation():Vector3D
		{
			return _translation;
		} 
		
		public function set translation(value:Vector3D):void
		{
			_translation = value;
			_transformComponents[0] = _translation;
			_dirty = true;
		}

		/**
		 * 
		 */ 
		public function get x():Number
		{
			return _translation.x;
		}
		
		public function set x(value:Number):void
		{
			_translation.x = value;
			_dirty = true;
		}
		
		/**
		 * 
		 */ 
		public function get y():Number
		{
			return _translation.y;
		}
		
		public function set y(value:Number):void
		{
			_translation.y = value;
			_dirty = true;
		}
		
		/**
		 * 
		 */ 
		public function get z():Number
		{
			return _translation.z;
		}
		
		public function set z(value:Number):void
		{
			_translation.z = value;
			_dirty = true;
		}
				
		/**
		 * 
		 */ 
		public function get rotationX():Number
		{
			return _rotation.x * MathUtil.TO_DEGREES;
		}
		
		public function set rotationX(value:Number):void
		{
			_rotation.x = value * MathUtil.TO_RADIANS;
			_dirty = true;
		}
		
		/**
		 * 
		 */ 
		public function get rotationY():Number
		{
			return _rotation.y * MathUtil.TO_DEGREES;
		}
		
		public function set rotationY(value:Number):void
		{
			_rotation.y = value * MathUtil.TO_RADIANS;
			_dirty = true;
		}
		
		/**
		 * 
		 */ 
		public function get rotationZ():Number
		{
			return _rotation.z * MathUtil.TO_DEGREES;
		}
		
		public function set rotationZ(value:Number):void
		{
			_rotation.z = value * MathUtil.TO_RADIANS;
			_dirty = true;
		}
		
		/**
		 * 
		 */ 
		public function get scaleX():Number
		{
			return _scale.x;
		}
		
		public function set scaleX(value:Number):void
		{
			_scale.x = value;
			_dirty = true;
		}
		
		/**
		 * 
		 */ 
		public function get scaleY():Number
		{
			return _scale.y;
		}
		
		public function set scaleY(value:Number):void
		{
			_scale.y = value;
			_dirty = true;
		}
		
		/**
		 * 
		 */ 
		public function get scaleZ():Number
		{
			return _scale.z;
		}
		
		public function set scaleZ(value:Number):void
		{
			_scale.z = value;
			_dirty = true;
		}
	}
}