package de.stefanocke.japkit.model

import de.stefanocke.japkit.activeannotations.Derived
import de.stefanocke.japkit.activeannotations.FieldsFromInterface
import de.stefanocke.japkit.rules.ElementsExtensions
import de.stefanocke.japkit.rules.ExtensionRegistry
import de.stefanocke.japkit.rules.TypesExtensions
import java.util.Comparator
import java.util.HashSet
import java.util.List
import java.util.Map
import java.util.Set
import javax.lang.model.element.Element
import javax.lang.model.element.ElementKind
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.Name
import javax.lang.model.element.NestingKind
import javax.lang.model.element.PackageElement
import javax.lang.model.element.QualifiedNameable
import javax.lang.model.element.TypeElement
import javax.lang.model.element.TypeParameterElement
import javax.lang.model.type.DeclaredType
import javax.lang.model.type.TypeMirror
import javax.lang.model.type.TypeVariable

@FieldsFromInterface
abstract class GenTypeElement extends GenParameterizable implements TypeElement {
	
	List<TypeMirror> interfaces = newArrayList
	NestingKind nestingKind
	TypeMirror superclass
	//auxiliary top level classes that have been generated for this GenTypeElement
	@org.eclipse.xtend.lib.Property
	Set<GenTypeElement> auxTopLevelClasses = newHashSet

	def Set<GenTypeElement> allAuxTopLevelClasses(){
		val result = new HashSet(auxTopLevelClasses)
		auxTopLevelClasses.forEach[result.addAll(it.allAuxTopLevelClasses)]
		result
	}	

	@Derived
	override getQualifiedName(){
		new GenName('''«(enclosingElement as QualifiedNameable)?.qualifiedName».«simpleName»''')
	}
	
	new(String name, String packageName) {
		this(name, GenPackage.packageForName(packageName))
	}
	
	new(String name, Element enclosingElement) {
		super(name)
		setEnclosingElement(enclosingElement)
		if (enclosingElement instanceof PackageElement) {
			setNestingKind(NestingKind.TOP_LEVEL)
		} else if (enclosingElement instanceof TypeElement) {
			setNestingKind(NestingKind.MEMBER)
		} else
			throw new IllegalArgumentException(
				"Enclosing element of a class must be a PackageElement or a TypeElement, but not " + enclosingElement)
	}

	/**
	 * Set the superclass. If the given superclass is generic, the parameter is expected to be a prototype.
	 * The type variables of the prototype will be replaces by the given type arguments then. The list of type arguments must match the
	 * type variables but is allowed to contain null values. 
	 * For each null value, the type element gets a type parameter with the same name as in the superclass. If there already exists
	 * a type parameter with that name (from some interface), it is reused.
	 * <p>
	 * 
	 */
	def void setSuperclass(DeclaredType type, TypeMirror... typeArgs) {
		if (type != null) {

			//Make sure we have a prototype an not the type erasure
			val superclassPrototype = type.asElement.asType as DeclaredType

			superclass = resolveTypeArgs(superclassPrototype, typeArgs)

		} else {
			superclass = null
		}
	}
	
	def void setSuperclass(DeclaredType type){
		setSuperclass(type, type?.typeArguments ?: {})
	}

	/**
	 * Adds an interface. If the given interface is generic, the parameter is expected to be a prototype.
	 * The type variables of the prototype will be replaces by the given type arguments then. The list of type arguments must match the
	 * type variables but is allowed to contain null values. 
	 * For each null value, the type element gets a type parameter with the same name as in the interface. If there already exists
	 * a type parameter with that name (from some other interface or from the superclass), it is reused.
	 */
	def void addInterface(DeclaredType type, TypeMirror... typeArgs) {
		//Make sure we have a prototype an not the type erasure
		val interfacePrototype = type.asElement.asType as DeclaredType
		
		interfaces.add(resolveTypeArgs(interfacePrototype, typeArgs))
	}
	
	def void addInterface(TypeMirror type){
		addInterface(type as DeclaredType, (type as DeclaredType).typeArguments)
	}
	
	/**
	 * Copies the type parameters from another type element. A typical use case is to generate an interface from an existing class.
	 * <p>
	 * TODO: Not all variables are needed in such cases ...
	 * TODO: also consider enclosing types?
	 * 
	 */
	def copyTypeParametersFrom(GenTypeElement other){
		other.typeParameters.forEach[p | 
			val ownParam = p.getOrCreateTypeParameter()
			this.addTypeParameter(ownParam)
			
		]
		
	}

	/**
	 * How are the type arguments of superclass and interfaces resolved in this type?
	 */
	val Map<TypeParameterElement, TypeMirror> resolvedTypeArgsMap = newHashMap()
	
	def getResolvedTypeArgsMap(){
		return resolvedTypeArgsMap;
	}
	
