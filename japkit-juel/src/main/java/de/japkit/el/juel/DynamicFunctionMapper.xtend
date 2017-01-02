package de.japkit.el.juel

import de.japkit.el.ElExtensions
import java.lang.reflect.Method
import java.util.ArrayList
import java.util.Map
import java.util.WeakHashMap
import javax.el.FunctionMapper
import net.bytebuddy.ByteBuddy
import net.bytebuddy.dynamic.ClassLoadingStrategy
import net.bytebuddy.instrumentation.MethodDelegation
import net.bytebuddy.modifier.MethodArguments
import net.bytebuddy.modifier.Ownership
import net.bytebuddy.modifier.Visibility
import org.eclipse.xtend.lib.annotations.Data

/**
 * A function mapper that allows to call functions on value stack.
 */
@Data
class DynamicFunctionMapper extends FunctionMapper {
	val Map<String, ? extends Object> contextMap
	static transient val methodCache = new WeakHashMap<Object, Method>()

	static class Invoker {
		val Object function

		new(Object function) {
			this.function = function
		}

		def Object invoke(Object ... params) {
			ElExtensions.invoke(function, null, params)
		}
	}

	override Method resolveFunction(String prefix, String localName) {
		if(!prefix.nullOrEmpty) throw new UnsupportedOperationException('''Prefix «prefix» not supported.''')
		val function = contextMap.get(localName)
		if(function == null) return null

		methodCache.get(function) ?: {

			val invoker = new Invoker(function)

			// Java EL only allows static methods to be used as functions. Thus, we create a class with a static method on the fly.
			// This static method in turn calls our function from the values stack.
			val method = createStaticDelegateMethod(localName, invoker)
			val method1 = method
			methodCache.put(function, method1)
			method1
		}
	}

	def private Method createStaticDelegateMethod(String functionName, Invoker invoker) {
		val argTypes = new ArrayList<Class<?>>()
		argTypes.add(typeof(Object[]))

		// TODO: This probably causes a perm gen space memory leak since the classes
		// won't get unloaded, an they are re-generated every round of annotation processing :(	
		// On the other hand, the Javadoc of ClassLoadingStrategy.Default.WRAPPER sounds as if
		// the classes would be properly garbage collected. TODO: check if that works as expected. 
		val invokerClass = new ByteBuddy().subclass(Object).name(
			class.package.name + ".functioninvokers." + functionName.toFirstUpper).defineMethod(
			"invoke",
			Object,
			argTypes,
			MethodArguments.VARARGS,
			Ownership.STATIC,
			Visibility.PUBLIC
		).intercept(MethodDelegation.to(invoker)).make().load(class.classLoader, ClassLoadingStrategy.Default.WRAPPER).
			getLoaded()

		val method = invokerClass.getMethod("invoke", typeof(Object[]))
		method
	}

}
