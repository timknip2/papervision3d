package org.papervision3d.objects.primitives
{
	import org.papervision3d.core.geom.Triangle;
	import org.papervision3d.core.geom.UVCoord;
	import org.papervision3d.core.geom.Vertex;
	import org.papervision3d.core.geom.provider.TriangleGeometry;

	/**
	 * 
	 */ 
	public class Cube extends TriangleGeometry
	{
		/**
		 * 
		 */ 
		public function Cube(name:String=null, size:Number=100)
		{
			super(name);
			
			create(size);
		}
		
		/**
		 * 
		 */ 
		protected function create(size:Number):void
		{
			var sz : Number = size / 2;
			var v :Array = [
				new Vertex(-sz, sz, -sz),
				new Vertex(sz, sz, -sz),
				new Vertex(sz, -sz, -sz),
				new Vertex(-sz, -sz, -sz),
				new Vertex(-sz, sz, sz),
				new Vertex(sz, sz, sz),
				new Vertex(sz, -sz, sz),
				new Vertex(-sz, -sz, sz)
			];
			
			var vertex : Vertex;
			for each(vertex in v) {
				this.addVertex(vertex);
			}
			
			var uv0 :UVCoord = new UVCoord(0, 1);
			var uv1 :UVCoord = new UVCoord(0, 0);
			var uv2 :UVCoord = new UVCoord(1, 0);
			var uv3 :UVCoord = new UVCoord(1, 1);
						
			// top
			addTriangle(new Triangle(v[0], v[4], v[5], uv0, uv1, uv2) );
			addTriangle(new Triangle(v[0], v[5], v[1], uv0, uv2, uv3) );
			
			// bottom
			addTriangle(new Triangle(v[6], v[7], v[3], uv2, uv1, uv0) );
			addTriangle(new Triangle(v[6], v[3], v[2], uv2, uv0, uv3) );
			
			// left
			addTriangle(new Triangle(v[0], v[3], v[7], uv1, uv0, uv3) );
			addTriangle(new Triangle(v[0], v[7], v[4], uv1, uv3, uv2) );
			
			// right
			addTriangle(new Triangle(v[5], v[6], v[2], uv1, uv0, uv3) );
			addTriangle(new Triangle(v[5], v[2], v[1], uv1, uv3, uv2) );
			
			// front
			addTriangle(new Triangle(v[0], v[1], v[2], uv2, uv1, uv0) );
			addTriangle(new Triangle(v[0], v[2], v[3], uv2, uv0, uv3) );
			
			// back
			addTriangle(new Triangle(v[6], v[5], v[4], uv0, uv1, uv2) );
			addTriangle(new Triangle(v[6], v[4], v[7], uv0, uv2, uv3) );
		}	
	}
}