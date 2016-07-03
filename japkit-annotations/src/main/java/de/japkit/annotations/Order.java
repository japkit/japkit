package de.japkit.annotations;

/**
 * Eclipse APT seems not to obey source element order but to sort enclosed
 * elements alphabetically.
 *  To enforce order, this
 * annotation can be used.
 * <p>
 * Note: Order is especially important for properties, since for example the
 * constructor parameter order of generated constructors depends on it.
 * 
 * @author stefan
 * @see <a href="https://bugs.eclipse.org/bugs/show_bug.cgi?id=300408s">https://bugs.eclipse.org/bugs/show_bug.cgi?id=300408</a>
 * 
 */
public @interface Order {
	/**
	 * 
	 * @return the ordinal number
	 */
	int value();
}
