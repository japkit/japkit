package de.japkit.services

import de.japkit.el.ELProviderException
import de.japkit.el.ELSupport
import de.japkit.model.AnnotationAndParent
import de.japkit.model.ParameterWrapper
import de.japkit.model.Path
import de.japkit.rules.Rule
import java.util.List
import java.util.Map
import java.util.Set
import javax.annotation.processing.ProcessingEnvironment
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.AnnotationValue
import javax.lang.model.element.Element
import javax.lang.model.element.PackageElement
import javax.lang.model.element.QualifiedNameable
import javax.lang.model.element.TypeElement
import javax.tools.Diagnostic
import javax.tools.Diagnostic.Kind
import org.eclipse.xtend.lib.annotations.Accessors

import static extension de.japkit.util.MoreCollectionExtensions.*
import de.japkit.rules.RuleException

/** Collects error messages for annotated classes.
 * <p>
 * While it might seem sufficient to use the ProcessingEnvironment.Messager for this, it is not... 
 * Eclipse tends to "forget" reported errors in some cases, especially, when annotated classes refer to generated classes 
 * and Eclipse has to compile them again after an annotation processor round.
 * Thus, we collect all errors and report them in last annotation processing round.
 * 
 * See: <a href="https://bugs.eclipse.org/bugs/show_bug.cgi?id=419769">https://bugs.eclipse.org/bugs/show_bug.cgi?id=419769 </a>
 * 
 */
class MessageCollector {

	extension ProcessingEnvironment processingEnvironment = ExtensionRegistry.get(ProcessingEnvironment)
	extension GenerateClassContext = ExtensionRegistry.get(GenerateClassContext)
	
	@Accessors
	boolean diagnosticLogging = false


	Map<String, Set<Message>> messagesPerAnnotatedClass = newHashMap

	def void addMessage(Message m) {
		if (currentAnnotatedClass === null) {
			throw new IllegalStateException("Currently processed annotated class must be set to report errors!")
		}
		val currentAnnotatedClassFqn = currentAnnotatedClass.qualifiedName.toString
		//messager.printMessage(Kind.NOTE, '''add Message: «m»''')
		messagesPerAnnotatedClass.getOrCreateSet(currentAnnotatedClassFqn).add(m)

	}

	def void addMessage(Kind kind, String msg, Element element, AnnotationMirror annotation, String annotationValueName) {
		val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
		
		val typeOrPackageElement = element?.nextEnclosingTypeOrPackageElement
		val String  uniqueElementName = if (typeOrPackageElement == element) null else element?.uniqueNameWithin(typeOrPackageElement)
		
		val rootAnnotation = if (annotation instanceof AnnotationAndParent) annotation?.rootAnnotation else annotation
		
		val nestedAnnotationPath =  if (annotation instanceof AnnotationAndParent) annotation?.pathFromRootAnnotation else null
		
		
		val m = new Message(kind, msg, 
			typeOrPackageElement?.qualifiedName?.toString,
			uniqueElementName?.toString, 
			(rootAnnotation?.annotationType?.asElement as TypeElement)?.qualifiedName?.toString,
			nestedAnnotationPath,
			annotationValueName)  //TODO: AV value !?
		addMessage(m)
	}

	def private dispatch QualifiedNameable nextEnclosingTypeOrPackageElement(QualifiedNameable e) {
		e
	}

	def private dispatch QualifiedNameable nextEnclosingTypeOrPackageElement(Element e) {
		e.enclosingElement.nextEnclosingTypeOrPackageElement
	}
	
	

