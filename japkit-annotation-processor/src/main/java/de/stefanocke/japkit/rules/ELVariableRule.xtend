package de.stefanocke.japkit.rules

import de.stefanocke.japkit.el.ELSupport
import de.stefanocke.japkit.el.ElVariableError
import de.stefanocke.japkit.util.MoreCollectionExtensions
import java.util.ArrayList
import java.util.Collections
import java.util.List
import java.util.Set
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.TypeElement
import javax.lang.model.type.TypeMirror
import org.eclipse.xtext.xbase.lib.Functions.Function0
import org.eclipse.xtext.xbase.lib.Functions.Function1

import static extension de.stefanocke.japkit.util.MoreCollectionExtensions.*

@Data
class ELVariableRule extends AbstractRule implements Function1<Object, Object>,  Function0<Object> {
	val extension ElementsExtensions elements = ExtensionRegistry.get(ElementsExtensions)

	extension TypesExtensions types = ExtensionRegistry.get(TypesExtensions)
	val extension MessageCollector = ExtensionRegistry.get(MessageCollector)
	extension GenerateClassContext = ExtensionRegistry.get(GenerateClassContext)
	extension ELSupport = ExtensionRegistry.get(ELSupport)
	val extension RuleFactory = ExtensionRegistry.get(RuleFactory)
	val extension TypeResolver = ExtensionRegistry.get(TypeResolver)

	String name
	boolean ifEmpty
	boolean isFunction
	String expr
	String lang
	Class<?> type
	Set<TypeMirror> requiredTriggerAnnotation


	//TODO: Das könnten auch direkt PropertyFilter sein, aber im Moment ist die Trigger Anntoation Teil ihres State...
	AnnotationMirror[] propertyFilterAnnotations

	//TODO: TypeQuery Rule?
	AnnotationMirror typeQuery
	TypeMirror annotationToRetrieve
	ElementMatcher matcher

	new(AnnotationMirror elVarAnnotation) {
		super(elVarAnnotation, null)
		_name = elVarAnnotation.value("name", String);
		
		_ifEmpty = elVarAnnotation.value("ifEmpty", Boolean);
		_isFunction = elVarAnnotation.value("isFunction", Boolean);
		_expr = elVarAnnotation.value("expr", String);
		_lang = elVarAnnotation.value("lang", String);
		_type = Class.forName(elVarAnnotation.value("type", TypeMirror).asElement.qualifiedName.toString);

		//TODO: Use Rule factory. But this is not possible, if we use triggerAnnotation. Reconsider...
		_propertyFilterAnnotations = elVarAnnotation.value("propertyFilter", typeof(AnnotationMirror[]))

		_typeQuery = elVarAnnotation.value("typeQuery", AnnotationMirror)

		_annotationToRetrieve = elVarAnnotation.value("annotation", TypeMirror)

		_matcher = elVarAnnotation.value("matcher", typeof(AnnotationMirror[])).map[createElementMatcher].singleValue
		
		_requiredTriggerAnnotation = elVarAnnotation.value("requiredTriggerAnnotation", typeof(TypeMirror[])).toSet

		
	}

	def void putELVariable() {
		
			if (isFunction) {
				valueStack.put(name, this)
			} else {
				val exisitingValue = valueStack.get(name)
				if(ifEmpty && exisitingValue!==null && !exisitingValue.emptyVar) return
				
				val value = eval(currentSrc)
				valueStack.put(name, value)
			}
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

					} else if (typeQuery != null) {
						evalTypeQuery(typeQuery)
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

					if (!requiredTriggerAnnotation.nullOrEmpty) {
						if (value instanceof TypeElement) {
							value = generatedTypeElementAccordingToTriggerAnnotation(value, requiredTriggerAnnotation,
								false)
						} else if (value instanceof TypeMirror) {
							value = generatedTypeAccordingToTriggerAnnotation(value, requiredTriggerAnnotation, false)
						}

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
					new ElVariableError(_name)
				} catch (Exception e) {

					reportRuleError('''Could not evaluate EL variable «name»: «e.message»''')
					
					new ElVariableError(_name)
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

	def private evalTypeQuery(AnnotationMirror typeQuery) {
		val triggerAnnotation = typeQuery.value("annotation", TypeMirror);
		val shadow = typeQuery.value("shadow", Boolean);
		val unique = typeQuery.value("unique", Boolean);
		val filterAV = typeQuery.value("filterAV", String);
		val inExpr = typeQuery.value("inExpr", String);
		val inExprLang = typeQuery.value("inExprLang", String);

		//TODO: constant
		val ac = currentAnnotatedClass

		val inTypesSet = if (filterAV.nullOrEmpty)
				emptySet
			else {
				val inTypes =  eval(inExpr, inExprLang, Object)
				

				(if (inTypes instanceof Iterable<?>) {
					(inTypes as Iterable<TypeMirror>).toSet
				} else {
					Collections.singleton(inTypes as TypeMirror)
				}).map[qualifiedName].toSet

			}

		val types = ExtensionRegistry.get(TypesRegistry).
			findAllTypeElementsWithTriggerAnnotation(ac, triggerAnnotation.qualifiedName, shadow).filter [ te |
				filterAV.nullOrEmpty || {
					val t = te.annotationMirror(triggerAnnotation.qualifiedName).annotationValuesByNameUnwrapped.apply(filterAV)
					if(t instanceof TypeMirror){
						inTypesSet.contains(t.qualifiedName)				
					} else if(t instanceof List<?>){
						//if both values are sets, we return true if they are not disjoint. Does this make any sense? 
						val filterTypes = t.filterInstanceOf(TypeMirror).map[qualifiedName].toSet
						filterTypes.retainAll(inTypesSet)
						!filterTypes.empty
					} else {
						throw new IllegalArgumentException("filterAV must be a type or a set of types, but not "+t);
					}
				}
			].map[asType];

		if(unique) MoreCollectionExtensions.singleValue(types) else types

	}
	
	override apply(Object p) {
		eval(p)
	}
	
	override apply() {
		eval(currentSrc)
	}
	
}
