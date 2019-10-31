package de.japkit.rules

import de.japkit.model.GenAnnotationMirror
import de.japkit.model.GenAnnotationType
import de.japkit.model.GenAnnotationValue
import de.japkit.model.GenClass
import de.japkit.model.GenElement
import de.japkit.model.GenEnum
import de.japkit.model.GenExecutableElement
import de.japkit.model.GenExtensions
import de.japkit.model.GenInterface
import de.japkit.model.GenPackage
import de.japkit.model.GenTypeElement
import de.japkit.services.ExtensionRegistry
import de.japkit.services.ProcessingException
import de.japkit.services.TypeElementNotFoundException
import java.util.List
import java.util.Set
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.ElementKind
import javax.lang.model.element.Modifier
import javax.lang.model.element.TypeElement
import javax.lang.model.type.DeclaredType
import javax.lang.model.type.TypeMirror
import org.eclipse.xtend.lib.annotations.Data
import java.util.Collections
import de.japkit.services.ReportedException

@Data
class ClassRule extends AbstractRule {

	protected val transient extension AnnotationExtensions = ExtensionRegistry.get(AnnotationExtensions)

	()=>boolean activationRule
	TemplateRule templateRule
	MembersRule membersRule
	ElementKind kind
	()=>Set<Modifier> modifiersRule
	boolean keepAbstract
	(GenElement)=>List<? extends AnnotationMirror> annotationsRule
	()=>CharSequence commentRule
	boolean isTopLevelClass
	ClassNameRule nameRule
	BehaviorDelegationRule behaviorRule

	()=>TypeMirror superclassRule
	List<()=>TypeMirror> interfaceRules
	ScopeRule<GenTypeElement> scopeRule

	boolean shallCreateShadowAnnotation

	// is it a top level calls that is generated as a "by-product" of the main top level class?
	boolean isAuxClass

	List<ELVariableRule> varRules

	new(AnnotationMirror metaAnnotation, TypeElement templateClass, boolean isTopLevelClass) {
		this(metaAnnotation, templateClass, isTopLevelClass, false)
	}

	new(AnnotationMirror metaAnnotation, TypeElement templateClass, boolean isTopLevelClass, boolean isAuxClass) {
		super(metaAnnotation, templateClass)
		activationRule = createActivationRule(metaAnnotation, null)
		templateRule = templateClass?.createTemplateRule(metaAnnotation)
		
		//"Legacy support" when @Clazz is not on a template but on the trigger annotation.
		membersRule = if(templateClass === null) new MembersRule(metaAnnotation) else null
		annotationsRule = if(templateClass === null) createAnnotationMappingRules(metaAnnotation, null, null) else null
		
		
		kind = metaAnnotation.value('kind', ElementKind)
		modifiersRule = createModifiersRule(metaAnnotation, templateClass, null)
		keepAbstract = metaAnnotation.value("keepAbstract", Boolean) ?: false

		
		commentRule = createCommentRule(metaAnnotation, templateClass, null, null)

		shallCreateShadowAnnotation = metaAnnotation.value("createShadowAnnotation", Boolean) ?: false
		this.isTopLevelClass = isTopLevelClass
		this.isAuxClass = isAuxClass
		nameRule = if(isTopLevelClass) new ClassNameRule(metaAnnotation) else null
		behaviorRule = new BehaviorDelegationRule(metaAnnotation)
		
		//superclass from AV or template
		superclassRule = createTypeRule(metaAnnotation, templateClass?.superclass, "superclass", null, null)
		
		//interfaces from AV  (interfaces from template are implemented in TemplateRule, since templates can
		// "contribute" interface implementations to the generated class, even if the template is not the ClassRule itself but only called by it.)
		interfaceRules = (1 .. 2).map[createTypeRule(metaAnnotation, null, '''interface«it»''', null, null)].toList

		// Supports ELVariables in the scope of the generated class. For inner classes, this is already done in the inner class rule
		// Note: src expression is currently not supported in the annotation, since generating multiple classes is not supported
		// and would for instance be in conflict with ElementExtensions.generatedTypeElementAccordingToTriggerAnnotation 
		varRules = if(isTopLevelClass) createELVariableRules(metaAnnotation, templateClass, null) else null;
		
		//TODO: A ClassRule can be a library. An InnerClassRule not. Why?
		scopeRule = if(isTopLevelClass) createScopeRule(metaAnnotation, templateClass, null) else scopeWithCurrentSrc
		
		
	}

