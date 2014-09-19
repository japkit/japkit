package de.stefanocke.japkit.roo.japkit;

import javax.persistence.AttributeOverride;
import javax.persistence.AttributeOverrides;
import javax.persistence.Column;
import javax.persistence.Embeddable;
import javax.persistence.Embedded;
import javax.persistence.Entity;

import de.stefanocke.japkit.roo.japkit.meta.AnnotationTemplates;

@AnnotationTemplates(targetAnnotations = {Column.class, Entity.class, Embeddable.class, Embedded.class, AttributeOverride.class, AttributeOverrides.class})
public class JpaAnnotationTemplates {

	
}
