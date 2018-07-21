package de.japkit.services

import javax.annotation.processing.ProcessingEnvironment
import javax.lang.model.element.TypeElement
import java.util.Map

/**
 * Elements.getTypeElement() can be quite slow (see https://github.com/japkit/japkit/issues/37).
 * Since we expect always the same result from that method if we are within the same round and pass the same fqn,
 * we can cache the results per round.
 */
class TypeElementFromCompilerCache {
	val transient extension ProcessingEnvironment = ExtensionRegistry.get(ProcessingEnvironment)
	
	val Map<String, TypeElement> cache = newHashMap
		
	def TypeElement getTypeElement(String name) {
		if(!cache.containsKey(name)) {
			val typeElement = elementUtils.getTypeElement(name)
			cache.put(name, typeElement)
			return typeElement
		} else {
			return cache.get(name);
		}	
	}
	
	def clear() {
		cache.clear();
	}
}