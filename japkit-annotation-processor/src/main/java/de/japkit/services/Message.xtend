package de.japkit.services

import de.japkit.model.Path
import javax.tools.Diagnostic.Kind
import org.eclipse.xtend.lib.annotations.Data

/**
 * A "serializable" message that does not contain any direct references to Elements or Annotations but only their (fully qualified) names.
 * So, the message can be kept for more than one annotation processing round.
 */
@Data
public class Message {
	Kind kind
	
	/**
	 * The message content.
	 */
	CharSequence msg
	
	/**
	 * Japkit supports to process annotated TypeElements or PackageElements.
	 * This is the fqn of the annotated TypeElement or PackageElement for which the message is reported.
	 */
    String typeOrPackageElementFqn
    
    /** 
     * The name of the Element within the TypeElement, for which the message is reported.
     * If it is nested, this a qualified name separated by dots.
     * Null, if the Message is for the annotated TypeElement itself or if the Message is for an annotated PackageElement.
     */
    String uniqueMemberName
    
    /**
     * If the message is for a (top level) Annotation or a 'nested' Annotation, this is the FQN of the top level Annotation.
     */
    String annotationFqn
    
    /**
     * If the annotation is nested: the path within the root annotation.
     */
    Path nestedAnnotationPath
    
    /**
     * If the message is for a specific AnnotrationValue within the Annotation, this is the name of the annotation value.
     */
    String avName
	
}