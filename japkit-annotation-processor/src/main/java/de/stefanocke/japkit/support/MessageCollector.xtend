package de.stefanocke.japkit.support

import java.util.Map
import java.util.Set
import javax.annotation.processing.ProcessingEnvironment
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.AnnotationValue
import javax.lang.model.element.Element
import javax.lang.model.element.PackageElement
import javax.lang.model.element.TypeElement
import javax.lang.model.util.Elements
import javax.tools.Diagnostic.Kind

import static extension de.stefanocke.japkit.util.MoreCollectionExtensions.*

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
	extension Elements elementUtils = ExtensionRegistry.get(Elements)
	extension GenerateClassContext = ExtensionRegistry.get(GenerateClassContext)
	
	@org.eclipse.xtend.lib.Property
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
		
		val typeElement = element?.nextEnclosingTypeElement
		val simpleElementName = if (typeElement == element) null else element?.simpleName
		val m = new Message(kind, msg, 
			typeElement?.qualifiedName?.toString,
			simpleElementName?.toString, 
			(annotation?.annotationType?.asElement as TypeElement)?.qualifiedName?.toString,
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
		printDiagnosticMessage(['''Print Messages: «messagesPerAnnotatedClass»'''])
		messagesPerAnnotatedClass.values.filter[it != null].flatten.forEach [ m |
			//Rediscover the element where the message occured...
			var Element element = null 
			var AnnotationMirror annotation = null
			var AnnotationValue annotationValue = null
			try{
				element = getTypeElement(m.typeElementFqn)
				if(m.elementSimpleName!=null){
					element = element.enclosedElements.findFirst[simpleName.contentEquals(m.elementSimpleName)]
				} 
				annotation = element?.annotationMirrors.findFirst[(annotationType.asElement as TypeElement).qualifiedName.contentEquals(m.annotationFqn)]
				annotationValue = annotation?.elementValues.filter[k, v| k.simpleName.contentEquals(m.annotationValueName)].values.head
			} catch(RuntimeException e){
			}
			messager.printMessage(m.kind, m.msg, element, annotation, annotationValue)
			
			//Make it appear at least in error log...
			messager.printMessage(m.kind, m.msg)
		]
		messagesPerAnnotatedClass.clear
	}

	def removeMessagesForAnnotatedClass(String annotatedClassFqn) {
		messagesPerAnnotatedClass.remove(annotatedClassFqn)
	}
	
	def reportError(CharSequence msg, Element element, AnnotationMirror annotation, CharSequence annotationValueName){
		reportError(new ProcessingException(msg?.toString, element, annotation, annotationValueName, null))  //TODO: Refactor
	}
	
	def reportError(CharSequence msg, Exception ex, Element element, AnnotationMirror annotation, CharSequence annotationValueName){
		reportError(new ProcessingException('''«msg» Cause: «ex»: «ex.message»\n at «ex.stackTrace.join("\n at ")»''', element, annotation, annotationValueName, null))  //TODO: Refactor
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
		
		val metaAnnotationStr = if (currentMetaAnnotation != null) {
				'''Meta Annotation: «currentMetaAnnotation»'''
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
