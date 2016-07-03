package de.japkit.roo.japkit.web;

/**
 * Makes a property visible in table view.
 * @author stefan
 *
 */
public @interface TableColumn {
	boolean sortable() default true; 
}
