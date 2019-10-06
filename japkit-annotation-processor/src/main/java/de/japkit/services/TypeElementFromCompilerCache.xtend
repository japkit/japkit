package de.japkit.services

import javax.annotation.processing.ProcessingEnvironment
import javax.lang.model.element.TypeElement
import java.util.Map
import java.util.Objects

/**
 * Elements.getTypeElement() can be quite slow (see https://github.com/japkit/japkit/issues/37).
 * Since we expect always the same result from that method if we are within the same round and pass the same fqn,
 * we can cache the results per round.
 */
class TypeElementFromCompilerCache {
	val transient extension ProcessingEnvironment = ExtensionRegistry.get(ProcessingEnvironment)
	val transient extension MessageCollector = ExtensionRegistry.get(MessageCollector)
	
	val Map<String, TypeElement> cache = newHashMap
		
	def TypeElement getTypeElement(String name) {
		Objects.requireNonNull(name, "FQN must be provided.");
		if(!cache.containsKey(name)) {	
			try {	
				val typeElement = elementUtils.getTypeElement(name)
				cache.put(name, typeElement)
				return typeElement		
			} catch (Exception e) {
				// This should never happen, but it does in Eclipse. 
				// For example, see https://bugs.eclipse.org/bugs/show_bug.cgi?id=547970
				
				printDiagnosticMessage['''Error in getTypeElement for «name». «e» «e.stackTrace.map[toString].join('\n')»''']
				return null;
			}
		} else {
			return cache.get(name);
		}	
	}
	
	def clear() {
		cache.clear();
	}
}