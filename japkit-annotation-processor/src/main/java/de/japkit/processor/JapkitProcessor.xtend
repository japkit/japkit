package de.japkit.processor

import de.japkit.annotations.Behavior
import de.japkit.el.ELSupport
import de.japkit.metaannotations.Trigger
import de.japkit.model.GenTypeElement
import de.japkit.model.JavaEmitter
import de.japkit.rules.AnnotationExtensions
import de.japkit.rules.RuleFactory
import de.japkit.rules.TypeResolver
import de.japkit.services.ElementsExtensions
import de.japkit.services.ExtensionRegistry
import de.japkit.services.GenerateClassContext
import de.japkit.services.MessageCollector
import de.japkit.services.TypeElementNotFoundException
import de.japkit.services.TypesExtensions
import de.japkit.services.TypesRegistry
import java.util.Collections
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

import static extension de.japkit.util.MoreCollectionExtensions.*

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

		typesRegistry = ExtensionRegistry.get(TypesRegistry)
		ruleFactory = ExtensionRegistry.get(RuleFactory)
		elSupport = ExtensionRegistry.get(ELSupport)

	}

	override finalize() {

		//Argh.
		ExtensionRegistry.cleanup
	}

	override getSupportedAnnotationTypes() {
		val set = newHashSet('''«Behavior.package.name».*''','''«Trigger.package.name».*''')
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
		//The rules cannot be reused in later rounds since they contain references to elements that are no longer valid.
		ruleFactory.clearCaches

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

		

		//The annotated classes that have been defered by previous rounds. During the round, some of them will be removed and processed.
		//But also, new ones might be added
		val annotatedClassesToDefer = new HashSet(deferredClasses.keySet.map[getTypeElement].toSet)
		deferredClasses.clear

		val classesToProcessUnfiltered = roundEnv.rootElements.typeElements.toList
		val classesToProcess = new HashSet(classesToProcessUnfiltered)

		//Search for trigger annotations
		val annotatedClassesAndTriggerAnnotations = classesToProcess.toInvertedMap[triggerAnnotations].filter[ac, t|
			!t.empty]
			
		//type elements that ARE trigger annotations
		val triggerAnnotations = new HashSet(classesToProcess.filter[triggerAnnotation].map[it.qualifiedName.toString].toSet)
		triggerAnnotations.addAll(getTriggerAnnotationsForMetaTypeElements(classesToProcess))
		
		val classesWithTrigger = triggerAnnotations.map[findAllTypeElementsWithTriggerAnnotation(it, false)].flatten.toSet

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
		
		printDiagnosticMessage(
			['''Annotated classes for triggers found in root TypeElements: «classesWithTrigger»'''])
		//For incremental build: If a trigger annotation has changed, add all classes we know to have this trigger
		classesToProcess.addAll(classesWithTrigger)

		var boolean roundDone = false
		val writtenTypeElementsInCurrentRound = newHashSet
		
		while(!roundDone){
			val allClasses = new HashSet(annotatedClassesToDefer)
			allClasses.addAll(classesToProcess)
			
			if(!allClasses.empty){
				val layerCompleted = processLayerAsFarAsPossible(annotatedClassesToDefer, classesToProcess, getMinLayer(allClasses), writtenTypeElementsInCurrentRound)
				//The layer could not be completed in this round due to dependencies to unknown types. 
				//Re-consider the regarding classes in next round
				roundDone = !layerCompleted
				classesToProcess.retainAll(annotatedClassesToDefer)			
			} else {
				roundDone = true
			}
		}
		//If the lowest layer could not be completed in this round, its remaining classes and
		//all higher layer classes are deferred to next round

		//defer remaining annotated classes to next round
		annotatedClassesToDefer.forEach[deferredClasses.put(qualifiedName.toString, null)]

		typesRegistry.cleanUpGenTypesAtEndOfRound //They refer types of current round and thus should not be used in next round, but re-generated. TODO: Really?

		printDiagnosticMessage[
			'''
				Deferred classes: «deferredClasses.keySet.join(", ")»
				Dependencies: 
				«deferredClasses.keySet.map['''«it» depends on «getTypesByGenClassOnWhichThatAnnotatedClassDependsOn»'''].join('\n')»
			''']

		printDiagnosticMessage['''Round Time (ms): «System.currentTimeMillis - startTime»''']

		false
	}
	
	def getMinLayer(Set<TypeElement> annotatedClasses){
		val layers = annotatedClasses.map[layer].toSet
		Collections.min(layers)
	}
	
	def getLayer(TypeElement annotatedClass){
		val layers = annotatedClass.annotationMirrors.map[metaAnnotation(Trigger)].filter[it!=null].map[value('layer', Integer)].toSet
				
		Collections.max(layers)
		
	}
	
	def filterLayer(Iterable<TypeElement> elements, int l) {
		new HashSet(elements.filter[layer == l].toSet)
	}
	
	def boolean processLayerAsFarAsPossible(HashSet<TypeElement> annotatedClassesToDefer, HashSet<TypeElement> classesInCurrentRound, int layer, HashSet<GenTypeElement> writtenTypeElementsInCurrentRound) {
		printDiagnosticMessage(['''Processing layer «layer»'''])
		
		//Key the annotated class. Value is Set of  generated type elements for it.
		val Map<TypeElement, Set<GenTypeElement>> generatedTypeElementsInCurrentRound = newHashMap
		
		val writtenTypeElementsInCurrentLoop = newHashSet
		
		var Set<TypeElement> classesToProcess = classesInCurrentRound.filterLayer(layer)
		
		val ctp = classesToProcess
		printDiagnosticMessage['''Annotated classes to process in layer «layer»: «ctp»''']
		
		val higherLayerClassesInCurrentRound = new HashSet(classesInCurrentRound)
		higherLayerClassesInCurrentRound.removeAll(classesToProcess)
		
		annotatedClassesToDefer.addAll(higherLayerClassesInCurrentRound)
		
		do {
			writtenTypeElementsInCurrentLoop.clear
		
			//Add all deferred classes without unresolved dependencies
			val annotatedClassesFromPreviousRoundWithNoDependencies = annotatedClassesToDefer.filter[
				!hasUnresolvedTypeDependencies(it.qualifiedName.toString, emptySet)].filterLayer(layer)
			printDiagnosticMessage(
				[
					'''Annotated classes from previous rounds / iterations with no type dependencies: «annotatedClassesFromPreviousRoundWithNoDependencies»'''])
			classesToProcess.addAll(annotatedClassesFromPreviousRoundWithNoDependencies)
			
		
			processClassesAndWriteTypeElements(classesToProcess, false, generatedTypeElementsInCurrentRound,
				annotatedClassesToDefer, writtenTypeElementsInCurrentLoop)
		
			classesToProcess = annotatedClassesToDefer.filterLayer(layer)
			
			//Still no progress. Check for cyclic dependencies and try to resolve them
			processClassesWithCycles(classesToProcess, generatedTypeElementsInCurrentRound, annotatedClassesToDefer,
				writtenTypeElementsInCurrentLoop)
		
			classesToProcess = annotatedClassesToDefer.filterLayer(layer)

			if (writtenTypeElementsInCurrentRound.empty && !classesToProcess.empty) {
				// We had no progress up to now, since no source file has been written successfully wuthin the round.
				// Thus, write the classes with permanent type errors now.
				writeClassesWithPermanentTypeErrors(classesToProcess, generatedTypeElementsInCurrentRound,
					annotatedClassesToDefer, writtenTypeElementsInCurrentLoop, false)

			}

			writtenTypeElementsInCurrentRound.addAll(writtenTypeElementsInCurrentLoop)

			classesToProcess = new HashSet
		
		} while (!writtenTypeElementsInCurrentLoop.empty)
		
		//if there is still no progress, consider the classes with dependencies to unknown types again now.
		if (writtenTypeElementsInCurrentRound.empty) {
		
			//deferred classes with unknown dependencies 
			val annotatedClassesWithUnknownDependencies = annotatedClassesToDefer
				.filterLayer(layer)
				.filter[dependsOnUnknownTypes(qualifiedName)]
				.toSet
			printDiagnosticMessage(
				[
					'''Consider Annotated classes from previous rounds /iterations with unknown type dependencies: «annotatedClassesWithUnknownDependencies»'''])
		
			processClassesAndWriteTypeElements(annotatedClassesWithUnknownDependencies.toSet, false,
				generatedTypeElementsInCurrentRound, annotatedClassesToDefer, writtenTypeElementsInCurrentRound)
		
			classesToProcess = annotatedClassesToDefer.filterLayer(layer)
			
			processClassesWithCycles(classesToProcess, generatedTypeElementsInCurrentRound, annotatedClassesToDefer,
				writtenTypeElementsInCurrentRound)
		
			classesToProcess = annotatedClassesToDefer.filterLayer(layer)
			writeClassesWithPermanentTypeErrors(classesToProcess, generatedTypeElementsInCurrentRound, annotatedClassesToDefer,
				writtenTypeElementsInCurrentRound, false)
		
		}
		
		classesToProcess = annotatedClassesToDefer.filterLayer(layer)
		
		//if there is still no progress, write the classes with dependencies to unknown types, even if those dependencies are not resolved.
		if (writtenTypeElementsInCurrentRound.empty) {	
			writeClassesWithPermanentTypeErrors(classesToProcess, generatedTypeElementsInCurrentRound, annotatedClassesToDefer,
				writtenTypeElementsInCurrentRound, true)
		}
		
		val layerDone = annotatedClassesToDefer.filterLayer(layer).isEmpty
		
		if(layerDone){
			printDiagnosticMessage['''Finished processing of layer «layer»''']			
		} else {
			printDiagnosticMessage['''Need to defer processing of layer «layer» to next annotation processing round.''']			
		}
		
		layerDone
	}
	
	

	def writeClassesWithPermanentTypeErrors(
			Set<TypeElement> classesToProcess,
			Map<TypeElement, Set<GenTypeElement>> generatedTypeElementsInCurrentRound,
			HashSet<TypeElement> annotatedClassesToDefer,
			HashSet<GenTypeElement> writtenTypeElementsInCurrentRound,
			boolean alsoWriteClassesThatDependOnUnknownTypes
		) {

			// Those annotated classes have no dependency to other annotated classes. Thus, they have permanent type errors, that cannot be resolved by generating other classes. 
			// Note: classes from cycles that have been resolved in the previous step are included here, since 
			// the dependencies to the other annotated classes of the cycle have been removed.
			val annotatedClassesWithUnresolvableTypeErrors = classesToProcess.filter [
				!dependsOnOtherAnnotatedClasses(qualifiedName.toString)
			].toSet

			if (!annotatedClassesWithUnresolvableTypeErrors.empty) {
				messageCollector.printDiagnosticMessage [
					'''
						Consider classes with unresolvable type errors (alsoWriteClassesThatDependOnUnknownTypes = «alsoWriteClassesThatDependOnUnknownTypes»): 
						«annotatedClassesWithUnresolvableTypeErrors.map[
							'''«it» depends on: «unresolvableTypesOnWhichThatAnnotatedClassDependsOn(qualifiedName.toString, false)»'''].
							join('\n')»
					'''
				]

				val stillToGenerate = annotatedClassesWithUnresolvableTypeErrors.filter [
					generatedTypeElementsInCurrentRound.get(it).nullOrEmpty
				]

				stillToGenerate.forEach [
					processAnnotatedClass.forEach [gen, org|
						generatedTypeElementsInCurrentRound.getOrCreateSet(org).add(gen)
					]
				]

				// Write the classes with permanent type errors, so we can continue (in next round) with classes that depend on them.
				typesRegistry.throwTypeElementNotFoundExceptionWhenResolvingSimpleTypeNames = false

				generatedTypeElementsInCurrentRound.filter [annotatedClass, genTypeElements|
					annotatedClassesWithUnresolvableTypeErrors.contains(annotatedClass)
				].forEach [ annotatedClass, genTypeElements |

					val genClassesNotWritten = newHashSet()
					genTypeElements.forEach [
						// If alsoWriteClassesThatDependOnUnknownTypes is false, we try to write as much of the generated classes as possible
						// since there is still the chance that those classes will resolve the uknown dependency.
						// For example, an AV might refer to an auxiliary class and the primary class uses this AV.
						if (alsoWriteClassesThatDependOnUnknownTypes ||
							!dependsOnUnknownTypes(annotatedClass.qualifiedName.toString, it.qualifiedName.toString)) {
							writeSourceFileAndCommitTypeElement(it, annotatedClass, writtenTypeElementsInCurrentRound)
						} else {
							genClassesNotWritten.add(it)
						}
					]
					if (genClassesNotWritten.empty) {
						annotatedClassesToDefer.remove(annotatedClass)
					}
				]

				typesRegistry.throwTypeElementNotFoundExceptionWhenResolvingSimpleTypeNames = true

			}

		}

	def processClassesWithCycles(Set<TypeElement> classesToProcess, Map<TypeElement, Set<GenTypeElement>> generatedTypeElementsInCurrentRound,
		Set<TypeElement> annotatedClassesToDefer, HashSet<GenTypeElement> writtenTypeElementsInCurrentRound) {
		if (writtenTypeElementsInCurrentRound.empty && !classesToProcess.empty) {

			val cyclesToProcess = findCyclesInAnnotatedClasses(classesToProcess)

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
			
			printDiagnosticMessage(['''Classes to process: «classesToProcess». Is cycle: «isCycle»'''])
			
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
			
			printDiagnosticMessage(['''AnnotatedClassesToDefer: «annotatedClassesToDefer». GeneratedTypeElementsInCurrentRound: «generatedTypeElementsInCurrentRound»'''])
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

		scope[
			currentAnnotatedClass = original  //required for error reporting
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
			null
		]
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
		
		val triggerAnnotations = getTriggerAnnotations(annotatedClass)

		triggerAnnotations.filter[!value].map [ 
			val triggerAnnotationRule = createTriggerAnnotationRule(it.key.annotationAsTypeElement)
			triggerAnnotationRule.processTriggerAnnotation(annotatedClass, it.key)		
		].flatten.toSet

	}
	
	
	//TODO: Some Caching.
	def List<Pair<AnnotationMirror, Boolean>> getTriggerAnnotations(TypeElement annotatedClass) {
		annotatedClass.annotationsWithMetaAnnotation(Trigger).map[it -> it.shadowAnnotation].toList
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

			//This happens if only some of the generated classes of an annotated class have been written
			//and later the remaining ones
			printDiagnosticMessage['''Source file «typeElement.qualifiedName» already exists.''']
		}

		writtenTypeElements.add(typeElement.qualifiedName.toString)

	}

}
