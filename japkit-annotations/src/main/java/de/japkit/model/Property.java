package de.japkit.model;

import javax.lang.model.element.Element;
import javax.lang.model.element.ExecutableElement;
import javax.lang.model.element.VariableElement;
import javax.lang.model.type.TypeMirror;

public interface Property extends VariableElement {

	/**
	 * 
	 * @return the name of the property. same as {@link #getSimpleName()}.toString().
	 */
	String getName();
	
	/**
	 * 
	 * @return the type of the property. same as {@link #asType()}.
	 */
	TypeMirror getType();

	/**
	 * @return the field, if existent. 
	 */
	VariableElement getField();

	/**
	 * @return the getter, if existent. 
	 */
	ExecutableElement getGetter();
	
	/**
	 * The source of the property. If it was a field, the field is returned. Otherwise the getter.
	 */
	Element fieldOrGetter();

	/**
	 * @return the setter, if existent. 
	 */
	ExecutableElement getSetter();
	
	/** 
	 * @return the name of the getter according to Java Beans conventions. Is not null, even if there is no getter.
	 */
	String getGetterName();
	  
	/** 
	 * @return the name of the setter according to Java Beans conventions. Is not null, even if there is no setter.
	 */
	String getSetterName();

}