	def DeclaredType resolveTypeArgs(DeclaredType prototype, TypeMirror[] typeArgs) {
		//messager.printMessage(Kind.WARNING, '''Prototype: «prototype» - Type Args «prototype.typeArguments» ''')
		
		if (prototype.typeArguments.nullOrEmpty) {
			return prototype
		}	
		
		val resolvedTypeArgs = (0 ..< prototype.typeArguments.size).map [ n |
			val typeArg = if(typeArgs.nullOrEmpty) null else typeArgs.get(n)
			val typeVariable = prototype.typeArguments.get(n) as TypeVariable
			val resolved = if (typeArg == null) {
				addTypeParameter(getOrCreateTypeParameter(typeVariable.asElement as TypeParameterElement));

				//Das Folgende ist so nicht ganz exakt. Eigentlich müsste man hier eine neue Typ-Variable erzeugen, 
				//die auf den neuen Typ-Parameter zeigt.
				//damit würde dann aber z.B. getDeclaredType weiter unten nicht mehr funktionieren, da Eclipse bzw. javac
				//die von uns erzeugte TypVariable nicht kennen, sondern  versuchen , auf ihre eigene Impl zu casten.
				//Das Ganze ist aber trotzdem einigermaßen "okay", da wir den selben simpleName verwenden.
				//Im generierten Code macht es also keinen Unterschied.
				typeVariable
				
				//Note: Es würde mehr Flexibilität bringen, wenn wir eigene TypeVariablen erzeugen könnten. Z.B. könnte 
				//man dann Typ-Parameter innerer Klassen an Typ-Variable der umgebenden Klasse binden usw.
			} else {

				typeArg
			}
			//messager.printMessage(Kind.WARNING, '''Prototype: «prototype» - Resolved «typeVariable» to «resolved»''')
			
			resolvedTypeArgsMap.put(typeVariable.asElement as TypeParameterElement, resolved)
			resolved
		]
		getDeclaredType(prototype, resolvedTypeArgs)
	}
	
	
	
	/**
	 * Given some type that is used in a generic superclass or interface of this type element, this method resolves the contained 
	 * type variables according to the resolvedSuperTypeArgs.
	 */
	override protected TypeMirror resolveTypeVariable(TypeVariable tv){
		val resolvedTypeVar = resolvedTypeArgsMap.get(tv.asElement)
		if(resolvedTypeVar==null && nestingKind == NestingKind.TOP_LEVEL){
			//We reached top level type and the variable is still not resolved -> error 
			//throw new IllegalArgumentException('''Could not resolve type variable «tv» in «this.qualifiedName»''');
		}
		resolvedTypeVar	
	}
		
	override addEnclosedElement(Element enclosed){
		super.addEnclosedElement(enclosed)
		//now, that the enclosing type is known, we can resolve all contained type variables
		//for example, if we override a method from superclass, the type variables contained in the method signature
		//can be simply copied at first as they are. Then, when the method is finally added to its declaring type,
		//those type variables will be resolved.
		(enclosed as GenElement).resolveContainedTypeVariables(this) 
	}
	
	static val memberComparator = [Element e1, Element e2 | e1.memberOrderOf.compareTo(e2.memberOrderOf)]
	
	//TODO: Make configurable
	//TODO: Make static and non-static members distinguishable
	static val  memberOrder = #[
		ElementKind.ENUM_CONSTANT, 
		ElementKind.FIELD,
		ElementKind.STATIC_INIT,
		ElementKind.INSTANCE_INIT,
		ElementKind.CONSTRUCTOR,
		ElementKind.METHOD,
		ElementKind.ENUM,
		ElementKind.INTERFACE,
		ElementKind.CLASS
	]
	
	def static int memberOrderOf(Element e){
		val index = memberOrder.indexOf(e.kind)
		if(index >= 0) index else memberOrder.size
	}
	
	
	override Comparator<Element> enclosedElementComparator (){
 		memberComparator
 	}
 	
	//TODO: Refactoring. Move to ElementExtensions
	def List<ExecutableElement> allMethods(){
		val extension TypesExtensions = ExtensionRegistry.get(TypesExtensions)
		val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
		val List<ExecutableElement> methods = newArrayList();
		val te = this
		
		//Add all superclass methods that are not overriden and that are visible.
		//TODO: In Eclipse liefert Types.allMethods zwar die "asMemberOf-Sicht". Maven tut dies jedoch nicht! D.h. , die TypeVariablen werden nicht ersetzt. 
		if (superclass != null) {
			
			
			methods.addAll(
				superclass.asElement.allMethods.filter [ExecutableElement m |
					!this.declaredMethods.exists[it.overrides(m)] && (m.public || m.protected ||
						(m.defaultAccess && samePackage(m, te)))
				].map [ m |
					//TODO: Move all to ElementsExtensions ??
					val m1 = ExtensionRegistry.get(GenExtensions).asMemberOf(m, te)
					//messager.printMessage(Kind.WARNING, '''allMethods: «m» - transformed to: «m1.returnType» «m1.simpleName» ''')
					m1
				]
			)

		}
		methods.addAll(this.declaredMethods)
		methods	
	}
	
	
	
	override asType(){
		//TODO: Caching?
		new GenDeclaredType(this)[
			typeArguments = this.typeParameters.map[asType]
		]
	}
	
	new(String name) {
		super(name)
	}

	new(Name name) {
		super(name)
	}

	new() {
	}
}
