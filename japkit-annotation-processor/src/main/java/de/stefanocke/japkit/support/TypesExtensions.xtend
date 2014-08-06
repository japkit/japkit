package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenDeclaredType
import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.gen.GenTypeMirror
import java.math.BigDecimal
import java.math.BigInteger
import java.util.Calendar
import java.util.Collection
import java.util.Date
import java.util.List
import java.util.Map
import java.util.Set
import java.util.SortedSet
import javax.lang.model.element.Element
import javax.lang.model.element.ElementKind
import javax.lang.model.element.TypeElement
import javax.lang.model.type.ArrayType
import javax.lang.model.type.DeclaredType
import javax.lang.model.type.ErrorType
import javax.lang.model.type.ExecutableType
import javax.lang.model.type.PrimitiveType
import javax.lang.model.type.TypeKind
import javax.lang.model.type.TypeMirror
import javax.lang.model.type.WildcardType
import javax.lang.model.util.Elements
import javax.lang.model.util.Types

class TypesExtensions /**implements Types*/{
	Types typeUtils = ExtensionRegistry.get(Types)
	extension Elements elementUtils = ExtensionRegistry.get(Elements)
	extension TypesRegistry typesRegistry = ExtensionRegistry.get(TypesRegistry)
	
	public val OBJECT = findTypeElement(Object.name).asType

	def boxed(TypeKind typeKind) {
		typeKind.primitiveType.boxedClass.asType
	}

	def isPrimitive(TypeMirror mirror) {
		mirror.kind.primitive
	}

	static val BOXED_TYPES = #{Boolean, Byte, Short, Integer, Long, Character, Float, Double}.map[name].toSet

	def isBoxed(TypeMirror mirror) {
		BOXED_TYPES.contains(mirror?.qualifiedName)
	}

	public static val STRING = String.name

	def isString(TypeMirror mirror) {
		STRING == mirror.qualifiedName
	}

	static val TEMPORAL_TYPES = #{Calendar, Date}.map[name].toSet

	def isTemporal(TypeMirror mirror) {
		TEMPORAL_TYPES.contains(mirror?.qualifiedName)
	}

	static val MATH_TYPES = #{BigDecimal.name, BigInteger.name}

	def boolean isMath(TypeMirror mirror) {
		MATH_TYPES.contains(mirror?.qualifiedName)
	}

	def boolean collectionOrMap(TypeMirror type) {
		type.collection || type.map
	}

	static val COLLECTION_TYPES = #{Collection.name, Set.name, List.name, SortedSet.name}

	def dispatch boolean isCollection(DeclaredType type) {
		COLLECTION_TYPES.contains(type?.qualifiedName)
	}

	def dispatch boolean isCollection(TypeMirror type) {
		false
	}

	static val MAP = Map.name

	def dispatch boolean isMap(DeclaredType type) {
		type.toString.startsWith(MAP)
	}

	def dispatch boolean isMap(TypeMirror type) {
		false
	}

	static val SET = Set.name

	def dispatch boolean isSet(DeclaredType type) {
		type.toString.startsWith(SET)
	}

	def dispatch boolean isSet(TypeMirror type) {
		false
	}

	static val LIST = List.name

	def dispatch boolean isList(DeclaredType type) {
		type.toString.startsWith(LIST)
	}

	def dispatch boolean isList(TypeMirror type) {
		false
	}

	def dispatch boolean isEnum(DeclaredType type) {
		type.asTypeElement.kind == ElementKind.ENUM
	}

	def dispatch boolean isEnum(TypeMirror type) {
		false
	}

	def boolean isBoolean(TypeMirror mirror) {
		mirror == TypeKind.BOOLEAN.primitiveType || mirror == TypeKind.BOOLEAN.boxed
	}
	
	def dispatch getTypeArg(DeclaredType type, int argIndex){
		if(argIndex >= type.typeArguments.size ){
			null
		} else {
			type.typeArguments.get(argIndex)
		}
	}
	
