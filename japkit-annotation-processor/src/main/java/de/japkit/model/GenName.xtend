package de.japkit.model

import javax.lang.model.element.Name
import org.eclipse.xtend.lib.annotations.Data

@Data
class GenName implements Name {
	String name
	
	override contentEquals(CharSequence cs) {
		name == cs.toString
	}
	
	override charAt(int index) {
		name.charAt(index)
	}
	
	override length() {
		name.length
	}
	
	override subSequence(int start, int end) {
		name.subSequence(start, end)
	}

	override toString(){
		name
	}	
}