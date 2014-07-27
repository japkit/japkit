package de.stefanocke.japkit.roo.japkit;

import de.stefanocke.japkit.metaannotations.Var;
import de.stefanocke.japkit.metaannotations.Method;
import de.stefanocke.japkit.metaannotations.ParamNames;
import de.stefanocke.japkit.metaannotations.Template;
import de.stefanocke.japkit.metaannotations.classselectors.SrcElementType;

@Template(vars = @Var(expr = "#{src.name.toFirstUpper}", name = "propertyName"))
public class PropertyTemplateTest {
	@Method(nameExpr = "add#{propertyName}")
	@ParamNames("e")
	void add(SrcElementType e) {

	}

	@Method(nameExpr = "remove#{propertyName}")
	@ParamNames("e")
	void remove(SrcElementType e) {

	}
}
