package de.japkit.rules

import de.japkit.el.ElVariableError
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.TypeElement
import org.eclipse.xtend.lib.annotations.Data

@Data
class ELVariableRule extends AbstractRule implements IParameterlessFunctionRule<Object> {
	 
	String name
	boolean ifEmpty
	()=>Object exprOrFunctionCallRule
	Class<?> beanClass
	boolean createBeanInstance

	new(AnnotationMirror elVarAnnotation, Element metaElement) {
		super(elVarAnnotation, null)
		val nameFromAV = elVarAnnotation.value("name", String);
		name = if(nameFromAV.nullOrEmpty) metaElement?.simpleName?.toString?.toFirstLower else nameFromAV
		if(name.nullOrEmpty){
			throwRuleCreationException("Either the name annotation value must be set or the @Var annotation must be used at a member of a class.");
		}
		
		ifEmpty = elVarAnnotation.value("ifEmpty", Boolean);
		
		val nullable = elVarAnnotation.value("nullable", Boolean) ?: false;
		
		exprOrFunctionCallRule = createExpressionOrFunctionCallAndFilterRule(metaAnnotation, metaElement,
			"expr", "fun", "lang", "filter", "filterFun", "collect", "collectFun", "toSet", "groupBy", "groupByFun", "type", null,
			[|currentSrc], nullable, "unique"
		)
		
		
		var beanType = elVarAnnotation.value("bean", TypeElement)		
		createBeanInstance = beanType != null;	
		beanType = beanType?: elVarAnnotation.value("beanClass", TypeElement)	
			
		beanClass = try{	
			if(beanType != null) ELVariableRule.classLoader.loadClass(beanType.qualifiedName.toString) else null;		
		} catch (ClassNotFoundException cnfe) {
			throwRuleCreationException("The class could not be loaded from annotation processor's classpath:" + cnfe.message);	
			null
		}
		
	}

	def void putELVariable() {
		
		val exisitingValue = valueStack.get(name)
		if(ifEmpty && exisitingValue!==null && !exisitingValue.emptyVar) return
		
		val value = handleException([| new ElVariableError(name) as Object], null)[
			eval(currentSrc)
		]
		valueStack.put(name, value)
			
	}
	
	def Object eval(Object src) {
		inRule[
			if (beanClass != null) {
				if(createBeanInstance) beanClass.newInstance else beanClass;
			} else
				exprOrFunctionCallRule.apply
		]
	}
	
	override apply(Object arg0) {
		throw new UnsupportedOperationException("The src for a VariableRule cannot be changed. ")
	}
	
	//If a variable is referred to as function, it's value is retrieved from the stack.
	//TODO: We could use the MetaElement as key, to have an "FQN" here.
	override apply() {
		valueStack.get(name)
	}


	
}
