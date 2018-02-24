package de.japkit.model

import de.japkit.activeannotations.FieldsFromInterface
import de.japkit.services.ExtensionRegistry
import de.japkit.services.TypesExtensions
import java.util.List
import javax.lang.model.element.Name
import javax.lang.model.element.Parameterizable
import javax.lang.model.element.TypeElement
import javax.lang.model.element.TypeParameterElement
import javax.lang.model.type.DeclaredType
import javax.lang.model.type.TypeMirror
import javax.lang.model.type.TypeVariable
import javax.lang.model.util.SimpleTypeVisitor8
import javax.lang.model.type.ErrorType

@FieldsFromInterface
abstract class GenParameterizable extends GenElement implements Parameterizable {

	List<TypeParameterElement> typeParameters = newArrayList()

	def DeclaredType getDeclaredType(DeclaredType prototype, Iterable<TypeMirror> resolvedTypeArgs) {
		if (prototype instanceof GenDeclaredType) {
			new GenDeclaredType(prototype.asElement as TypeElement) [
				typeArguments = resolvedTypeArgs.toList
			]
		} else {
			ExtensionRegistry.get(TypesExtensions).getDeclaredType(prototype.asElement as TypeElement, resolvedTypeArgs)
		}
	}

	def TypeMirror resolveTypeVariables(TypeMirror type) {
		type?.accept(new SimpleTypeVisitor8<TypeMirror, Void>() {
			override defaultAction(TypeMirror type, Void p) {
				type
			}

			override TypeMirror visitDeclared(DeclaredType type, Void p) {
				if (type.typeArguments.nullOrEmpty) {
					type
				} else {
					getDeclaredType(type, type.typeArguments.map[resolveTypeVariables])
				}
			}
			
			override TypeMirror visitError(ErrorType type, Void p) {
				//Really? Is just 1:1 to the dispatch behavior before...
				visitDeclared(type, p);
			}

			override TypeMirror visitTypeVariable(TypeVariable tv, Void p) {

				var resolvedTypeVar = resolveTypeVariable(tv)
				if (resolvedTypeVar === null) {
					if (enclosingParameterizable !== null) {
						// If there is an enclosing type, look there...
						resolvedTypeVar = enclosingParameterizable.resolveTypeVariables(tv)
					} else {
						// Otherwise, leave the type variable unresolved for now, since the element might be added to its enclosing type
						// at a later point in time. 
						resolvedTypeVar = tv
					}
				}

				// messager.printMessage(Kind.WARNING, '''Resolve type variable in context «this.simpleName»: «tv» - Resolved: «resolvedTypeVar» ''')
				resolvedTypeVar
			}

		}, null);
	}

	/**
	 * resolve the type variable "locally" , for example by using type arguments of the method / class
	 * 
	 */
	def protected abstract TypeMirror resolveTypeVariable(TypeVariable tv);

	/**
	 * Gets or creates a type parameter with the same name and bounds as the given type parameter (typically from a superclass)
	 */
	def TypeParameterElement getOrCreateTypeParameter(TypeParameterElement otherTypeParam) {
		typeParameters.filter[simpleName.contentEquals(otherTypeParam.simpleName)].head ?: {
			new GenTypeParameter(otherTypeParam, this)
		}
	}

	// The following constructors shall be generated, but xtend has some bug and claims there are no super-constructors...
	new(String simpleName) {
		super(simpleName)
	}

	new(Name simpleName) {
		super(simpleName)
	}

}
