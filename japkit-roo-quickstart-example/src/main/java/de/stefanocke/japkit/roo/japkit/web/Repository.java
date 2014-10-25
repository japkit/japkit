package de.stefanocke.japkit.roo.japkit.web;

import de.stefanocke.japkit.metaannotations.classselectors.ClassSelector;

@ClassSelector(expr = "#{shadowAnnotation.repository.singleValue}")
public abstract class Repository {
}