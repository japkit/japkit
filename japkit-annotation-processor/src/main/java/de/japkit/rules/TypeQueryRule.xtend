package de.japkit.rules

import de.japkit.services.ExtensionRegistry
import de.japkit.services.TypesRegistry
import de.japkit.util.MoreCollectionExtensions
import java.util.Collections
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.type.TypeMirror
import org.eclipse.xtend.lib.annotations.Data

import static extension de.japkit.util.MoreCollectionExtensions.filterInstanceOf
import javax.lang.model.element.Element

@Data
class TypeQueryRule extends AbstractFunctionRule<Object> {
		
	TypeMirror triggerAnnotation
	Boolean shadow	
	Boolean unique	
	String filterAV	
	String inExprLang	
	String inExpr
	
	new(AnnotationMirror typeQuery){
		this(typeQuery, null)
	}
	
	new(AnnotationMirror typeQuery, Element e){
		super(typeQuery, e, Object)
		triggerAnnotation = typeQuery.value("annotation", TypeMirror);
		shadow = typeQuery.value("shadow", Boolean);
		unique = typeQuery.value("unique", Boolean);
		filterAV = typeQuery.value("filterAV", String);
		inExpr = typeQuery.value("inExpr", String);
		inExprLang = typeQuery.value("inExprLang", String);
		
	}
	
	override protected evalInternal() {
		val ac = currentAnnotatedClass

		val inTypesSet = if (filterAV.nullOrEmpty)
				emptySet
			else {
				val inTypes = if(inExpr.nullOrEmpty) currentSrc else  eval(inExpr, inExprLang, Object, "inExpr", null)
				
				//TODO: Error reporting, if wrong type
				//TODO: Support for type element?

				(if (inTypes instanceof Iterable<?>) {
					(inTypes as Iterable<TypeMirror>).toSet
				} else {
					Collections.singleton(inTypes as TypeMirror)
				}).map[qualifiedName].toSet

			}

		val types = ExtensionRegistry.get(TypesRegistry).
			findAllTypeElementsWithTriggerAnnotation(ac, triggerAnnotation.qualifiedName, shadow).filter [ te |
				filterAV.nullOrEmpty || {
					val t = te.annotationMirror(triggerAnnotation.qualifiedName).annotationValuesByNameUnwrapped.apply(filterAV)
					if(t instanceof TypeMirror){
						inTypesSet.contains(t.qualifiedName)				
					} else if(t instanceof List<?>){
						//if both values are sets, we return true if they are not disjoint. Does this make any sense? 
						val filterTypes = t.filterInstanceOf(TypeMirror).map[qualifiedName].toSet
						filterTypes.retainAll(inTypesSet)
						!filterTypes.empty
					} else {
						throw new IllegalArgumentException("filterAV must be a type or a set of types, but not "+t);
					}
				}
			].map[asType].sortBy[qualifiedName];

		if(unique) MoreCollectionExtensions.singleValue(types) else types
	}
	
}