package de.stefanocke.japkit.rules

import de.stefanocke.japkit.el.ElVariableError
import de.stefanocke.japkit.services.ExtensionRegistry
import de.stefanocke.japkit.services.TypeElementNotFoundException
import de.stefanocke.japkit.services.TypesRegistry
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.type.TypeMirror
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtext.xbase.lib.Functions.Function0
import org.eclipse.xtext.xbase.lib.Functions.Function1

@Data
class ELVariableRule extends AbstractRule implements Function1<Object, Object>,  Function0<Object> {
	 
	String name
	boolean ifEmpty
	String expr
	String lang
	Class<?> type


	new(AnnotationMirror elVarAnnotation) {
		super(elVarAnnotation, null)
		name = elVarAnnotation.value("name", String);
		
		ifEmpty = elVarAnnotation.value("ifEmpty", Boolean);
		expr = elVarAnnotation.value("expr", String);
		lang = elVarAnnotation.value("lang", String);
		type = Class.forName(elVarAnnotation.value("type", TypeMirror).asElement.qualifiedName.toString);
		
	}

	def void putELVariable() {
		
		val exisitingValue = valueStack.get(name)
		if(ifEmpty && exisitingValue!==null && !exisitingValue.emptyVar) return
		
		val value = eval(currentSrc)
		valueStack.put(name, value)
			
	}
	
	
	def Object filter(Iterable<? extends Element> collection) {
		collection.filter[
			eval(it) as Boolean
		]
	}
	
	def Object map(Iterable<? extends Element> collection) {
		collection.map[
			eval(it)			
		]
	}
	
	def Object eval(Object src) {
		inRule[
			val result = scope(src) [
				try {
					if (!expr.nullOrEmpty) {
						eval(expr, lang, type);
					} else {
						//By default, the value is the current src. 
						currentSrc
					}
				} catch(ElVariableError e){
					//Do not report the error again to avoid error flooding
					e
				} 
				catch (TypeElementNotFoundException tenfe) {
					ExtensionRegistry.get(TypesRegistry).handleTypeElementNotFound(tenfe, currentAnnotatedClass)
					new ElVariableError(name)
				} catch (Exception e) {
					reportRuleError('''Could not evaluate EL variable «name»: «e.message»''')
					new ElVariableError(name)
				}
			]
			
			
			result
		]
	}

	override apply(Object p) {
		eval(p)
	}
	
	override apply() {
		eval(currentSrc)
	}
	
}
