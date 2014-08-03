package de.stefanocke.japkit.roo.japkit;

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

@Template(vars={
		@Var(name = "inheritedProperties", propertyFilter=@Properties(sourceClass=GeneratedClassSuperClass.class)),
		@Var(name = "hasNoInheritedPropertyWithName", isFunction=true, expr="inheritedProperties.find{it.name.contentEquals(src)}==null", lang="GroovyScript"),


})
public class IdAndVersion {
	/**#{src.simpleName}*/
	@Field(activation=@Matcher(condition="#{hasNoInheritedPropertyWithName.eval('id')}"))
	@Getter(activation=@Matcher(condition="#{hasNoInheritedPropertyWithName.eval('id')}"))
	@Setter(activation=@Matcher(condition="#{hasNoInheritedPropertyWithName.eval('id')}"))
	@Id
	@GeneratedValue(strategy = GenerationType.AUTO)
	@Column(name = "id")
	private Long id;

	@Field(activation=@Matcher(condition="#{hasNoInheritedPropertyWithName.eval('version')}"))
	@Getter(activation=@Matcher(condition="#{hasNoInheritedPropertyWithName.eval('version')}"))
	@Setter(activation=@Matcher(condition="#{hasNoInheritedPropertyWithName.eval('version')}"))
	@Version
	@Column(name = "version")
	private Integer version;

}
