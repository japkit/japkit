package de.japkit.rules

import de.japkit.model.GenClass
import de.japkit.model.GenConstructor
import de.japkit.model.GenExtensions
import de.japkit.model.GenField
import de.japkit.model.GenInterface
import de.japkit.model.GenMethod
import de.japkit.model.GenParameter
import de.japkit.model.GenTypeElement
import de.japkit.model.GenUnresolvedType
import de.japkit.services.ExtensionRegistry
import de.japkit.services.TypeElementNotFoundException
import java.util.ArrayList
import java.util.IdentityHashMap
import java.util.Map
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.Modifier
import javax.lang.model.element.TypeElement
import javax.lang.model.type.TypeMirror
import org.eclipse.xtend.lib.annotations.Data

@Data
class BehaviorDelegationRule extends AbstractRule {
	val transient extension TypeResolver typesResolver = ExtensionRegistry.get(TypeResolver)

	()=>boolean activationRule
	TypeMirror behaviorClass
	String renamePrefix
	String internalInterfaceName
	Boolean internalInterfaceIsInnerClass
	String internalInterfaceImplName
	String abstractBehaviorClassName

	new(AnnotationMirror metaAnnotation) {
		super(metaAnnotation, null)
		activationRule = metaAnnotation.createActivationRule("customBehavior", null)
		behaviorClass = metaAnnotation.value("behaviorClass", TypeMirror)
		renamePrefix = metaAnnotation.value("behaviorGenMethodRenamePrefix", String)
		internalInterfaceName = metaAnnotation.value("behaviorInternalInterface", String)
		internalInterfaceIsInnerClass = metaAnnotation.value("behaviorInternalInterfaceIsInnerClass", Boolean)
		internalInterfaceImplName = metaAnnotation.value("behaviorInternalInterfaceImpl", String)
		abstractBehaviorClassName = metaAnnotation.value("behaviorAbstractClass", String)
	}

	def private getGenExtensions() {
		ExtensionRegistry.get(GenExtensions)
	}

