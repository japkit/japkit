package de.japkit.test.classname;

import de.japkit.annotations.RuntimeMetadata;
import de.japkit.metaannotations.Clazz;

/**
 * In this example the custom prefix "Generated" is used for the name of the
 * generated class. Before appending it, the prefix "I" (like in "interface") is
 * removed from the name of the annotated class. Furthermore, the default suffix
 * "Gen" is overwritten with an empty string. So, for the annotated class
 * {@link IClassNamePrefixExample} the class
 * {@link GeneratedClassNamePrefixExample} will be generated in the same
 * package.
 */
@Clazz(
		namePrefixToPrepend = "Generated",
		namePrefixToRemove = "I",
		nameSuffixToAppend = "",
		commentExpr = "The generated class for the example.")
@RuntimeMetadata
public class ClassNamePrefixTemplate {

}
