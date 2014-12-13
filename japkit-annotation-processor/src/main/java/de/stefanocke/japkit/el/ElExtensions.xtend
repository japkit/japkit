package de.stefanocke.japkit.el

import de.stefanocke.japkit.model.EmitterContext
import de.stefanocke.japkit.rules.JavaBeansExtensions
import de.stefanocke.japkit.services.ElementsExtensions
import de.stefanocke.japkit.services.ExtensionRegistry
import de.stefanocke.japkit.services.GenerateClassContext
import de.stefanocke.japkit.services.TypesExtensions
import de.stefanocke.japkit.services.TypesRegistry
import de.stefanocke.japkit.util.MoreCollectionExtensions
import java.util.Map
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.TypeElement
import javax.lang.model.type.TypeMirror
import org.eclipse.xtext.xbase.lib.Functions.Function0
import org.eclipse.xtext.xbase.lib.Functions.Function1

import static de.stefanocke.japkit.services.ExtensionRegistry.*

class ElExtensions {

	def static Map<String, Object> getValueStack() {
		ExtensionRegistry.get(ELSupport).valueStack
	}


	def static getAsElement(TypeMirror type) {
		type.asElement()
	}

	def static asElement(TypeMirror type) {
		val extension TypesExtensions = get(TypesExtensions)
		type.asElement
	}
	
	def static isSame(TypeMirror type1, TypeMirror type2){
		val extension TypesExtensions = get(TypesExtensions)
		type1.isSameType(type2)
	}
	
	def static hasType(Element e, CharSequence fqn){
		val extension TypesExtensions = get(TypesExtensions)
		e.asType.qualifiedName.contentEquals(fqn)
	}

	def static getSingleValueType(Element e) {
		val extension ElementsExtensions = get(ElementsExtensions)
		val extension TypesExtensions = get(TypesExtensions)
		e.srcType.singleValueType
	}
	
	

	/** The annotations of the element as Function from annotation class name to annotation, where annotation is again a function from
	 * annotation value name to annotation value.  "At" == @ == Annotation 
	 */
	def static getAt(Element e) {
		e.getAt(valueStack)
	}
	
	def private static getAt(Element e, Map<String, Object> context) {
		val extension ElementsExtensions = get(ElementsExtensions)
		val extension GenerateClassContext = get(GenerateClassContext)
		val packageForSimpleNames = currentTriggerAnnotation.annotationAsTypeElement.package.qualifiedName.toString
		e.annotationsByName(packageForSimpleNames);
	}
	
	def static dispatch getSingleValue(Iterable<?> values){
		MoreCollectionExtensions.singleValue(values)
	}
	
	//Ein Workaround. Irgendwo in den AV-Mappings wird noch nicht korrekt in eine Collection eingepackt, dadurch tauchen in genrierten
	//Annotation Values manchmal Einzelwerte auf, obwohl der Typ des AV ein Array ist... 
	def static dispatch getSingleValue(Object value){
		value
	}
	
//	def static findAllTypeElementsWithTrigger(String triggerFqn, boolean shadow) {
//		findAllTypeElementsWithTrigger(triggerFqn, shadow, context)
//	}
//	
//	def static findAllTypeElementsWithTrigger(String triggerFqn, boolean shadow, Map<String, Object> context) {
//		val TypesRegistry tr = get(TypesRegistry)
//		val annotatedClass = context.get("currentAnnotatedClass")
//		if(annotatedClass==null){
//			throw new IllegalArgumentException("No current annotated class.")
//		}
//		tr.findAllTypeElementsWithTriggerAnnotation(annotatedClass as TypeElement, triggerFqn, shadow);
//	}

	/**
	 * An Xtend closure with one (String) parameter can be used like "closure.fooBar". In this case, the closure is called with "foobar" as param.
	 *  (F.E. annotationsByName above returns such a closure. So, one can do things like annotatedClass.at.JapkitEntity 
	 *  to get a JapkitEntity annotation) 
	 */
	 //Note: Also not documented, this works with Groovy extension modules... (getProperty() does NOT work.)
	def static get(Function1<String, ? extends Object> function, String propertyName) {
		function.apply(propertyName)
	}

	/**
	 * Allows to write something like "annotation.entityClass" to access the annotation value "entityClass" of the annotation
	 */
	def static get(AnnotationMirror am, String avName) {
		val extension ElementsExtensions = get(ElementsExtensions)
		am.annotationValuesByNameUnwrapped.apply(avName)
	}
	
	/**
	 * Allows to apply functions on the values stack like this: element.functionName
	 */
	def static get(Element e, String functionName,  Map<String, Object> context) {
		val function = context.get(functionName)
		if(function != null && function instanceof Function1<?,?>){
			(function as Function1<Element,?>).apply(e)
		} else {
			//TODO: Prop Not Found Exception to allow default resolving?
			//Mit Groovy scheint das zu funktionieren, da die get Methode anscheinden die letzte ist, die aufgerufen wird
			throw new ELPropertyNotFoundException('''No function with name «functionName» is on value stack and there is also no other property of element «e.simpleName» with this name.''')
		}
	}
	
	def static get(Element e, String functionName) {
		get(e, functionName, valueStack)
	}
	

	def static getProperties(TypeElement e){
		val extension JavaBeansExtensions = get(JavaBeansExtensions)
		e.properties(Object.name, false)
	}
	
	def static getDeclaredFields(TypeElement type) {
		val extension ElementsExtensions = get(ElementsExtensions)
		type.declaredFields()
	}

	def static getDeclaredMethods(TypeElement type) {
		val extension ElementsExtensions = get(ElementsExtensions)
		type.declaredMethods()
	}

	def static getDeclaredConstructors(TypeElement type) {
		val extension ElementsExtensions = get(ElementsExtensions)
		type.declaredConstructors()
	}

