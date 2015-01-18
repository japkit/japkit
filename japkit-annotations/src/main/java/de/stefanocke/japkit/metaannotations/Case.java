package de.stefanocke.japkit.metaannotations;

public @interface Case {
	
	String cond() default "";
	
	String condLang() default "";
	
	Class<?>[] condFunction() default {};
	
	String value() default "";
	
	String valueLang() default "";
	
	Class<?>[] valueFunction() default {};
}
