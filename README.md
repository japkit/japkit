japkit
======

[![Maven Central](https://img.shields.io/maven-central/v/com.github.stefanocke.japkit/japkit-parent.svg)](http://mvnrepository.com/artifact/com.github.stefanocke.japkit)
[![Build Status](https://travis-ci.org/stefanocke/japkit.svg?branch=master)](https://travis-ci.org/stefanocke/japkit)


Japkit is an annotation processor that allows to develop Java code generators by using natural templates. That is, a code template that is written in Java (with some annotations) describes what to generate. There is no need to write any imperative code. This makes the code generators short and concise and so eases their maintenance. 
	
Huh?
Okay, an example will help... We will develop a code generator for a simple DTO. The full example can be found [here](https://github.com/stefanocke/japkit-examples/tree/master/japkit-examples-simpledto).

Consider the following interface:

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
- The annotation `@Trigger` tells the annotation processor, that @DTO is an annotation to trigger code generation. 
- The template class `DTOTemplate` (that we will see in a moment) tells what to generate. 
- The annotation value `shadow` is some ceremony required by japkit that you can ignore for the moment. 
- We could define some more annotation values here to make the code generator configurable, but we don't need that yet.

Generate Fields and Accessors
----------------------------

Let's look at the most interesting part, the DTOTemplate:

```Java
@Clazz(nameSuffixToAppend = "DTO")
@RuntimeMetadata
public class DTOTemplate implements SrcInterface {
	@Field(src = "#{src.properties}",	getter = @Getter,	setter = @Setter)
	private SrcType $name$;
}
```

- The annotation `@Clazz` tells the annotation processor that this is a template for generating a new class. 
- The `nameSuffixToAppend` describes the name of the generated class. It shall consist of the name of the source class (which is Person in our case) plus "DTO". So we get PersonDTO.
- `@RuntimeMetadata` should be on every template class. It is again some ceremony of japkit.
- The template implements the interface `SrcInterface`. This is a so called type function that means "use the type of the source here". The source is again Person in our example. So, the generated PersonDTO will implement the Person interface.
- `@Field` tells to generate a field
- Thr annotation value `src` is a JavaEL expression that defines the source the field is generated from. 
- `#{src.properties}` means "all properties of class Person", since Person was the src we started with. Since `#{src.properties}` is a collection, a field will be generated for every element in the collection, that is for every property of class Person.
 - Person is a [TypeElement](https://docs.oracle.com/javase/8/docs/api/javax/lang/model/element/TypeElement.html). So, in the JavaEL expression you have access to all properties of TypeElement. TypeElement does not have any property with the name "properties". However, "properties" is some convinient extension that japkit provides for TypeElements in EL expressions.
- You can generate arbitrary methods with japkit, but getters and setters are so common, that there are convinient `@Getter` and `@Setter` annotations to generate the accessor methods for a field. They allow for some customization, for example fluent setters. But we don't use this feature here.
- Next you see, how the generated field should look like. It is private and it shall have the type and name of the source element (the property of Person).
 - `SrcType` is a type function similar to `SrcInterface` and means to use the type of the source element
 - The $...$ syntax tells japkit to insert the result of an expression evaluation here. `$name$` really means `#{src.name}`. So the name of a property of the class Person is inserted here.

That's it. Besides some setup in the Maven POM of the project (see [Installation](https://github.com/stefanocke/japkit/wiki/Installation), nothing more needs to be done.

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
- The trigger annotation @DTO is copied onto the generated class (since it might provide metadata of use in subsequent code generators). 
- The annotation value `shadow` is set to true. This tells japkit to not trigger code generation again (this time with PersonDTO as source class).
- An `@Generated` annotation is added that tells the source class for code generation.
- The PersonDTO implements Person and has all expected fields and accessors.


Generate a Method
-----------------

The generated code so far was trivial. Let's continue with a `toString()` method:

```Java
public class DTOTemplate implements SrcInterface {
	//...
	
	@Override
	public String toString() {
		return null;
	}
}
```

With this, a `toString()` method is generated in PersonDTO (if not immediately, try a clean build). However, there is a compiler error, since the generated method has no body, yet. 
Why? Annoation processors cannot access the statements in a method body. So the `return null;` above is just a dummy. Even if japkit could access the method bodies of the template classes, it would be of little use, since it is nearly impossible to write valid Java statements that contain template expressions.

One way to go is to write the code template as annotation value:

```Java
public class DTOTemplate implements SrcInterface {
	//...
	
	@Override
	@Method(bodyCode="return \"A #{src.simpleName}.\";")
	public String toString() {
		return null;
	}
}
```

In PersonDTO this yields:

```Java
@Override
public String toString(){
	return "A Person.";
}
```

But the code template is hard to read due to the escaping of the quotes. Thus, japkit also allows to write code templates as JavaDoc comments:

```Java
@Clazz(nameSuffixToAppend = "DTO")
@RuntimeMetadata
public class DTOTemplate implements SrcInterface {
	//...
	
	/**
	 * @japkit.bodyCode return "A #{src.simpleName}.";
	 */
	@Override
	public String toString() {
		return null;
	}
}
```

As you can see, the code template is easier to read. Even the `@Method` annotation is gone again, since every method in a template class is considered to be a template for a method to be generated by default.

To make this work it is important not to forget the `@RuntimeMetadata` annotation: JavaDoc comments are not available in class files. `@RuntimeMetadata` triggers the generation of additional metadata files that provide comments for a template class at runtime (that is, when the source code of the template class is not available to japkit).

Our `toString()` is not satisfying yet. Instead of just returning "A Person." we want to concatenate the properties of the DTO. 
This can be done the following way:

```Java
@Clazz(nameSuffixToAppend = "DTO")
@RuntimeMetadata
public class DTOTemplate implements SrcInterface {
	//...
	
	/**
	 * @japkit.bodyBeforeIteratorCode return "#{src.simpleName} {"+
	 * @japkit.bodyCode "#{name}=" + #{name} +
	 * @japkit.bodySeparator ", " +
	 * @japkit.bodyAfterIteratorCode "}";
	 */
	@Method(bodyIterator = "#{properties}", bodyIndentAfterLinebreak=true)
	@Override
	public String toString() {
		return null;
	}
}
```

- The `bodyIterator` says we want to iterate over the properties of the source class when generating the method body.
 - As you can see here, it is possible to omit `src.` in `#{src.properties}`. It is implicit.
- The `bodyBeforeIteratorCode` and `bodyAfterIteratorCode` is the code to be generate before and after we iterate.
 - Within these two code fragments, the source element is Person.
- The `bodyCode` is generated for each element in the iteration. So we get `"#{name}=" + #{name} +` for each property of the source class.
- The `bodySeparator` is the code to generate between the iterations, but not before the first one and after the last one.

With the template above we get the following in PersonDTO:

```Java
@Override
public String toString(){
	return "Person {"+
		"age=" + age +", " +
		"name=" + name +"}";
}
```

There is a bunch of other ways to generate more complex method body code in japkit. For example, you can define reusable CodeFragments or you can even use Groovy templates.


What next?
----------

There is a more comprehensive step by step tutorial for generating [value objects](https://github.com/stefanocke/japkit-tutorial-valueobject).
The [documentation](https://github.com/stefanocke/japkit/wiki) for japkit is still work in progress and only covers a small part yet.
A complex example for generating whole applications like Spring Roo can be found in the [examples repository}(https://github.com/stefanocke/japkit-examples/tree/master/japkit-examples-roo-petclinic).


