package de.stefanocke.japkit.rules

import java.util.Map
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import javax.lang.model.type.TypeMirror
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtext.xbase.lib.Procedures.Procedure0

/**
 * A collection of functions and code fragments to be made available on value stack.
 */
@Data 
class LibraryRule extends AbstractRule implements Procedure0 {
	
	Map<String, Rule> functions 
	
	new(AnnotationMirror metaAnnotation, TypeElement metaElement) {
		super(metaAnnotation, metaElement)

		functions = newHashMap(); 		
			
		metaElement.enclosedElementsOrdered
				.map[simpleName.toString -> createFunctionRule]
				.filter[value!=null]
				.forEach[functions.put(key, value)]
				
		//annotations that shall be accessed by their simple names like this: typeElement.Entity
		metaAnnotation?.value("annotationImports", typeof(TypeMirror[]))?.forEach[functions.put(simpleName, createAnnotationFunction)]
	}
	
	def createAnnotationFunction(TypeMirror annotationType) {
		new AbstractNoArgFunctionRule<AnnotationMirror>(metaAnnotation, metaElement as TypeElement, AnnotationMirror) {

			override protected evalInternal() {
				_eLSupport.getCurrentSrcElement().annotationMirror(annotationType.qualifiedName)
			}

		}
	}
	
	/**Puts the functions on value stack. There is no new scope here since the functions are put into the scope of the parent rule. */
	override apply() {
		valueStack.putAll(functions)
	}
	
	
}