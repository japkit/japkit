package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenElement
import de.stefanocke.japkit.gen.GenTypeElement
import java.util.List
import javax.lang.model.element.AnnotationMirror
import org.eclipse.xtext.xbase.lib.Functions.Function1

/**supports generating members  from annotation values "fields", "methods", "constructors" and "innerClasses"*/
@Data
class MembersRule implements Function1<GenTypeElement, List<? extends GenElement>> {
	val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)

	AnnotationMirror metaAnnotation
	List<(GenTypeElement)=>List<? extends GenElement>> memberRules

	new(AnnotationMirror metaAnnotation) {
		_metaAnnotation = metaAnnotation
		_memberRules = newArrayList

		
		addMemberRules("innerClasses", [new InnerClassRule(it, null)])
		addMemberRules("fields", [new FieldRule(it, null)])
		addMemberRules("constructors", [new ConstructorRule(it, null)])
		addMemberRules("methods", [new MethodRule(it, null)])
		

	}

	def private addMemberRules(String avName,
		(AnnotationMirror)=>(GenTypeElement)=>List<? extends GenElement> ruleFactory) {
		_memberRules.addAll(metaAnnotation?.value(avName, typeof(AnnotationMirror[]))?.map(ruleFactory) ?: emptyList)

	}

	override apply(GenTypeElement generatedClass) {
		memberRules.map[it.apply(generatedClass)].flatten.toList
	}

}