	//report all collected errors to the Messager
	def void printAllMessages() {
		val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
		printDiagnosticMessage(['''Print Messages: «messagesPerAnnotatedClass»'''])
		messagesPerAnnotatedClass.values.filter[it !== null].flatten.forEach [ m |
			//Rediscover the element where the message occured...
			var Element element = null 
			var AnnotationMirror annotation = null
			var AnnotationValue annotationValue = null
			var Element enclosingExecutableElement = null;
			var String paramName = null;
			
			try{
				if(m.typeOrPackageElementFqn !== null) {
					val typeElement = getTypeElement(m.typeOrPackageElementFqn) ?: getPackageElement(m.typeOrPackageElementFqn)
					if(m.uniqueMemberName !== null){	
						val enclosedElementsAndParams = typeElement.elementAndAllEnclosedElements(true)
						element = enclosedElementsAndParams.findFirst[uniqueNameWithin(typeElement).contentEquals(m.uniqueMemberName)]
						if(element instanceof ParameterWrapper) {
							enclosingExecutableElement = element.enclosingElement
							paramName = element.name?.toString
							element = element.delegate						
						}
					} else {
						element = typeElement
					}
					
					if (element !== null && m.annotationFqn !== null) {
						val rootAnnotation = element.annotationMirrors.findFirst [
							(annotationType.asElement as TypeElement).qualifiedName.contentEquals(m.annotationFqn)
						]
	
						annotation = if(supportsNestedAnnotations) getNestedAnnotation(rootAnnotation,
							m.nestedAnnotationPath) else rootAnnotation
	
						annotationValue = annotation?.getValue(
							// If the messager does not support nested annotations, only use the first path segment to determine the AV
							if(supportsNestedAnnotations) m.avName else m.nestedAnnotationPath?.segments?.get(0)?.name ?:
								m.avName,
							null
						)
	
					}			
				}
			} catch (Exception e) {
				messager.printMessage(Diagnostic.Kind.ERROR, 
					'''Error during error reporting: «e», cause: «e.rootCause.message» 
					«FOR ste : e.stackTrace.subList(0, Math.min(20, e.stackTrace.length))»
						«ste»
					«ENDFOR»'''
				)
			}
			messager.printMessage(m.kind, m.msg, element, annotation, annotationValue)
			
			//Workaround for https://github.com/stefanocke/japkit/issues/20 ,  https://bugs.eclipse.org/bugs/show_bug.cgi?id=427752
			if(enclosingExecutableElement !== null) {
				messager.printMessage(m.kind, 
				'''Error in parameter «paramName» (Annotation: «m.annotationFqn», AnnotationValue: «m.avName»): ''' + m.msg, enclosingExecutableElement, null, null)
			}
			
			//Make it appear at least in error log...
			messager.printMessage(m.kind, '''«m.msg» «m.typeOrPackageElementFqn» «m.annotationFqn» «m.nestedAnnotationPath»''')
		]
		messagesPerAnnotatedClass.clear
	}
	
	def boolean supportsNestedAnnotations(){
		//Eclipse implementation of messager does not support nested annotations
		//!isEclipse()
		//Since Eclipse Mars, nested annotations are supported...
		true
	}
	
	def boolean isEclipse(){
		messager.class.package.name.startsWith("org.eclipse")
	}
	
	def getNestedAnnotation(AnnotationMirror rootAnnotation, Path path){
		if(rootAnnotation === null) {
			return null;
		}
		val pathSegments = path?.segments
		var annotation = rootAnnotation
				
		if(pathSegments !== null){
			for(s : pathSegments){
				var av = annotation.getValue(s.name, s.index)
				
				annotation = av.value as AnnotationMirror
			}				
		}
		annotation
	}

	def getValue(AnnotationMirror am, String avName, Integer index){
		if(avName.nullOrEmpty) return null
		val av = am?.elementValues.filter[k, v| k.simpleName.contentEquals(avName)].values.head
		if(index !== null) (av?.value as List<AnnotationValue>).get(index) else av
	}

	def removeMessagesForAnnotatedClass(String annotatedClassFqn) {
		messagesPerAnnotatedClass.remove(annotatedClassFqn)
	}
	
	
	
	def private Throwable getRootCause(Throwable t) {
		t.cause?.rootCause ?: t
	}
	
	def dispatch void reportRuleError(CharSequence msg){
		reportRuleError(currentRule, msg, null,null)
	}
	
	def dispatch void reportRuleError(Exception e){
		reportRuleError(e, null)
	}
	
