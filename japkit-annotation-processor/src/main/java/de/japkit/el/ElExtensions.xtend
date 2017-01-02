package de.japkit.el

import de.japkit.model.EmitterContext
import de.japkit.rules.AbstractFunctionRule
import de.japkit.rules.JavaBeansExtensions
import de.japkit.services.ElementsExtensions
import de.japkit.services.ExtensionRegistry
import de.japkit.services.GenerateClassContext
import de.japkit.services.TypesExtensions
import de.japkit.services.TypesRegistry
import de.japkit.util.MoreCollectionExtensions
import java.util.Map
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.TypeElement
import javax.lang.model.type.DeclaredType
import javax.lang.model.type.TypeMirror
import org.apache.commons.lang3.reflect.FieldUtils
import org.eclipse.xtext.xbase.lib.Functions.Function0
import org.eclipse.xtext.xbase.lib.Functions.Function1

import static de.japkit.services.ExtensionRegistry.*
import org.apache.commons.lang3.reflect.MethodUtils

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
	
	/**
	 * name as alias for getSimpleName().toString().
	 */
	def static getName(Element e) {
		e.simpleName.toString
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
	
	def static dispatch getSingleValue(Object value){
		value
	}

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
	
	def static getProperties(DeclaredType t){
		get(TypesExtensions).asElement(t).properties
	}
	
	def static getDeclaredFields(TypeElement type) {
		val extension ElementsExtensions = get(ElementsExtensions)
		type.declaredFields()
	}
	
	def static getDeclaredFields(DeclaredType t) {
		get(TypesExtensions).asElement(t).declaredFields
	}

	def static getDeclaredMethods(TypeElement type) {
		val extension ElementsExtensions = get(ElementsExtensions)
		type.declaredMethods()
	}
	
	def static getDeclaredMethods(DeclaredType t) {
		get(TypesExtensions).asElement(t).declaredMethods
	}

	def static getDeclaredConstructors(TypeElement type) {
		val extension ElementsExtensions = get(ElementsExtensions)
		type.declaredConstructors()
	}
	
	def static getDeclaredConstructors(DeclaredType t) {
		get(TypesExtensions).asElement(t).declaredConstructors
	}	
	
	def static getDeclaredTypes(TypeElement type) {
		val extension ElementsExtensions = get(ElementsExtensions)
		type.declaredTypes()
	}
	
	def static getDeclaredTypes(DeclaredType t) {
		get(TypesExtensions).asElement(t).declaredTypes
	}
	
	def static getSimpleName(DeclaredType t){
		get(TypesExtensions).asElement(t).simpleName
	}
	
	def static getQualifiedName(DeclaredType t){
		get(TypesExtensions).asElement(t).qualifiedName
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
		val Object[] paramList = if(params instanceof Object[]) params else #[params] 
		
		invokeMethod(base, name, null , paramList, valueStack)
	}
	
	def static invokeMethod(Object base, String name, Class<?>[] paramTypes, Object[] params,
		Map<String, Object> contextMap) {

		val invokeMethodClosure = registry.findInvokeMethodClosure(base)

		try {
			if (invokeMethodClosure != null) {
				return invokeMethodClosure.apply(contextMap, base, name, paramTypes, params)
			}

		} catch (ELMethodException e) {
		}

		val function = contextMap.get(name)
		if (function == null)
			throw new ELMethodException('''No function with name «name» is on value stack and there is also no other property of element «base» with this name.''')

		invoke(function, base, params)

	}
	
	def static invoke(Object functionObject, Object base, Object[] params) {
		if(functionObject instanceof AbstractFunctionRule<?>){
			if(functionObject.mustBeCalledWithParams){
				if(base==null){
					return functionObject.evalWithParams(params)
				} else {
					val paramsWithBase = newArrayList(base)
					paramsWithBase.addAll(params.toList)
					return functionObject.evalWithParams(params)
				}
			}
		}
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
	public static val ElExtensionsRegistry registry  = new ElExtensionsRegistry() => [
		registerExtensionProperties
		registerExtensionMethods
	]
	

	//TODO: Das kann man bestimmt auch fein generieren... :)
	def static registerExtensionProperties(ElExtensionsRegistry registry) {
		registry.registerProperty(TypeMirror, "asElement", [context, type|type.asElement()])

		registry.registerProperty(Element, "singleValueType", [context, e|e.singleValueType])

		registry.registerProperty(Element, "at", [context, e| e.getAt(context)])
		
		registry.registerProperty(Element, "name", [context, e| e.name])
		
		registry.registerProperty(Object, "singleValue", [context, values| values.getSingleValue])

		registry.registerGetProperty(Function1, [context, closure, propertyName|closure.get(propertyName)])

		registry.registerGetProperty(AnnotationMirror, [context, am, avName|am.get(avName)])
		
		registry.registerGetProperty(Element, [context, e, functionName|e.get(functionName, context)])
		
		// Allow access to static fields of "beanClasses" 
		registry.registerGetProperty(Class, [ context, c, staticFieldName |
			try {
				FieldUtils.readStaticField(c, staticFieldName)
			} catch (IllegalArgumentException e) {
				throw new ELPropertyNotFoundException(e.message);
			}
		])

		registry.registerProperty(String, "asType", [context, qualName| qualName.getAsType(context)])
		
		//TODO: Deprecate that in favor of code?  But this one is used in a static sense...
		registry.registerProperty(TypeMirror, "name", [context, type| type.getName(context)])
		
		registry.registerProperty(TypeMirror, "code", [context, type| type.getCode(context)])

		registry.registerProperty(CharSequence, "toFirstUpper", [context, s|s.toFirstUpper])

		registry.registerProperty(CharSequence, "toFirstLower", [context, s|s.toFirstLower])
		
		registry.registerProperty(TypeElement, "properties", [context, t|t.properties])
		
		registry.registerProperty(DeclaredType, "properties", [context, t|t.properties])
		
		registry.registerProperty(TypeElement, "declaredFields", [context, t|t.declaredFields])
		
		registry.registerProperty(TypeElement, "declaredConstructors", [context, t|t.declaredConstructors])
		
		registry.registerProperty(TypeElement, "declaredTypes", [context, t|t.declaredTypes])
		
		registry.registerProperty(TypeElement, "declaredMethods", [context, t|t.declaredMethods])
		
		registry.registerProperty(DeclaredType, "declaredFields", [context, t|t.declaredFields])
		
		registry.registerProperty(DeclaredType, "declaredConstructors", [context, t|t.declaredConstructors])
		
		registry.registerProperty(DeclaredType, "declaredTypes", [context, t|t.declaredTypes])
		
		registry.registerProperty(DeclaredType, "declaredMethods", [context, t|t.declaredMethods])
		
		registry.registerProperty(DeclaredType, "simpleName", [context, t|t.simpleName])
		
		registry.registerProperty(DeclaredType, "qualifiedName", [context, t|t.qualifiedName])
	}

	def static registerExtensionMethods(ElExtensionsRegistry registry) {
		registry.registerMethod(TypeMirror, "asElement", [context, type, paramTypes, params|type.asElement()])
		
		registry.registerMethod(TypeMirror, "isSame", [context, type, paramTypes, params|type.isSame(params.get(0) as TypeMirror)])
		
		registry.registerMethod(Element, "hasType", [context, e, paramTypes, params|e.hasType(params.get(0) as CharSequence)])
		
		registry.registerMethod(Iterable, "findByName", [context, elements, paramTypes, params|elements.findByName(params.get(0) as CharSequence)])
		
		registry.registerInvokeMethod(Class, [context, clazz, methodName, paramTypes, params| 
			try {
				if(paramTypes == null) MethodUtils.invokeStaticMethod(clazz, methodName, params) else MethodUtils.invokeStaticMethod(clazz, methodName, params, paramTypes)
			} catch (NoSuchMethodException e) {
				throw new ELMethodException(e.message)
			}
		])
		
	}
	
	
	/**
	 * Der Key sagt, ob die Property gefunden wurde. Der Value ist der Wert der Property (kann null sein).
	 */
	def static Pair<Boolean, Object> getPropertyFromExtensions(Map<String, Object> rootProperties, Object base, String propertyName) {
		{
			val closure = registry.findPropertyClosure(base, propertyName)
		
			if (closure != null) {
				return true -> closure.apply(rootProperties, base) 
			} else {
		
				try {
					val getPropertyClosure = de.japkit.el.ElExtensions.registry.findGetPropertyClosure(base)
					if (getPropertyClosure != null) {						
						return true -> getPropertyClosure.apply(rootProperties, base, propertyName)
					} 		
				} catch (ELPropertyNotFoundException e) {
					
				}
				
			}
			false -> null
		
		}
	}
	
	def static Pair<Boolean, Object> invokeMethodFromExtensions(Map<String, Object> rootProperties, Object base,
		String methodName, Class<?>[] paramTypes, Object[] params) {
		val closure = registry.findMethodClosure(base, methodName)

		if (closure != null) {
			return true -> closure.apply(rootProperties, base, paramTypes, params)
		} else {

			try {
				return true -> ElExtensions.invokeMethod(base, methodName, paramTypes, params, rootProperties)
			} catch (ELMethodException e) {
			}		
		}
		false -> null
	}

}