	/**
	 * Generates a top level or inner class and potentially some auxillary classes.
	 * 
	 * @return the list of generated classes (one per source). Does not contain the aux classes.
	 */
	def List<? extends GenTypeElement> generateClass(
		String name,
		Set<GenTypeElement> generatedTopLevelClasses
	) {
		inRule[
			if(!activationRule.apply) return Collections.<GenTypeElement>emptyList

			val enclosingClass = if (!isTopLevelClass) {
					if (currentGeneratedClass === null) {
						throw new IllegalArgumentException(
							"currentGeneratedClass must be available when it is a rule for an inner class.")
					}
					currentGeneratedClass
				} else
					null
			if (!isTopLevelClass && (enclosingClass === null)) {
				throw new IllegalArgumentException(
					"enclosingClass must be available when it is a rule for an inner class.")
			}

			if (isAuxClass) {
				if (currentGeneratedClass === null) {
					throw new IllegalArgumentException(
						"currentGeneratedClass must be available when it is a rule for an aux class.")
				}
				
			}
			
			


			scopeRule.apply([
				val generatedClass = createClass(enclosingClass, name)
				if (isAuxClass) {
					// early registration of aux classes to allow other aux classes to find them.
					currentPrimaryGenClass.auxTopLevelClasses.add(generatedClass)
					generatedClass.auxClass = true
				}
				// Register generated class as early as possible to allow error type resolution in other classes
				registerGeneratedTypeElement(generatedClass, currentAnnotatedClass,
					if(isTopLevelClass && !isAuxClass) currentTriggerAnnotation else null)
				setCurrentGeneratedClass(generatedClass)
				
				if (isTopLevelClass && !isAuxClass) {
					currentPrimaryGenClass = generatedClass
				}
			], [
				val generatedClass = currentGeneratedClass
				try {

					varRules?.forEach[it.putELVariable]
					generatedClass.modifiers = modifiersRule.apply

					if (templateRule !== null && !keepAbstract) {
						generatedClass.removeModifier(Modifier.ABSTRACT) // Templates are usually abstract
					}

					val superClass = superclassRule.apply;
					if(!superClass.isVoid){
						generatedClass.setSuperclass(superclassRule.apply)
					}

					interfaceRules.map[apply].filter[!isVoid].forEach [
						generatedClass.addInterface(it)
					]

					if (isTopLevelClass && !isAuxClass) {
						createShadowAnnotation(generatedClass)
					}

					if(annotationsRule !== null) {
						generatedClass.annotationMirrors = annotationsRule.apply(generatedClass)			
					}
					generatedClass.comment = commentRule.apply

					membersRule?.apply(generatedClass)

					// For @InnerClass, the annotated inner class is the template
					templateRule?.apply(generatedClass)

					behaviorRule.createBehaviorDelegation(generatedClass)

				} catch (ProcessingException pe) {
					reportError(pe)

				} catch (TypeElementNotFoundException tenfe) {
					handleTypeElementNotFound(tenfe, currentAnnotatedClass)

				} catch (ReportedException re) {
					// Do not report again to avoid error flooding
				} catch (Exception e) {
					reportRuleError(e)
				} finally {
					if (isTopLevelClass && !isAuxClass && generatedClass !== null) {
						val Set<GenTypeElement> generatedClasses = newHashSet
						generatedClasses.add(generatedClass)
						addAllAuxTopLevelClasses(generatedClasses, generatedClass)

						generatedClasses.forEach[markAsGenerated(it, currentAnnotatedClass)]
						generatedClasses.forEach[addOrderAnnotations]
						generatedClasses.forEach[addParamNamesAnnotations]

						if (generatedTopLevelClasses !== null) {
							generatedTopLevelClasses.addAll(generatedClasses)
						}

					}

				}
				generatedClass

			]).toList

		]
	}

