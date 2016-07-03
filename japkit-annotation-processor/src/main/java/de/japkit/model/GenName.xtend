package de.japkit.model

import javax.lang.model.element.Name
import org.eclipse.xtend.lib.annotations.Data

@Data
class GenName implements Name {
	CharSequence charSequence
	
	override contentEquals(CharSequence cs) {
		charSequence.toString == cs.toString
	}
	
	override charAt(int index) {
		charSequence.charAt(index)
	}
	
	override length() {
		charSequence.length
	}
	
	override subSequence(int start, int end) {
		charSequence.subSequence(start, end)
	}

	override toString(){
		charSequence.toString
	}	
}