package de.stefanocke.japkit.support.el

import de.stefanocke.japkit.support.ElementsExtensions
import de.stefanocke.japkit.support.ExtensionRegistry
import de.stefanocke.japkit.support.GenerateClassContext
import de.stefanocke.japkit.support.MessageCollector
import de.stefanocke.japkit.support.PropertyFilter
import de.stefanocke.japkit.support.RuleFactory
import de.stefanocke.japkit.support.SwitchRule
import de.stefanocke.japkit.support.TypeElementNotFoundException
import de.stefanocke.japkit.support.TypesExtensions
import de.stefanocke.japkit.support.TypesRegistry
import de.stefanocke.japkit.util.MoreCollectionExtensions
import java.util.ArrayList
import java.util.Collections
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.type.TypeMirror

import static extension de.stefanocke.japkit.util.MoreCollectionExtensions.*
import de.stefanocke.japkit.support.ElementMatcher

@Data
class ELVariableRule {
	val extension ElementsExtensions elements = ExtensionRegistry.get(ElementsExtensions)

	extension TypesExtensions types = ExtensionRegistry.get(TypesExtensions)
	val extension MessageCollector = ExtensionRegistry.get(MessageCollector)
	extension GenerateClassContext = ExtensionRegistry.get(GenerateClassContext)
	extension ELSupport = ExtensionRegistry.get(ELSupport)
	val extension RuleFactory = ExtensionRegistry.get(RuleFactory)

	AnnotationMirror elVarAnnotation
	String name
	boolean isFunction
	String triggerAv
	String expr
	String lang
	Class<?> type
	boolean setInShadowAnnotation

	//TODO: Das könnten auch direkt PropertyFilter sein, aber im Moment ist die Trigger Anntoation Teil ihres State...
	AnnotationMirror[] propertyFilterAnnotations

	//TODO: TypeQuery Rule?
	AnnotationMirror typeQuery
	TypeMirror annotationToRetrieve
	ElementMatcher matcher
	SwitchRule switcher

	new(AnnotationMirror elVarAnnotation) {
		_elVarAnnotation = elVarAnnotation

		_name = elVarAnnotation.value("name", String);
		_isFunction = elVarAnnotation.value("isFunction", Boolean);
		_triggerAv = elVarAnnotation.value("triggerAV", String);
		_expr = elVarAnnotation.value("expr", String);
		_lang = elVarAnnotation.value("lang", String);
		_type = Class.forName(elVarAnnotation.value("type", TypeMirror).asElement.qualifiedName.toString);

		_setInShadowAnnotation = elVarAnnotation.value("setInShadowAnnotation", Boolean);

		//TODO: Use Rule factory. But this is not possible, if we use triggerAnnotation. Reconsider...
		_propertyFilterAnnotations = elVarAnnotation.value("propertyFilter", typeof(AnnotationMirror[]))

		_typeQuery = elVarAnnotation.value("typeQuery", AnnotationMirror)

		_annotationToRetrieve = elVarAnnotation.value("annotation", TypeMirror)

		_matcher = elVarAnnotation.value("matcher", typeof(AnnotationMirror[])).map[createElementMatcher].singleValue

		//TODO: Use Rulefactory
		_switcher = elVarAnnotation.value("switcher", typeof(AnnotationMirror[])).map[new SwitchRule(it)].singleValue
	}

	def void putELVariable(ValueStack vs, Element element, AnnotationMirror triggerAnnotation) {
		try {
			if (isFunction) {
				vs.put(name, this)
			} else {
				val value = eval(vs, element, triggerAnnotation)
				vs.put(name, value)
			}
		} catch (TypeElementNotFoundException tenfe) {
			ExtensionRegistry.get(TypesRegistry).handleTypeElementNotFound(tenfe, currentAnnotatedClass)
		} catch (Exception e) {
			//Idee: Hier auf dem ValueStack speziell markieren, dass es mit der Varaiable einen Fehler gab
			//Der ValueStack kann dann beim Zugriff auf die Variable eine spezielle Exception werfen, die 
			//dann dazu genutzt werden kann die Flut an gemeldeten Folgefehlern einzudämmen. 
			reportError(
				'''Could not evaluate EL variable «name»: «e.message» EL expression: «expr», Property Filter: «propertyFilterAnnotations».''',
				e, element, elVarAnnotation, null)
		}
	}

