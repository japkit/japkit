package de.stefanocke.japkit.roo.japkit.domain;

import de.stefanocke.japkit.annotations.ParamNames;
import de.stefanocke.japkit.metaannotations.Method;
import de.stefanocke.japkit.metaannotations.Template;
import de.stefanocke.japkit.metaannotations.Var;
import de.stefanocke.japkit.metaannotations.classselectors.SrcType;

@Template(vars = @Var(expr = "#{src.name.toFirstUpper}", name = "propertyName"))
public class PropertyTemplateTest {
	@Method(nameExpr = "add#{propertyName}")
	@ParamNames("e")
	void add(SrcType e) {

	}

	@Method(nameExpr = "remove#{propertyName}")
	@ParamNames("e")
	void remove(SrcType e) {

	}
}
