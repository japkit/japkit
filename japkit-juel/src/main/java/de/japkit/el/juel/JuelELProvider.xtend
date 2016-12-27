package de.japkit.el.juel

import de.japkit.el.ELProvider
import de.japkit.el.ELProviderException
import de.japkit.el.ValueStack
import de.japkit.el.juel.JuelELProvider.ElContext
import de.japkit.services.ExtensionRegistry
import de.odysseus.el.util.SimpleContext
import java.io.Writer
import java.net.URL
import javax.el.CompositeELResolver
import javax.el.ELContext
import javax.el.ELException
import javax.el.ExpressionFactory
import javax.el.FunctionMapper
import javax.el.PropertyNotFoundException

class JuelELProvider implements ELProvider {
	val ExpressionFactory ef = ExtensionRegistry.get(ExpressionFactory, [| 
		val oldCCL =  Thread.currentThread().contextClassLoader
		try {
			//ExpressionFactory.newInstance	uses ContextClassLoader to load the ExpressionFactoryImpl
			//In case of Javac, the CCL does not contain the annotation processor class path but something like the compiler classpath (?) instead.
			//See also  https://community.oracle.com/thread/1184129 
			//So, we temporary set the CCL to something useful.
			Thread.currentThread().contextClassLoader = JuelELProvider.classLoader
			ExpressionFactory.newInstance		
		} finally { 
			Thread.currentThread().contextClassLoader = oldCCL		
		}
	])
	
	static class ElContext extends SimpleContext {
		val FunctionMapper functionMapper 
		
		new(javax.el.ELResolver resolver, ValueStack contextMap) {
			super(resolver)			
			functionMapper = new DynamicFunctionMapper(contextMap)
		}
				
		override getFunctionMapper() {
			functionMapper
		}
	}

	override eval(ValueStack contextMap, String expr, Class<?> expectedType, String language) {
		try {
			val context = createElContext(contextMap)
			eval(context, expr, expectedType)
		} catch (ELException e) {
			throw new ELProviderException(e)
		}
	}

	def private createElContext(ValueStack contextMap) {
		val resolver = new CompositeELResolver() {
			
			override getValue(ELContext context, Object base, Object property) {
				try {
					return super.getValue(context, base, property)
				} catch (PropertyNotFoundException pnfe) {
					if(base!=null) throw pnfe;
					//The RootPropertyResolver of JUEL throws PNFE if it cannot find a root property.
					//we retry in this case by prepending "src."
					val src = getValue(context, null, "src");
					context.setPropertyResolved(false)
					return getValue(context, src, property)
				}
			}
			
		};
		
		//TODO: Ggf zu einem Resolver zusammenfassen.
		resolver.add(new MapRootResolver(contextMap))
		resolver.add(new ELResolver(contextMap));
		
		val context = new ElContext(resolver, contextMap)

		//Force the use of the same context. For example, when the ELResolver internally calls getExpressionFactory(context)
		//Otherwise we run into some class loading issues..
		context.putContext(ExpressionFactory, ef)
		context

	}

	def private <T> T eval(SimpleContext context, String expr, Class<T> expectedType) {
		expectedType.cast(ef.createValueExpression(context, expr, expectedType).getValue(context))
	}
	
	override getSupportedLanguages() {
		#["JavaEL"]
	}
	
	override getSupportedTemplateLanguages() {
		emptyList
	}
	
	override write(Writer writer, URL templateUrl, ValueStack contextMap, String templateLanguage, Long templateLastModified) {
		throw new UnsupportedOperationException("Java EL Provider does not support templates.")
	}
	
}
