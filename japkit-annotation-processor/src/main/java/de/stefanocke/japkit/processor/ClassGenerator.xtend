package de.stefanocke.japkit.processor

import de.stefanocke.japkit.gen.GenAnnotationMirror
import de.stefanocke.japkit.gen.GenAnnotationValue
import de.stefanocke.japkit.gen.GenClass
import de.stefanocke.japkit.gen.GenElement
import de.stefanocke.japkit.gen.GenEnum
import de.stefanocke.japkit.gen.GenExtensions
import de.stefanocke.japkit.gen.GenInterface
import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.metaannotations.GenerateClass
import de.stefanocke.japkit.support.AnnotationExtensions
import de.stefanocke.japkit.support.ClassNameRule
import de.stefanocke.japkit.support.ElementsExtensions
import de.stefanocke.japkit.support.ExtensionRegistry
import de.stefanocke.japkit.support.GenerateClassContext
import de.stefanocke.japkit.support.MessageCollector
import de.stefanocke.japkit.support.ProcessingException
import de.stefanocke.japkit.support.RelatedTypes
import de.stefanocke.japkit.support.RuleFactory
import de.stefanocke.japkit.support.TypeElementNotFoundException
import de.stefanocke.japkit.support.TypesExtensions
import de.stefanocke.japkit.support.TypesRegistry
import de.stefanocke.japkit.support.el.ELSupport
import java.util.ArrayList
import java.util.HashMap
import java.util.List
import java.util.Map
import java.util.ServiceLoader
import java.util.Set
import javax.annotation.processing.ProcessingEnvironment
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.ElementKind
import javax.lang.model.element.Modifier
import javax.lang.model.element.TypeElement
import javax.lang.model.type.ArrayType
import javax.lang.model.type.DeclaredType
import javax.lang.model.type.TypeMirror
import javax.tools.Diagnostic.Kind
import javax.lang.model.element.ExecutableElement
import de.stefanocke.japkit.gen.GenExecutableElement

class ClassGenerator {
	val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val extension ProcessingEnvironment = ExtensionRegistry.get(ProcessingEnvironment)
	val extension MessageCollector = ExtensionRegistry.get(MessageCollector)
	val extension TypesRegistry = ExtensionRegistry.get(TypesRegistry)
	val extension TypesExtensions = ExtensionRegistry.get(TypesExtensions)
	val extension ELSupport elSupport = ExtensionRegistry.get(ELSupport)
	val extension GenerateClassContext = ExtensionRegistry.get(GenerateClassContext)
	val extension RuleFactory = ExtensionRegistry.get(RuleFactory)
	val extension RelatedTypes = ExtensionRegistry.get(RelatedTypes)
	val extension AnnotationExtensions = ExtensionRegistry.get(AnnotationExtensions)

	BehaviorDelegationGenerator behaviorDelegationGenerator = new BehaviorDelegationGenerator

	def Set<GenTypeElement> processGenClassAnnotation(TypeElement annotatedClass, AnnotationMirror triggerAnnotation) {

		val genClass = triggerAnnotation.metaAnnotation(GenerateClass)

		if(genClass == null) return emptySet;
		try {
			pushCurrentMetaAnnotation(genClass)

			//superclass with type args
			val generatedClass = createClass(annotatedClass, triggerAnnotation, genClass)
			setCurrentGeneratedClass(generatedClass)

			setSuperClassAndInterfaces(annotatedClass, generatedClass, triggerAnnotation, genClass)

			valueStack.putELVariables(generatedClass, triggerAnnotation, genClass)

			createShadowAnnotation(triggerAnnotation, annotatedClass, genClass, generatedClass)
			
			generatedClass.annotationMirrors = mapTypeAnnotations(annotatedClass, triggerAnnotation, genClass, 
				new ArrayList(generatedClass.annotationMirrors)
			)
			processMemberGenerators(annotatedClass, generatedClass, triggerAnnotation, genClass)

			val Set<GenTypeElement> generatedClasses = newHashSet
			generatedClasses.addAll(
				behaviorDelegationGenerator.createBehaviorDelegation(annotatedClass, triggerAnnotation, generatedClass,
					genClass));
			generatedClasses.add(generatedClass)

			generatedClasses.forEach[markAsGenerated(it, annotatedClass)]

			generatedClasses.forEach[addOrderAnnotations]
			
			generatedClasses.forEach[addParamNamesAnnotations]

			generatedClasses

		} finally {
			popCurrentMetaAnnotation
		}
	}
	
