package de.japkit.roo.japkit.domain;

import javax.persistence.Column;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.Version;

import de.japkit.metaannotations.Field;
import de.japkit.metaannotations.Getter;
import de.japkit.metaannotations.Matcher;
import de.japkit.metaannotations.Setter;
import de.japkit.metaannotations.Template;
import de.japkit.metaannotations.Var;

@Template(vars = @Var(name = "inheritedProperties", expr="#{genClass.superclass.asElement.properties}"),
		fieldDefaults = @Field(condFun = IdAndVersion.notInherited.class,
				getter = @Getter,
				setter = @Setter(modifiers={})))
public class IdAndVersion {

	@Matcher(src = "template", nameNotIn = "inheritedProperties")
	class notInherited{};
	
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
