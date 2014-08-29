package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenElement
import de.stefanocke.japkit.gen.GenTypeElement
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import org.eclipse.xtext.xbase.lib.Functions.Function1

/**supports generating members  from annotation values "fields", "methods", "constructors" and "innerClasses"*/
@Data
class MembersRule extends AbstractRule implements Function1<GenTypeElement, List<? extends GenElement>> {
	val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val extension RuleUtils = ExtensionRegistry.get(RuleUtils)
	val extension RuleFactory = ExtensionRegistry.get(RuleFactory)

	
	List<(GenTypeElement)=>List<? extends GenElement>> memberRules

	new(AnnotationMirror metaAnnotation) {
		super(metaAnnotation, null)
		_memberRules = newArrayList

		
		addMemberRules("innerClasses", [new InnerClassRule(it, null)])
		addMemberRules("fields", [new FieldRule(it, null)])
		addMemberRules("constructors", [new ConstructorRule(it, null)])
		addMemberRules("methods", [new MethodRule(it, null)])
		addMemberRules("templates", [createTemplateCallRule(it)])
		

	}
	
	def (GenTypeElement)=>List<? extends GenElement> createTemplateCallRule(AnnotationMirror templateCallAnnotation) {
		val activationRule = createActivationRule(templateCallAnnotation, null)
		val scopeRule = createScopeRule(templateCallAnnotation, null, null)
		val templateRule = createTemplateRule(templateCallAnnotation.value("value", TypeElement));
		[genClass |
			if (!activationRule.apply) {
				emptyList
			} else {
				scopeRule.apply[
					templateRule.apply(genClass)		
				].flatten.toList
			}]

	}

	def private addMemberRules(String avName,
		(AnnotationMirror)=>(GenTypeElement)=>List<? extends GenElement> ruleFactory) {
		_memberRules.addAll(metaAnnotation?.value(avName, typeof(AnnotationMirror[]))?.map(ruleFactory) ?: emptyList)

	}

	override apply(GenTypeElement generatedClass) {
		memberRules.map[it.apply(generatedClass)].flatten.toList
	}

}
