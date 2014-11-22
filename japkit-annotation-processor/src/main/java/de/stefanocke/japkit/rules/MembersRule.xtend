package de.stefanocke.japkit.rules

import de.stefanocke.japkit.model.GenElement
import de.stefanocke.japkit.model.GenTypeElement
import java.util.List
import javax.lang.model.element.AnnotationMirror
import org.eclipse.xtext.xbase.lib.Functions.Function1

/**supports generating members  from annotation values "fields", "methods", "constructors" and "innerClasses"*/
@Data
class MembersRule extends AbstractRule implements Function1<GenTypeElement, List<? extends GenElement>> {
	
	List<(GenTypeElement)=>List<? extends GenElement>> memberRules

	new(AnnotationMirror metaAnnotation) {
		super(metaAnnotation, null)
		_memberRules = newArrayList

		
		addMemberRules("innerClasses", [new InnerClassRule(it, null)])
		addMemberRules("fields", [new FieldRule(it, null)])
		addMemberRules("constructors", [new ConstructorRule(it, null)])
		addMemberRules("methods", [new MethodRule(it, null)])
		addMemberRules("templates", [new TemplateCallRule(it)])
		
	}

	def private addMemberRules(String avName,
		(AnnotationMirror)=>(GenTypeElement)=>List<? extends GenElement> ruleFactory) {
		_memberRules.addAll(metaAnnotation?.value(avName, typeof(AnnotationMirror[]))?.map(ruleFactory) ?: emptyList)

	}

	override apply(GenTypeElement generatedClass) {
		inRule[
			memberRules.map[it.apply(generatedClass)].flatten.toList		
		]
	}

}