	def static getDeclaredTypes(TypeElement type) {
		val extension ElementsExtensions = get(ElementsExtensions)
		type.declaredTypes()
	}


	private def static getEmitterContext(Map<String, Object> context) {
		context.get("ec") as EmitterContext
	}
	/**
	 * Gets TypeMirror for qualified name and adds import statement,if possible.
	 */
	//TODO: Good name?
	def private static getAsType(String qualName, Map<String, Object> context) {
		get(TypesRegistry).findTypeElement(qualName).asType.name
	}
	
	def static getAsType(String qualName) {
		qualName.getAsType(valueStack)
	}
	
	/**Gets the name of a type in a way usable in code bodies. If possible, an according import statement is added.*/
	def private static getName(TypeMirror type, Map<String, Object> context) {
		getEmitterContext(context)?.staticTypeRef(type) ?: ExtensionRegistry.get(TypesExtensions).qualifiedName(type)
	}
	
	def static getName(TypeMirror type) {
		type.getName(valueStack)
	}

	def private static getCode(TypeMirror type, Map<String, Object> context){
		getEmitterContext(context)?.typeRef(type) ?: type.toString
	}
	
	def static getCode(TypeMirror type){
		getCode(type, valueStack)
	}
	
	def static getToFirstUpper(CharSequence s) {
		s.toString.toFirstUpper
	}

	def static getToFirstLower(CharSequence s) {
		s.toString.toFirstLower
	}
	
	def static Element findByName(Iterable<?> elements, CharSequence name){
		MoreCollectionExtensions.filterInstanceOf(elements, Element).findFirst[simpleName.contentEquals(name)]
	}
	
	
	def static invokeMethod(Object base, String name, Object params){
		
		invokeMethod(base, name, if(params instanceof Object[]) params else #[params] , valueStack)
	}
	
	def static invokeMethod(Object base, String name, Object[] params, Map<String, Object> contextMap){
		val function =  contextMap.get(name)
		if(function == null)
		throw new ELMethodException('''No function with name «name» is on value stack and there is also no other property of element «base» with this name.''')	

		invoke(function, base, params)
				
	}
	
	def static invoke(Object functionObject, Object base, Object[] params) {
		if(functionObject instanceof Function0<?>){
			if(base==null && params.empty){
				return functionObject.apply
			}			
		} 
		if(functionObject instanceof Function1){
			if(base!=null && params.empty){
				return functionObject.apply(base)
			}
			if(base==null && params.size==1){
				return functionObject.apply(params.get(0))
			}
		}
		
		throw new ELMethodException('''«functionObject» is no function or could could not be applied to base «base» and params «params».''')
	}
	
	
	//Provide the extensions as Collections of closures...
	public static val ElExtensionPropertiesAndMethods extensions  = new ElExtensionPropertiesAndMethods() => [
		registerExtensionProperties
		registerExtensionMethods
	]
	

	//TODO: Das kann man bestimmt auch fein generieren... :)
	def static registerExtensionProperties(ElExtensionPropertiesAndMethods elExtensions) {
		elExtensions.registerProperty(TypeMirror, "asElement", [context, type|type.asElement()])

		elExtensions.registerProperty(Element, "singleValueType", [context, e|e.singleValueType])

		elExtensions.registerProperty(Element, "at", [context, e| e.getAt(context)])
		
		elExtensions.registerProperty(Object, "singleValue", [context, values| values.getSingleValue])

		elExtensions.registerGetProperty(Function1, [context, closure, propertyName|closure.get(propertyName)])

		elExtensions.registerGetProperty(AnnotationMirror, [context, am, avName|am.get(avName)])
		
		elExtensions.registerGetProperty(Element, [context, e, functionName|e.get(functionName, context)])

		elExtensions.registerProperty(String, "asType", [context, qualName| qualName.getAsType(context)])
		
		elExtensions.registerProperty(TypeMirror, "name", [context, type| type.getName(context)])
		
		elExtensions.registerProperty(TypeMirror, "code", [context, type| type.getCode(context)])

		elExtensions.registerProperty(CharSequence, "toFirstUpper", [context, s|s.toFirstUpper])

		elExtensions.registerProperty(CharSequence, "toFirstLower", [context, s|s.toFirstLower])
		
		elExtensions.registerProperty(TypeElement, "properties", [context, t|t.properties])
		
		elExtensions.registerProperty(TypeElement, "declaredFields", [context, t|t.declaredFields])
		
		elExtensions.registerProperty(TypeElement, "declaredConstructors", [context, t|t.declaredConstructors])
		
		elExtensions.registerProperty(TypeElement, "declaredTypes", [context, t|t.declaredTypes])
		
		elExtensions.registerProperty(TypeElement, "declaredMethods", [context, t|t.declaredMethods])
	}

	def static registerExtensionMethods(ElExtensionPropertiesAndMethods elExtensions) {
		elExtensions.registerMethod(TypeMirror, "asElement", [context, type, paramTypes, params|type.asElement()])
		
		elExtensions.registerMethod(TypeMirror, "isSame", [context, type, paramTypes, params|type.isSame(params.get(0) as TypeMirror)])
		
		elExtensions.registerMethod(Element, "hasType", [context, e, paramTypes, params|e.hasType(params.get(0) as CharSequence)])
		
		elExtensions.registerMethod(Iterable, "findByName", [context, elements, paramTypes, params|elements.findByName(params.get(0) as CharSequence)])
		
//		elExtensions.registerMethod(String, "findAllTypeElementsWithTrigger", [context, triggerFqn, paramTypes, params|
//			findAllTypeElementsWithTrigger(triggerFqn, (params as Object[]).get(0) as Boolean, context)
//		])
	}

}
