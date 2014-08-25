package de.stefanocke.japkit.processor

import de.stefanocke.japkit.annotations.Behavior
import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.gen.JavaEmitter
import de.stefanocke.japkit.metaannotations.Clazz
import de.stefanocke.japkit.support.AnnotationExtensions
import de.stefanocke.japkit.support.ElementsExtensions
import de.stefanocke.japkit.support.ExtensionRegistry
import de.stefanocke.japkit.support.GenerateClassContext
import de.stefanocke.japkit.support.MessageCollector
import de.stefanocke.japkit.support.RuleFactory
import de.stefanocke.japkit.support.TypeElementNotFoundException
import de.stefanocke.japkit.support.TypeResolver
import de.stefanocke.japkit.support.TypesExtensions
import de.stefanocke.japkit.support.TypesRegistry
import de.stefanocke.japkit.support.el.ELSupport
import java.util.HashMap
import java.util.HashSet
import java.util.List
import java.util.Map
import java.util.Set
import javax.annotation.processing.AbstractProcessor
import javax.annotation.processing.ProcessingEnvironment
import javax.annotation.processing.RoundEnvironment
import javax.annotation.processing.SupportedSourceVersion
import javax.lang.model.SourceVersion
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import javax.lang.model.util.Elements
import javax.lang.model.util.Types
import javax.tools.Diagnostic.Kind

import static extension de.stefanocke.japkit.util.MoreCollectionExtensions.*

@SupportedSourceVersion(SourceVersion.RELEASE_6)
/**
 * Processes all annotations annotated with @GenerateClass.
 */
class JapkitProcessor extends AbstractProcessor {

	extension ProcessingEnvironment processingEnv
	protected Elements elementUtils
	protected Types typeUtils

	extension ElementsExtensions elementsExtensions
	extension TypesExtensions typesExtensions

	extension AnnotationExtensions annotationExtensions
	extension TypeResolver typesResolver
	extension MessageCollector messageCollector
	extension GenerateClassContext generateClassContext
	extension TypesRegistry typesRegistry
	extension RuleFactory ruleFactory
	extension ELSupport elSupport

	//annotated classes that have to be re-considered in a later round
	val Map<String, TypeElementNotFoundException> deferredClasses = new HashMap

	override init(ProcessingEnvironment processingEnv) {

		super.init(processingEnv)
		this.processingEnv = processingEnv;
		this.elementUtils = processingEnv.elementUtils
		this.typeUtils = processingEnv.typeUtils
		ExtensionRegistry.cleanup //Make sure old stuff is removed.
		ExtensionRegistry.register(ProcessingEnvironment, processingEnv)
		ExtensionRegistry.register(Types, typeUtils)
		ExtensionRegistry.register(Elements, elementUtils)

		this.elementsExtensions = ExtensionRegistry.get(ElementsExtensions);
		this.typesExtensions = ExtensionRegistry.get(TypesExtensions);

		//this.formatter = new EclipseFormatter(messager)
		annotationExtensions = ExtensionRegistry.get(AnnotationExtensions)
		messageCollector = ExtensionRegistry.get(MessageCollector)
		messageCollector.diagnosticLogging = "true".equals(processingEnv.options.get("diagnosticMessages"))

		generateClassContext = ExtensionRegistry.get(GenerateClassContext)
		typesResolver = ExtensionRegistry.get(TypeResolver)
		typesRegistry = ExtensionRegistry.get(TypesRegistry)
		ruleFactory = ExtensionRegistry.get(RuleFactory)
		elSupport = ExtensionRegistry.get(ELSupport)

	}

	override finalize() {

		//Argh.
		ExtensionRegistry.cleanup
	}

	override getSupportedAnnotationTypes() {
		val set = newHashSet('''«Behavior.package.name».*''')
		val annotationsOption = processingEnv.options.get("annotations")
		if (annotationsOption != null) {
			annotationsOption.split(",").forEach[set.add(it)]
		} else {
			messager.printMessage(Kind.ERROR, "The processor option 'annotations' is not set. ");
		}
		set
	}

	override getSupportedOptions() {
		#{"annotations", "diagnosticMessages", "templateDir"}
	}