	/**
	 * Creates a mechanism to delegate behavior to a separate class that can be changed manually.
	 */
	def void createBehaviorDelegation(GenTypeElement c) {
		inRule[
			if (activationRule != null && !activationRule.apply) {
				return null
			}
			//TODO: Name of interface and base class configurable
			//TODO: Visibility of interface and base class configurable
			val behaviorProxyAndTypeElement = behaviorClass.resolveTypeAndCreateProxy
			val foundBehaviorClass = behaviorProxyAndTypeElement.value
			
			if(activationRule==null && foundBehaviorClass==null){
				//If there is no custom activation rule, the behavior delegation is only generated if the custom behavior class exists.
				return null;
			}
			
			val behaviorClass = behaviorProxyAndTypeElement.key
			val behaviorClassInSamePackageAsGenClass = c.package.qualifiedName.contentEquals(
				behaviorClass.package.qualifiedName)
								
				
			val allInstanceMethods = handleTypeElementNotFound(emptyList,
				'''Could not determine all methods of generated class «c.qualifiedName», probably due to some missing supertype.''') [
				c.allMethods.filter[!isStatic]
			]
			
			//Methods defined in the behavior class
			val customBehaviorMethods = if (foundBehaviorClass == null)
					#[]
				else
					foundBehaviorClass.declaredMethods.filter[!static && !private]
			//Methods, that exist in generated class AND behavior class
			//Key is method in behavior class, value is method in gen class
			val Map<ExecutableElement, GenMethod> collidingBehaviorMethods = new IdentityHashMap
			//printDiagnosticMessage('''customBehaviorMethods: «customBehaviorMethods»''')
			c.declaredMethods.forEach [ m |
				val collidingMethod = customBehaviorMethods.findFirst [
					val result = isSubSignature(m)
					result
				]
				if (collidingMethod != null) {
					collidingBehaviorMethods.put(collidingMethod, m as GenMethod)
				}
			]
			//printDiagnosticMessage('''collidingBehaviorMethods: «collidingBehaviorMethods»''')
			//Add a prefix to the colliding methods. Greetings to EMF.
			//TODO: Make prefix configurable
			collidingBehaviorMethods.values.forEach [
				val newName = '''«renamePrefix»«simpleName.toString.toFirstUpper»'''
				simpleName = newName
			]
			//The "internal" interface provide access to all methods (declared an inherited)
			//Abstract methods are excluded, since they provide no behavior and so there is no reason to call them from the behavior delegate
			val internalMethods = allInstanceMethods.filter[notDeclaredBy(Object.name) && !abstractOrInInterface]
			val abstractMethodsToImplement = if(c.abstract) #[] else allInstanceMethods.filter[abstractOrInInterface]
			val Map<ExecutableElement, ExecutableElement> orgMethod = new IdentityHashMap
			val internalInterface = if (internalInterfaceIsInnerClass) {
					new GenInterface(internalInterfaceName) => [c.add(it);]
				} else {
					new GenInterface(c.simpleName + internalInterfaceName, c.package) => [
						//remember that we have created a new top level class so that it can be found
						//and rendered later.
						c.auxTopLevelClasses.add(it)
						registerGeneratedTypeElement(it, currentAnnotatedClass, null)
					]
				}
			if (!behaviorClassInSamePackageAsGenClass) {
				internalInterface.setVisibility(Modifier.PUBLIC)
			}
			internalInterface => [
				//addModifier(Modifier.PUBLIC)
				copyTypeParametersFrom(c) //TODO: We may only need a subset of the type params...
				internalMethods.forEach [ m |
					val interfaceMethod = getGenExtensions.asInterfaceMethod(m)
					add(interfaceMethod)
					orgMethod.put(interfaceMethod, m)
				]
			]
			val internalInterfaceImpl = new GenClass(internalInterfaceImplName) => [
				addModifier(Modifier.PRIVATE) //Führt z.Z. zu einem Fehler bei den Import Statements
				addInterface(internalInterface.asType)
				internalInterface.declaredMethods.forEach [ m |
					add(
						getGenExtensions.createOverride(m) [
							val thisOrSuper = if(orgMethod.get(m).enclosingElement == c) 'this' else 'super'
							val delegate = '''«c.simpleName».«thisOrSuper»'''
							codeForDelegation(m, delegate)
						])
				]
			]
			c.add(internalInterfaceImpl)
			val abstractBehaviorClass = new GenClass(abstractBehaviorClassName) => [
				copyTypeParametersFrom(c) //TODO: We may only need a subset of the type params...
				modifiers = #{Modifier.STATIC, Modifier.ABSTRACT}
				if (!behaviorClassInSamePackageAsGenClass) {
					setVisibility(Modifier.PUBLIC)
				}
				val internalInterfaceFieldName = internalInterfaceName.toFirstLower
				add(
					new GenField(internalInterfaceFieldName, internalInterface.asType) => [
						visibility = Modifier.PRIVATE
					])
				//TODO: Constructors from fields in some extension class
				add(
					new GenConstructor() => [
						visibility = Modifier.PROTECTED
						addParameter(new GenParameter(internalInterfaceFieldName, internalInterface.asType))
						body = ['''this.«internalInterfaceFieldName» = «internalInterfaceFieldName»;''']
					])
				//create delegate methods for everything the internal interface offers
				internalInterface.declaredMethods.forEach[m|
					add(
						getGenExtensions.copyFrom(m) => [
							visibility = m.visibilityFromJavaLangObject ?: Modifier.PROTECTED
							body = [codeForDelegation(m, internalInterfaceFieldName)]
						])]
				//create abstract methods for all abstract methods to implement
				//make sure they have modifier abstract, since they could come from interface
				abstractMethodsToImplement.forEach[m|add(getGenExtensions.asAbstractMethod(m))]
				val methodsAddedSoFar = new ArrayList(it.declaredMethods)
				//create abstract methods for every method in the concrete behavior class. Avoid duplicates.
				customBehaviorMethods.filter[m1|methodsAddedSoFar.forall[m2|!m1.isOverrideEquivalent(m2)]].forEach[m|
					add(getGenExtensions.asAbstractMethod(m))]
			//TODO: abstract methods from superclasses ?
			]
			c.add(abstractBehaviorClass)
			behaviorClass.setSuperclass(abstractBehaviorClass.asType)
			val behaviorFieldName = "behavior"
			c.add(
				new GenField(behaviorFieldName, abstractBehaviorClass.asType) => [
					visibility = Modifier.PRIVATE
					addModifier(Modifier.TRANSIENT) //We never want to persist behavior ...
					constantExpr = ['''new «behaviorClass.asType»(new «typeRef(internalInterfaceImpl.asType)»())''']
				])
			customBehaviorMethods.forEach [ m |
				c.add(
					getGenExtensions.copyFrom(m, true) => [
						body = [codeForDelegation(m, behaviorFieldName)]
						comment = m.docComment
						val genMethod = collidingBehaviorMethods.get(m)
						if (genMethod != null) {

							//if it is a colliding method, retain the visibility of the existing (renamed) gen-method
							visibility = genMethod.visibility ?: m.visibility

							//Copy the annotations from the gen method, if the custom method has no annotations
							//TODO: konfiguriebar? AnnotationMapping rule?
							//TODO: Das geht schöner.
							if (annotationMirrors.nullOrEmpty) {
								annotationMirrors = getGenExtensions().copyAnnotations(genMethod)
							}
							for (i : 0 ..< parameters.size) {
								if (parameters.get(i).annotationMirrors.nullOrEmpty) {
									(parameters.get(i) as GenParameter).annotationMirrors = getGenExtensions().
										copyAnnotations(genMethod.parameters.get(i))

								}
							}

						}
					])
			]
			//Make the renamed gen methods private, since only the behavior class shall be able to call them.
			collidingBehaviorMethods.values.forEach [
				visibility = Modifier.PRIVATE
				//Remove the annotations in the gen method (example: in a Spring MVC controller , they would lead to ambiguous request mappings)
				//TODO: make configurable?
				annotationMirrors = emptyList
				parameters.forEach[(it as GenParameter).annotationMirrors = emptyList]
			]
			null
		]
	}

