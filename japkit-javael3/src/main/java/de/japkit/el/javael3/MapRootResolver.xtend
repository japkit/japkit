package de.japkit.el.javael3

import java.util.Map
import javax.el.ELContext
import javax.el.PropertyNotFoundException

/**
 * Resolves root properties (base === null) from a map. 
 */
class MapRootResolver extends javax.el.ELResolver {
	Map<String, ? extends Object> map;
	
	def private boolean isResolvable(Object base) {
		return base === null;
	}
	
	def private boolean isResolvable(ELContext context, Object base, Object property) {
		isResolvable(base) && property instanceof String;
	}
	
	override getCommonPropertyType(ELContext context, Object base) {
		return if(isResolvable(context)) String else null;
	}
	
	override getFeatureDescriptors(ELContext context, Object base) {
		return null;
	}
	
	override getType(ELContext context, Object base, Object property) {
		return if(isResolvable(context, base, property)) { 
			context.propertyResolved = true
			Object
		} else null;
	}
	
	override getValue(ELContext context, Object base, Object property) {
		if (isResolvable(context, base, property) && map.containsKey(property)) {
			context.propertyResolved = true
			return map.get(property);
		}
		return null;
	}
	
	override isReadOnly(ELContext context, Object base, Object property) {
		return true;
	}
	
	override setValue(ELContext context, Object base, Object property, Object value) {
		throw new UnsupportedOperationException("Not allowed to set root properties.")
	}	
	
	new(Map<String, ? extends Object> map){	
		this.map=map
	}
	
}