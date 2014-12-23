package de.stefanocke.japkit.rules

import de.stefanocke.japkit.el.ElVariableError
import de.stefanocke.japkit.services.ExtensionRegistry
import de.stefanocke.japkit.services.TypeElementNotFoundException
import de.stefanocke.japkit.services.TypesRegistry
import de.stefanocke.japkit.util.MoreCollectionExtensions
import java.util.ArrayList
import java.util.Collections
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.type.TypeMirror
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtext.xbase.lib.Functions.Function0
import org.eclipse.xtext.xbase.lib.Functions.Function1

import static extension de.stefanocke.japkit.util.MoreCollectionExtensions.*

@Data
class ELVariableRule extends AbstractRule implements Function1<Object, Object>,  Function0<Object> {
	 
	String name
	boolean ifEmpty
	String expr
	String lang
	Class<?> type


	//TODO: Das könnten auch direkt PropertyFilter sein, aber im Moment ist die Trigger Anntoation Teil ihres State...
	AnnotationMirror[] propertyFilterAnnotations

	TypeMirror annotationToRetrieve
	ElementMatcher matcher

	new(AnnotationMirror elVarAnnotation) {
		super(elVarAnnotation, null)
		name = elVarAnnotation.value("name", String);
		
		ifEmpty = elVarAnnotation.value("ifEmpty", Boolean);
		expr = elVarAnnotation.value("expr", String);
		lang = elVarAnnotation.value("lang", String);
		type = Class.forName(elVarAnnotation.value("type", TypeMirror).asElement.qualifiedName.toString);

		//TODO: Use Rule factory. But this is not possible, if we use triggerAnnotation. Reconsider...
		propertyFilterAnnotations = elVarAnnotation.value("propertyFilter", typeof(AnnotationMirror[]))

		annotationToRetrieve = elVarAnnotation.value("annotation", TypeMirror)

		matcher = elVarAnnotation.value("matcher", typeof(AnnotationMirror[])).map[createElementMatcher].singleValue
		
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

					//Be default, the value is the current src. This is useful for matcher 
					var Object value = currentSrc

					value = if (!expr.nullOrEmpty) {
						eval(expr, lang, type);
					} else if (!propertyFilterAnnotations.nullOrEmpty) {

						//TODO: Rule caching?
						val propertyFilters = propertyFilterAnnotations.map[new PropertyFilter(it)]
						propertyFilters.map[getFilteredProperties()].flatten.toList

					} else {
						value
					}

					value = if (matcher != null) {
						if (value instanceof Iterable<?>) {
							matcher.filter(value)
						} else if (value instanceof Element) {
							matcher.matches(value)
						} else {
							throw new IllegalArgumentException(
								'''If matcher is set, expr must yield an element collection or an element, but not «value»''');
						}
					} else {
						value
					}

					val valueForVariable = if (annotationToRetrieve == null) {
							value
						} else {
							value?.retrieveAnnotationMirrors(annotationToRetrieve.qualifiedName)
						}

					valueForVariable
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

	def private dispatch Object retrieveAnnotationMirrors(Iterable<?> iterable, String annotationFqn) {
		new ArrayList(iterable.map[retrieveAnnotationMirrors(annotationFqn)].filter[it != null].toList)
	}

	def private dispatch AnnotationMirror retrieveAnnotationMirrors(TypeMirror t, String annotationFqn) {
		t.asElement.annotationMirror(annotationFqn)
	}

	def private dispatch AnnotationMirror retrieveAnnotationMirrors(Element e, String annotationFqn) {
		e.annotationMirror(annotationFqn)
	}

	def private dispatch Object retrieveAnnotationMirrors(Object object, String annotationFqn) {
		throw new IllegalArgumentException('''Cannot retrieve annotation «annotationFqn» for «object»''')
	}

	override apply(Object p) {
		eval(p)
	}
	
	override apply() {
		eval(currentSrc)
	}
	
}
