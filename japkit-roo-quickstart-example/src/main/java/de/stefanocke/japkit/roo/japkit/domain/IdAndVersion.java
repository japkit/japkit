package de.stefanocke.japkit.roo.japkit.domain;

import javax.persistence.Column;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.Version;

import de.stefanocke.japkit.metaannotations.Field;
import de.stefanocke.japkit.metaannotations.Getter;
import de.stefanocke.japkit.metaannotations.Matcher;
import de.stefanocke.japkit.metaannotations.Properties;
import de.stefanocke.japkit.metaannotations.Setter;
import de.stefanocke.japkit.metaannotations.Template;
import de.stefanocke.japkit.metaannotations.Var;

@Template(vars = @Var(name = "inheritedProperties",
		propertyFilter = @Properties(sourceClass = GeneratedClassSuperClass.class)),
		fieldDefaults = @Field(activation = @Matcher(src = "template",
				nameNotIn = "inheritedProperties"),
				getter = @Getter,
				setter = @Setter(modifiers={})))
public class IdAndVersion {

	@Field
	@Id
	@GeneratedValue(strategy = GenerationType.AUTO)
	@Column(name = "id")
	private Long id;

	@Field
	@Version
	@Column(name = "version")
	private Long version;

}
