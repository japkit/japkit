package de.stefanocke.japkit.support

import javax.tools.Diagnostic.Kind

@Data
public class Message {
	Kind kind
	CharSequence msg
    String typeElementFqn
    String elementSimpleName  //null, it the element is the type element
    String annotationFqn
    String annotationValueName
	
}