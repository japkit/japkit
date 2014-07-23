package de.stefanocke.japkit.roo.japkit;

import javax.persistence.Column;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.Version;

import de.stefanocke.japkit.metaannotations.Field;
import de.stefanocke.japkit.metaannotations.Template;

@Template
public class IdAndVersion {
	@Field(generateGetter=true, generateSetter=true)
	@Id
	@GeneratedValue(strategy = GenerationType.AUTO)
	@Column(name = "id")
	private Long id;

	@Field(generateGetter=true, generateSetter=true)
	@Version
	@Column(name = "version")
	private Integer version;

}
