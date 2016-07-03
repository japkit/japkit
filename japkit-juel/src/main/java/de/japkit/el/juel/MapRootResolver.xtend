package de.japkit.el.juel

import de.odysseus.el.util.RootPropertyResolver
import java.util.Map

class MapRootResolver extends RootPropertyResolver {
	//TODO: ValueStack?
	Map<String, ? extends Object> map;
	
	override getProperty(String property) {
		map.get(property)
	}
	
	override isProperty(String property) {
		map.containsKey(property);
	}
	
	override setProperty(String property, Object value) {
		throw new UnsupportedOperationException("Not allowed to set root properties.")
	}
	
	override properties() {
		throw new UnsupportedOperationException("Not allowed to iterate over root properties.")
	}
	
	new(Map<String, ? extends Object> map){
		
		this.map=map
	}
	
}