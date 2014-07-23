package de.stefanocke.japkit.roo.japkit;

import javax.persistence.Column;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.Version;

import de.stefanocke.japkit.metaannotations.Field;
import de.stefanocke.japkit.metaannotations.Getter;
import de.stefanocke.japkit.metaannotations.Setter;
import de.stefanocke.japkit.metaannotations.Template;

@Template
public class IdAndVersion {
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
