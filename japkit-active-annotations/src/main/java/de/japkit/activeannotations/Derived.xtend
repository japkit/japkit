package de.japkit.activeannotations

import java.lang.annotation.Target
import java.lang.annotation.ElementType

/**
 * When a getter is annotated with that, the property is assumed to be calculated from ohter properties.
 * No field or setter is generated.
 */
@Target(value=ElementType.METHOD)
annotation Derived {
	
}