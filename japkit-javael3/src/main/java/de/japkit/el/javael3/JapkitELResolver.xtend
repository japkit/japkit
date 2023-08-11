package de.japkit.el.javael3

import de.japkit.el.ElExtensions
import de.japkit.el.javael3.JapkitImportHandler.ValueStackPseudoClass
import java.util.Map
import jakarta.el.ArrayELResolver
import jakarta.el.CompositeELResolver
import jakarta.el.ELClass
import jakarta.el.ELContext
import jakarta.el.ELResolver
import jakarta.el.ExpressionFactory
import jakarta.el.ListELResolver
import jakarta.el.MapELResolver
import jakarta.el.ResourceBundleELResolver
import jakarta.el.StaticFieldELResolver
import jakarta.el.ELException

/**
 * An ELResolver that resolves root properties from a map (japkit ValueStack) and that supports the extensions provided by de.japkit.el.ElExtensions.
 */
class JapkitELResolver extends ELResolver {

	val Map<String, Object> valueStack

	val ELResolver delegate
	
	static val defaultResolvers = new CompositeELResolver() => [
		add(new StaticFieldELResolver());
		add(new MapELResolver(true));
		add(new ResourceBundleELResolver());
		add(new ListELResolver(true));
		add(new ArrayELResolver(true));
		add(new de.japkit.el.javael3.patch.BeanELResolver(true));
	]

	new(ExpressionFactory factory, Map<String, ? extends Object> valueStack) {
		this.valueStack = valueStack as Map<String, Object>
		
		
		//MapRootResolver resolves root properties from value stack. The remaining resolvers are the default ones. 
		this.delegate = new CompositeELResolver() => [
			
			add(new MapRootResolver(valueStack));
			val streamELResolver = factory.streamELResolver
			if(streamELResolver !== null) add(streamELResolver);
			add(defaultResolvers);
		]

	}

	override getValue(ELContext context, Object base, Object property) {
		val rootProperties = valueStack

		val propertyValueFromExtensions = if (property instanceof String)
				ElExtensions.getPropertyFromExtensions(rootProperties, base, property)
			else
				null

		if (propertyValueFromExtensions?.key) {
			context.setPropertyResolved(true)
			return propertyValueFromExtensions.value
		}

		// TODO: We have a different order here compared to Groovy. In Groovy the default resolver seems to be called first !?
		val value =  delegate.getValue(context, base, property)
		
		if(base === null && !context.propertyResolved) {
			// For root properties, we retry  by prepending "src."			
			try{
				val src = getValue(context, null, "src");
				context.setPropertyResolved(false)
				return getValue(context, src, property)	
			} catch (ELException e) {
				if(e.cause !== null && !(e.cause instanceof ELException)){
					//Exception caused by bug (and not due to PropertyNotFound or similar) -> rethrow
					throw e.cause
				}
				
				//Do not rethrow. Give EL imports a chance (for example, default import for java.lang, used like #{Boolean.TRUE}). 
				context.setPropertyResolved(false)
			}
		}
			
		value
	}

	override invoke(ELContext context, Object base, Object method, Class<?>[] paramTypes, Object[] params) {

		val rootProperties = valueStack

		val methodResultFromExtensions = if (method instanceof String) {
				val baseToUse = if(base instanceof ELClass && (base as ELClass).klass == ValueStackPseudoClass ) null else base
				ElExtensions.invokeMethodFromExtensions(rootProperties, baseToUse, method, paramTypes, params)
			} else
				null

		if (methodResultFromExtensions?.key) {
			context.setPropertyResolved(true)
			return methodResultFromExtensions.value
		}

		// TODO: We have a different order here compared to Groovy. In Groovy the default resolver seems to be called first !?
		delegate.invoke(context, base, method, paramTypes, params)
	}
	
	override getCommonPropertyType(ELContext context, Object base) {
		//Not exact for the japkit extensions !?
		delegate.getCommonPropertyType(context, base)
	}
	
	override getFeatureDescriptors(ELContext context, Object base) {
		//Not exact for the japkit extensions !?
		delegate.getFeatureDescriptors(context, base)
	}
	
	override isReadOnly(ELContext context, Object base, Object property) {
		true
	}
	
	override getType(ELContext context, Object base, Object property) {
		//Not exact for the japkit extensions !?
		delegate.getType(context, base, property)
	}
	
	override setValue(ELContext context, Object base, Object property, Object value) {
		throw new UnsupportedOperationException("Not allowed to set values.")
	}

}
