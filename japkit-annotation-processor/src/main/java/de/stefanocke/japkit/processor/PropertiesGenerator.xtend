package de.stefanocke.japkit.processor

import de.stefanocke.japkit.annotations.BeforeSet
import de.stefanocke.japkit.gen.CodeBody
import de.stefanocke.japkit.gen.GenEnumConstant
import de.stefanocke.japkit.gen.GenField
import de.stefanocke.japkit.gen.GenMethod
import de.stefanocke.japkit.gen.GenParameter
import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.metaannotations.Properties
import de.stefanocke.japkit.support.DelegateMethodsRule
import de.stefanocke.japkit.support.Property
import de.stefanocke.japkit.support.PropertyFilter
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.ElementKind
import javax.lang.model.element.Modifier
import javax.lang.model.element.TypeElement
import javax.lang.model.type.TypeMirror

class PropertiesGenerator extends MemberGeneratorSupport implements MemberGenerator {

	override createMembers(TypeElement membersClass, TypeElement annotatedClass, GenTypeElement generatedClass,
		AnnotationMirror annotation, AnnotationMirror propertiesAnnotation) {

		val activation = annotation.elementMatchers("activation", propertiesAnnotation)

		if (!activation.nullOrEmpty && !activation.exists[matches(annotatedClass)]) {
			return
		}

		
		
	

		//TODO:  Maybe its better to define a separate annotations for this.
		val createNameConstants = annotation.valueOrMetaValue("createNameConstants", Boolean, propertiesAnnotation)
		val createProperties = annotation.valueOrMetaValue("createProperties", Boolean, propertiesAnnotation)

		val generateSetters = annotation.valueOrMetaValue("generateSetters", Boolean, propertiesAnnotation)
		val settersExcludeRules = annotation.elementMatchers("settersExcludeRules", propertiesAnnotation)

		val generateGetters = annotation.valueOrMetaValue("generateGetters", Boolean, propertiesAnnotation)
		val gettersExcludeRules = annotation.elementMatchers("gettersExcludeRules", propertiesAnnotation)
		
		val excludePropertiesFromSuperclass = annotation.valueOrMetaValue("excludePropertiesFromSuperclass", Boolean, propertiesAnnotation)
		

		val fieldModifiers = annotation.valueOrMetaValue("fieldModifiers", typeof(Modifier[]), propertiesAnnotation)
		val getterModifiers = annotation.valueOrMetaValue("getterModifiers", typeof(Modifier[]),
			propertiesAnnotation)
		val setterModifiers = annotation.valueOrMetaValue("setterModifiers", typeof(Modifier[]),
			propertiesAnnotation)

		val ruleSource = annotation.valueOrMetaValue("ruleSource", Properties.RuleSource, propertiesAnnotation)
		val annotationMappingsForFields = annotation.annotationMappings("annotationMappings", propertiesAnnotation)
		val annotationMappingsForGetters = annotation.annotationMappings("annotationMappingsForGetters",
			propertiesAnnotation)

		
		val delegateMethodRules = annotation.valueOrMetaValue("delegateMethods", typeof(AnnotationMirror[]), propertiesAnnotation).map [
			new DelegateMethodsRule(it, null)
		]

		//TODO: Rule caching
		val templateRules = annotation.valueOrMetaValue("templates", typeof(TypeMirror[]), propertiesAnnotation).map [
			//zusätzlicher Aufruf von getTypeElement wegen Bug in UnresolvedAnnotationBinding.getElementValuePairs(): Arrays mit UnresolvedTypeBindings werden nicht resolved.
			val templateClass = getTypeElement(asTypeElement.qualifiedName)
			createTemplateRule(templateClass, null)
		]
		
		val overridesSource = 
			relatedType(annotatedClass, generatedClass, annotation, "overrides", propertiesAnnotation, annotatedClass)?.asTypeElement
			
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
				
				
				val genGetter = if (generateGetters && !gettersExcludeRules.exists[matches(ruleSourceElement)]) {
					val method = new GenMethod(p.getterName) => [
												modifiers = getterModifiers.toSet
												returnType = p.type
												annotationMirrors = mapAnnotations(ruleSourceElement, annotationMappingsForGetters)
												val b = getterBody(generatedClass, p)
												body = b
												comment = '''@return «srcComment»'''
											]
					generatedClass.add(method)
					method
					
				}
				val genSetter = if (generateSetters && !settersExcludeRules.exists[matches(ruleSourceElement)]) {
					val method = new GenMethod(p.setterName) => [
												modifiers = setterModifiers.toSet
												addParameter(new GenParameter(p.name, p.type))
												body = [
													'''
														«beforeSet(p, annotatedClass, annotation, propertiesAnnotation)»
														this.«p.name» = «p.name»;
													''']
												comment = '''@param «p.name» «srcComment»'''
											]
					generatedClass.add(method)
					method
				}
				
				val genProperty = new Property(genField, genGetter, genSetter)
				

				delegateMethodRules.forEach[apply(generatedClass, genProperty)]
			}
			
			templateRules.forEach[it.apply(annotatedClass, generatedClass, annotation, ruleSourceElement)]
			
		]

	}

	private def CodeBody getterBody(GenTypeElement generatedClass, Property p) {
		['''return «p.name»;''']
	}

	//TODO: Das ist sehr prototypisch! Ggf. mit immutabilty rules zu allgemeinen "GetSetModificationRules" o.ä. zusammenführen.
	def beforeSet(Property p, TypeElement annotatedClass, AnnotationMirror annotation,
		AnnotationMirror propertiesAnnotation) {
		val beforeMethods = annotatedClass.declaredMethods.filter [
			val am = annotationMirror(BeforeSet)
			val allowedType = am?.value(it, "propertyType", TypeMirror)
			am != null &&
				(p.type.isSubtype(allowedType) || (p.type.kind.primitive && p.type.kind.boxed.isSubtype(allowedType))) //&& allowedType.asTypeElement.qualifiedName.toString == OBJECT)  // TODO: Filter by field annotation ...am.value(it, "fieldAnnotation" )
		]

		//TODO: Map the parameters.
		'''
			«FOR m : beforeMethods»
				«(m.enclosingElement as TypeElement).qualifiedName».«m.simpleName»(«p.name»);  
			«ENDFOR»
		'''

	}

	override getSupportedMetaAnnotation() {
		Properties.name
	}

}