	override process(Set<? extends TypeElement> annotations, extension RoundEnvironment roundEnv) {
		elementsExtensions.clearCaches

		val startTime = System.currentTimeMillis

		printDiagnosticMessage(
			[
				'''New Round. «roundEnv.rootElements» Annotations: «annotations» errorRaised «roundEnv.errorRaised» processingOver: «roundEnv.
					processingOver»'''])

		if (roundEnv.processingOver) {
			typesRegistry.persist

			//Do not generate anything in last round but just report all errors that have been collected so far.
			printAllErrors()
			return false
		}

		//Key the annotated class. Value is Set of  generated type elements for it.
		val Map<TypeElement, Set<GenTypeElement>> generatedTypeElementsInCurrentRound = newHashMap

		val writtenTypeElementsInCurrentRound = newHashSet

		//The annotated classes that have been defered by previous rounds. During the round, some of them will be removed and processed.
		//But also, new ones might be added
		val annotatedClassesToDefer = new HashSet(deferredClasses.keySet.map[getTypeElement].toSet)
		deferredClasses.clear

		val classesToProcessUnfiltered = roundEnv.rootElements.typeElements.toList
		val classesToProcess = new HashSet(classesToProcessUnfiltered)

		//Search for trigger annotations
		val annotatedClassesAndTriggerAnnotations = classesToProcess.toInvertedMap[triggerAnnotations].filter[ac, t|
			!t.empty]

		//Register all classes with trigger annotations, including the ones with shadow annotations
		annotatedClassesAndTriggerAnnotations.forEach[ac, t|typesRegistry.registerAnnotatedClass(ac, t)]

		//Retain all classes with non-shadow trigger annotations
		classesToProcess.retainAll(annotatedClassesAndTriggerAnnotations.filter[ac, t|t.exists[!value]].keySet)

		printDiagnosticMessage(['''Annotated classes in root TypeElements: «classesToProcess»'''])

		//For incremental build... If the compiler re-compiles a generated class, we should also re-generate it to spread the changes.
		val annotatedClassesForUncommitedGenClasses = classesToProcessUnfiltered.filter[!committed].map[
			annotatedClassForGenClassOnDisk].filter[it != null].toSet

		printDiagnosticMessage(
			['''Annotated classes for uncommited gen classes: «annotatedClassesForUncommitedGenClasses»'''])
		classesToProcess.addAll(annotatedClassesForUncommitedGenClasses)

		val writtenTypeElementsInCurrentLoop = newHashSet
		do {
			writtenTypeElementsInCurrentLoop.clear

			//Add all deferred classes without unresolved dependencies
			val annotatedClassesFromPreviousRoundWithNoDependencies = annotatedClassesToDefer.filter[
				getTypesOnWhichThatAnnotatedClassDependsOn(qualifiedName).empty]
			printDiagnosticMessage(
				[
					'''Annotated classes from previous rounds / iterations with no type dependencies: «annotatedClassesFromPreviousRoundWithNoDependencies»'''])
			classesToProcess.addAll(annotatedClassesFromPreviousRoundWithNoDependencies)

			processClassesAndWriteTypeElements(classesToProcess, false, generatedTypeElementsInCurrentRound,
				annotatedClassesToDefer, writtenTypeElementsInCurrentLoop)

			//Still no progress. Check for cyclic dependencies and try to resolve them
			processClassesWithCycles(generatedTypeElementsInCurrentRound, annotatedClassesToDefer,
				writtenTypeElementsInCurrentLoop)

			//We had no progress up to now, since no source file has been written successfully.
			//Thus, write the classes with permanent type errors now.
			writeClassesWithPermanentTypeErrors(generatedTypeElementsInCurrentRound, annotatedClassesToDefer,
				writtenTypeElementsInCurrentLoop, false)

			writtenTypeElementsInCurrentRound.addAll(writtenTypeElementsInCurrentLoop)

			classesToProcess.clear

		} while (!writtenTypeElementsInCurrentLoop.empty)

		//if there is still no progress, consider the classes with dependencies to unknown types again now.
		if (writtenTypeElementsInCurrentRound.empty) {

			//deferred classes with unknown dependencies 
			val annotatedClassesWithUnknownDependencies = new HashSet(
				annotatedClassesToDefer.filter[dependsOnUnknownTypes(qualifiedName)].toSet)
			printDiagnosticMessage(
				[
					'''Consider Annotated classes from previous rounds with unknown type dependencies: «annotatedClassesWithUnknownDependencies»'''])

			processClassesAndWriteTypeElements(annotatedClassesWithUnknownDependencies.toSet, false,
				generatedTypeElementsInCurrentRound, annotatedClassesToDefer, writtenTypeElementsInCurrentRound)

			processClassesWithCycles(generatedTypeElementsInCurrentRound, annotatedClassesToDefer,
				writtenTypeElementsInCurrentRound)

			writeClassesWithPermanentTypeErrors(generatedTypeElementsInCurrentRound, annotatedClassesToDefer,
				writtenTypeElementsInCurrentRound, false)

		}

		//if there is still no progress, write the classes with dependencies to unknown types, even if those dependencies are not resolved.
		if (writtenTypeElementsInCurrentRound.empty) {
			writeClassesWithPermanentTypeErrors(generatedTypeElementsInCurrentRound, annotatedClassesToDefer,
				writtenTypeElementsInCurrentRound, true)
		}

		//defer remaining annotated classes to next round
		annotatedClassesToDefer.forEach[deferredClasses.put(qualifiedName.toString, null)]

		typesRegistry.cleanUpGenTypesAtEndOfRound //They refer types of current round and thus should not be used in next round, but re-generated. TODO: Really?

		printDiagnosticMessage[
			'''
				Deferred classes: «deferredClasses.keySet.join(", ")»
				Dependencies: 
				«deferredClasses.keySet.map['''«it» depends on «getTypesOnWhichThatAnnotatedClassDependsOn»'''].join('\n')»
			''']

		printDiagnosticMessage['''Round Time (ms): «System.currentTimeMillis - startTime»''']

		false
	}