	def createShadowAnnotation(AnnotationMirror triggerAnnotation, TypeElement annotatedClass, AnnotationMirror genClass, GenTypeElement generatedClass) {
		try{
			val shallCreateShadowAnnotation = triggerAnnotation.valueOrMetaValue(annotatedClass, "createShadowAnnotation", Boolean, genClass)
			if(shallCreateShadowAnnotation){
				val shadowAnnotation = GenExtensions.copy(triggerAnnotation) => [it.setShadowIfAppropriate]
				
				valueStack.getVariablesForShadowAnnotation().forEach[name, value |
					shadowAnnotation.setValue(name, [t| 
						//TODO: Schicker. In extension o.ä verlagern
						new GenAnnotationValue(coerceAnnotationValue(value, t))
					])
				]
				
				generatedClass.addAnnotationMirror(shadowAnnotation)
			}
		
		} catch (RuntimeException re){
			reportError('''Error when creating shadow annotation:''', re, annotatedClass, triggerAnnotation, null)
		}
	}

	private def void addOrderAnnotations(Element e) {
		val enclosed = e.enclosedElements
		for (order : 0 ..< enclosed.size) {
			enclosed.get(order).addOrderAnnotation(order);
			enclosed.get(order).addOrderAnnotations()
		}
	}

	def dispatch void addOrderAnnotation(GenElement element, Integer order) {
		element.addAnnotationMirror(
			new GenAnnotationMirror(elementUtils.getTypeElement(ORDER_ANNOTATION_NAME).asType as DeclaredType) => [
				setValue("value", [new GenAnnotationValue(order)])
			]
		)
	}

	def dispatch void addOrderAnnotation(Element element, Integer integer) {
	}
	
	
	def dispatch void addParamNamesAnnotations(GenTypeElement typeElement) {
		typeElement.enclosedElements.forEach[it.addParamNamesAnnotations]
	}
	
	def dispatch void addParamNamesAnnotations(GenExecutableElement element) {
		if(!element.parameters.nullOrEmpty){
			element.addAnnotationMirror(
				new GenAnnotationMirror(elementUtils.getTypeElement(PARAM_NAMES_ANNOTATION_NAME).asType as DeclaredType) => [
					setValue("value", [new GenAnnotationValue(element.parameters.map[simpleName.toString].map[new GenAnnotationValue(it)].toList)])
				]
			)		
		}
	}
	def dispatch void addParamNamesAnnotations(Element element) {
		
	}

	def mapTypeAnnotations(TypeElement annotatedClass, AnnotationMirror am, AnnotationMirror genClassAnnotation, 
		List<GenAnnotationMirror> existingAnnotations) {
		val annotationMappings = am.valueOrMetaValue(annotatedClass, "annotationMappings", typeof(AnnotationMirror[]),
			genClassAnnotation).map[createAnnotationMappingRule(it)]
		mapAnnotations(annotatedClass, annotationMappings, existingAnnotations)
	}

	def GenTypeElement createClass(TypeElement annotatedClass, AnnotationMirror am, AnnotationMirror genClass) {
		val nameRule = new ClassNameRule(am, genClass)
		val genClassName = nameRule.generateClassName(annotatedClass)
		val genClassPackageName = nameRule.generatePackageName(annotatedClass.packageOf)

		val kind = am.valueOrMetaValue(annotatedClass, 'kind', ElementKind, genClass)

		val generatedClass = switch (kind) {
			case ElementKind.CLASS:
				new GenClass(genClassName, genClassPackageName)
			case ElementKind.ENUM:
				new GenEnum(genClassName, genClassPackageName)
			case ElementKind.INTERFACE:
				new GenInterface(genClassName, genClassPackageName)
			default:
				throw new ProcessingException('''Invalid element kind in GenClass annotation: «kind»''',
					annotatedClass)
		}

		//Register generated class as early as possible to allow error type resolution in other classes
		//TODO: Passing am here means the class is supposed to have a shadow annotation. That's not always the case.
		//Maybe , we should have a boolean flag createShadow in GenerateClass... 
		//If the dependencies shall be filtered by the filterAV value, the shadow annotation must be available. Or: the according AV value
		//is taken from the original annotation and not supposed to change in shadow annotation.
		registerGeneratedTypeElement(generatedClass, annotatedClass, am)

		val modifier = am.valueOrMetaValue("modifier", typeof(Modifier[]), genClass)

		generatedClass => [
			modifier.forEach[m|addModifier(m)]
		]

		generatedClass
	}

	def setSuperClassAndInterfaces(TypeElement annotatedClass, GenTypeElement generatedClass, AnnotationMirror am,
		AnnotationMirror genClass) {
		val superclass = relatedType(annotatedClass, generatedClass, am, "superclass", genClass, annotatedClass) as DeclaredType ->
			relatedTypes(annotatedClass, generatedClass, am, "superclassTypeArgs", genClass, annotatedClass) //interfaces with type args
		val interfaces = (1 .. 2).map[i|
			relatedType(annotatedClass, generatedClass, am, '''interface«i»''', genClass, annotatedClass) as DeclaredType ->
				relatedTypes(annotatedClass, generatedClass, am, '''interface«i»TypeArgs''', genClass, annotatedClass)].filter[
			key != null].toList

		generatedClass => [
			setSuperclass(superclass.key, superclass.value)
			interfaces.forEach[i|addInterface(i.key, i.value)]
		]
	}

