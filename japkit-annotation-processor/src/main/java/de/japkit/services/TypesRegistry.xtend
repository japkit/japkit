package de.japkit.services

import de.japkit.annotations.Generated
import de.japkit.model.GenAnnotationMirror
import de.japkit.model.GenAnnotationValue
import de.japkit.model.GenDeclaredType
import de.japkit.model.GenTypeElement
import de.japkit.model.GenTypeMirror
import de.japkit.model.GenUnresolvedType
import java.io.BufferedReader
import java.io.BufferedWriter
import java.util.Collections
import java.util.List
import java.util.Map
import java.util.Set
import javax.annotation.processing.ProcessingEnvironment
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.TypeElement
import javax.lang.model.type.DeclaredType
import javax.lang.model.type.ErrorType
import javax.lang.model.type.TypeMirror
import javax.lang.model.util.Elements
import javax.lang.model.util.Types
import javax.tools.StandardLocation
import org.eclipse.xtend.lib.annotations.Accessors
import org.jgrapht.alg.StrongConnectivityInspector
import org.jgrapht.graph.DefaultDirectedGraph
import org.jgrapht.graph.DefaultEdge

import static extension de.japkit.util.MoreCollectionExtensions.*

/**
 * Registry for generated types. Helps with the resolution of those type when they are used in other classes.
 */
class TypesRegistry {

	val transient extension Types = ExtensionRegistry.get(Types)
	val transient extension Elements = ExtensionRegistry.get(Elements)
	val transient extension ProcessingEnvironment = ExtensionRegistry.get(ProcessingEnvironment)
	val MessageCollector messageCollector = ExtensionRegistry.get(MessageCollector)
	val transient extension GenerateClassContext = ExtensionRegistry.get(GenerateClassContext)

	new(){
		load	
	}
	
	def String getGenAnnotationFqn() {
		Generated.name
	}

	def markAsGenerated(GenTypeElement typeElement, TypeElement original) {
		val genAnno = new GenAnnotationMirror(getTypeElement(getGenAnnotationFqn()).asType as DeclaredType) => [
			setValue("src", new GenAnnotationValue(original.qualifiedName.toString))
		]
		typeElement.addAnnotationMirror(genAnno)
	}

	def isGenerated(TypeElement typeElement) {
		(typeElement instanceof GenTypeElement) || findGenAnnotation(typeElement) != null
	}

	def findGenAnnotation(TypeElement typeElement) {
		val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
		
		typeElement.annotationMirror(getGenAnnotationFqn())
	}

	def getAnnotatedClassForGenClassOnDisk(TypeElement typeElement) {
		val am = typeElement.findGenAnnotation
		if (am == null) {
			return null
		}

		val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
		val fqn = am.value("src", String)

		fqn.getTypeElement
	}
	