	//For special cases, where the Behavior overrides some method from java.lang.Object (prevent to reduce visibility)
	def private Modifier getVisibilityFromJavaLangObject(ExecutableElement method) {
		val methodFromObject = getTypeElement(Object.name).declaredMethods.findFirst[method.overrides(it)]
		methodFromObject?.modifiers?.findFirst[it == Modifier.PUBLIC || it == Modifier.PROTECTED]
	}

	/**
	 * Creates code to delegate to a method with the same signature as the given method
	 */
	def private codeForDelegation(ExecutableElement m, String delegate) {
		'''«IF !m.returnType.isVoid»return «ENDIF»«delegate».«m.simpleName»(«FOR p : m.parametersWithSrcNames SEPARATOR ', '»«p.
			simpleName»«ENDFOR»);'''

	//TODO: Make delegation code gen available in some extension class and support more complex delegation styles
	}
	
	
	def public resolveTypeAndCreateProxy(TypeMirror selector) {
		try {

			var tm = resolveType(selector, false)
			var TypeElementNotFoundException tenfe
			
			var TypeElement te = try {
					tm.asTypeElement
				} catch (TypeElementNotFoundException e) {
					tenfe = e
					null
				}
			
			if(te!=null){
				//The class has already been created by the user.
				// Nevertheless create a proxy to provide a place to add expected interfaces and superclasses. 
				val proxy = new GenClass(te.simpleName)
				proxy.enclosingElement = te.enclosingElement
				proxy -> te
			} else {
				if(tm instanceof GenUnresolvedType){
					val proxy = if(tm.innerClass){
						new GenClass(tm.simpleName, findTypeElement(tm.enclosingQualifiedName))
					} else {
						new GenClass(tm.simpleName, tm.enclosingQualifiedName)
					}
					proxy -> null
				} else {
					throw tenfe
				}
				
			}
			

			

		} catch (TypeElementNotFoundException tenfe) {
			throw tenfe
		} catch (Exception e) {
			reportRuleError(e)
			throw e;
		}

	}
}
