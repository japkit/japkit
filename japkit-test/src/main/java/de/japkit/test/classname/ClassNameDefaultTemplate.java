package de.japkit.test.classname;

import de.japkit.annotations.RuntimeMetadata;
import de.japkit.metaannotations.Clazz;
import de.japkit.test.members.common.source.SourceExample;

/**
 * By default, "Gen" will be appended to the name of the annotated class to
 * create the name of the generated class. So, for the annotated class
 * {@link SourceExample} the class {@link ClassNameDefaultExampleGen} will be
 * generated in the same package.
 */
@Clazz(commentExpr = "The generated class for the example.")
@RuntimeMetadata
public class ClassNameDefaultTemplate {

}
