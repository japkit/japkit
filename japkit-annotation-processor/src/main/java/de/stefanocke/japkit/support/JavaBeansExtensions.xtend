package de.stefanocke.japkit.support

import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.TypeElement
import javax.lang.model.element.VariableElement
import javax.lang.model.type.TypeMirror

class JavaBeansExtensions {
	extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val extension TypesExtensions = ExtensionRegistry.get(TypesExtensions)

	def getterName(CharSequence propertyName, boolean isBoolean) {
		(if(isBoolean) "is" else "get") + propertyName.toString.toFirstUpper
	}

	def setterName(Property p) {
		"set" + p.name.toString.toFirstUpper
	}
	
	def setterName(CharSequence propertyName) {
		"set" + propertyName.toString.toFirstUpper
	}

	def setterName(VariableElement field) {
		setterName(field.simpleName)
	}

	def getterName(CharSequence propertyName, TypeMirror type) {
		getterName(propertyName, type.isBoolean)
	}

	def getterName(VariableElement field) {
		getterName(field.simpleName, field.asType)
	}
	
	def getterName(Property p) {
		getterName(p.name, p.type)
	}

	def isBooleanGetterWithIs(extension ExecutableElement method) {
		method.simpleName.toString.startsWith("is") && returnType.isBoolean && parameters.length == 0
	}

	def isGetterWithGet(extension ExecutableElement method) {
		method.simpleName.toString.startsWith("get") && parameters.length == 0
	}

	def isGetter(extension ExecutableElement method) {
		method.isGetterWithGet || method.isBooleanGetterWithIs
	}

	def isSetter(extension ExecutableElement method) {
		method.simpleName.toString.startsWith("set") && parameters.length == 1
	}

	def isAccessor(ExecutableElement method) {
		method.isSetter || method.isGetter
	}

	//TODO: Type parameter replacements?
	def toProperty(extension ExecutableElement method) {
		if (method.isGetter) {
			val int offset = if(method.isBooleanGetterWithIs) 2 else 3
			val propertyName = simpleName.subSequence(offset, simpleName.length).toString.toFirstLower
			new Property(returnType, propertyName, method, null, null)
		} else if (method.isSetter) {
			val propertyName = simpleName.subSequence(3, simpleName.length).toString.toFirstLower
			new Property(parameters.get(0).asType, propertyName, null, method, null)
		} else {
			throw new IllegalArgumentException("Method is no getter or setter: " + method)
		}

	}
	
	//TODO: Type parameter replacements?
	def toProperty(VariableElement field){
		new Property(field.asType, field.simpleName.toString, null, null, field);
	}

	def getters(Iterable<ExecutableElement> methods){
		methods.filter[isGetter]
	}
	
	def setters(Iterable<ExecutableElement> methods){
		methods.filter[isSetter]
	}
	
	def isSetterFor(extension ExecutableElement method, Property p){
		method.isSetter 
		&& simpleName.contentEquals(p.name.setterName) 
		&& parameters.get(0).hasType(p.type)
	}
	
	def isGetterFor(extension ExecutableElement method, Property p){
		method.isGetter 
		&& simpleName.contentEquals(p.getterName) 
		&& method.returnType.isSameType(p.type)
	}
	
	def settersFor(Iterable<ExecutableElement> methods, Property p){
		methods.filter[isSetterFor(p)]
	}
	
	/**Searches the field for a property. If not found in the type itself, its supertype is considered. 
	 */	
	def fieldFor(TypeElement typeElement, Property p, String stopSuperclass){
		typeElement.findFirstInTypeAndSuperclasses(stopSuperclass)[
			declaredFields.filter[simpleName.contentEquals(p.name) && hasType(p.type)].head
		]
	}
	 
	/**Find the properties of a class by their getters. */
	def propertiesFromGetters(TypeElement typeElement, String stopSuperclass) {
		val methods = typeElement.allMethods(stopSuperclass)
		methods.getters
			.map[toProperty]
			.map[withSetter(methods.settersFor(it).head)]
			.map[withField(typeElement.fieldFor(it, stopSuperclass))]

	}
	
	def propertiesFromFields(TypeElement typeElement){
		val methods = typeElement.declaredMethods
		typeElement.declaredFields.map[toProperty]
			.map[
				withSetter(methods.settersFor(it).head)
				.withGetter(methods.filter[m | m.isGetterFor(it)].head)
			]
	}
	
	def properties(TypeElement typeElement, String stopSuperclass, boolean fromFields) {
		if(fromFields) typeElement.propertiesFromFields else typeElement.propertiesFromGetters(stopSuperclass)
	}
	
}
