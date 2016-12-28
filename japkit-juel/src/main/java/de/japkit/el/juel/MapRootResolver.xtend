package de.japkit.el.juel

import java.util.Map
import javax.el.ELContext
import javax.el.PropertyNotFoundException

/**
 * Resolves root properties (base == null) from a map. 
 */
class MapRootResolver extends javax.el.ELResolver {
	Map<String, ? extends Object> map;
	
	def private boolean isResolvable(Object base) {
		return base == null;
	}
	
	def private boolean resolve(ELContext context, Object base, Object property) {
		context.setPropertyResolved(isResolvable(base) && property instanceof String);
		return context.isPropertyResolved();
	}
	
	override getCommonPropertyType(ELContext context, Object base) {
		return if(isResolvable(context)) String else null;
	}
	
	override getFeatureDescriptors(ELContext context, Object base) {
		return null;
	}
	
	override getType(ELContext context, Object base, Object property) {
		return if(resolve(context, base, property)) Object else null;
	}
	
	override getValue(ELContext context, Object base, Object property) {
		if (resolve(context, base, property)) {
			if (!map.containsKey(property)) {
				throw new PropertyNotFoundException("Cannot find property " + property);
			}
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