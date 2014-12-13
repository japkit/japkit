package de.stefanocke.japkit.rules

import de.stefanocke.japkit.services.TypeElementNotFoundException
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import javax.lang.model.type.TypeMirror
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtext.xbase.lib.Functions.Function0
import org.eclipse.xtext.xbase.lib.Functions.Function1

@Data
abstract class AbstractNoArgFunctionRule<T> extends AbstractRule implements Function1<Object, T>,  Function0<T>{
	
	Class<T> type
	
	new(AnnotationMirror metaAnnotation, TypeElement metaElement, Class<T> type){
		super(metaAnnotation, metaElement)
		this.type = type ?: 
		(Class.forName(metaAnnotation.value("type", TypeMirror)?.asElement?.qualifiedName?.toString ?: "java.lang.Object") as Class<T>);
	}
	
	def eval(Object src){
		inRule[
			try{
				scope(src) [
					evalInternal()
				]
			
			} catch (TypeElementNotFoundException tenfe) {
				throw tenfe
			} catch (Exception e) {
				reportRuleError(e)				
				throw e
			}
			
		]
	}
	
	def protected abstract T evalInternal()
	
	override T apply(Object src) {
		eval(src)
	}
	
	override T apply() {
		eval(currentSrc)
	}
	
}