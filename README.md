japkit
======

[![Maven Central](https://img.shields.io/maven-central/v/com.github.stefanocke.japkit/japkit-parent.svg)](http://mvnrepository.com/artifact/com.github.stefanocke.japkit)
[![Build Status](https://travis-ci.org/stefanocke/japkit.svg?branch=master)](https://travis-ci.org/stefanocke/japkit)


Japkit is an annotation processor that allows to develop Java code generators by using natural templates. That is, a code template that is written in Java (with some annotations) describes what to generate. There is no need to write any imperative code. This makes the code generators short and concise and so eases their maintenance. 
	
Huh?
Okay, an example will help... We will develop a code generator for a simple DTO. The full example can be found [here](https://github.com/stefanocke/japkit-examples/tree/master/japkit-examples-simpledto).

Consider the following class:

```Java
@DTO
public interface Person {
	String getName();	
	int getAge();
}
```

Our goal is a code generator that creates a class PersonDTO that implements the interface above and has according fields, getters and setters for the properties that are defined by the getters of the interface.
That generator shall be triggered whenever it finds the @DTO annotation. The annotation does not exist yet, so let's define it:

```Java
@Trigger(template = DTOTemplate.class)
@Target(ElementType.TYPE)
public @interface DTO {
	boolean shadow() default false;
}
```
- The annotation @Trigger tells the annotation processor, that @DTO is an annotation to trigger code generation. 
- The template class DTOTemplate (that we will see in a moment) tells what to generate. 
- The annotation value shadow is some ceremony required by japkit that you can ignore for the moment. 
- We could define some more annotation values here to make the code generator configurable, but we don't need that yet.

Let's look at the most interesting part, the DTOTemplate:

```Java
@Clazz(nameSuffixToAppend = "DTO")
@RuntimeMetadata
public class DTOTemplate implements SrcInterface {
	@Field(src = "#{src.properties}",	getter = @Getter,	setter = @Setter)
	private SrcType $name$;
}
```

- The annotation @Class tells the annotation processor that this is a template for generating a new class. 
- The nameSuffixToAppend describes the name of the generated class. It shall consist of the name of the source class (which is Person in our case) plus "DTO". So we get PersonDTO.
- @RuntimeMetadata should be on every template class. It is again some ceremony of japkit.
- The template implements the interface SrcInterface. This is a so called type function that means "use the type of the source here". The source is again Person in our example. So, the generated PersonDTO will implement the Person interface.
- @Field tells to generate a field
- src is a JavaEL expression that defines from which source the field is generated from. Src is the current source element (the class Person), so `#{src.properties}` means "all properties of class Person". Since this is a collection, a field will be generated for every element in the collection, that is for every property of class Person.
- You can generate arbitrary methods with japkit, but getters and setters are so common, that there are convinient @Getter and @Setter annotations to generate the accessor methods for a field. They allow for some customization, for example fluent setters. But we don't us this feature here.
- Next you see, how the generated field should look like. It is private and it shall have the type and name of the source element (the property of Person).
 - SrcType is a type function similar to SrcInterface and means to use the type of the source element
 - The $...$ syntax tells japkit to insert the result of an expression evaluation here. `$name$` really means `#{src.name}`. So the name of a property of the class Person is inserted here.

That's it. Besides some setup in the Maven POM of the project, nothing more needs to be done.

Finally, this is the code that will be generated:
```Java
@DTO(shadow = true)
@Generated(src = "de.japkit.examples.simpledto.test.Person")
public class PersonDTO implements Person {
	private String name;
	
	private int age;
	
	public String getName(){
		return name;
	}
  
	public void setName(String name){
		this.name = name;
	}
	
	public int getAge(){
		return age;
	}
	
	public void setAge(int age){
		this.age = age;
	}	
}
```
- The trigger annoation @DTO is copied onto the generated class (since it might provide metadata of use in subsequent code generators). 
- The annoation value "shadow" is set to true. This tells japkit to not trigger code generation again (this time with PersonDTO as source class).
- An @Generated annotation is added that tells the source class for code generation.
- The PersonDTO implements Person and has all expected fields and accessors.