	def Object eval(Element element) {
		eval(valueStack, element, currentAnnotation)
	}
	
	def Object filter(Iterable<? extends Element> collection) {
		collection.filter[eval(it) as Boolean]
	}
	
	def Object map(Iterable<? extends Element> collection) {
		collection.map[eval(it)]
	}
	
	def Object eval(ValueStack vs, Element element, AnnotationMirror triggerAnnotation) {

		pushCurrentMetaAnnotation(elVarAnnotation)
		try {

			var Object av
			
			//Be default, the value is the current element. This is useful for matcher and retrieveAV
			var Object value = element
			
			value = if (!triggerAv.nullOrEmpty && {
					av = currentAnnotation.value(triggerAv, type);
					!av.nullOrEmptyAV
				}) {

					av

				} else if (!expr.nullOrEmpty) {
					vs.scope(element) [ //TODO: Das ist etwas ineffizient. Es würde reichen, diesen Scope aufzumachen, wann immer das ruleSourceElement bestimmt wird
						eval(vs, expr, lang, type);
					]					

				} else if (!propertyFilterAnnotations.nullOrEmpty) {

					//TODO: Rule caching?
					val propertyFilters = propertyFilterAnnotations.map[new PropertyFilter(triggerAnnotation, it)]
					propertyFilters.map[getFilteredProperties(currentAnnotatedClass, currentGeneratedClass)].flatten.
						toList

				} else if (typeQuery != null) {
					evalTypeQuery(vs, typeQuery, element)
				} else {
					value
				}
				
			value = if (matcher != null) {
					if (value instanceof Iterable<?>) {
						matcher.filter(value as Iterable<?>)
					} else if(value instanceof Element) {
						matcher.matches(value as Element)
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
					value.retrieveAnnotationMirrors(annotationToRetrieve.qualifiedName)
				}

			//Das hier funktioniert so nicht, wenn isFunction true ist. Macht aber nichts.
			if (setInShadowAnnotation && !triggerAv.nullOrEmpty) {

				//TODO: Es fürfte ungewöhnlich sein, hier einen AnnotationMirror zu setzen. Daher nehmen wir value anstatt valueForVariable.
				//Ist das sinnvoll oder eher verwirrend? 
				vs.getVariablesForShadowAnnotation().put(triggerAv, value)
			}

			valueForVariable

		} finally {
			popCurrentMetaAnnotation()
		}

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

	def evalTypeQuery(ValueStack vs, AnnotationMirror typeQuery, Element element) {
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
				val inTypes = vs.scope(element) [ //TODO: Das ist etwas ineffizient. Es würde reichen, diesen Scope aufzumachen, wann immer das ruleSourceElement bestimmt wird
					eval(vs, inExpr, inExprLang, Object);
				]

				(if (inTypes instanceof Iterable<?>) {
					(inTypes as Iterable<TypeMirror>).toSet
				} else {
					Collections.singleton(inTypes as TypeMirror)
				}).map[qualifiedName].toSet

			}

		val types = ExtensionRegistry.get(TypesRegistry).
			findAllTypeElementsWithTriggerAnnotation(ac, triggerAnnotation.qualifiedName, shadow).filter [ te |
				filterAV.nullOrEmpty || {
					val t = te.annotationMirror(triggerAnnotation.qualifiedName).value(filterAV, TypeMirror)
					inTypesSet.contains(t.qualifiedName)
				}
			].map[asType];

		if(unique) MoreCollectionExtensions.singleValue(types) else types

	}
}
