package de.japkit.test.classname;

import de.japkit.annotations.RuntimeMetadata;
import de.japkit.metaannotations.Clazz;
import de.japkit.test.classname.ClassNameSuffixExampleModel;

/**
 * In this example the custom suffix "Impl" is used for the name of the
 * generated class. Before appending it, the suffix "Model" is removed from the
 * name of the annotated class. So, for the annotated class
 * {@link ClassNameSuffixExampleModel} the class
 * {@link ClassNameSuffixExampleImpl} will be generated in the same package.
 */
@Clazz(nameSuffixToAppend = "Impl", nameSuffixToRemove = "Model", commentExpr = "The generated class for the example.")
@RuntimeMetadata
public class ClassNameSuffixTemplate {

}
