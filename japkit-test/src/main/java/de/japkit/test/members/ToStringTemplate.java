package de.japkit.test.members;

import javax.lang.model.element.TypeElement;

import de.japkit.annotations.RuntimeMetadata;
import de.japkit.metaannotations.Function;
import de.japkit.metaannotations.Method;
import de.japkit.metaannotations.Template;

/**
 * A template that adds a simple toString method to the generated class.
 */
@Template
@RuntimeMetadata
public class ToStringTemplate {
	/**
	 * A function to get the fields of a {@link TypeElement}.
	 */
	@Function(expr = "#{enclosedElements}", filter = "#{kind == 'FIELD'}")
	class fields {
	}

	/**
	 * This method prints the field values of the generated class.
	 * 
	 * @japkit.bodyBeforeIteratorCode return "#{src.simpleName} {"+
	 * @japkit.bodyCode "#{name}=" + #{name} +
	 * @japkit.bodySeparator ", " +
	 * @japkit.bodyAfterIteratorCode "}";
	 */
	@Method(bodyIterator = "#{genClass.fields()}", bodyIndentAfterLinebreak = true)
	@Override
	public String toString() {
		return null;
	}

}
