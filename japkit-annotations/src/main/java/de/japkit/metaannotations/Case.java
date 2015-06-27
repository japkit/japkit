package de.japkit.metaannotations;

public @interface Case {
	
	String cond() default "";
	
	String condLang() default "";
	
	Class<?>[] condFun() default {};
	
	String value() default "";
	
	String valueLang() default "";
	
	Class<?>[] valueFun() default {};
}