	def persist() {
		persistAnnotatedClasses()
		persistGenericDependencies()
		persistMultiMap(metaTypeElementsToTriggerAnnotations, ".japkitMetaDependencies", [k,v | #[k, v]])
	}
	
	def load(){
		loadAnnotatedClasses()
		loadGenericDependencies()
		loadMultiMap(metaTypeElementsToTriggerAnnotations, ".japkitMetaDependencies", [line | line.get(0)->line.get(1)])
	}
	
	def persistAnnotatedClasses() {
		val writer = new BufferedWriter(filer.createResource(StandardLocation.SOURCE_OUTPUT, "", ".japkitClasses").openWriter)
		try {
			allAnnotatedClasses.forEach [ ac, triggers |
				triggers.forEach[trigger |
					writer.append('''«ac»,«trigger.key»,«trigger.value»''')		
					writer.newLine
				]				
			]
		
		} finally {
			writer.close
		}
	}
	
		
	def loadAnnotatedClasses() {
		var BufferedReader reader = null
		allAnnotatedClasses.clear
		allAnnotatedClassesByTrigger.clear
		try{
			reader = new BufferedReader(filer.getResource(StandardLocation.SOURCE_OUTPUT, "", ".japkitClasses").openReader(true))
			var String[] line = null
			do{
				line = reader.readLine?.split(',')
				if(line!=null){
					val acFqn = line.get(0)
					val trigger = line.get(1)->Boolean.valueOf(line.get(2))
					allAnnotatedClasses.getOrCreateList(acFqn).add(trigger)		
					allAnnotatedClassesByTrigger.getOrCreateSet(trigger).add(acFqn)
				}
			} while (line!=null)
		} catch (Exception e){
			ExtensionRegistry.get(MessageCollector).printDiagnosticMessage['''Loading .japkitClasses failed: «e»''']
		} finally {
			reader?.close
		}
	}
	
	def persistGenericDependencies() {
		val writer = new BufferedWriter(filer.createResource(StandardLocation.SOURCE_OUTPUT, "", ".japkitGenericDependencies").openWriter)
		try {
			genericTriggerDependencies.forEach [ trigger, annotatedClasses |
				annotatedClasses.forEach[ac |
					writer.append('''«trigger.key»,«trigger.value»,«ac»''')		
					writer.newLine
				]			
			]
		
		} finally {
			writer.close
		}
	}
	
	
	
	def loadGenericDependencies() {
		var BufferedReader reader = null
		genericTriggerDependencies.clear
		
		try{
			reader = new BufferedReader(filer.getResource(StandardLocation.SOURCE_OUTPUT, "", ".japkitGenericDependencies").openReader(true))
			var String[] line = null
			do{
				line = reader.readLine?.split(',')
				if(line!=null){
					val triggerFqn = line.get(0)
					val shadow = Boolean.valueOf(line.get(1))
						
					genericTriggerDependencies.getOrCreateSet(triggerFqn->shadow).add(line.get(2))
					
				}
			} while (line!=null)
		} catch (Exception e){
			ExtensionRegistry.get(MessageCollector).printDiagnosticMessage['''Loading .japkitGenericDependencies failed: «e»''']
		} finally {
			reader?.close
		}
	}
	
	//all discovered annotated classes with trigger annotations recognized by japkit.
	//key is annotated class fqn, value is list of trigger annotations with a boolean for each that tells whether it is a shadow annotation.
	val Map<String, List<Pair<String,Boolean>>> allAnnotatedClasses = newHashMap;
	
	
	val Map<Pair<String,Boolean>, Set<String>> allAnnotatedClassesByTrigger = newHashMap;
	
	def registerAnnotatedClass(TypeElement annotatedClass, List<Pair<AnnotationMirror,Boolean>> triggers){
		val triggerFqns = triggers.map[trigger| (trigger.key.annotationType.asElement as TypeElement).qualifiedName.toString->trigger.value]
		val acFqn = annotatedClass.qualifiedName.toString
		
		allAnnotatedClasses.put(acFqn, triggerFqns)
		
		triggerFqns.forEach[
			allAnnotatedClassesByTrigger.getOrCreateSet(it).add(acFqn)
		]
	}

	//Maps from a type to annotated classes that asked for it
	//the key is the name of the type. For a type, that does not yet exist, it is usually only the simple name.
	val Map<String, Set<String>> annotatedClassesThatDependOnThatType = newHashMap

	//reverse mapping: Key is FQN of anntotated class. 
	//Value is set of pairs where key is generated class fqn and value is the fqn of the type on which it depends
	val Map<String, Set<Pair<String, String>>> typesOnWhichThatAnnotatedClassDependsOn = newHashMap

	//key is fqn of generated type element. value is fqn of annotated class from which the type element is generated
	val Map<String, String> annotatedClassForGenTypeElement = newHashMap

	//key is fqn for generated type element. value is the generated type element
	val Map<String, GenTypeElement> genTypeElementInCurrentRoundByFqn = newHashMap

	def getTypeElementInCurrentRoundByFqn() {
		genTypeElementInCurrentRoundByFqn.immutableCopy
	}

	//key is simple name for generated type element. value is the fqn
	//The reason for using simple name instead of FQN is, that we can only get the simple name for error types.
	//So, in situations with cyclic type dependencies, we can only rely on simple name of the types
	val Map<String, String> typeElementSimpleNameToFqn = newHashMap

	//Generated type elements that have already been written to disk.
	val Set<String> commitedGenTypeElements = newHashSet

	/**
	 * Based on the dependencies and generated type elements registered so far, this method examines, on which 
	 * other annotated classes the given class depends on.
	 * 
	 * TODO: This does not handle the "<error>" case of javac yet.
	 */
	def annotatedClassesOnWhichThatOneDependsOn(String annotatedClassFqn) {
		annotatedClassFqn.getTypesOnWhichThatAnnotatedClassDependsOn.map[annotatedClassForGenTypeElement.get(it)].filter[
			it != null && !equals(annotatedClassFqn)].toSet
	}

	/**
	 * Returns a list of strongly connected components within the graph of the given annotated classes.
	 * See also  http://en.wikipedia.org/wiki/Strongly_connected_component.
	 */
	def findCyclesInAnnotatedClasses(Set<String> annotatedClasses) {
		val g = new DefaultDirectedGraph<String, DefaultEdge>(DefaultEdge);

		annotatedClasses.forEach[g.addVertex(it)]

		annotatedClasses.forEach [ v1 |
			v1.annotatedClassesOnWhichThatOneDependsOn.filter[annotatedClasses.contains(it)].forEach[v2|
				g.addEdge(v1, v2)]
		]

		val ci = new StrongConnectivityInspector<String, DefaultEdge>(g)

		ci.stronglyConnectedSets.filter [
			size > 1 || //Mindestens 2 Klassen, die gegenseitig voneinander abhängen.
			size == 1 && {
				val v = head;
				g.containsEdge(v, v)
			} //Reflexiv. Ist das relevant?
		]

	//Als nächstes dann die cycles heraussuchen, die nicht noch von anderen annotated classes außerhalb des cycles abhängen. 
	//Sie sollten auch nicht von "<error>" abhängen, denn eine solche Abhängikeit lässt sich nicht auflösen. 
	//Aber veilleicht kann man in einem solchen Fall die Klassen trotzdem einfach schreiben... mit den Fehlern.
	}

	def dependsOnOtherAnnotatedClasses(String annotatedClassFqn) {
		annotatedClassFqn.getTypesOnWhichThatAnnotatedClassDependsOn.exists [
			val other = annotatedClassForGenTypeElement.get(it)
			other != null && !other.equals(annotatedClassFqn)
		]
	}

	/**
	 * Determines, whether the given annotated classes depend on any other annotated class not within the set.
	 */
	def dependOnOtherAnnotatedClasses(Set<String> annotatedClassesFqn) {
		annotatedClassesFqn.exists [
			!annotatedClassesFqn.containsAll(annotatedClassesOnWhichThatOneDependsOn)
		]

	}

	/**
	 * Based on the dependencies and generated type elements registered so far, this method examines, on which 
	 * types the given class depends on that are not to be generated from some other annotated class and thus will never be resolved.
	 * 
	 * <p>
	 * With the flag ignoreUnknowTypes the caller can control how to cope with type references where javac only returns "<error>" instead of an ErrorType
	 * with the short name of the missing type. If the flag is set to true, it is assumed, that those type can still be resolved (in one of the next rounds).
	 * So, types, that depend on an UNKNOWN_TYPE, are not considered as being unresolvable.
	 * 
	 * 
	 */
	def unresolvableTypesOnWhichThatAnnotatedClassDependsOn(String annotatedClassFqn, boolean ignoreUnknownTypes) {
		annotatedClassFqn.getTypesOnWhichThatAnnotatedClassDependsOn.filter [
			if (it == TypeElementNotFoundException.UNKNOWN_TYPE)
				!ignoreUnknownTypes
			else
				!annotatedClassForGenTypeElement.containsKey(it) && elementUtils.getTypeElement(it) == null
		]
	}

	/**
	 * Does the annotated class have type dependencies where javac has only returned the String "error" instead of an ErrorType
	 * with the short name of the missing type? 
	 */
	def boolean dependsOnUnknownTypes(CharSequence annotatedClassFqn) {
		annotatedClassFqn.getTypesOnWhichThatAnnotatedClassDependsOn.contains(TypeElementNotFoundException.UNKNOWN_TYPE)
	}
	
	def boolean dependsOnUnknownTypes(CharSequence annotatedClassFqn, CharSequence genClassFqn) {
		(typesOnWhichThatAnnotatedClassDependsOn.get(annotatedClassFqn) ?: emptySet).exists[
			value == TypeElementNotFoundException.UNKNOWN_TYPE &&
			(
				key.nullOrEmpty ||  //the dependency was not for a specific gen class but for the annotatated class in general. Example: @Var in Trigger annotation		
				key == genClassFqn ||
				key.startsWith(genClassFqn+".") //innerclass of the generated class
			)  
		]
	}

	def boolean dependOnUnknownTypes(Set<String> annotatedClassesFqn) {
		annotatedClassesFqn.exists[dependsOnUnknownTypes]
	}

	def registerGeneratedTypeElement(GenTypeElement genTypeElement){
		registerGeneratedTypeElement(genTypeElement, currentAnnotatedClass, currentTriggerAnnotation)
	}
	
	def registerGeneratedTypeElement(GenTypeElement genTypeElement, TypeElement annotatedClass, AnnotationMirror trigger) {
		val genTypeFqn = genTypeElement.qualifiedName.toString
		val genTypeSimpleName = getSimpleOrPartiallyQualifiedName(genTypeElement).toString
		val acFqn = annotatedClass.qualifiedName.toString
		annotatedClassForGenTypeElement.put(genTypeFqn, acFqn);

		messageCollector.printDiagnosticMessage[
			'''Register generated Type Element «genTypeFqn» «genTypeElement».''']
		genTypeElementInCurrentRoundByFqn.put(genTypeFqn, genTypeElement)

		val exisitingFqn = typeElementSimpleNameToFqn.get(genTypeSimpleName)

		if (exisitingFqn != null && !exisitingFqn.equals(genTypeFqn)) {
			messageCollector.reportRuleError(
				'''The simple names of generated classes must be unique. Found «exisitingFqn» and «genTypeFqn»''')
		} else if (exisitingFqn == null) {
			messageCollector.printDiagnosticMessage[
				'''Register fqn for simple name: «genTypeSimpleName» -> «genTypeFqn»''']
			typeElementSimpleNameToFqn.put(genTypeSimpleName, genTypeFqn)
		}

		rectifyTypeDependencies(genTypeSimpleName, genTypeFqn)
		
		
		
		//If the generated class has a shadow trigger annotation, register the class as annotated class, to allow other classes 
		//to find it by findAllTypeElementsWithTriggerAnnotation
		//TODO: Also manually created classes with trigger annotation should be registered to make them query-able.
		if(trigger!=null){
			
			registerAnnotatedClass(genTypeElement, Collections.singletonList(trigger->true))	
		
			val triggerFqn = trigger.annotationType.asTypeElement.qualifiedName.toString
		    //Look for all annotated classes that generically depend on generated classes with the trigger and register a
			//concrete dependency to the generated type. By this, the annotated class will be deferred to the next iteration
			//and its type query can find the new generated type then.
			genericTriggerDependencies.get(triggerFqn->true)?.forEach[
				registerTypeDependencyForAnnotatedClassByFqn(genTypeFqn, '''Generic dependency on trigger annotation «triggerFqn»''')
			]
		
		}
		
	}
	
	/**For top level classes, that method returns the simple name. For inner classes it returns the qualified name without the package name.
	 * The rationale behind this is, that at least Eclipse annotation processing provides this kind of names for ErrorTypes. 
	 */
	def dispatch CharSequence getSimpleOrPartiallyQualifiedName(TypeElement typeElement) {
		val enclosingName = typeElement.enclosingElement?.simpleOrPartiallyQualifiedName
			
		if(enclosingName!=null)
			'''«enclosingName».«typeElement.simpleName»'''	
		else
			typeElement.simpleName
	}
	
	def dispatch CharSequence getSimpleOrPartiallyQualifiedName(Element element) {
		null
	}
	
	


	//Some types might never be resolved since they just don't exist and won't be generated. By setting
	//the following property to false, such error types are ignored.
	@Accessors
	boolean throwTypeElementNotFoundExceptionWhenResolvingSimpleTypeNames = true

	def dispatch tryToGetFqnForErrorType(GenDeclaredType errorType) {
		errorType.qualifiedName
	}
	
	def dispatch tryToGetFqnForErrorType(TypeMirror errorType) {
		tryToGetFqnForErrorTypeSimpleName(errorType.simpleNameForErrorType)
	}
	
	def dispatch getSimpleNameForErrorType(GenDeclaredType errorType){
		errorType.simpleName
	}
	
	def dispatch getSimpleNameForErrorType(TypeMirror errorType){
		
		val name = errorType.toString
		
		if(name.startsWith("<any?>.")){
			//Javac
			name.substring(7)
		} else {
			name
		}
	}
	
	def private tryToGetFqnForErrorTypeSimpleName(String simpleName) {

		val fqn = typeElementSimpleNameToFqn.get(simpleName)
		if (fqn == null) {
			if (throwTypeElementNotFoundExceptionWhenResolvingSimpleTypeNames) {
				throw new TypeElementNotFoundException(simpleName)
			} else {
				return simpleName //We leave it to the compiler to complain...
			}
		}
		fqn
	}

	//update simple name (of an ErrorType) with qualified name
	def private rectifyTypeDependencies(String genTypeSimpleName, String genTypeFqn) {

		//There can be a mix of FQN and simple name usages. Get all of them.
		val annotatedClasses = newHashSet
		annotatedClasses.addAll(annotatedClassesThatDependOnThatType.remove(genTypeSimpleName) ?: emptySet)
		annotatedClasses.addAll(annotatedClassesThatDependOnThatType.remove(genTypeFqn) ?: emptySet)

		if (!annotatedClasses.empty) {
			annotatedClassesThatDependOnThatType.put(genTypeFqn, annotatedClasses)
			annotatedClasses.forEach [
				val dependentTypes = typesOnWhichThatAnnotatedClassDependsOn.get(it)
				if(dependentTypes!=null){
					val simpleTypeNameDependencies = dependentTypes.filter[value==genTypeSimpleName].toSet  
					dependentTypes.addAll(simpleTypeNameDependencies.map[key -> genTypeFqn])
					dependentTypes.removeAll(simpleTypeNameDependencies)
				}
					
			]
		}

	}

	/** DEPRECATED ... As soon as a GenTypeElement is written to disk, it should be removed from registry by calling this method.
	 * In next round, the "real" type element will be available, so there is no need for the generated one anymore.
	 * (and it cannot be changed anymore as soon as it is written to disk). DEPRECATED
	 * The dependencies, where this type is target, are also removed from the registry, since they are resolved
	 *  (as soon as the next round starts and the type element is available). 
	 */
	def void commitGeneratedTypeElement(GenTypeElement genTypeElement) {
		val typeFqn = genTypeElement.qualifiedName.toString

		//genTypeElementInCurrentRoundByFqn.remove(typeFqn)
		val annotatedClasses = annotatedClassesThatDependOnThatType.remove(typeFqn) ?: emptySet

		annotatedClasses.map[typesOnWhichThatAnnotatedClassDependsOn.get(it)]?.forEach [
			val dependenciesOnType = it.filter[value == typeFqn || value == genTypeElement.simpleName].toSet
			it.removeAll(dependenciesOnType)
		]

		commitedGenTypeElements.add(typeFqn)
		
		//Recursively commit all inner classes
		genTypeElement.enclosedElements.filterInstanceOf(GenTypeElement).forEach[commitGeneratedTypeElement]

	}

	def removeDependenciesForAnnotatedClass(String annotatedClassFqn) {
		val types = typesOnWhichThatAnnotatedClassDependsOn.remove(annotatedClassFqn)?.map[value]?.toSet
		types?.forEach [
			val ac = annotatedClassesThatDependOnThatType.get(it)
			if (ac != null) {
				ac.remove(annotatedClassFqn)
				if (ac.empty) {
					annotatedClassesThatDependOnThatType.remove(it)
				}
			}
		]
	}

	def isCommitted(TypeElement typeElement) {
		commitedGenTypeElements.contains(typeElement.qualifiedName.toString)
	}

	def isCommitted(String fqn) {
		commitedGenTypeElements.contains(fqn)
	}

	def Set<String> getAnnotatedClassesThatDependentOn(TypeElement type) {
		val fqn = type.qualifiedName.toString
		val result = newHashSet
		result.addAll(annotatedClassesThatDependOnThatType.get(fqn) ?: emptySet)

		//For ErrorTypes, usually only the short name is available...
		result.addAll(annotatedClassesThatDependOnThatType.get(type.simpleName.toString) ?: emptySet)
		result
	}

	def dispatch void registerTypeDependencyForAnnotatedClass(TypeElement annotatedClass, DeclaredType type) {
		type.typeArguments.forEach[annotatedClass.registerTypeDependencyForAnnotatedClass(it)]
		val rawType = type.erasure
		try {
			val typeElement = rawType.asTypeElement
			val typeFqn = typeElement.qualifiedName.toString
			val annotatedClassFqn = annotatedClass.qualifiedName.toString
			if (typeFqn.startsWith("java") || typeFqn.equals(annotatedClassFqn) || !typeElement.generated ||
				typeElement == currentGeneratedClass || typeElement.committed) {
				//TODO: Die self-cycles zu generierten inner classes werden bsiher noch hier registriert und erst in 	
				//hasUnresolvedTypeDependencies aussortiert. Das kann man noch etwas schöner machen.	

				//Es werden hier nur Abhängigkeiten zu anderen generierten Klassen existiert, denn nur diese können
				//sich im Rahmen des inkrementellen Builds ändern.
				//(Beim Full-Build hingegen gibt es diese anderen generierten Klassen zunächst nicht. Es wird daher immer eine Dependency
				//registriert. Siehe handleTypeElementNotFoundException)
				return;
			}
			registerTypeDependencyForAnnotatedClassByFqn(annotatedClassFqn, typeFqn,
				'''The type element for «type» already existes but might be re-generated during incremental build.''')
		} catch (TypeElementNotFoundException e) {
			//handleTypeElementNotFound('''Type «type» not found.''', rawType.toString, annotatedClass)
			registerTypeDependencyForAnnotatedClassByFqn(annotatedClass.qualifiedName.toString, e.fqn, 
				'''TypeElement for «type» not found. Using «e.fqn» as short name or fqn for dependency registration.''')
		}
	}

	def dispatch void registerTypeDependencyForAnnotatedClass(TypeElement annotatedClass, TypeMirror type) {
	}
	
	def void registerTypeDependencyForCurrentAnnotatedClass(TypeMirror type) {
		if(currentAnnotatedClass!=null){
			registerTypeDependencyForAnnotatedClass(currentAnnotatedClass, type)
		}
	}

	def private dispatch TypeMirror erasure(GenDeclaredType type) {
		type.erasure
	}

	def private dispatch TypeMirror erasure(GenTypeMirror type) {
		type
	}

	def private dispatch TypeMirror erasure(TypeMirror type) {
		typeUtils.erasure(type)
	}

	private def registerTypeDependencyForAnnotatedClassByFqn(String annotatedClassFqn, String typeFqnOrSimpleName,
		CharSequence causeMsg) {
		val typeFqn = typeElementSimpleNameToFqn.get(typeFqnOrSimpleName) ?: typeFqnOrSimpleName

		annotatedClassesThatDependOnThatType.getOrCreateSet(typeFqn).add(annotatedClassFqn)
		
		//TODO: Das is eigentlich nur korrekt, wenn der annotatedClassFqn auch immer die currentAnnotatedClass ist. Das wäre zu prüfen und zu bereinigen...
		val genClassFqn = currentGeneratedClass?.qualifiedName?.toString
		
		val isNewDependency = typesOnWhichThatAnnotatedClassDependsOn
			.getOrCreateSet(annotatedClassFqn)
			.add(genClassFqn -> typeFqn)

		if (isNewDependency) {
			messageCollector.printDiagnosticMessage[
				'''Registered dependency from «annotatedClassFqn» to «typeFqn». Generated class: «genClassFqn». Details: «causeMsg»''']
		}
	}

	/**
	 * An annotated class is said to have unresolved type dependencies if it depends on types that do not yet exist 
	 * or that exist but are re-generated in current round.
	 * <p>
	 * When resolving cyclic dependencies, all classes of the cycle must be passed as annotatedClassesInSameCycle.
	 * Type dependencies within the cycle are ignored.
	 */
	def hasUnresolvedTypeDependencies(String annotatedClassFqn, Set<String> annotatedClassesInSameCycle) {
		val dependsOn = getTypesOnWhichThatAnnotatedClassDependsOn(annotatedClassFqn)

		dependsOn.exists [
			val annotatedClassForType = annotatedClassForGenTypeElement.get(it)
			
			//Self-cycles of an annotated class (or between multiple classes generated from same annotated class) are (currently) not considered.
			annotatedClassForType != annotatedClassFqn &&
			
			{
				//The type is known to be generated from an annotated class and has just been generated in current round. 
				//The annotated class is not part of a cycle currently being resolved.	
				annotatedClassForType != null && !annotatedClassesInSameCycle.contains(annotatedClassForType) &&
				genTypeElementInCurrentRoundByFqn.containsKey(it) ||
				
				//The type does not exist and will not be generated as  part of a cycle currently being resolved.		
				(annotatedClassForType == null || !annotatedClassesInSameCycle.contains(annotatedClassForType)) && 
				{ 
					//TODO: Das ist evtl. etwas ineffizient. Wir wissen i.d.R. schon beim Registrieren der dependency, ob der typ bereits existiert oder nicht.
					val te = elementUtils.getTypeElement(it) //Eclipse may return MissingTypeElement here. Therfore the additional check in next line.
					te == null || te.asType instanceof ErrorType 
					
				}
				
			}
		]
	}

	def Set<String> getTypesOnWhichThatAnnotatedClassDependsOn(CharSequence annotatedClassFqn) {
		annotatedClassFqn.getTypesByGenClassOnWhichThatAnnotatedClassDependsOn.map[value].toSet
	}
	
	def Set<Pair<String, String>> getTypesByGenClassOnWhichThatAnnotatedClassDependsOn(CharSequence annotatedClassFqn) {
		(typesOnWhichThatAnnotatedClassDependsOn.get(annotatedClassFqn.toString) ?: emptySet)
	}
	

	def void handleTypeElementNotFound(CharSequence msg, TypeElement annotatedClass, (Object)=>void closure) {
		try {
			closure.apply(null)
		} catch (TypeElementNotFoundException e) {
			handleTypeElementNotFound(msg, e.fqn, annotatedClass)
		}
	}

	def <T> T handleTypeElementNotFound(T defaultValue, CharSequence msg, TypeElement annotatedClass,
		(Object)=>T closure) {
		try {
			closure.apply(null)
		} catch (TypeElementNotFoundException e) {
			handleTypeElementNotFound(msg, e.fqn, annotatedClass)
			return defaultValue
		}
	}

	def <T> T handleTypeElementNotFound(T defaultValue, CharSequence msg, (Object)=>T closure) {
		val annotatedClass = currentAnnotatedClass //TODO: Ugly	?
		handleTypeElementNotFound(defaultValue, msg, annotatedClass, closure)
	}

	def handleTypeElementNotFound(TypeElementNotFoundException e, TypeElement annotatedClass) {
		handleTypeElementNotFound(e.message, e.fqn, annotatedClass)
	}

	//	def handleTypeElementNotFound(TypeElement annotatedClass, (Object)=>void closure){
	//		handleTypeElementNotFound('''No more details available.''', annotatedClass, closure)
	//	} 
	//	def handleTypeElementNotFound(CharSequence msg, String typeFqnOrShortname) {
	//		val annotatedClass = messageCollector.currentAnnotatedClass //TODO: Ugly	?
	//		handleTypeElementNotFound(msg, typeFqnOrShortname, annotatedClass)
	//	}
	
	def handleTypeElementNotFound(CharSequence msg, String typeFqnOrShortname){
		handleTypeElementNotFound(msg, typeFqnOrShortname, currentAnnotatedClass)
	}
	
	def handleTypeElementNotFound(CharSequence msg, String typeFqnOrShortname, TypeElement annotatedClass) {
		if(annotatedClass != null) { //Null check is for corner cases where annotation types are missing, since they are to be generated (f.e. annotation templates).
			val errorMsg = '''«msg» Missing type: «typeFqnOrShortname»'''		
			registerTypeDependencyForAnnotatedClassByFqn(annotatedClass.qualifiedName.toString, typeFqnOrShortname, msg)		
	
			//Report the error. This might be remover later, when the class is generated again
			messageCollector.reportRuleError(errorMsg)
		
		}
	}

	//Whether asTypeElement shall return generated types, if "real" type is not found (yet).
	boolean returnUncommitedGenTypes = false

	/** For cycle resolution, we need to be able to lookup GenTypes that are "half-done"*/
	def startUsingUncomittedGenTypes() {
		this.returnUncommitedGenTypes = true
	}

	/** Stop using uncommitted generated type elements. */
	def stopUsingUncommitedGenTypes() {
		this.returnUncommitedGenTypes = false
	}

	/**Removes all generated type elements from cache. */
	def cleanUpGenTypesAtEndOfRound() {
		genTypeElementInCurrentRoundByFqn.clear
	}

	def dispatch TypeElement asTypeElement(GenUnresolvedType genDeclType) {
		//May be it exists now. Try to find it.
		val te = findTypeElement(genDeclType.qualifiedName) 
		if(te!=null) return te
		throw new TypeElementNotFoundException(genDeclType.qualifiedName)
	}
	
	def dispatch TypeElement asTypeElement(GenDeclaredType genDeclType) {
		genDeclType.asElement as TypeElement
	}

	//val generatedTypesByFqn
	def dispatch TypeElement asTypeElement(DeclaredType declType) {

		val e = declType.asElement
		
		if (e instanceof TypeElement) {
			//Even if we find the type element, we prefer the generated one, since it is newer.
			//This is relevant during incremental build.
			findGenTypeElementIfAllowed(e.qualifiedName.toString) ?: e
		} else {
			//should not happen
			throw new TypeElementNotFoundException(declType.erasure.toString)
		}
		
		
	}

	def dispatch TypeElement asTypeElement(ErrorType declType) {
		if (!declType.typeArguments.nullOrEmpty) {
			return declType.erasure.asTypeElement
		}
		val e = findGenTypeElementIfAllowed(declType.simpleNameForErrorType)
		if (e != null) {
			e
		} else {
			throw new TypeElementNotFoundException(declType.simpleNameForErrorType)
		}
		
	}
	
	def dispatch TypeElement asTypeElement(TypeMirror declType) {
		declType.asElement as TypeElement
	}

	//Key is FQN of trigger annotation and shadow flag. 
	//Value is set of all annotated classes that genrically depend on that trigger. That is, they shall be regernerated,
	//if anything changes regarding the classes with the trigger annotation. 
	

	val Map<Pair<String, Boolean>, Set<String>> genericTriggerDependencies = newHashMap
	
	def boolean hasGenericDependencyOnTriggerShadowAnnotation(TypeElement annotatedClass, Iterable<AnnotationMirror> triggers){
		val acFqn = annotatedClass.qualifiedName.toString
		triggers.exists[
			val triggerFqn = annotationType.asTypeElement.qualifiedName.toString;
			val shadow = true
			(getAnnotatedClassesDependingGenericallyOnThatTriggerAnnotation(triggerFqn, shadow)).contains(acFqn)
		]
		
	}
	
	def getAnnotatedClassesDependingGenericallyOnThatTriggerAnnotation(String triggerFqn, boolean shadow) {
		genericTriggerDependencies.get(triggerFqn->shadow) ?: emptySet
	}
	
	def getAnnotatedClassesDependingGenericallyOnThatTriggerAnnotations(Iterable<AnnotationMirror> triggers){
		val annotatedClasses = newHashSet
		
		triggers.map[annotationType.asTypeElement.qualifiedName.toString].toSet.forEach[triggerFqn|
			annotatedClasses.addAll(getAnnotatedClassesDependingGenericallyOnThatTriggerAnnotation(triggerFqn, true))
			annotatedClasses.addAll(getAnnotatedClassesDependingGenericallyOnThatTriggerAnnotation(triggerFqn, false))	
		]
		annotatedClasses.map[findTypeElement]
			.filter[it!=null]
			//Eclipse sometimes returns TypeElements for non-existing types, instead of null	
			.filter[!(it.asType instanceof ErrorType)]
		
	}

	//finds type elements with a given trigger annotation known so far. does not register any dependencies
	def findAllTypeElementsWithTriggerAnnotation(String triggerFqn, boolean shadow){
		findAllTypeElementsWithTriggerAnnotation(null as String, triggerFqn, shadow)
	}
	
	//finds type elements with a given trigger annotation and registers a depnedency to re-consider the annotated class again
	//when more such types are discoverd / generated
	def findAllTypeElementsWithTriggerAnnotation(TypeElement annotatedClass, String triggerFqn, boolean shadow){
		val acFqn = annotatedClass?.qualifiedName?.toString
		findAllTypeElementsWithTriggerAnnotation(acFqn, triggerFqn, shadow)
	}
	
	def findAllTypeElementsWithTriggerAnnotation(String clienAnnotatedClassFqn, String triggerFqn, boolean shadow){
		val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
		
		val typeFqns = allAnnotatedClassesByTrigger.get(triggerFqn->shadow)	?: emptySet
		if(clienAnnotatedClassFqn!=null){
			genericTriggerDependencies.getOrCreateSet(triggerFqn->shadow).add(clienAnnotatedClassFqn)	
		}
		
		ExtensionRegistry.get(MessageCollector).printDiagnosticMessage[
			'''Found types for trigger «triggerFqn», «shadow»: «typeFqns»'''
		]
		
		if(clienAnnotatedClassFqn!=null){
			//Register dependencies to those types, that cannot be found yet. That is, they are not yet generated since they 
			//have dependencies to other types.
			//Note: Types to be generated that are discovered later in the iteration will also wake up the clientAnnotatedClass
			//but this happens in registerGenTypeElement.
			typeFqns.filter[findTypeElement(it) == null].forEach[
				registerTypeDependencyForAnnotatedClassByFqn(clienAnnotatedClassFqn, it, '''Generic dependency on trigger annotation «triggerFqn»''')
			]	
		}
		
		
		//Order?
		val elements = typeFqns.map[findTypeElement]
			.filter[it!=null]
			//Eclipse sometimes returns TypeElements for non-existing types, instead of null	
			.filter[!(it.asType instanceof ErrorType)]
			//make sure they really have the requested annotation
			.filter[annotationMirror(triggerFqn) != null]  
		
		ExtensionRegistry.get(MessageCollector).printDiagnosticMessage[
			'''Found type elements for trigger «triggerFqn», «shadow»: «elements.map[qualifiedName]»'''
		]
		elements
	}

	//Finding type element by name. If returnGenTypes is set, the generated types of the current round are considered too.
	def TypeElement findTypeElement(String typeFqnOrShortname) {
		var TypeElement te = findGenTypeElementIfAllowed(typeFqnOrShortname)

		if (te == null) {
			te = elementUtils.getTypeElement(typeFqnOrShortname)
		}
		te
	}

	def TypeElement findGenTypeElementIfAllowed(String typeFqnOrShortname) {
		val fqn = typeElementSimpleNameToFqn.get(typeFqnOrShortname) ?: typeFqnOrShortname.toString
		
		//Always resolve a self cycle and dependency to aux classes immediately.
		if (currentGeneratedClass != null){ 
			val foundType = findTypeInGeneratedClass(currentGeneratedClass, fqn) 
				?: (currentPrimaryGenClass ?: currentGeneratedClass).allAuxTopLevelClasses?.map[findTypeInGeneratedClass(fqn)]?.findFirst[it!=null]
			if(foundType!=null) return foundType
		}
		
		if (returnUncommitedGenTypes || isCommitted(fqn)) {
			val genType = genTypeElementInCurrentRoundByFqn.get(fqn)
			if (genType != null) {
				return genType
			}
		}
		null
	}
	
	
	
	def private TypeElement findTypeInGeneratedClass(GenTypeElement genClass, String typeFqnOrShortname){
		val genClassFqn = genClass.qualifiedName.toString
		if(typeFqnOrShortname == genClassFqn || typeFqnOrShortname == currentGeneratedClass.simpleName.toString) {			
			return genClass
		}
		if(typeFqnOrShortname.startsWith(genClassFqn+".")){
			//Find an inner class of the currently generated class
			val innerClassPath = typeFqnOrShortname.substring(genClassFqn.length+1).split("\\.")
			val innerClass = genClass.findNestedElement(innerClassPath)
			if(innerClass instanceof TypeElement) return innerClass
		}
	}
	
	def Element findNestedElement(Element e, String[] path){
		var result = e
		for(segment : path){
			result = result.enclosedElements.findFirst[simpleName.contentEquals(segment)]
			if(result==null) return null;
		}
		result
		
	}
	
	//Key is a meta TypeElement (template class, function etc.). Value is the set of trigger annoations that use the meta type element directly or indirectly.
	val Map<String, Set<String>> metaTypeElementsToTriggerAnnotations = newHashMap();
	
	//registers the dependency from the rule's meta type element to the current trigger annotation.
	//This is necessary to determine the classes to re-generate, when a meta type element.
	//Note that the meta type element should be always the top level type element, even if the rule uses an inner class.	
	def registerMetaTypeElement(TypeElement rootMetaTypeElement, TypeElement triggerAnnotation){
		metaTypeElementsToTriggerAnnotations.getOrCreateSet(rootMetaTypeElement.qualifiedName.toString).add(triggerAnnotation.qualifiedName.toString)
	}
	
	def getTriggerAnnotationsForMetaTypeElements(Iterable<TypeElement> metaTypeElements){
		metaTypeElements.map[metaTypeElementsToTriggerAnnotations.get(it.qualifiedName.toString) ?: emptySet].flatten.toSet
	}

	def <K,V> persistMultiMap(Map<K, Set<V>> map, String fileName, (K,V)=>List<String> lineCreator) {
		val writer = new BufferedWriter(filer.createResource(StandardLocation.SOURCE_OUTPUT, "", fileName).openWriter)
		try {
			map.forEach [ k, values |
				values.forEach[v |
					writer.append(lineCreator.apply(k, v).join(","))		
					writer.newLine
				]			
			]
		
		} finally {
			writer.close
		}
	}
	
	
	
	def <K,V> loadMultiMap(Map<K, Set<V>> map, String fileName, (List<String>)=>Pair<K,V> lineParser) {
		var BufferedReader reader = null
		map.clear
		
		try{
			reader = new BufferedReader(filer.getResource(StandardLocation.SOURCE_OUTPUT, "", fileName).openReader(true))
			var String[] line = null
			do{
				line = reader.readLine?.split(',')
				if(line!=null){
					val keyValue = lineParser.apply(line)
						
					map.getOrCreateSet(keyValue.key).add(keyValue.value)
					
				}
			} while (line!=null)
		} catch (Exception e){
			ExtensionRegistry.get(MessageCollector).printDiagnosticMessage['''Loading «fileName» failed: «e»''']
		} finally {
			reader?.close
		}
	}
}
