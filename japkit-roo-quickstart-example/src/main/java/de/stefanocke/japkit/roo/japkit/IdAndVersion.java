package de.stefanocke.japkit.roo.japkit;

import javax.persistence.Column;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.Version;

import de.stefanocke.japkit.metaannotations.Field;
import de.stefanocke.japkit.metaannotations.Getter;
import de.stefanocke.japkit.metaannotations.Properties;
import de.stefanocke.japkit.metaannotations.Setter;
import de.stefanocke.japkit.metaannotations.Template;
import de.stefanocke.japkit.metaannotations.Var;
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelector;
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelectorKind;
import de.stefanocke.japkit.roo.japkit.IdAndVersion.GeneratedClassSuperClass;

@Template(vars=@Var(name = "superClassProperties", propertyFilter=@Properties(sourceClass=GeneratedClassSuperClass.class)))
public class IdAndVersion {
	@ClassSelector(kind=ClassSelectorKind.EXPR, expr="#{currentGenClass.superclass}")
	static class GeneratedClassSuperClass {}

	@Field(getter=@Getter, setter=@Setter)
	@Id
	@GeneratedValue(strategy = GenerationType.AUTO)
	@Column(name = "id")
	private Long id;

	@Field(getter=@Getter, setter=@Setter)
	@Version
	@Column(name = "version")
	private Integer version;

}