	def dispatch void reportRuleError(ELProviderException e, CharSequence metaAnnotationValueName) {
		reportRuleError(currentRule, '''«e.rootCause.message»''', null, metaAnnotationValueName)
	}
	
	def dispatch void reportRuleError(RuleException e, CharSequence metaAnnotationValueName) {
		val avName = metaAnnotationValueName ?: e.metaAnnotationValueName
		//A RuleException is usually an "expected" exception caused by the user.
		//Thus, no stacktrace is printed unless a cause exists in the RuleException. 
		reportRuleError(currentRule, '''
			«e.message»
			«IF e.cause !== null »
			Cause:
			«stacktrace(e.rootCause)»
			«ENDIF»''', 
			e.metaAnnotation, avName)
	}
	
	def dispatch void reportRuleError(Exception e, CharSequence metaAnnotationValueName) {
		//In case of an "unknown" exception, a stacktrace is always printed. 
		//Either the one of the root cause or the one of the exception itself. 
		reportRuleError(currentRule, '''
			«stacktrace(e.rootCause)»''', 
			null, metaAnnotationValueName)
	}
	
	protected def CharSequence stacktrace(Throwable e) {
		if (e !== null)
			'''
			«e.class.name»: «e.message» 
			«FOR ste : e.stackTrace.subList(0, Math.min(20, e.stackTrace.length))»
				«ste»
			«ENDFOR»'''
		else
			''
	}
	
	
	def dispatch void reportRuleError(CharSequence msg, CharSequence metaAnnotationValueName){
		reportRuleError(currentRule, msg, null, metaAnnotationValueName)
	}
		
	def reportRuleError(Rule rule, CharSequence msg, AnnotationMirror metaAnnotation_,
		CharSequence metaAnnotationValueName) {
		val extension ELSupport = ExtensionRegistry.get(ELSupport)

		val metaAnnotation = metaAnnotation_ ?: rule?.metaAnnotation
		var metaElement = if(metaAnnotation instanceof AnnotationAndParent) metaAnnotation?.
				rootAnnotatedElement else rule?.metaElement
				
		// There are rules without any meta annotation. They only have a template element.
		// Always report on currentAnnotatedClass, since if the meta elements are in a different project, the errors would not be shown at all otherwise
		addMessage(Kind.ERROR, '''
			«msg?.toString» 
			«IF metaElement !== null »Meta-Element: «metaElement»,«ENDIF»
			«IF metaAnnotation !== null »Meta-Annotation: «metaAnnotation»,«ENDIF»
			«IF metaAnnotationValueName !== null »Meta-AnnotationValue: «metaAnnotationValueName»,«ENDIF»
			Src: «currentSrcOptional ?: currentAnnotatedClass»
			''', 
			currentAnnotatedClass, null, null)

		addMessage(Kind.ERROR, '''«IF metaAnnotationValueName !== null »«metaAnnotationValueName»: «ENDIF»«msg»''', 
			metaElement, metaAnnotation, metaAnnotationValueName?.toString
		)

	}
	
	def reportMessage(String msg, Element element, Kind kind) {
		addMessage(kind, msg, element, currentTriggerAnnotation, null)
		//If the element is not the current annotated class or is not contained in it, report one more message for the annotated class
		if (currentAnnotatedClass !== null && element.enclosingTopLevelElement != currentAnnotatedClass) {
			addMessage(kind, msg, currentAnnotatedClass, currentTriggerAnnotation, null)
		}
	}
	
	def private Element enclosingTopLevelElement(Element element){
		val enclosing = element?.enclosingElement 
		if(enclosing === null || enclosing instanceof PackageElement){
			element
		} else {
			enclosing.enclosingTopLevelElement
		}
	}
	
	
	
	def printDiagnosticMessage((Object)=>CharSequence cs){
		if(diagnosticLogging){
			messager.printMessage(Kind.NOTE, cs.apply(null))
		
		}
	}
	
	def printDiagnosticMessage(Element e, (Object)=>CharSequence cs){
		if(diagnosticLogging){
			messager.printMessage(Kind.NOTE, cs.apply(null), e)
		
		}
	}
	
	

}