	def void addAllAuxTopLevelClasses(Set<GenTypeElement> result, GenTypeElement typeElement) {
		result.addAll(typeElement.auxTopLevelClasses)
		typeElement.declaredTypes.forEach[addAllAuxTopLevelClasses(result, it as GenTypeElement)]
		typeElement.auxTopLevelClasses.forEach[addAllAuxTopLevelClasses(result, it)]
	}

	def createShadowAnnotation(GenTypeElement generatedClass) {
		try {

			if (shallCreateShadowAnnotation) {
				val shadowAnnotation = GenExtensions.copy(currentTriggerAnnotation)

				shadowAnnotation.annotationValueNames.forEach [ avName |
					val valueFromStack = valueStack.get(avName.toString)
					if (valueFromStack !== null && !valueFromStack.isEmptyVar) {
						shadowAnnotation.setValue(avName.toString, [ t |
							// TODO: Schicker. In extension o.ä verlagern. 
							new GenAnnotationValue(coerceAnnotationValue(valueFromStack, t))
						])
					}

				]

				shadowAnnotation.setShadowIfAppropriate

				generatedClass.addAnnotationMirror(shadowAnnotation)
				// put on value stack
				putShadowAnnotation(shadowAnnotation)
			}

		} catch (TypeElementNotFoundException tenfe) {
			handleTypeElementNotFound('''Missing type when creating shadow annotation:''', tenfe.fqn)
		} catch (RuntimeException re) {
			reportRuleError('''Error when creating shadow annotation: «re»''')
		}
	}

	private def void addOrderAnnotations(Element e) {
		val enclosed = e.enclosedElements
		for (order : 0 ..< enclosed.size) {
			enclosed.get(order).addOrderAnnotation(order);
			enclosed.get(order).addOrderAnnotations()
		}
	}

	def dispatch void addOrderAnnotation(GenElement element, Integer order) {
		element.addAnnotationMirror(
			new GenAnnotationMirror(getTypeElement(ORDER_ANNOTATION_NAME).asType as DeclaredType) => [
				setValue("value", [new GenAnnotationValue(order)])
			]
		)
	}

	def dispatch void addOrderAnnotation(Element element, Integer integer) {
	}

	def dispatch void addParamNamesAnnotations(GenTypeElement typeElement) {
		typeElement.enclosedElements.forEach[it.addParamNamesAnnotations]
	}

	def dispatch void addParamNamesAnnotations(GenExecutableElement element) {
		if (!element.parameters.nullOrEmpty) {
			element.addAnnotationMirror(
				new GenAnnotationMirror(getTypeElement(PARAM_NAMES_ANNOTATION_NAME).asType as DeclaredType) => [
					setValue("value", [
						new GenAnnotationValue(element.parameters.map[simpleName.toString].map [
							new GenAnnotationValue(it)
						].toList)
					])
				]
			)
		}
	}

	def dispatch void addParamNamesAnnotations(Element element) {
	}

	def GenTypeElement createClass(
		GenTypeElement enclosingClass,
		String name
	) {

		val enclosingElAndClassName = if (isTopLevelClass) {
				val names = nameRule.generateClassAndPackageName(currentAnnotatedClass)
				GenPackage.packageForName(names.key) -> names.value
			} else {
				// For inner classes, use provided class name
				enclosingClass -> name
			}

		val generatedClass = switch (kind) {
			case ElementKind.CLASS:
				new GenClass(enclosingElAndClassName.value, enclosingElAndClassName.key)
			case ElementKind.ENUM:
				new GenEnum(enclosingElAndClassName.value, enclosingElAndClassName.key)
			case ElementKind.INTERFACE:
				new GenInterface(enclosingElAndClassName.value, enclosingElAndClassName.key)
			case ElementKind.ANNOTATION_TYPE:
				new GenAnnotationType(enclosingElAndClassName.value, enclosingElAndClassName.key)
			default:
				throw new ProcessingException('''Invalid element kind in GenClass annotation: «kind»''',
					currentAnnotatedClass)
		}

		generatedClass
	}

	/**
	 * Gets the qualified name of the TypeElement generated by this rule for the currentAnnotatedClass.
	 */
	def String getGeneratedTypeElementFqn() {		
			nameRule.generateQualifiedName(currentAnnotatedClass)		
	}

}
