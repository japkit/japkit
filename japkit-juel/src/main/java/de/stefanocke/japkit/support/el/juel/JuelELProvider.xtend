package de.stefanocke.japkit.support.el.juel

import de.odysseus.el.util.SimpleContext
import de.stefanocke.japkit.support.el.ELProvider
import de.stefanocke.japkit.support.el.ElExtensionPropertiesAndMethods
import java.util.Map
import javax.el.ExpressionFactory
import de.stefanocke.japkit.support.el.juel.ELResolver
import de.stefanocke.japkit.support.ExtensionRegistry
import de.odysseus.el.ExpressionFactoryImpl
import javax.el.ELException
import de.stefanocke.japkit.support.el.ELProviderException
import java.io.Writer
import java.net.URL
import de.stefanocke.japkit.support.el.ElExtensions
import javax.el.CompositeELResolver

class JuelELProvider implements ELProvider {
	val ExpressionFactory ef = ExtensionRegistry.get(ExpressionFactory, [|new ExpressionFactoryImpl])
	
	

	override eval(Map contextMap, String expr, Class expectedType, String language) {
		try {
			val context = createElContext(contextMap, ElExtensions.extensions)
			eval(context, expr, expectedType)
		} catch (ELException e) {
			throw new ELProviderException(e)
		}
	}

	def private createElContext(Map<String, ? extends Object> contextMap, ElExtensionPropertiesAndMethods elExtensions) {
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
	
	override write(Writer writer, URL templateUrl, Map contextMap, String templateLanguage, Long templateLastModified) {
		throw new UnsupportedOperationException("Java EL Provider does not support templates.")
	}
	
}
