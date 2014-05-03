package de.stefanocke.japkit.support.el.juel

import de.odysseus.el.util.SimpleResolver
import javax.el.ELContext
import de.stefanocke.japkit.support.el.ElExtensionPropertiesAndMethods
import de.stefanocke.japkit.support.el.ELPropertyNotFoundException

class ELResolver extends SimpleResolver {

	val extension ElExtensionPropertiesAndMethods elExtensionPropertiesAndMethods

	

	new(ElExtensionPropertiesAndMethods elExtensionPropertiesAndMethods) {
		this.elExtensionPropertiesAndMethods = elExtensionPropertiesAndMethods
	}

	override getValue(ELContext context, Object base, Object property) {
		val closure = if(property instanceof String) findPropertyClosure(base, property as String) else null

		//Etwas ineffizient, jedesmal eine map zu bauen...
		val rootProperties = getRootPropertyResolver().properties.toInvertedMap[getRootPropertyResolver().getProperty(it)]

		if (closure != null) {
			context.setPropertyResolved(true)
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

		//Etwas ineffizient, jedesmal eine map zu bauen...
		val rootProperties = getRootPropertyResolver().properties.toInvertedMap[getRootPropertyResolver().getProperty(it)]
		
		val closure = if(method instanceof String) findMethodClosure(base, method as String) else null

		if (closure != null) {
			context.setPropertyResolved(true)
			return closure.apply(rootProperties, base, paramTypes, params)
		}

		super.invoke(context, base, method, paramTypes, params)
	}

}
