package de.japkit.el.javael3

import de.japkit.el.ELProvider
import de.japkit.el.ELProviderException
import de.japkit.el.ValueStack
import java.io.Writer
import java.net.URL
import javax.el.ELException
import javax.el.ELManager
import java.util.List

class JavaEL3Provider implements ELProvider {

	override eval(ValueStack vs, String expr, Class<?> expectedType, String language, List<String> importedClasses ) {
		val oldCCL = Thread.currentThread().contextClassLoader

		try {
			// ExpressionFactory.newInstance uses ContextClassLoader to load the ExpressionFactoryImpl
			// In case of Javac, the CCL does not contain the annotation processor class path but something like the compiler classpath (?) instead.
			// See also  https://community.oracle.com/thread/1184129 
			// So, we temporary set the CCL to something useful.
			Thread.currentThread().contextClassLoader = JavaEL3Provider.classLoader
			
			val ef = ELManager.expressionFactory
			
			val context = new JapkitELContext(ef, vs);
			for (importedClass : importedClasses) {
				context.importHandler.importClass(importedClass);
			}			
			expectedType.cast(ef.createValueExpression(context, expr, expectedType).getValue(context))
		} catch (ELException e) {
			if(e.cause !== null && !(e.cause instanceof ELException)){
				//Unwrap all Exceptions that are likely not caused by human mistakes.
				//This will lead to better error reporting (stack trace)
				throw e.cause
			}
			throw new ELProviderException(e)
		} finally {
			Thread.currentThread().contextClassLoader = oldCCL
		}
	}

	override getSupportedLanguages() {
		#["JavaEL"]
	}

	override getSupportedTemplateLanguages() {
		emptyList
	}

	override write(Writer writer, URL templateUrl, ValueStack vs, String templateLanguage, Long templateLastModified) {
		throw new UnsupportedOperationException("Java EL Provider does not support templates.")
	}

}
