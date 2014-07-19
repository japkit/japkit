package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenField
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.VariableElement
import javax.lang.model.type.TypeMirror
import de.stefanocke.japkit.gen.GenParameter
import java.util.Collections

@Data
class FieldRule extends MemberRuleSupport<VariableElement, GenField> {
	extension JavaBeansExtensions = ExtensionRegistry.get(JavaBeansExtensions)
	
	CodeRule initCodeRule
	
	(Element)=>TypeMirror typeRule
	
	new(AnnotationMirror metaAnnotation, VariableElement template) {
		super(metaAnnotation, template)
		_initCodeRule = new CodeRule(metaAnnotation,"init")
		
		_typeRule = createTypeRule
		
		addGetterRule
		addSetterRule
		
	}
	
	def addGetterRule() {
		if (metaAnnotation?.value("generateGetter", boolean) == Boolean.TRUE) {
			val mr = new MethodRule(
				ru.createActivationRule(metaAnnotation, "getter"),
				null,
				[f | (f as GenField).getterName],
				ru.createModifiersRule(metaAnnotation, null, "getter"),
				null,
				null,
				[m , f | ['''return «f.simpleName»;''']],
				[f | f.asType]
			)
			dependentMemberRules.add(
				[g, e|mr.apply(g, e)]
			)
		}
	}
	
	def addSetterRule() {
		if (metaAnnotation?.value("generateSetter", boolean) == Boolean.TRUE) {
			val mr = new MethodRule(
				ru.createActivationRule(metaAnnotation, "setter"),
				null,
				[f | (f as GenField).setterName],
				ru.createModifiersRule(metaAnnotation, null, "setter"),
				null,
				[f | Collections.singletonList(new GenParameter(f.simpleName, f.asType))],
				[m , f | ['''this.«f.simpleName» = «f.simpleName»;''']],
				null
			)
			dependentMemberRules.add(
				[g, e|mr.apply(g, e)]
			)
		}
	}
	
	protected def (Element)=>TypeMirror createTypeRule() {
		ru.createTypeRule(metaAnnotation, template?.asType, null)
	}
	
	override protected createMember(Element ruleSrcElement, String name) {
		new GenField(name, null)
	}
	
	protected override applyRulesAfterCreation(GenField member, Element ruleSrcElement) {
		super.applyRulesAfterCreation(member, ruleSrcElement)
		member.type = typeRule.apply(ruleSrcElement)
	}

}
