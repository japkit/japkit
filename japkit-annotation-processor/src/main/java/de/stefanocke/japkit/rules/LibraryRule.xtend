package de.stefanocke.japkit.rules

import de.stefanocke.japkit.metaannotations.CodeFragment
import de.stefanocke.japkit.metaannotations.Function
import de.stefanocke.japkit.metaannotations.Matcher
import java.util.Map
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.TypeElement
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtext.xbase.lib.Procedures.Procedure0
import javax.lang.model.type.TypeMirror
import de.stefanocke.japkit.metaannotations.TypeQuery
import java.util.List
import java.lang.annotation.Annotation

/**
 * A collection of functions and code fragments to be made available on value stack.
 */
@Data 
class LibraryRule extends AbstractRule implements Procedure0 {
	
	Map<String, AbstractRule> functions 
	
	new(AnnotationMirror metaAnnotation, TypeElement metaElement) {
		super(metaAnnotation, metaElement)

		functions = newHashMap(); 		
			
		metaElement.enclosedElementsOrdered
				.map[simpleName.toString -> createFunctionForMember]
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
	
	static val List<Pair<Class<? extends Annotation>, (AnnotationMirror, TypeElement)=>AbstractRule>> 
		functionFactories = #[
			CodeFragment->[am, e | new CodeFragmentRule(am, e)],
			Function->[am, e | new FunctionRule(am, e)],
			Matcher->[am, e | new ElementMatcher(am)],
			TypeQuery->[am, e | new TypeQueryRule(am)]
		]
	
	def private dispatch createFunctionForMember(TypeElement member){
		val factory = functionFactories.map[member.annotationMirror(key)->value].findFirst[key!=null]
		factory?.value?.apply(factory.key, member)
	}
	
	def private dispatch createFunctionForMember(Element member){
		null
	}
	
}