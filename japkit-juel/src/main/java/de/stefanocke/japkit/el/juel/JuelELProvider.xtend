package de.stefanocke.japkit.el.juel

import de.odysseus.el.ExpressionFactoryImpl
import de.odysseus.el.util.SimpleContext
import de.stefanocke.japkit.el.ELProvider
import de.stefanocke.japkit.el.ELProviderException
import de.stefanocke.japkit.el.ElExtensionPropertiesAndMethods
import de.stefanocke.japkit.el.ElExtensions
import de.stefanocke.japkit.el.ValueStack
import de.stefanocke.japkit.services.ExtensionRegistry
import java.io.Writer
import java.lang.reflect.Method
import java.net.URL
import java.util.ArrayList
import java.util.WeakHashMap
import javax.el.CompositeELResolver
import javax.el.ELException
import javax.el.ExpressionFactory
import javax.el.FunctionMapper
import net.bytebuddy.ByteBuddy
import net.bytebuddy.dynamic.ClassLoadingStrategy
import net.bytebuddy.instrumentation.MethodDelegation
import net.bytebuddy.modifier.MethodArguments
import net.bytebuddy.modifier.Ownership
import net.bytebuddy.modifier.Visibility
import org.eclipse.xtend.lib.annotations.Data

class JuelELProvider implements ELProvider {
	val ExpressionFactory ef = ExtensionRegistry.get(ExpressionFactory, [|new ExpressionFactoryImpl])
	
	static class ElContext extends SimpleContext {
		val FunctionMapper functionMapper 

		/**
		 * A function mapper that allows to call functions on value stack.
		 */
		@Data
		static class DynamicFunctionMapper extends FunctionMapper {
			val ValueStack contextMap
			static transient val methodCache = new WeakHashMap<Object, Method>()
			
			
			static class Invoker{
				val Object function
				
				new(Object function){
					this.function=function
				}
				def Object invoke(Object ... params){
					ElExtensions.invoke(function, null, params)
				}
			}
			
			override Method resolveFunction(String prefix, String localName) {
				if(!prefix.nullOrEmpty) throw new UnsupportedOperationException('''Prefix «prefix» not supported.''')
				val function = contextMap.get(localName)
				if(function==null) return null
				
				methodCache.get(function) ?:{
				
					val invoker = new Invoker(function)
					
					//Java EL only allows static methods to be used as functions. Thus, we create a class with a static method on the fly.
					//This static method in turn calls our function from the values stack.
					val method = createStaticDelegateMethod(localName, invoker)
					val method1 = method
					methodCache.put(function, method1)
					method1					
				}
			}
			
			def private Method createStaticDelegateMethod(String functionName, Invoker invoker) {
				val argTypes = new ArrayList<Class<?>>()
				argTypes.add(typeof(Object[]))
										
				val invokerClass = new ByteBuddy()
					.subclass(Object)
					.name(class.package.name+".functioninvokers."+functionName.toFirstUpper)
					.defineMethod("invoke", Object, argTypes, 
						MethodArguments.VARARGS, 
						Ownership.STATIC,
						Visibility.PUBLIC
					)
					.intercept(MethodDelegation.to(invoker))
					.make()
					.load(class.classLoader, ClassLoadingStrategy.Default.WRAPPER)
					.getLoaded()
					
				
				
				val method = invokerClass.getMethod("invoke", typeof(Object[]))
				method
			}
		
		}
		
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
			val context = createElContext(contextMap, ElExtensions.extensions)
			eval(context, expr, expectedType)
		} catch (ELException e) {
			throw new ELProviderException(e)
		}
	}

	def private createElContext(ValueStack contextMap, ElExtensionPropertiesAndMethods elExtensions) {
		val resolver = new CompositeELResolver();
		
		//TODO: Ggf zu einem Resolver zusammenfassen.
		resolver.add(new MapRootResolver(contextMap))
		resolver.add(new ELResolver(ElExtensions.extensions, contextMap));
		
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
