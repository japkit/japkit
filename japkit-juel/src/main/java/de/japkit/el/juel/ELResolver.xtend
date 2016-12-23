package de.japkit.el.juel

import de.japkit.el.ElExtensions
import de.odysseus.el.util.SimpleResolver
import java.util.Map
import javax.el.ELContext

class ELResolver extends SimpleResolver {

	val Map<String, Object> contextMap

	new(Map<String, ? extends Object> contextMap) {
		this.contextMap = contextMap as Map<String, Object>

	}

	override getValue(ELContext context, Object base, Object property) {
		val rootProperties = contextMap

		val propertyValueFromExtensions = if(property instanceof String) ElExtensions.
				getPropertyFromExtensions(rootProperties, base, property) else null

		if (propertyValueFromExtensions?.key) {
			context.setPropertyResolved(true)
			return propertyValueFromExtensions.value
		}

		// TODO: We have a different order here compared to Groovy. In Groovy the default resolver seems to be called first !?
		return super.getValue(context, base, property)
	}

	override invoke(ELContext context, Object base, Object method, Class<?>[] paramTypes, Object[] params) {

		val rootProperties = contextMap

		val methodResultFromExtensions = if (method instanceof String)
				ElExtensions.invokeMethodFromExtensions(rootProperties, base, method, paramTypes, params)
			else
				null

		if (methodResultFromExtensions?.key) {
			context.setPropertyResolved(true)
			return methodResultFromExtensions.value
		}

		// TODO: We have a different order here compared to Groovy. In Groovy the default resolver seems to be called first !?
		super.invoke(context, base, method, paramTypes, params)
	}

}
