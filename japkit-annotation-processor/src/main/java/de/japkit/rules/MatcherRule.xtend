package de.japkit.rules

import de.japkit.metaannotations.TypeCategory
import java.util.Set
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.ElementKind
import javax.lang.model.element.Modifier
import javax.lang.model.element.TypeElement
import javax.lang.model.type.DeclaredType
import javax.lang.model.type.TypeKind
import javax.lang.model.type.TypeMirror
import org.eclipse.xtend.lib.annotations.Data
import de.japkit.rules.RuleException

@Data
class MatcherRule extends AbstractFunctionRule<Boolean> {

	String srcExpr
	String srcLang
	String name
	Modifier[] modifiers
	Modifier[] modifiersNot
	Set<ElementKind> kind
	DeclaredType[] annotations
	DeclaredType[] annotationsNot
	DeclaredType[] enclosingAnnotations
	DeclaredType[] enclosingAnnotationsNot
	Set<String> notDeclaredBy // FQNs
	TypeMirror elementType
	TypeCategory[] typeCategory
	TypeCategory[] typeCategoryNot
	DeclaredType[] typeAnnotations
	TypeMirror singleValueType
	TypeCategory[] singleValueTypeCategory
	TypeCategory[] singleValueTypeCategoryNot
	DeclaredType[] singleValueTypeAnnotations
	DeclaredType[] typeArg0Annotations
	DeclaredType[] typeArg1Annotations
	String condition
	String conditionLang

	// TODO: Move this to scopeRule?
	ConstraintRule[] constraints

	(CharSequence)=>boolean nameIn
	(CharSequence)=>boolean nameNotIn

	def filter(Iterable<?> elements) {
		elements.filter [
			if (!(it instanceof Element)) {
				throw new IllegalArgumentException('''Matcher can only be applied to elements, but not to «it»''')
			}
			matches(it as Element)
		]
	}

	def matches(Element originalSrcElement) {
		apply(originalSrcElement)
	}

	override evalInternal() {

		val src = srcElementOrType(currentSrc)

		scope(src) [

			val e = if(src instanceof Element) src
			val type = if(src instanceof TypeMirror) src else e?.srcType
			
			if(e === null && type === null) {
				throw new RuleException('''For a Matcher, the source must be an Element or a TypeMirror, but src «src» is of type «src?.class»''');
			}
			
			if(e === null && hasAnyElementConditions) {
				throw new RuleException('''The Matcher has conditions that apply to an Element, but src «src» is a TypeMirror.''');
			}
			

			val result = 
				(e === null || fulfillsElementConditions(e)) 
				&& (type === null || fulfillsTypeConditions(type)) 
				&& fulfillsConditionExpression

			// evaluate all constraints, if the matcher matches
			if (result) {
				constraints.forEach[validate]
			}

			result

		]

	}

	private def boolean fulfillsTypeConditions(TypeMirror type) {
		type.hasAllAnnotations(typeAnnotations) && type.isSubtype(elementType) &&
			(typeCategory.nullOrEmpty || type.belongsToOneOfCategories(typeCategory)) &&
			!type.belongsToOneOfCategories(typeCategoryNot) &&
			type.singleValueType.hasAllAnnotations(singleValueTypeAnnotations) &&
			type.singleValueType.isSubtype(singleValueType) &&
			(singleValueTypeCategory.nullOrEmpty ||
				type.singleValueType.belongsToOneOfCategories(singleValueTypeCategory)) &&
			!type.singleValueType.belongsToOneOfCategories(singleValueTypeCategoryNot) &&
			type.typeArgHasAllAnnotations(typeArg0Annotations, 0) &&
			type.typeArgHasAllAnnotations(typeArg1Annotations, 1)
	}

	private def boolean fulfillsElementConditions(Element e) {
		(name.nullOrEmpty || name.contentEquals(e.simpleName)) && (nameIn?.apply(e.simpleName) ?: true) &&
			!(nameNotIn?.apply(e.simpleName) ?: false) && e.hasAllModifiers(modifiers) && e.hasNotModifiers(modifiersNot) &&
			e.hasAnyKind(kind) && e.hasAllAnnotations(annotations) && e.hasNotAnnotations(annotationsNot) &&
			e.enclosingElement.hasAllAnnotations(enclosingAnnotations) &&
			e.enclosingElement.hasNotAnnotations(enclosingAnnotationsNot) && e.isNotDeclaredBy(notDeclaredBy)
	}
	
	private def boolean hasAnyElementConditions() {
		!name.nullOrEmpty || nameIn !== null || nameNotIn !== null || !modifiers.empty || !modifiersNot.empty ||
			!kind.empty || !annotations.empty || !annotationsNot.empty || !enclosingAnnotations.empty || !enclosingAnnotationsNot.empty ||
			!notDeclaredBy.empty 
	}

	def private Object srcElementOrType(Object src) {
		if (srcExpr.nullOrEmpty)
			src
		else
			eval(srcExpr, srcLang,
				Object, 'src', null)

	}

	def private boolean isNotDeclaredBy(Element element, Set<String> notDeclaredByFqns) {
		notDeclaredByFqns.nullOrEmpty ||
			!notDeclaredByFqns.contains((element.enclosingElement as TypeElement).qualifiedName.toString)
	}

	def private boolean hasAnyKind(Element element, ElementKind[] kinds) {
		kinds.nullOrEmpty || kinds.contains(element.kind)
	}

