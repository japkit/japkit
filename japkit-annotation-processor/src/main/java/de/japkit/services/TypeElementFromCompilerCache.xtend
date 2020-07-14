package de.japkit.services

import javax.annotation.processing.ProcessingEnvironment
import javax.lang.model.element.TypeElement
import java.util.Map
import java.util.Objects
import java.util.Collection

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
				// See https://bugs.eclipse.org/bugs/show_bug.cgi?id=547970
				
				if(name.contains('.')) {
					val dotIndex = name.lastIndexOf('.')
					
					val parentName = name.substring(0, dotIndex)
					val simpleName = name.substring(dotIndex + 1)
					val parent = getTypeElement(parentName)
					val result = parent?.enclosedElements?.findFirst[it.simpleName.toString == simpleName && (it.kind.isClass || it.kind.isInterface)] as TypeElement;
					if(result === null) {
						printDiagnosticMessage['''Error in getTypeElement (Eclispe Workaround) for «name». «e» «e.stackTrace.map[toString].join('\n')»''']
					}
					result
				
				} else {
					printDiagnosticMessage['''Error in getTypeElement for «name». «e» «e.stackTrace.map[toString].join('\n')»''']
					return null;
				}
			}
		} else {
			return cache.get(name);
		}	
	}
	
	def clear() {
		cache.clear();
	}
	
	/**
	 * At the begin of each round, this method must be called to initialize the cache with the root elements.
	 * This gives some slight performance benefit but primarily prevents bug https://bugs.eclipse.org/bugs/show_bug.cgi?id=547970, 
	 * since Eclipse does not like getTypeElement-calls for types within the rootElements.
	 */
	def init(Collection<TypeElement> rootElements) {
		rootElements.forEach[cache.put(it.qualifiedName.toString(), it)]
	}
}