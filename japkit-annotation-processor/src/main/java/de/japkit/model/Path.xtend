package de.japkit.model

import java.util.ArrayList
import java.util.List
import org.eclipse.xtend.lib.annotations.Data

/** Path for nested annotations / annotation values or for bean properties. */
@Data
class Path {
	List<Segment> segments
	
	@Data
	static class Segment{
		//Name of the annotation value
		String name
	
		//position of the annotation within the annotation value (in case it is an array)
		Integer index
		
		override toString(){
			'''«name»«IF index !=null»[«index»]«ENDIF»'''.toString
		}
	}
	
	override toString(){
		segments.map[toString].join('.')
	}
	
	def Path append(Segment segment){
		val newSegments = new ArrayList(segments)
		newSegments.add(segment)
		new Path(newSegments)
	}
}