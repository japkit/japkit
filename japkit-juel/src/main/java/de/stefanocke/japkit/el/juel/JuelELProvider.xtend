package de.stefanocke.japkit.el.juel

import de.odysseus.el.ExpressionFactoryImpl
import de.odysseus.el.util.SimpleContext
import de.stefanocke.japkit.rules.ExtensionRegistry
import de.stefanocke.japkit.el.ELProvider
import de.stefanocke.japkit.el.ELProviderException
import de.stefanocke.japkit.el.ElExtensionPropertiesAndMethods
import de.stefanocke.japkit.el.ElExtensions
import de.stefanocke.japkit.el.ValueStack
import java.io.Writer
import java.net.URL
import javax.el.CompositeELResolver
import javax.el.ELException
import javax.el.ExpressionFactory

class JuelELProvider implements ELProvider {
	val ExpressionFactory ef = ExtensionRegistry.get(ExpressionFactory, [|new ExpressionFactoryImpl])
	
	

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
		
		val context = new SimpleContext(resolver)


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
