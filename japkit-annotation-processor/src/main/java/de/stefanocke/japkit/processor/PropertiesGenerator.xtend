package de.stefanocke.japkit.processor

import de.stefanocke.japkit.gen.GenEnumConstant
import de.stefanocke.japkit.gen.GenField
import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.metaannotations.Properties
import de.stefanocke.japkit.support.DelegateMethodsRule
import de.stefanocke.japkit.support.ExtensionRegistry
import de.stefanocke.japkit.support.GetterSetterRules
import de.stefanocke.japkit.support.Property
import de.stefanocke.japkit.support.PropertyFilter
import de.stefanocke.japkit.support.el.ELSupport
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.ElementKind
import javax.lang.model.element.Modifier
import javax.lang.model.element.TypeElement
import javax.lang.model.type.TypeMirror
import javax.lang.model.element.ExecutableElement

class PropertiesGenerator extends MemberGeneratorSupport implements MemberGenerator {
	val protected extension ELSupport elSupport = ExtensionRegistry.get(ELSupport)
	protected extension GetterSetterRules = ExtensionRegistry.get(GetterSetterRules)

	override createMembers(TypeElement membersClass, TypeElement annotatedClass, GenTypeElement generatedClass,
		AnnotationMirror annotation, AnnotationMirror propertiesAnnotation) {

		val activation = annotation.elementMatchers("activation", propertiesAnnotation)

		if (!activation.nullOrEmpty && !activation.exists[matches(annotatedClass)]) {
			return
		}

		//TODO:  Maybe its better to define a separate annotations for this.
		val createNameConstants = annotation.valueOrMetaValue("createNameConstants", Boolean, propertiesAnnotation)
		val createProperties = annotation.valueOrMetaValue("createProperties", Boolean, propertiesAnnotation)


		
		val excludePropertiesFromSuperclass = annotation.valueOrMetaValue("excludePropertiesFromSuperclass", Boolean, propertiesAnnotation)
		

		val fieldModifiers = annotation.valueOrMetaValue("fieldModifiers", typeof(Modifier[]), propertiesAnnotation)


		val ruleSource = annotation.valueOrMetaValue("ruleSource", Properties.RuleSource, propertiesAnnotation)
		val annotationMappingsForFields = annotation.annotationMappings("annotationMappings", propertiesAnnotation)

		val getterRule = createGetterRuleFromGetterAV(propertiesAnnotation)
		val setterRule = createSetterRuleFromSetterAV(propertiesAnnotation)
		
		val delegateMethodRules = annotation.valueOrMetaValue("delegateMethods", typeof(AnnotationMirror[]), propertiesAnnotation).map [
			new DelegateMethodsRule(it, null)
		]

		//TODO: Rule caching
		val templateRules = annotation.valueOrMetaValue("templates", typeof(TypeMirror[]), propertiesAnnotation).map [
			//zusätzlicher Aufruf von getTypeElement wegen Bug in UnresolvedAnnotationBinding.getElementValuePairs(): Arrays mit UnresolvedTypeBindings werden nicht resolved.
			val templateClass = getTypeElement(asTypeElement.qualifiedName)
			createTemplateRule(templateClass, null)
		]
		
		val overridesSource = resolveType(propertiesAnnotation, "overrides")?.asTypeElement
			
		val overridesMatcher = annotation.valueOrMetaValue("overridesMatcher", AnnotationMirror, propertiesAnnotation).createElementMatcher
		
		val overrideElementsByName = (overridesSource?.enclosedElements?.filter[overridesMatcher.matches(it)] ?: emptyList).toMap[simpleName.toString]
		
		//TODO: Rule caching
		val propertyFilter = new PropertyFilter(annotation, propertiesAnnotation)

		var properties =  propertyFilter.getFilteredProperties(annotatedClass, generatedClass)
		
		
		val (Property)=>boolean propertiesFromSuperClassFilter = if(excludePropertiesFromSuperclass){
			//TODO: Make "fromFields" configurable
			val propertiesFromSuperclass = generatedClass.superclass?.asTypeElement.properties(Object.name, false).map[name].toSet ?: emptySet;
			[!propertiesFromSuperclass.contains(name)]
		} else { 
			[true]
		}

		val propertiesToGenerate = properties.filter(propertiesFromSuperClassFilter)
		
		val propertiesToGenerateNames = propertiesToGenerate.map[name].toSet
		
		//Validate that an according property exists for each override element 
		overrideElementsByName.forEach [ oeName, oe |
			if (!propertiesToGenerateNames.contains(oeName)) {
				messageCollector.reportError(
					'''No property exists with name «oeName». Properties from source class are: «propertiesToGenerateNames»''',
					overrideElementsByName.get(oeName), null, null
				)
			}
		]
		
		
		propertiesToGenerate.forEach [ p |
			val ruleSourceElement = p.getSourceElement(ruleSource)
			
			scope(ruleSourceElement)[
			
			val overrideElement = overrideElementsByName.get(p.name)
			
			//TODO: Javadoc
			if (createNameConstants) {
				if (generatedClass.kind == ElementKind.ENUM) {
					generatedClass.add(
						new GenEnumConstant(p.name.toUpperCase, null) => [
							annotationMirrors = mapAnnotations(ruleSourceElement, annotationMappingsForFields)
						])
				} else {
					generatedClass.add(
						new GenField(p.name.toUpperCase, getTypeElement(String.name).asType) => [
							modifiers = #{Modifier.PUBLIC, Modifier.STATIC, Modifier.FINAL}
							constantExpr = ['''"«p.name»"''']
						])
				}

			}
			if (createProperties) {
			
				//TODO: In case of getter, extract the @return
				val srcComment = p.fieldOrGetter.docComment?.toString?.trim
				
				val genField = new GenField(p.name, p.type) => [
						modifiers = fieldModifiers.toSet
						
						annotationMirrors = overrideAnnotations(overrideElement, mapAnnotations(ruleSourceElement, annotationMappingsForFields))
												
						comment = srcComment
					//TODO: Make configurable whether just to use an @see here.
					]
				generatedClass.add(genField)
								
				val genGetter = getterRule?.apply(generatedClass)?.head as ExecutableElement
							
				val genSetter = setterRule?.apply(generatedClass)?.head as ExecutableElement
				
				val genProperty = new Property(genField, genGetter, genSetter)
				
				scope(genProperty) [
					delegateMethodRules.forEach[apply(generatedClass)]
				]
			}
			
			templateRules.forEach[it.apply(generatedClass)]
			
			]
			
		]

	}



	override getSupportedMetaAnnotation() {
		Properties.name
	}
	
	
	override createMemberRule(TypeElement membersClass, AnnotationMirror metaAnnotationToBeProcessed) {
		throw new UnsupportedOperationException("Not used here")
	}

}
