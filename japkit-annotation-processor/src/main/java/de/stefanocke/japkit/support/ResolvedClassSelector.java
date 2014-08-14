package de.stefanocke.japkit.support;

import javax.lang.model.element.TypeElement;
import javax.lang.model.type.TypeMirror;

import de.stefanocke.japkit.metaannotations.classselectors.ClassSelectorKind;


class ResolvedClassSelector {
	public ClassSelectorKind kind;
	public TypeMirror type;
	public TypeElement typeElement; //currently only for inner class
	public TypeElement enclosingTypeElement; //currently only for inner class
	public String innerClassName;
}
