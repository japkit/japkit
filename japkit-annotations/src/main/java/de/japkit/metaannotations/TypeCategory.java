package de.japkit.metaannotations;


public enum TypeCategory {

	/** A primitive type or a primitive wrapper type. */
	PRIMITIVE,

	/** A string.*/
	STRING,
	
	/** BigDecimal or BigInteger*/
	MATH,
	
	/** Date or Calendar*/
	TEMPORAL,
	
	/** An enum.*/
	ENUM,
	
	/** An array. */
	ARRAY,
	
	/** A collection type from java.util.** */
	COLLECTION,
	
	/** java.util.Map */
	MAP,
	
	/** java.util.Set*/
	SET,
	
	/** java.util.List*/
	LIST
	
}
