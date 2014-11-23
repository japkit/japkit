package de.stefanocke.japkit.rules

import de.stefanocke.japkit.el.ELSupport
import de.stefanocke.japkit.model.AnnotationAndParent
import de.stefanocke.japkit.model.Path
import java.util.List
import java.util.Map
import java.util.Set
import javax.annotation.processing.ProcessingEnvironment
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.AnnotationValue
import javax.lang.model.element.Element
import javax.lang.model.element.PackageElement
import javax.lang.model.element.TypeElement
import javax.tools.Diagnostic.Kind

import static extension de.stefanocke.japkit.util.MoreCollectionExtensions.*
import org.eclipse.xtend.lib.annotations.Accessors

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
		if (currentAnnotatedClass == null) {
			throw new IllegalStateException("Currently processed annotated class must be set to report errors!")
		}
		val currentAnnotatedClassFqn = currentAnnotatedClass.qualifiedName.toString
		//messager.printMessage(Kind.NOTE, '''add Message: «m»''')
		messagesPerAnnotatedClass.getOrCreateSet(currentAnnotatedClassFqn).add(m)

	}

	def void addMessage(Kind kind, String msg, Element element, AnnotationMirror annotation, String annotationValueName) {
		val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
		
		val typeElement = element?.nextEnclosingTypeElement
		val String  uniqueElementName = if (typeElement == element) null else element?.uniqueNameWithin(typeElement)
		
		val rootAnnotation = if (annotation instanceof AnnotationAndParent) annotation?.rootAnnotation else annotation
		
		val nestedAnnotationPath =  if (annotation instanceof AnnotationAndParent) annotation?.pathFromRootAnnotation else null
		
		
		val m = new Message(kind, msg, 
			typeElement?.qualifiedName?.toString,
			uniqueElementName?.toString, 
			(rootAnnotation?.annotationType?.asElement as TypeElement)?.qualifiedName?.toString,
			nestedAnnotationPath,
			annotationValueName)  //TODO: AV value !?
		addMessage(m)
	}

	def private dispatch TypeElement nextEnclosingTypeElement(TypeElement e) {
		e
	}

	def private dispatch TypeElement nextEnclosingTypeElement(Element e) {
		e.enclosingElement.nextEnclosingTypeElement
	}
	
	

	//report all collected errors to the Messager
	def void printAllMessages() {
		val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
		printDiagnosticMessage(['''Print Messages: «messagesPerAnnotatedClass»'''])
		messagesPerAnnotatedClass.values.filter[it != null].flatten.forEach [ m |
			//Rediscover the element where the message occured...
			var Element element = null 
			var AnnotationMirror annotation = null
			var AnnotationValue annotationValue = null
			try{
				val typeElement = getTypeElement(m.typeElementFqn)
				if(m.uniqueMemberName!=null){
					//TODO: Support inner classes. Use uniqueIdentifier
					element = typeElement.enclosedElements.findFirst[uniqueNameWithin(typeElement).contentEquals(m.uniqueMemberName)]
				} else {
					element = typeElement
				}
				val rootAnnotation = element?.annotationMirrors.findFirst[(annotationType.asElement as TypeElement).qualifiedName.contentEquals(m.annotationFqn)]
				
				annotation = if(supportsNestedAnnotations) getNestedAnnotation(rootAnnotation, m.nestedAnnotationPath) else rootAnnotation
				
				annotationValue = annotation.getValue(
					//If the messager does not support nested annotations, only use the first path segment to determine the AV
					if(supportsNestedAnnotations) m.avName else m.nestedAnnotationPath?.segments?.get(0)?.name ?: m.avName,
					null
				)


			} catch(RuntimeException e){
			}
			messager.printMessage(m.kind, m.msg, element, annotation, annotationValue)
			
			//Make it appear at least in error log...
			messager.printMessage(m.kind, '''«m.msg» «m.typeElementFqn» «m.annotationFqn» «m.nestedAnnotationPath»''')
		]
		messagesPerAnnotatedClass.clear
	}
	
	def boolean supportsNestedAnnotations(){
		//Eclipse implementation of messager does not support nested annotations
		//!isEclipse()
		true
	}
	
	def boolean isEclipse(){
		messager.class.package.name.startsWith("org.eclipse")
	}
	
	def getNestedAnnotation(AnnotationMirror rootAnnotation, Path path){
		val pathSegments = path?.segments
		var annotation = rootAnnotation
				
		if(pathSegments!=null){
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
		if(index!=null) (av?.value as List<AnnotationValue>).get(index) else av
	}

	def removeMessagesForAnnotatedClass(String annotatedClassFqn) {
		messagesPerAnnotatedClass.remove(annotatedClassFqn)
	}
	
	def reportRuleError(CharSequence msg){
		reportRuleError(currentRule, msg, null)
	}
	
	def reportRuleError(CharSequence msg, CharSequence metaAnnotationValueName){
		reportRuleError(currentRule, msg, metaAnnotationValueName)
	}
	
	def reportRuleError(Rule rule, CharSequence msg, CharSequence metaAnnotationValueName){
		val extension ELSupport = ExtensionRegistry.get(ELSupport)
		
		val metaAnnotation = rule?.metaAnnotation 
		val metaElement = if (metaAnnotation instanceof AnnotationAndParent) metaAnnotation?.rootAnnotatedElement else rule?.metaElement   //There are rules without any meta annotation. They only have a template element.
		
		
		
		addMessage(Kind.ERROR, '''«msg?.toString» MetaElement: «metaElement», MetaAnnotation: «metaAnnotation», Src: «currentSrcOptional»''', currentAnnotatedClass, null, null)
		
		addMessage(Kind.ERROR, msg?.toString, metaElement, metaAnnotation, metaAnnotationValueName?.toString)
		
		
	}
	
	
	
	def reportError(CharSequence msg, Exception ex, Element element, AnnotationMirror annotation, CharSequence annotationValueName){
		reportError(new ProcessingException('''«msg» Cause: «ex»: «ex.message»\n at «ex.stackTrace.join("\n at ")»''', element, annotation, annotationValueName, null))  //TODO: Refactor
	}
	
	def reportError(CharSequence msg, Element element, AnnotationMirror annotation, CharSequence annotationValueName){
		reportError(new ProcessingException(msg?.toString, element, annotation, annotationValueName, null))  //TODO: Refactor
	}

	def reportError(ProcessingException pe) {

		//Always prepend the location, so it can be found even if not in current project (f.e. annotations with meta annotations)
		val elementStr = if (pe.element != null) {
				'''Element: «pe.element», '''
			} else {
				''
			}
		val annotationStr = if (pe.annotationMirror != null) {
				'''Annotation: «pe.annotationMirror», '''
			} else {
				''
			}
		val annotationValueStr = if (pe.annotationValueName != null) {
				'''Annotation Value: «pe.annotationValueName»«IF pe.annotationValue != null» ="«pe.annotationValue.value»"«ENDIF», '''
			} else {
				''
			}
		

		val msg = '''«elementStr»«annotationStr»«annotationValueStr»«pe.message»'''
		var element = pe.element
		if (element == null) {
			element = currentAnnotatedClass //Make sure there is always an element where the error can be reported
		}
		var annotation = pe.annotationMirror
		if (annotation == null) {
			annotation = currentTriggerAnnotation
		}

		addMessage(Kind.ERROR, msg, element, annotation, pe.annotationValueName?.toString)

		if (currentAnnotatedClass!=null) {

			//Make sure, the error is reported for an element within the project, even if the original cause is an element outside the project
			addMessage(Kind.ERROR, msg, currentAnnotatedClass, currentTriggerAnnotation, null)
		}

	}
	
	def reportMessage(String msg, Element element, Kind kind) {
		addMessage(kind, msg, element, currentTriggerAnnotation, null)
		//If the element is not the current annotated class or is not contained in it, report one more message for the annotated class
		if (currentAnnotatedClass!=null && element.enclosingTopLevelElement != currentAnnotatedClass) {
			addMessage(kind, msg, currentAnnotatedClass, currentTriggerAnnotation, null)
		}
	}
	
	def private Element enclosingTopLevelElement(Element element){
		val enclosing = element?.enclosingElement 
		if(enclosing == null || enclosing instanceof PackageElement){
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
