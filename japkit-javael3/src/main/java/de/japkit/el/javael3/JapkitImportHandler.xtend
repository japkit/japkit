package de.japkit.el.javael3

import java.util.Map

/**
 * Besides its usual functionality, this import handler resolves functions from the japkit value stack.
 */
class JapkitImportHandler extends ImportHandler{
	val Map<String, ? extends Object> valueStack
	
	new(Map<String, ? extends Object> valueStack){
		this.valueStack = valueStack;
	}
	
	override resolveStatic(String name) {
		if(valueStack.containsKey(name)){
			ValueStackPseudoClass
		} else {
			super.resolveStatic(name)
		}
	}
	
	static class ValueStackPseudoClass {
	}
	
}