package de.stefanocke.japkit.el.juel

import de.stefanocke.japkit.el.ElExtensions
import de.stefanocke.japkit.el.ValueStack
import java.lang.reflect.Method
import java.util.ArrayList
import java.util.WeakHashMap
import javax.el.FunctionMapper
import net.bytebuddy.ByteBuddy
import net.bytebuddy.dynamic.ClassLoadingStrategy
import net.bytebuddy.instrumentation.MethodDelegation
import net.bytebuddy.modifier.MethodArguments
import net.bytebuddy.modifier.Ownership
import net.bytebuddy.modifier.Visibility
import org.eclipse.xtend.lib.annotations.Data

@Data
class DynamicFunctionMapper extends FunctionMapper {
	val ValueStack contextMap
	static transient val methodCache = new WeakHashMap<Object, Method>()

	@Data
	static class Invoker {
		Object function

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

			//Java EL only allows static methods to be used as functions. Thus, we create a class with a static method on the fly.
			//This static method in turn calls our function from the values stack.
			val method = createStaticDelegateMethod(localName, invoker)
			methodCache.put(function, method)
			method
		}
	}

	def private Method createStaticDelegateMethod(String functionName, Invoker invoker) {
		val argTypes = new ArrayList<Class<?>>()
		argTypes.add(typeof(Object[]))

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

		invokerClass.getMethod("invoke", typeof(Object[]))
	}

}