	def private boolean hasAllModifiers(Element e, Modifier[] modifiers) {
		modifiers.nullOrEmpty || modifiers.forall[e.modifiers.contains(it)]
	}

	def private boolean hasNotModifiers(Element e, Modifier[] modifiers) {
		modifiers.nullOrEmpty || modifiers.forall[!e.modifiers.contains(it)]
	}

	def private boolean isSubtype(TypeMirror t1, TypeMirror type) {
		type.isJavaLangObject || // shortcut to avoid unnecessary type lookups
		_typesExtensions.isSubtype(t1, type)
	}

	def private boolean belongsToOneOfCategories(TypeMirror type, TypeCategory[] categories) {
		categories.exists[type.belongsToCategory(it)]
	}

	def private Boolean belongsToCategory(TypeMirror type, TypeCategory category) {
		handleTypeElementNotFound(false, '''Could not determine type category of type «type»''') [
			switch (category) {
				case TypeCategory.PRIMITIVE: type.primitive || type.boxed
				case TypeCategory.STRING: type.string
				case TypeCategory.TEMPORAL: type.temporal
				case TypeCategory.MATH: type.math
				case TypeCategory.ARRAY: type.kind == TypeKind.ARRAY
				case TypeCategory.COLLECTION: type.collection
				case TypeCategory.MAP: type.map
				case TypeCategory.LIST: type.list
				case TypeCategory.SET: type.set
				case TypeCategory.ENUM: type.enum
				default: throw new IllegalArgumentException('''Unknown type category «category»''')
			}
		]
	}

	def private boolean fulfillsConditionExpression() {
		condition.nullOrEmpty ||
			eval(condition, conditionLang,
				Boolean, 'condition', false)
	}

	def private boolean hasAllAnnotations(TypeMirror type, DeclaredType[] annotations) {
		annotations.nullOrEmpty || // avoid to get type element as far as possible	
		type.typeElementHasAllAnnotations(annotations)
	}

	def private boolean typeArgHasAllAnnotations(TypeMirror type, DeclaredType[] annotations, int argIndex) {
		annotations.nullOrEmpty || // avoid to get type element as far as possible	
		type.getTypeArg(argIndex).typeElementHasAllAnnotations(annotations)
	}

	def private boolean typeElementHasAllAnnotations(TypeMirror type, DeclaredType[] annotations) {
		if(!type.isDeclaredOrError ) return annotations.nullOrEmpty;
		
		handleTypeElementNotFound(true, '''Matcher cannot determine annotations of type «type»''') [
			type !== null && type.asTypeElement.hasAllAnnotations(annotations)
		]
	}


	def private boolean hasAllAnnotations(Element e, DeclaredType[] annotations) {
		annotations.forall[e.hasAnnotation(it)]
	}

	def private boolean hasNotAnnotations(Element e, DeclaredType[] annotations) {
		annotations.forall[!e.hasAnnotation(it)]
	}

	def private boolean hasAnnotation(Element e, DeclaredType annotationType) {
		e.annotationMirrors.exists[am|am.hasFqn(annotationType.qualifiedName)]
	}

	new(AnnotationMirror am) {
		this(am, null)
	}

	new(AnnotationMirror am, Element element) {
		super(am, element, boolean)
		srcExpr = am.value("src", String)
		srcLang = am.value("srcLang", String)
		name = am.value("name", String)
		modifiers = am.value("modifiers", typeof(Modifier[]))
		modifiersNot = am.value("modifiersNot", typeof(Modifier[]))
		kind = am.value("kind", typeof(ElementKind[]))?.toSet
		annotations = am.value("annotations", typeof(DeclaredType[]))
		annotationsNot = am.value("annotationsNot", typeof(DeclaredType[]))
		enclosingAnnotations = am.value("enclosingAnnotations", typeof(DeclaredType[]))
		enclosingAnnotationsNot = am.value("enclosingAnnotationsNot", typeof(DeclaredType[]))
		notDeclaredBy = am.value("notDeclaredBy", typeof(DeclaredType[]))?.map[asTypeElement.qualifiedName.toString].
			toSet
		elementType = am.value("type", TypeMirror)
		typeCategory = am.value("typeCategory", typeof(TypeCategory[]))
		typeCategoryNot = am.value("typeCategoryNot", typeof(TypeCategory[]))
		typeAnnotations = am.value("typeAnnotations", typeof(DeclaredType[]))
		singleValueType = am.value("singleValueType", TypeMirror)
		singleValueTypeCategory = am.value("singleValueTypeCategory", typeof(TypeCategory[]))
		singleValueTypeCategoryNot = am.value("singleValueTypeCategoryNot", typeof(TypeCategory[]))
		singleValueTypeAnnotations = am.value("singleValueTypeAnnotations", typeof(DeclaredType[]))
		typeArg0Annotations = am.value("typeArg0Annotations", typeof(DeclaredType[]))
		typeArg1Annotations = am.value("typeArg1Annotations", typeof(DeclaredType[]))
		condition = am.value("condition", String)
		conditionLang = am.value("conditionLang", String)
		constraints = am.value("constraints", typeof(AnnotationMirror[])).map[new ConstraintRule(it)]
		nameIn = createNameInSetRule(am, "nameIn")
		nameNotIn = createNameInSetRule(am, "nameNotIn")

	}

}