	def writeClassesWithPermanentTypeErrors(
		Map<TypeElement, Set<GenTypeElement>> generatedTypeElementsInCurrentRound,
		HashSet<TypeElement> annotatedClassesToDefer,
		HashSet<GenTypeElement> writtenTypeElementsInCurrentRound,
		boolean alsoWriteClassesThatDependOnUnknownTypes
	) {
		if (writtenTypeElementsInCurrentRound.empty && !annotatedClassesToDefer.empty) {

			//Those annotated classes have no dependency to other annotated classes. Thus, they have permanent type errors, that cannot be resolved by generating other classes. 
			//Note: classes from cycles that have been resolved in the previous step are included here, since 
			//the dependencies to the other annotated classes of the cycle have been removed.
			val annotatedClassesWithUnresolvableTypeErrors = annotatedClassesToDefer.filter [
				!dependsOnOtherAnnotatedClasses(qualifiedName.toString) &&
					(alsoWriteClassesThatDependOnUnknownTypes || !dependsOnUnknownTypes(qualifiedName.toString))
			].toSet

			if (!annotatedClassesWithUnresolvableTypeErrors.empty) {
				messageCollector.printDiagnosticMessage[
					'''
						Write classes with permanent type errors: 
						«annotatedClassesWithUnresolvableTypeErrors.map[
							'''«it» depends on: «unresolvableTypesOnWhichThatAnnotatedClassDependsOn(qualifiedName.toString, true)»'''].
							join('\n')»
					''']

				val stillToGenerate = annotatedClassesWithUnresolvableTypeErrors.filter[
					generatedTypeElementsInCurrentRound.get(it).nullOrEmpty]

				stillToGenerate.forEach [
					processAnnotatedClass.forEach[gen, org|
						generatedTypeElementsInCurrentRound.getOrCreateSet(org).add(gen)]
				]

				//Write the classes with permanent type errors, so we can continue (in next round) with classes that depend on them.
				typesRegistry.throwTypeElementNotFoundExceptionWhenResolvingSimpleTypeNames = false

				generatedTypeElementsInCurrentRound.filter[annotatedClass, genTypeElements|
					annotatedClassesWithUnresolvableTypeErrors.contains(annotatedClass)].forEach [ annotatedClass, genTypeElements |
					genTypeElements.forEach [
						writeSourceFileAndCommitTypeElement(it, annotatedClass, writtenTypeElementsInCurrentRound)
						annotatedClassesToDefer.remove(annotatedClass)
					]
				]

				typesRegistry.throwTypeElementNotFoundExceptionWhenResolvingSimpleTypeNames = true

			}

		}
	}

	def processClassesWithCycles(Map<TypeElement, Set<GenTypeElement>> generatedTypeElementsInCurrentRound,
		HashSet<TypeElement> annotatedClassesToDefer, HashSet<GenTypeElement> writtenTypeElementsInCurrentRound) {
		if (writtenTypeElementsInCurrentRound.empty && !annotatedClassesToDefer.empty) {

			val cyclesToProcess = findCyclesInAnnotatedClasses(annotatedClassesToDefer)

			if (!cyclesToProcess.empty) {
				printDiagnosticMessage['''Try to resolve cyclic dependencies: «cyclesToProcess»''']

				cyclesToProcess.forEach [
					processClassesAndWriteTypeElements(it, true, generatedTypeElementsInCurrentRound,
						annotatedClassesToDefer, writtenTypeElementsInCurrentRound)
				]
			}

		}
	}