	def dispatch getTypeArg(TypeMirror type, int argIndex){
		null
	}
	
	def private getRequiredTypeArg(TypeMirror type, int argIndex){
		val typeArg = getTypeArg(type, argIndex)
		if(typeArg==0){
			throw new IllegalArgumentException('''Type argument (pos.: «argIndex») required but not found: «type»''')
		}
		typeArg
	}
	
	
	
	def dispatch singleValueType(DeclaredType type) {
		if(type.collection){
			type.getRequiredTypeArg(0)
		} else if(type.map) {
			type.getRequiredTypeArg(1)
		} else {
			type
		}
	}
	
	def dispatch singleValueType(TypeMirror type) {
		type
	}

	def declaredType(Class<?> clazz, TypeMirror ... typeArgs) {
		declaredType(clazz.name, typeArgs)
	}

	def declaredType(String fqn, TypeMirror ... typeArgs) {
		typeUtils.getDeclaredType(getTypeElement(fqn), typeArgs)
	}

	def isJavaLangObject(TypeMirror type) {
		val typeFqn = type.toString 
		
		typeFqn== Object.name
	}

	def dispatch erasure(GenDeclaredType type) {
		if(type.typeArguments.nullOrEmpty) type else new GenDeclaredType(type.asElement as TypeElement)
	}

	def dispatch erasure(TypeMirror type) {
		typeUtils.erasure(type)
	}

	def isSameType(TypeMirror t1, TypeMirror t2) {
		if((t1 === null) || (t2 === null)){
			return false
		}

		//if(t1.containsErrorType || t1.containsErrorType){
		//There are several issues with error types that we try to workaround here:
		//Eclipse considers error types only as sameType, 
		//if they have same type binding. But this seems to be different for the obviously same type is some cases.
		//(For example, sometimes  List<SomeErrorType> != List<SomeErrorType>)
		//
		//In javac, all ErrorTypes seem to be considered as being the same.
		//
		//So, comparing their string representations seems to be the best way to compare ErrorTypes or types that contain error types.
		//
		//Alternatively, we could defer processing until the according class is generated. But by this, we would completely forbid circular dependencies between classes...
		val fqn1 = t1.qualifiedName
		val fqn2 = t2.qualifiedName
		fqn1.equals(fqn2) || {
			(t1.containsErrorType || t2.containsErrorType) &&
				//In Eclipse, ErrorTypes toString method does only yield simple name...
				(!fqn1.contains('.') || !fqn2.contains('.')) && t1.simpleName.equals(t2.simpleName)

		}

	//		} else {		
	//			val result = typeUtils.isSameType(t1, t2) 
	//			result
	//		}
	}

	def dispatch boolean containsErrorType(ErrorType t) {
		true
	}

	def dispatch boolean containsErrorType(DeclaredType t) {
		t.typeArguments.exists[containsErrorType]
	}

	def dispatch boolean containsErrorType(WildcardType t) {
		(t.extendsBound != null && t.extendsBound.containsErrorType) ||
			(t.superBound != null && t.superBound.containsErrorType)
	}

	def dispatch boolean containsErrorType(TypeMirror t) {
		false
	}

	def DeclaredType enclosingTopLevelType(DeclaredType declType) {
		if(declType.enclosingType?.kind == TypeKind.NONE) declType else (declType.enclosingType as DeclaredType).
			enclosingTopLevelType
	}

	def dispatch String qualifiedName(DeclaredType declType) {
		declType.asTypeElement.qualifiedName.toString
	}

	/** Best guess for error types... */
	def dispatch String qualifiedName(ErrorType declType) {
		if (declType.typeArguments.nullOrEmpty) {
			return typesRegistry.handleTypeElementNotFound(declType.toString, '''Cannot determine qualified name for error type «declType.toString»''')[
				typesRegistry.tryToGetFqnForErrorTypeSimpleName(declType.toString)			
			]
			
		} else {

			//In Eclipse, a generic type seem to be an ErrorType as soon as one of the type args is an ErrorType...
			//-> Try erasure instead.
			return declType.erasure.qualifiedName
		}
	}

