package de.stefanocke.japkit.rules

import java.lang.annotation.Annotation
import javax.lang.model.element.Element
import javax.lang.model.element.ElementVisitor
import javax.lang.model.element.ExecutableElement
import javax.lang.model.element.VariableElement
import javax.lang.model.type.TypeMirror
import de.stefanocke.japkit.model.GenName
import de.stefanocke.japkit.metaannotations.Properties

@Data
class Property implements VariableElement {

	/** The type of the property. */
	TypeMirror type //TODO: Redundant?

	/** The name of the property. */
	String name //TODO: Redundant?

	/** The getter, if existent. */
	ExecutableElement getter

	/** The setter, if existent. */
	ExecutableElement setter

	/** The field, the property relates to, if existent. */
	VariableElement field

	new(TypeMirror type, String name, ExecutableElement getter, ExecutableElement setter, VariableElement field) {
		_type = type
		_name = name
		_getter = getter
		_setter = setter
		_field = field
	}
	
	new(VariableElement field, ExecutableElement getter, ExecutableElement setter) {
		this(field.asType, field.simpleName.toString, getter, setter, field)
	}
	
	new(VariableElement field) {
		this(field.asType, field.simpleName.toString, null, null, field)
	}

	new(TypeMirror type, String name) {
		this(type, name, null, null, null)
	}

	def withSetter(ExecutableElement setter) {
		new Property(type, name, getter, setter, field)
	}

	def withGetter(ExecutableElement getter) {
		new Property(type, name, getter, setter, field)
	}

	def withField(VariableElement field) {
		new Property(type, name, getter, setter, field)
	}

	override <R, P> accept(ElementVisitor<R, P> v, P p) {
		throw new UnsupportedOperationException("Not supported for class Property.")
	}

	override asType() {
		type
	}

	override <A extends Annotation> getAnnotation(Class<A> annotationType) {
		fieldOrGetter.getAnnotation(annotationType)
	}

	override getAnnotationMirrors() {
		fieldOrGetter.annotationMirrors
	}

	override getEnclosedElements() {
		fieldOrGetter.enclosedElements
	}

	override getEnclosingElement() {
		fieldOrGetter.enclosingElement
	}

	override getKind() {
		throw new UnsupportedOperationException("Not supported for class Property, since it is a derived element.")
	}

	override getModifiers() {
		fieldOrGetter.modifiers
	}

	override getSimpleName() {
		new GenName(name)
	}

	def Element fieldOrGetter() {
		if(field != null) field else getter
	}
	
	override getConstantValue() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	
	def getSourceElement(Properties.RuleSource ruleSource) {
		switch (ruleSource) {
			case Properties.RuleSource.PROPERTY: this
			case Properties.RuleSource.FIELD: field
			case Properties.RuleSource.GETTER: getter
		}
	}
	
	override String toString(){
		name.toString
	}

}
