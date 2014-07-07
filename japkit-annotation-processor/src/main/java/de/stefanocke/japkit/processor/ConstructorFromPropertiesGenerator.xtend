package de.stefanocke.japkit.processor

import de.stefanocke.japkit.gen.CodeBody
import de.stefanocke.japkit.gen.GenConstructor
import de.stefanocke.japkit.gen.GenDeclaredType
import de.stefanocke.japkit.gen.GenMethod
import de.stefanocke.japkit.gen.GenParameter
import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.metaannotations.ConstructorFromProperties
import de.stefanocke.japkit.support.ImmutabiltyRules
import de.stefanocke.japkit.support.JavadocUtil
import de.stefanocke.japkit.support.Property
import de.stefanocke.japkit.support.PropertyFilter
import java.util.ArrayList
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.Modifier
import javax.lang.model.element.TypeElement

class ConstructorFromPropertiesGenerator extends MemberGeneratorSupport implements MemberGenerator {

	override createMembers(TypeElement membersClass, TypeElement annotatedClass, GenTypeElement generatedClass, AnnotationMirror annotation,
		AnnotationMirror constructorAnnotation) {
			
		val activation = annotation.elementMatchers("activation", constructorAnnotation)
		
		if(!activation.nullOrEmpty && !activation.exists[matches(annotatedClass)]){
			return
		}	

		val callSetters = annotation.valueOrMetaValue("callSetters", Boolean, constructorAnnotation);
		val copyConstructor = annotation.valueOrMetaValue("copyConstructor", Boolean, constructorAnnotation);
		val copyConstructorFieldAccess = annotation.valueOrMetaValue("copyConstructorFieldAccess", Boolean,
			constructorAnnotation);
		val cloneMethodCallingCopyConstructor = annotation.valueOrMetaValue("cloneMethodCallingCopyConstructor", Boolean,
			constructorAnnotation);

		val mods = annotation.valueOrMetaValue("modifiers", typeof(Modifier[]), constructorAnnotation);
		val createInitMethod = annotation.valueOrMetaValue("createInitMethod", Boolean, constructorAnnotation);
		val initMethodName = annotation.valueOrMetaValue("initMethodName", String, constructorAnnotation);
		val superConstructorMatchers = annotation.elementMatchers("superConstructors", constructorAnnotation);
		val annotationMappings = annotation.annotationMappings("annotationMappings", constructorAnnotation);

		val propertyFilter = new PropertyFilter(annotation, constructorAnnotation)
		val immutabilityRules = new ImmutabiltyRules(annotation, constructorAnnotation)

		val fromFields = true //TODO: If this shall be configurable for some reason, TENFE must be handled below.

		//It's important to get a current copy of the properties here. Otherwise we get a live list that will also include later changes.	
		val propertiesToSet = new ArrayList(propertyFilter.getFilteredProperties(generatedClass).toList)
			
			
		val paramsForProperties = propertiesToSet.map[new GenParameter(name, type)].toList

		val superConstructorCandidates = handleTypeElementNotFound(null, 
			'''Could not determine superclass constructors for «generatedClass.qualifiedName». No constructors will be generated.''',
			annotatedClass)[
						
			generatedClass.superclass?.asTypeElement?.declaredConstructors?.filter[c| c.isVisibleFromSubclass(generatedClass) && superConstructorMatchers.exists[matches(c)]]	
		] ?: emptyList

		val superConstructors = if (copyConstructor) {
				if (generatedClass.superclass.isJavaLangObject) {

					//Use default constructor if superclass is Object.
					superConstructorCandidates
				} else {
					superConstructorCandidates.filter[isCopyConstructor]
				}
			} else {
				superConstructorCandidates.filter[c|!c.isCopyConstructor && superConstructorMatchers.exists[matches(c)]]
			}

		superConstructors.forEach [ sc |
			val params = newArrayList()
			
			//list of super constructor params
			//key is original name. value is the new GenParam to be used in the subclass constructor
			val superParams = new ArrayList(sc.parameters.map[simpleName.toString->new GenParameter(simpleName, asType)].toList)
			
			//Avoid name clashes between the params
			superParams.filter[sp|paramsForProperties.exists[simpleName.toString == sp.key]].forEach[
				value.simpleName = '''super«key.toFirstUpper»''']
			params.addAll(superParams.map[value])
			params.addAll(paramsForProperties)
			val constructorParams = if (copyConstructor)
					newArrayList(new GenParameter("other", new GenDeclaredType(generatedClass)))
				else
					params.toList
			
			//TODO: Das brauchen wir sicher an anderer Stelle nochmal so oder ähnlich... 		
			val (Property)=>CharSequence assignmentRhs = if (copyConstructor) {
					if(copyConstructorFieldAccess){
						['''other.«field.simpleName»''']				
					} else {
						['''other.«getterName»()''']	
					}
				} else {
					[simpleName]

				}
				
			val assignments = codeForAssignments(generatedClass, propertiesToSet, callSetters, assignmentRhs, immutabilityRules)
				
			val c = new GenConstructor() => [
				modifiers = mods.toSet
				parameters = constructorParams
				body = [
					'''
						«IF copyConstructor && sc.copyConstructor»
							super(other);
						«ELSE»
							super(«FOR p : superParams.map[value] SEPARATOR ', '»«p.simpleName»«ENDFOR»);
						«ENDIF»
						«IF createInitMethod»
							«initMethodName»(«FOR p : constructorParams SEPARATOR ', '»«p.simpleName»«ENDFOR»);
						«ELSE»
							«assignments.code(it)»
						«ENDIF»
					'''
				]
				val superParamsDoc = JavadocUtil.getParams(sc.docComment)
				comment = '''
				
				«FOR sp : superParams»
				@param «sp.value.simpleName» «superParamsDoc.get(sp.key)»
				«ENDFOR»
				«FOR p : propertiesToSet»
				@param «p.name» «p.fieldOrGetter.docComment?.toString?.trim»
				«ENDFOR»
				'''
			]
			var existingConstructor = generatedClass.declaredConstructors.findFirst[isOverrideEquivalent(c)]
			if (existingConstructor == null) {

				generatedClass.add(c)
				existingConstructor = c

				if (createInitMethod) {
					val initMethod = new GenMethod(initMethodName) => [
						addModifier(Modifier.PRIVATE)
						parameters = constructorParams.toList
						body = assignments
					]

					if (!generatedClass.declaredMethods.exists[isOverrideEquivalent(initMethod)]) {
						generatedClass.add(initMethod)
					} else {
						//TODO: Check, if parameter names match. Otherwise, it is likely an error.
					}
				}

			}
			//TODO: Falls es schon einen gleichen Konstruktor gibt, sollen dann die Annotationen hinzugefügt werden?
			c.annotationMirrors = mapAnnotations(sc, annotationMappings)
			
			if(copyConstructor && cloneMethodCallingCopyConstructor){
				val cloneMethod = new GenMethod("clone") => [
					visibility = Modifier.PUBLIC
					returnType = OBJECT
					body=['''return new «staticTypeRef(new GenDeclaredType(generatedClass))»(this);''']
				]
					
				generatedClass.add(cloneMethod)
				generatedClass.addInterface(declaredType(Cloneable.name))
			}
		]
	}

	def isCopyConstructor(extension ExecutableElement constructor) {
		parameters.size == 1 && parameters.get(0).asType == constructor.enclosingElement.asType
	}

	def CodeBody codeForAssignments(GenTypeElement generatedClass, Iterable<? extends Property> propertiesToSet, Boolean callSetters,
		(Property)=>CharSequence rhs, ImmutabiltyRules immutabiltyRules) {
			
		val wrapped = newHashMap()
		
		//Hässlich. Alles nur, damit die rules nicht erst im emmitter ausgewertet werden und dort erst die TNFE fliegt...
		propertiesToSet.forEach[p | wrapped.put(p, immutabiltyRules.wrapAssignment(generatedClass, p, rhs.apply(p)))]
		 
		
		['''
			«FOR p : propertiesToSet»
				«IF callSetters && p.setter != null»
					«p.setterName»(«rhs.apply(p)»);
				«ELSE»
					this.«p.field.simpleName» = «wrapped.get(p).code(it)»;
				«ENDIF»
			«ENDFOR»
		''']
	}

	override getSupportedMetaAnnotation() {
		ConstructorFromProperties.name
	}

}