	def dispatch String qualifiedName(ArrayType type) {
		'''«type.componentType.qualifiedName»[]'''
	}

	def dispatch String qualifiedName(PrimitiveType type) {
		type.toString
	}

	def dispatch String simpleName(DeclaredType declType) {
		declType.asTypeElement.simpleName.toString
	}

	/** Best guess for error types... */
	def dispatch String simpleName(ErrorType declType) {
		if (declType.typeArguments.nullOrEmpty) {
			declType.toString //TODO: Get last segment
		} else {

			//In Elipse, a genric type seems to be an ErrorType as soon as one of the type args is an ErrorType...
			//-> Try erasure instead.
			declType.erasure.simpleName
		}
	}

	def dispatch String simpleName(PrimitiveType type) {
		type.toString
	}

	def boolean operator_equals(TypeMirror t1, TypeMirror t2) {
		if (t1 === null || t2 === null) {
			t1 === t2
		} else {
			t1.isSameType(t2) //???
		}
	}

	def operator_notEquals(TypeMirror t1, TypeMirror t2) {
		!(t1 == t2)
	}

	def boxedType(Class<?> primititveType) {
		Class.forName("java.lang." + primititveType.simpleName.toFirstUpper)
	}

	def isVoid(TypeMirror type) {
		type == null || type.kind == TypeKind.VOID || type.kind == TypeKind.NONE
	}
	
	def getVoid(){
		getNoType(TypeKind.VOID)
	}
	
	def asElement(TypeMirror t) {
		typesRegistry.asTypeElement(t)
	}
	
//	def TypeElement asTypeElement(TypeMirror t) {
//		typesRegistry.asTypeElement(t)
//	}
	
	//TODO: für GenTypes nicht delegieren.
	
	def asMemberOf(DeclaredType containing, Element element) {
		typeUtils.asMemberOf(containing, element)
	}
	
	def boxedClass(PrimitiveType p) {
		typeUtils.boxedClass(p)
	}
	
	def capture(TypeMirror t) {
		typeUtils.capture(t)
	}
	
	def contains(TypeMirror t1, TypeMirror t2) {
		typeUtils.contains(t1, t2)
	}
	
	def directSupertypes(TypeMirror t) {
		typeUtils.directSupertypes(t)
	}
	
	def getArrayType(TypeMirror componentType) {
		typeUtils.getArrayType(componentType)
	}
	
	def getDeclaredType(TypeElement typeElem, TypeMirror... args) {
		if(typeElem instanceof GenTypeElement || args.exists[it instanceof GenTypeMirror || it.isVoid]){
			new GenDeclaredType(typeElem) [
				typeArguments = args 
			]
		} else {
			typeUtils.getDeclaredType(typeElem, args)		
		}
	}
	
	def getDeclaredType(DeclaredType containing, TypeElement typeElem, TypeMirror... typeArgs) {
		typeUtils.getDeclaredType(containing, typeElem, typeArgs)
	}
	
	def getNoType(TypeKind kind) {
		typeUtils.getNoType(kind)
	}
	
	def getNullType() {
		typeUtils.nullType
	}
	
	def getPrimitiveType(TypeKind kind) {
		typeUtils.getPrimitiveType(kind)
	}
	
	def getWildcardType(TypeMirror extendsBound, TypeMirror superBound) {
		typeUtils.getWildcardType(extendsBound, superBound)
	}
	
	def isAssignable(TypeMirror t1, TypeMirror t2) {
		typeUtils.isAssignable(t1, t2)
	}
	
	def isSubsignature(ExecutableType m1, ExecutableType m2) {
		typeUtils.isSubsignature(m1, m2)
	}
	
	def isSubtype(TypeMirror t1, TypeMirror t2) {
		typeUtils.isSubtype(t1, t2)
	}
	
	def unboxedType(TypeMirror t) {
		typeUtils.unboxedType(t)
	}

}
