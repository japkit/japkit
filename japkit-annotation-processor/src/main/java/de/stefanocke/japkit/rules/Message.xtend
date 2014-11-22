package de.stefanocke.japkit.rules

import javax.tools.Diagnostic.Kind

@Data
public class Message {
	Kind kind
	CharSequence msg
    String typeElementFqn
    String uniqueMemberName  //null, it the element is the type element
    String annotationFqn  //The FQN of the root annotation
    Path nestedAnnotationPath  //If the annotation is nested: the path within the root annotation
    String avName //The name of the annotation value
	
}