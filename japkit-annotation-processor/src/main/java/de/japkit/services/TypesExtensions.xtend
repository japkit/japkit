package de.japkit.services

import de.japkit.model.GenDeclaredType
import de.japkit.model.GenTypeElement
import de.japkit.model.GenTypeMirror
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
import javax.lang.model.type.TypeVariable
import javax.lang.model.util.SimpleTypeVisitor8
import javax.lang.model.type.NoType

class TypesExtensions /**implements Types*/{
	val Types typeUtils = ExtensionRegistry.get(Types)
	val transient extension Elements elementUtils = ExtensionRegistry.get(Elements)
	val transient extension TypesRegistry typesRegistry = ExtensionRegistry.get(TypesRegistry)
	
	def TypeMirror getJavaLangObject(){
		findTypeElement(Object.name).asType
	}
	
	def boxed(TypeKind typeKind) {
		typeKind.primitiveType.boxedClass.asType
	}

	def isPrimitive(TypeMirror type) {
		type?.kind.isPrimitive
	}
	
	def isDeclared(TypeMirror type) {
		type?.kind == TypeKind.DECLARED
	}
	
	def isError(TypeMirror type) {
		type?.kind == TypeKind.ERROR
	}
	/**
	 * In JDT, a generic type seem to be an ErrorType as soon as one of the type args is an ErrorType...
	 * If one is only interested in the erasure of a generic type, this method should be used to check for DECLARED.
	 */
	def isDeclaredOrErasureIsDeclared(TypeMirror type) {
		return type.isDeclared || type.isError && (type as DeclaredType).erasure.isDeclared 
	}

	def isDeclaredOrError(TypeMirror type) {
		return type.isDeclared || type.isError
	}

	static val BOXED_TYPES = #{Boolean, Byte, Short, Integer, Long, Character, Float, Double}.map[name].toSet

	def isBoxed(TypeMirror type) {
		//No need to consider ErrorTypes here, since they will never become one of the boxed types.
		if (type.isDeclared) BOXED_TYPES.contains(type.qualifiedName) else false
	}

	def isString(TypeMirror type) {
		if (type.isDeclared) String.name == type.qualifiedName else false
	}

	static val TEMPORAL_TYPES = #{Calendar, Date}.map[name].toSet

	def isTemporal(TypeMirror type) {
		if (type.isDeclared) TEMPORAL_TYPES.contains(type.qualifiedName) else false
	}
	

	static val MATH_TYPES = #{BigDecimal.name, BigInteger.name}

	def boolean isMath(TypeMirror type) {
		if (type.isDeclared) MATH_TYPES.contains(type.qualifiedName) else false
	}

	def boolean collectionOrMap(TypeMirror type) {
		type.collection || type.map
	}

	static val COLLECTION_TYPES = #{Collection.name, Set.name, List.name, SortedSet.name}

	def boolean isCollection(TypeMirror type) {
		if(type.isDeclaredOrErasureIsDeclared) COLLECTION_TYPES.contains(type?.qualifiedName) else false
	}

	def boolean isMap(TypeMirror type) {
		if(type.isDeclaredOrErasureIsDeclared) Map.name == type.qualifiedName else false
	}

	def boolean isSet(TypeMirror type) {
		if(type.isDeclaredOrErasureIsDeclared) Set.name == type.qualifiedName else false
	}

	def boolean isList(TypeMirror type) {
		if(type.isDeclaredOrErasureIsDeclared) List.name == type.qualifiedName else false
	}

	def boolean isEnum(TypeMirror type) {
		if (type.isDeclared) type.asTypeElement.kind == ElementKind.ENUM else false
	}

	def boolean isBoolean(TypeMirror type) {
		type.isPrimitive && type == TypeKind.BOOLEAN.primitiveType || type.isDeclared && type == TypeKind.BOOLEAN.boxed
	}
	
	def dispatch TypeMirror getTypeArg(DeclaredType type, int argIndex){
		if(!type.isDeclaredOrError || argIndex >= type.typeArguments.size ){
			null
		} else {
			type.typeArguments.get(argIndex)
		}
	}
	
	def dispatch TypeMirror getTypeArg(TypeMirror type, int argIndex){
		null
	}
	