	def processMemberGenerators(TypeElement annotatedClass, GenTypeElement generatedClass,
		AnnotationMirror triggerAnnotation, AnnotationMirror genClassMetaAnnotation) {

		val membersAnnotationRefs = triggerAnnotation.valueOrMetaValue(annotatedClass, "members",
			typeof(AnnotationMirror[]), genClassMetaAnnotation)

		//For each @Members annotation, we get the class referred by its AV "value". That class has the member annotations to process.
		membersAnnotationRefs.forEach [
			val typeWithMemberAnnotations = triggerAnnotation.valueOrMetaValue("value", TypeMirror, it)
			val activation = triggerAnnotation.elementMatchers("activation", it)
			if (activation.nullOrEmpty || activation.exists[matches(annotatedClass)]) {
				val te = if (!typeWithMemberAnnotations.isVoid)
						typeWithMemberAnnotations.asTypeElement
					else
						triggerAnnotation.annotationAsTypeElement
				printDiagnosticMessage(['''Process member annotations on «te»'''])
				te.annotationMirrors.forEach [
					processMemberGenerator(te, annotatedClass, generatedClass, triggerAnnotation, genClassMetaAnnotation)
				]

			}
		]

	}

	def void processMemberGenerator(
		AnnotationMirror memberGeneratorMetaAnnotation,
		TypeElement membersClass,
		TypeElement annotatedClass,
		GenTypeElement generatedClass,
		AnnotationMirror triggerAnnotation,
		AnnotationMirror genClassMetaAnnotation
	) {
		if (memberGeneratorMetaAnnotation.equals(genClassMetaAnnotation)) {
			return;
		}

		try {

			pushCurrentMetaAnnotation(memberGeneratorMetaAnnotation)

			val annoType = memberGeneratorMetaAnnotation.annotationType
			val annoTypeElement = annoType.asTypeElement
			val triggerAnnotationTypeElement = if (annoTypeElement.simpleName.contentEquals("List")) {

					//Support for multiple trigger annotations of same type, wrapped in a List annotation.
					val valueAvType = annoTypeElement.declaredMethods.findFirst[simpleName.contentEquals('value')]?.
						returnType
					if (valueAvType instanceof ArrayType) {
						(valueAvType as ArrayType).componentType.asTypeElement
					} else
						annoTypeElement

				} else {
					annoTypeElement
				}

			val triggerFqn = triggerAnnotationTypeElement.qualifiedName.toString
			val MemberGenerator mg = getMemberGenerator(triggerFqn);
			if (mg != null) {
				if (triggerAnnotationTypeElement != annoTypeElement) {
					val avList = memberGeneratorMetaAnnotation.value("value", typeof(AnnotationMirror[]))
					avList.forEach [
						try {
							mg.createMembers(membersClass, annotatedClass, generatedClass, triggerAnnotation, it,
								genClassMetaAnnotation)
						} catch (TypeElementNotFoundException e) {
							handleTypeElementNotFound(
								'''Error while member generator «mg.class» processes meta annotation «it»: «e.message»''',
								e.fqn, annotatedClass)
						}
					]
				} else {
					try {
						mg.createMembers(membersClass, annotatedClass, generatedClass, triggerAnnotation,
							memberGeneratorMetaAnnotation, genClassMetaAnnotation)
					} catch (TypeElementNotFoundException e) {
						handleTypeElementNotFound(
							'''Error while member generator «mg.class» processes meta annotation «memberGeneratorMetaAnnotation»: «e.
								message»''', e.fqn, annotatedClass)
					}

				}
			} else {
				if (!triggerFqn.startsWith("java.lang.")) {
					messager.printMessage(Kind.WARNING,
						'''No MemberGenerator found for meta annotation «triggerFqn».''', annotatedClass,
						triggerAnnotation)
				}
			}

		} finally {
			popCurrentMetaAnnotation
		}
	}

	val builtInMemberGenerators = #{
		PropertiesGenerator,
		ConstructorGenerator,
		MethodGenerator,
		FromTemplateGenerator,
		AnnotationGenerator
	}
	var Map<String, MemberGenerator> memberGenerators;

	def MemberGenerator getMemberGenerator(String metaAnnotationFqn) {
		if (memberGenerators == null) {
			memberGenerators = new HashMap();
			ServiceLoader.load(MemberGenerator, MemberGenerator.classLoader).forEach[
				memberGenerators.put(it.supportedMetaAnnotation, it)]
			builtInMemberGenerators.forEach[val generator = newInstance
				memberGenerators.put(generator.supportedMetaAnnotation, generator)]
			System.out.println(memberGenerators)
		}
		memberGenerators.get(metaAnnotationFqn)
	}
}