	/**
	 * Finds cycles in annotated classes. Only those cycles are returned, that do not depend on / wait for other annotated classes and 
	 * that do not have dependencies to unknown types
	 */
	def findCyclesInAnnotatedClasses(Set<TypeElement> annotatedClasses) {
		val byFqn = annotatedClasses.toMap[qualifiedName.toString]
		typesRegistry.findCyclesInAnnotatedClasses(byFqn.keySet).filter[
			!dependOnOtherAnnotatedClasses && !dependOnUnknownTypes].map[map[byFqn.get(it)].toSet]
	}

	def processClassesAndWriteTypeElements(
		Set<TypeElement> classesToProcess,
		boolean isCycle,
		Map<TypeElement, Set<GenTypeElement>> generatedTypeElementsInCurrentRound,
		Set<TypeElement> annotatedClassesToDefer,
		Set<GenTypeElement> writtenTypeElementsInCurrentRound
	) {

		try {
			if (isCycle) {
				typesRegistry.startUsingUncomittedGenTypes
			}

			val generatedTypeElements = newHashMap

			val repeats = if(isCycle) classesToProcess.size else 1 //TODO: Jeder Zyklus muss so lange wiederholt werden, bis sich keine Änderungen mehr ergeben

			(1 .. repeats).forEach [
				generatedTypeElements.clear
				classesToProcess.forEach [ ac |
					val generated = ac.processAnnotatedClass
					generatedTypeElements.putAll(generated)
				]
			]

			generatedTypeElements.forEach [ gen, original |
				generatedTypeElementsInCurrentRound.getOrCreateSet(original).add(gen)
			]

			val finishedAnnotatedClasses = new HashSet(classesToProcess)

			//annotated classes that require related types that are subject to code generation, yet, will be deferred to next round
			//This is one the one hand for incremental build in eclipse, for situations where we get no TypeElementNotFoundExceptions,
			//since the type is already there (but may change due to code generation).
			//On the other hand, this is for classes that simply do not yet exist, since they have to be generated yet.		
			if (!isCycle) {
				annotatedClassesToDefer.removeAll(classesToProcess)
				annotatedClassesToDefer.addAll(
					classesToProcess.filter [
						hasUnresolvedTypeDependencies(qualifiedName.toString, emptySet)
					])

				//Wake up all classes that have generic dependencies on trigger annotations
				annotatedClassesToDefer.addAll(
					classesToProcess.filter [ ac |
						//TODO: Hier wirklich nochmal classesToProcess?
						classesToProcess.exists [ otherAc |
							typesRegistry.
								hasGenericDependencyOnTriggerShadowAnnotation(ac, otherAc.triggerAnnotations.map[key])
						]
					]
				)
			} else {

				//If a cycle is resolved and there are type errors, all classes in the cycle are deferred.
				val annotatedClassesInCycle = classesToProcess.map[qualifiedName.toString].toSet
				if (classesToProcess.exists[
					hasUnresolvedTypeDependencies(qualifiedName.toString, annotatedClassesInCycle)]) {
					annotatedClassesToDefer.addAll(classesToProcess)
				} else {
					annotatedClassesToDefer.removeAll(classesToProcess)
				}

			}

			//TODO: Veiellciht kann man das alles auch kürzer schreiben mit weniger Sets...
			finishedAnnotatedClasses.removeAll(annotatedClassesToDefer)

			//Wake up or defer classes, that genrically depended on trigger annotations of processed classes
			val processedTriggerAnnotations = finishedAnnotatedClasses.map[triggerAnnotations].flatten.toSet.map[key]
			val annotatedClassesDependingGenericallyOnProcessedTriggerAnnotations = typesRegistry.
				getAnnotatedClassesDependingGenericallyOnThatTriggerAnnotations(processedTriggerAnnotations)
			annotatedClassesToDefer.addAll(annotatedClassesDependingGenericallyOnProcessedTriggerAnnotations)
			printDiagnosticMessage[
				'''Defer or wake up annotated classes that depend generically on processed annotations «processedTriggerAnnotations»: «annotatedClassesDependingGenericallyOnProcessedTriggerAnnotations»''']

			//Note: Writing the generated classes is separated from generating them, since meanwhile we might be 
			//able to resolve some more error type names (short name) to FQNs. In many cases this can resolve circular dependency issues
			//(as long as the type is only referred but inspection of the type element is not required)
			val genClassesToWrite = generatedTypeElements.filter[genClass, original|
				!annotatedClassesToDefer.contains(original)]

			genClassesToWrite.forEach [ genClass, original |
				try {
					writeSourceFileAndCommitTypeElement(genClass, original, writtenTypeElementsInCurrentRound)

				} catch (TypeElementNotFoundException e) {
					//Mmh. Das funzt so nicht, wenn für eine annotierte Klasse mehrere Dateien generiert werden. Dann werden ggf. einige von denen bereits geschrieben.
					//Vielleicht sollte die TENFE doch nicht erst im JavaEmitter fliegen...
					//Lösung momentan: Beim SChreiben eiens Source-Files stellen wir sicher, dass es noch nicht exisitiert. Funzt so. Ist aber ggf nicht effizient.
					annotatedClassesToDefer.add(original)
				}
			]

		} finally {
			typesRegistry.stopUsingUncommitedGenTypes
		}
	}