	def private getRequiredTypeArg(TypeMirror type, int argIndex){
		val typeArg = getTypeArg(type, argIndex)
		if(typeArg==0){
			throw new IllegalArgumentException('''Type argument (pos.: «argIndex») required but not found: «type»''')
		}
		typeArg
	}
	
	def TypeMirror singleValueType(TypeMirror type) {
		type?.accept(new SimpleTypeVisitor8<TypeMirror,Void>(type) {
			override TypeMirror visitDeclared(DeclaredType type, Void v) {
				if(type.collection){
					type.getRequiredTypeArg(0).uppertBoundIfTypeVarOrWildcard
				} else if(type.map) {
					type.getRequiredTypeArg(1).uppertBoundIfTypeVarOrWildcard
				} else {
					type
				}
			}
			
			//In JDT, something like List<SomeErrorType> is itself an error type.
			//Thus, error types must be treated like DeclaredType.
			override TypeMirror visitError(ErrorType type, Void v) {
				visitDeclared(type, v)
			}
			
			override TypeMirror visitArray(ArrayType type, Void v) {
				type.componentType.singleValueType
			}
			
			override TypeMirror visitTypeVariable(TypeVariable type, Void v) {
				type.uppertBoundIfTypeVarOrWildcard
			}
		}, null)
	}
	
