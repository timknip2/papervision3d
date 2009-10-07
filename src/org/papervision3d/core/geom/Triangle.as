package org.papervision3d.core.geom
{
	import flash.geom.Vector3D;
	
	public class Triangle
	{
		/** */
		public var v0 :Vertex;
		
		/** */
		public var v1 :Vertex;
		
		/** */
		public var v2 :Vertex;
		
		/** */
		public var normal :Vector3D;
		
		/** */
		public var uv0 :UVCoord;
		
		/** */
		public var uv1 :UVCoord;
		
		/** */
		public var uv2 :UVCoord;
		
		/**
		 * Constructor
		 * 
		 * @param
		 * @param
		 * @param
		 */ 
		public function Triangle(v0:Vertex, v1:Vertex, v2:Vertex, uv0:UVCoord=null, uv1:UVCoord=null, uv2:UVCoord=null)
		{
			this.v0 = v0;
			this.v1 = v1;
			this.v2 = v2;
			this.uv0 = uv0 || new UVCoord();
			this.uv1 = uv1 || new UVCoord();
			this.uv2 = uv2 || new UVCoord();
		}
	}
}