	def printAllErrors() {
		if (!deferredClasses.empty) {
			deferredClasses.forEach [ fqn, exc |
				printDiagnosticMessage(
					['''For «fqn», code generation has failed partially or completely due to errors.'''])
			]
		}
		messageCollector.printAllMessages

	}

	def writeSourceFileAndCommitTypeElement(GenTypeElement genTypeElement, TypeElement original,
		Set<GenTypeElement> writtenTypeElementsInCurrentRound) {

		try {
			if (writeSourceFile(genTypeElement, original)) {
				writtenTypeElementsInCurrentRound.add(genTypeElement)
			}
			commitGeneratedTypeElement(genTypeElement)

		} catch (TypeElementNotFoundException e) {
			handleTypeElementNotFound(
				'''Type «e.fqn» not found when writing source file for «genTypeElement.qualifiedName»''', e.fqn,
				original)

			throw e
		}
	}

	def Map<GenTypeElement, TypeElement> processAnnotatedClass(TypeElement annotatedClass) {
		val Map<GenTypeElement, TypeElement> generatedTopLevelClasses = newHashMap;

		//Whatever messages we had so far - they will be re-created if the reason still exists
		removeMessagesForAnnotatedClass(annotatedClass.qualifiedName.toString)

		//Whatever type dependecies we had so far - they will be re-created. Especially UNKNOWN_TYPE dependencies might be replaced by normal ones
		removeDependenciesForAnnotatedClass(annotatedClass.qualifiedName.toString)

		
		processTriggerAnnotations(annotatedClass).forEach[generatedTopLevelClasses.put(it, annotatedClass)]		
		

		//TODO: Reconsider. Is @Behavior considered as Trigger Annotation or as something else?
		//generatedTopLevelClasses.putAll(processBehaviorAnnotation(annotatedClass))
		generatedTopLevelClasses
	}


	def private Set<GenTypeElement> processTriggerAnnotations(TypeElement annotatedClass) {
		
		//TODO: Maybe we could make Trigger annotations more explicit by some meta annotation @Trigger
		//At least, it should not be necessary to always have @GenerateClass ...
		val triggerAnnotations = getTriggerAnnotations(annotatedClass)

		triggerAnnotations.filter[!value].map [ 
			val triggerAnnotationRule = createTriggerAnnotationRule(it.key.annotationAsTypeElement)
			triggerAnnotationRule.processTriggerAnnotation(annotatedClass, it.key)		
		].flatten.toSet

	}
	
	
	//TODO: Some Caching.
	def List<Pair<AnnotationMirror, Boolean>> getTriggerAnnotations(TypeElement annotatedClass) {
		annotatedClass.annotationsWithMetaAnnotation(Clazz).map[it -> it.shadowAnnotation].toList
	}

	val Set<String> writtenTypeElements = newHashSet

	def boolean writeSourceFile(TypeElement typeElement, TypeElement orgClass) {
		printDiagnosticMessage['''Try to write source file: «typeElement.qualifiedName»''']

		if (!writtenTypeElements.contains(typeElement.qualifiedName.toString)) {
			val emitter = new JavaEmitter()

			var code = emitter.compilationUnit(typeElement);

			//code = formatCode(code)
			val file = filer.createSourceFile(typeElement.qualifiedName, orgClass);
			val writer = file.openWriter;
			writer.append(code)
			writer.close
			printDiagnosticMessage ['''Source file written: «typeElement.qualifiedName»''']

		} else {

			//TODO: This probably should be a "real" warning with the hint to do a clean build.
			printDiagnosticMessage['''Source file «typeElement.qualifiedName» already exists.''']
		}

		writtenTypeElements.add(typeElement.qualifiedName.toString)

	}

}