	def TypeMirror uppertBoundIfTypeVarOrWildcard(TypeMirror type) {
		type?.accept(new SimpleTypeVisitor8<TypeMirror,Void>(type) {
			override visitWildcard(WildcardType type, Void v ) {
				type.extendsBound
			} 
			override visitTypeVariable(TypeVariable type, Void v ) {
				type.upperBound
			}
		}, null)	
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

	def dispatch TypeMirror erasure(GenDeclaredType type) {
		if(type.typeArguments.nullOrEmpty) type else new GenDeclaredType(type.asElement as TypeElement)
	}

	def dispatch TypeMirror erasure(TypeMirror type) {
		typeUtils.erasure(type)
	}
	
	def boolean isSameType(TypeMirror t1, TypeMirror t2) {
		if((t1 === null) || (t2 === null)){
			return false
		}		
		if(t1.isVoid || t2.isVoid) {
			return t2.isVoid && t1.isVoid
		}
		
		//At least the roo-petclinic example fails if error types are always considered as being not equal to 
		//non-error declared types.
		//So, we relax the type kind comparision here. 
		//TODO: Determine exact place where it fails. Is it really circular dependency in generated classes or is it 
		//a flaw in Japkit processor workflow?
		val t1Kind = if(t1.kind == TypeKind.ERROR) TypeKind.DECLARED else t1.kind
		val t2Kind = if(t2.kind == TypeKind.ERROR) TypeKind.DECLARED else t2.kind
		
		if(t1Kind !== t2Kind) {
			return false;
		}
		//From now on, it is assumed the cast of t2 to the same interface as t1 is safe
		t1.accept(new SimpleTypeVisitor8<Boolean, TypeMirror> {
			override defaultAction(TypeMirror t1, TypeMirror t2) {
				typeUtils.isSameType(t1, t2);
			}
			
			override Boolean visitDeclared(DeclaredType t1, TypeMirror t2) {
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
			}
			
			override Boolean visitError(ErrorType t1, TypeMirror t2) {
				visitDeclared(t1,t2);
			}
			
			override Boolean visitArray(ArrayType t1, TypeMirror t2)  {
				//due to GenArrayType
				isSameType(t1.componentType, (t2 as ArrayType).componentType);
			}
			
		}, t2);
		
		
	}
	
	def private boolean containsErrorType(TypeMirror type) {
		return type.accept(new SimpleTypeVisitor8<Boolean, Void>(false) {
			override Boolean visitError(ErrorType t, Void v) {
				true
			}

			override Boolean visitDeclared(DeclaredType t, Void v) {
				t.typeArguments.exists[containsErrorType]
			}

			override Boolean visitWildcard(WildcardType t, Void v) {
				(t.extendsBound !== null && t.extendsBound.containsErrorType) ||
					(t.superBound !== null && t.superBound.containsErrorType)
			}
		}, null);
	}

	def DeclaredType enclosingTopLevelType(DeclaredType declType) {
		if(declType.enclosingType?.kind == TypeKind.NONE) declType else (declType.enclosingType as DeclaredType).
			enclosingTopLevelType
	}

	def String qualifiedName(TypeMirror type) {
		type?.accept(new SimpleTypeVisitor8<String, Void>() {
			override defaultAction(TypeMirror type, Void p) {
				throw new IllegalArgumentException('''Unsupported TypeMirror: «type» of kind «type.kind»''');
			}
			
			override String visitPrimitive(PrimitiveType type, Void p) {
				type.kind.toString.toLowerCase
			}
			
			override String visitNoType(NoType type, Void p) {
				type.kind.toString.toLowerCase
			}
			
			override String visitDeclared(DeclaredType declType, Void v) {
				if(declType instanceof GenDeclaredType) {
					return declType.qualifiedName
				}
				declType.asTypeElement.qualifiedName.toString
			}
			
			/** Best guess for error types... */
			override String visitError(ErrorType declType, Void v) {
				if (declType.typeArguments.nullOrEmpty) {
					return typesRegistry.handleTypeElementNotFound(declType.guessTypeNameFromToString, '''Cannot determine qualified name for error type «declType.guessTypeNameFromToString»''')[
						typesRegistry.tryToGetFqnForErrorType(declType)			
					]
					
				} else {		
					//In JDT, a generic type seem to be an ErrorType as soon as one of the type args is an ErrorType...
					//-> Try erasure instead.
					return declType.erasure.qualifiedName
				}
			}
			
			override String visitArray(ArrayType type, Void v) {
				'''«type.componentType.qualifiedName»[]'''
			}
		}, null);
	}

	def String simpleName(TypeMirror type) {
		type?.accept(new SimpleTypeVisitor8<String, Void>() {
			override defaultAction(TypeMirror type, Void p) {
				throw new IllegalArgumentException('''Unsupported TypeMirror: «type» of kind «type.kind»''');
			}
			
			override String visitPrimitive(PrimitiveType type, Void p) {
				type.kind.toString.toLowerCase
			}
			
			override String visitNoType(NoType type, Void p) {
				type.kind.toString.toLowerCase
			}
			
			override String visitDeclared(DeclaredType declType, Void v) {
				if(declType instanceof GenDeclaredType) {
					return declType.simpleName
				}
				declType.asTypeElement.simpleName.toString
			}
			
			/** Best guess for error types... */
			override String visitError(ErrorType declType, Void v) {
				if (declType.typeArguments.nullOrEmpty) {
					declType.simpleNameForErrorType  //TODO: Das ist bei inner classes nicht wirklich der simple name sondern das Symbol wie im Quelltext, also ggf mit umgebender Klasse
				} else {
		
					//In JDT, a generic type seems to be an ErrorType as soon as one of the type args is an ErrorType...
					//-> Try erasure instead.
					declType.erasure.simpleName
				}
			}
			
			override String visitArray(ArrayType type, Void v) {
				'''«type.componentType.simpleName»[]'''
			}
		}, null);
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
		type === null || type.kind == TypeKind.VOID || type.kind == TypeKind.NONE
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
			new GenDeclaredType(typeElem, args)
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
	
	
	def boolean isSubtype(TypeMirror t1, TypeMirror t2) {
		//TODO: Das sollte auch bei allen anderen Mehtoden getan werden, z.B. isSameType. (Wirklich?)
		//Es ist sinnlos, über nicht existierende Typen Aussagen bzgl ihrer Supertypen usw. machen zu wollen.
		//javac scheint z.B. immer true zu liefern, wenn man auf einem ErrorType isSubtype aufruft...
		isSubtypeInternal(t1.resolveIfErrorType, t2.resolveIfErrorType);
	}
		
	def private boolean isSubtypeInternal(TypeMirror t1, TypeMirror t2) {
		if (t1 instanceof GenTypeMirror || t2 instanceof GenTypeMirror) {
			t1.isSameType(t2) || t1.isDeclared && t2.isDeclared && t1.asTypeElement.superclass.isSubtypeInternal(t2) // TODO: What about type args here?
		} else
			typeUtils.isSubtype(t1, t2)
	}
	
	def unboxedType(TypeMirror t) {
		typeUtils.unboxedType(t)
	}

	def private resolveIfErrorType(TypeMirror t) {
		if(t?.kind == TypeKind.ERROR) t.asTypeElement.asType else t		
	}


}
