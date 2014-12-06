package de.stefanocke.japkit.rules

import de.stefanocke.japkit.metaannotations.CodeFragment
import java.util.Map
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.TypeElement
import org.eclipse.xtext.xbase.lib.Procedures.Procedure0
import org.eclipse.xtend.lib.annotations.Data
import de.stefanocke.japkit.metaannotations.Function
import de.stefanocke.japkit.metaannotations.Matcher

/**
 * A collection of functions and code fragments to be made available on value stack.
 */
@Data 
class LibraryRule extends AbstractRule implements Procedure0 {
	
	Map<String, AbstractRule> functions
	
	new(AnnotationMirror metaAnnotation, TypeElement metaElement) {
		super(metaAnnotation, metaElement)
		
		functions = newHashMap( 		
			metaElement.enclosedElementsOrdered
				.map[createFunctionForMember]
				.filter[it!=null])
	}
	
	/**Puts the functions on value stack. There is no new scope here since the functions are put into the scope of the parent rule. */
	override apply() {
		valueStack.putAll(functions)
	}
	
	def private dispatch createFunctionForMember(TypeElement member){
		val codeFragmentAnnotation = member.annotationMirror(CodeFragment)
		val name = member.simpleName.toString 
		if(codeFragmentAnnotation!=null){
			return name -> new CodeFragmentRule(codeFragmentAnnotation, member)
		}
		val functionAnnotation =  member.annotationMirror(Function)
		if(functionAnnotation!=null){
			return name -> new FunctionRule(functionAnnotation, member)
		}
		val matcherAnnotation =  member.annotationMirror(Matcher)
		if(matcherAnnotation!=null){
			return name -> new ElementMatcher(matcherAnnotation)
		}
		
		null
	}
	
	def private dispatch createFunctionForMember(Element member){
		null
	}
	
}