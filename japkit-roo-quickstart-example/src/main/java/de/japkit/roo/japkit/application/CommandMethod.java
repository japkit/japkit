package de.japkit.roo.japkit.application;

import java.lang.annotation.ElementType;
import java.lang.annotation.Target;

@Target(ElementType.METHOD)
public @interface CommandMethod {
	Class<?> aggregateRoot();
}
