package de.stefanocke.japkit.rules

import de.stefanocke.japkit.metaannotations.TypeCategory
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

@Data
class ElementMatcher extends AbstractNoArgFunctionRule<Boolean>{

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
	Set<String> notDeclaredBy //FQNs
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
	
	//TODO: Move this to scopeRule?
	ConstraintRule[] constraints
	
	
	(CharSequence)=>boolean nameIn
	(CharSequence)=>boolean nameNotIn

	def filter(Iterable<?> elements){
		elements.filter[
			if(!(it instanceof Element)){
				throw new IllegalArgumentException('''Matcher can only be applied to elements, but not to «it»''')
			}
			matches(it as Element)
		]
	}
	
	def matches(Element originalSrcElement){
		apply(originalSrcElement)
	}

	override evalInternal(){
		
		val e = srcElement(currentSrcElement) 
		
		scope(e)[
			val result = (e!=null)
			&& (name.nullOrEmpty || name.contentEquals(e.simpleName))
			&& nameIn.apply(e.simpleName)
			&& !nameNotIn.apply(e.simpleName)
			&& e.hasAllModifiers(modifiers)
			&& e.hasNotModifiers(modifiersNot)
			&& e.hasAnyKind(kind)
			&& e.hasAllAnnotations(annotations)
			&& e.hasNotAnnotations(annotationsNot)
			&& e.enclosingElement.hasAllAnnotations(enclosingAnnotations)
			&& e.enclosingElement.hasNotAnnotations(enclosingAnnotationsNot)
			&& e.isNotDeclaredBy(notDeclaredBy)
			
			&& e.srcType.hasAllAnnotations(typeAnnotations)		
			&& e.srcType.isSubtype(elementType)
			&& (typeCategory.nullOrEmpty || e.srcType.belongsToOneOfCategories(typeCategory))	
			&& !e.srcType.belongsToOneOfCategories(typeCategoryNot)	
				
			&& e.srcSingleValueType.hasAllAnnotations(singleValueTypeAnnotations)
			&& e.srcSingleValueType.isSubtype(singleValueType)
			&& (singleValueTypeCategory.nullOrEmpty || e.srcSingleValueType.belongsToOneOfCategories(singleValueTypeCategory))	
			&& !e.srcSingleValueType.belongsToOneOfCategories(singleValueTypeCategoryNot)	
				
			&& e.srcTypeArgHasAllAnnotations(typeArg0Annotations, 0)
			&& e.srcTypeArgHasAllAnnotations(typeArg1Annotations, 1)
			&& fulfillsCondition(e)
			
			//evaluate all constraints, if the matcher matches
			if(result){
				constraints.forEach[validate] 
			}
			
			result
		
		]
		
		
	}
	
	def private Element srcElement(Element element) {
			if(srcExpr.nullOrEmpty) element else 
				eval(srcExpr, srcLang, Element, '''Could not evaluate source element expression '«srcExpr»' in element matcher. ''', null)
			
		
	}
	
	
	def private boolean isNotDeclaredBy(Element element, Set<String> notDeclaredByFqns){
		notDeclaredByFqns.nullOrEmpty || !notDeclaredByFqns.contains((element.enclosingElement as TypeElement).qualifiedName.toString)
	}
	
	def private boolean hasAnyKind(Element element, ElementKind[] kinds){
		kinds.nullOrEmpty || kinds.contains(element.kind) 
	}
	
	
	def private boolean hasAllModifiers(Element e, Modifier[] modifiers){
		modifiers.nullOrEmpty || modifiers.forall[e.modifiers.contains(it)]
	}
	
	def private boolean hasNotModifiers(Element e, Modifier[] modifiers){
		modifiers.nullOrEmpty || modifiers.forall[!e.modifiers.contains(it)]
	}
	
	def private boolean isSubtype(TypeMirror t1, TypeMirror type) {
		type.isJavaLangObject ||  //shortcut to avoid unnecessary type lookups
		_typesExtensions.isSubtype(t1, type) 
	}
	
	def private boolean belongsToOneOfCategories(TypeMirror type, TypeCategory[] categories){
		categories.exists[type.belongsToCategory(it)]	
	}
	
	def private Boolean belongsToCategory(TypeMirror type, TypeCategory category){
		handleTypeElementNotFound(false, '''Could not determine type category of type «type»''')[
			switch(category){
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
	
	
	
	def private boolean fulfillsCondition(Element element) {
			condition.nullOrEmpty || 
				eval(condition, conditionLang, Boolean, '''Could not evaluate condition '«condition»' in element matcher. ''', false)		
	}

	def private boolean hasAllAnnotations(TypeMirror type, DeclaredType[] annotations) {
		annotations.nullOrEmpty ||		//avoid to get type element as far as possible	
		type.typeElementHasAllAnnotations(annotations)
	}
	
	def private boolean srcTypeArgHasAllAnnotations(Element e, DeclaredType[] annotations, int argIndex) {
		annotations.nullOrEmpty ||		//avoid to get type element as far as possible	
		e.srcType.getTypeArg(argIndex).typeElementHasAllAnnotations(annotations)	 
	}
	
	def private TypeMirror srcSingleValueType(Element e){
		singleValueType(e.srcType)
	}
	
	
	
	
	def private dispatch boolean typeElementHasAllAnnotations(DeclaredType type, DeclaredType[] annotations) {
		handleTypeElementNotFound(true, '''Matcher cannot determine annotations of type «type»''')[
			type!=null && type.asTypeElement.hasAllAnnotations(annotations)	
		]		
	}
	
	def private dispatch boolean typeElementHasAllAnnotations(TypeMirror type, DeclaredType[] annotations) {
		annotations.nullOrEmpty
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
		super(am, null, boolean)
		srcExpr =  am.value("src", String)
		srcLang =  am.value("srcLang", String)
		name = am.value("name", String)
		modifiers = am.value("modifiers", typeof(Modifier[]))
		modifiersNot = am.value("modifiersNot", typeof(Modifier[]))
		kind = am.value("kind", typeof(ElementKind[]))?.toSet
		annotations = am.value("annotations", typeof(DeclaredType[]))
		annotationsNot = am.value("annotationsNot", typeof(DeclaredType[]))
		enclosingAnnotations = am.value("enclosingAnnotations", typeof(DeclaredType[]))
		enclosingAnnotationsNot = am.value("enclosingAnnotationsNot", typeof(DeclaredType[]))
		notDeclaredBy = am.value("notDeclaredBy", typeof(DeclaredType[]))?.map[asTypeElement.qualifiedName.toString].toSet
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
		condition =  am.value("condition", String)
		conditionLang =  am.value("conditionLang", String)
		constraints = am.value("constraints", typeof(AnnotationMirror[])).map[new ConstraintRule(it)]	
		nameIn = createNameInSetRule(am, "nameIn", true)
		nameNotIn = createNameInSetRule(am, "nameNotIn", false)
		
	}
	
}
