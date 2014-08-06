package de.stefanocke.japkit.support.el.juel

import de.odysseus.el.util.SimpleResolver
import javax.el.ELContext
import de.stefanocke.japkit.support.el.ElExtensionPropertiesAndMethods
import de.stefanocke.japkit.support.el.ELPropertyNotFoundException
import java.util.Map

class ELResolver extends SimpleResolver {

	val extension ElExtensionPropertiesAndMethods elExtensionPropertiesAndMethods
	
	val Map<String, Object> contextMap

	

	new(ElExtensionPropertiesAndMethods elExtensionPropertiesAndMethods, Map<String, ? extends Object> contextMap) {
		this.elExtensionPropertiesAndMethods = elExtensionPropertiesAndMethods
		this.contextMap = contextMap as Map<String, Object>
		
	}

	override getValue(ELContext context, Object base, Object property) {
		val closure = if(property instanceof String) findPropertyClosure(base, property) else null

		val rootProperties = contextMap

		if (closure != null) {
			context.setPropertyResolved(true);
			return closure.apply(rootProperties, base)
		}

		try{
			val getPropertyClosure = findGetPropertyClosure(base)
			if (getPropertyClosure != null) {
				context.setPropertyResolved(true)
				return getPropertyClosure.apply(rootProperties, base, property as String)
			}
		
		} catch(ELPropertyNotFoundException e){
			//Ignore and fall back to default resolver
			context.setPropertyResolved(false)
			//TODO: We have a different order here compared to Groovy. In Groovy the default resolver seems to be called first !?
		}

		super.getValue(context, base, property)
	}

	override invoke(ELContext context, Object base, Object method, Class[] paramTypes, Object[] params) {

		val rootProperties = contextMap
		
		val closure = if(method instanceof String) findMethodClosure(base, method) else null

		if (closure != null) {
			context.setPropertyResolved(true)
			return closure.apply(rootProperties, base, paramTypes, params)
		}

		super.invoke(context, base, method, paramTypes, params)
	}

}
