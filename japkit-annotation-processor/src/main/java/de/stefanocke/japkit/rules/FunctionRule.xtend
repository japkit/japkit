package de.stefanocke.japkit.rules

import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import org.eclipse.xtext.xbase.lib.Functions.Function1
import org.eclipse.xtext.xbase.lib.Functions.Function0
import org.eclipse.xtend.lib.annotations.Data
import javax.lang.model.type.TypeMirror
import de.stefanocke.japkit.services.TypeElementNotFoundException

@Data
class FunctionRule extends AbstractRule implements Function1<Object, Object>,  Function0<Object>{
	
	String expr
	String lang
	Class<?> type
	
	new(AnnotationMirror metaAnnotation, TypeElement metaElement) {
		super(metaAnnotation, metaElement)
		expr = metaAnnotation.value("expr", String);
		lang = metaAnnotation.value("lang", String);
		type = Class.forName(metaAnnotation.value("type", TypeMirror)?.asElement?.qualifiedName?.toString ?: "java.lang.Object");
	}
	
	def eval(Object src){
		inRule[
			try{
			scope(src) [
				eval(expr, lang, type)
			]
			
			} catch (TypeElementNotFoundException tenfe) {
				throw tenfe
			} catch (Exception e) {
				reportRuleError(e.message)				
				throw e
			}
			
		]
	}
	
	override apply(Object src) {
		eval(src)
	}
	
	override apply() {
		eval(currentSrc)
	}
	
}