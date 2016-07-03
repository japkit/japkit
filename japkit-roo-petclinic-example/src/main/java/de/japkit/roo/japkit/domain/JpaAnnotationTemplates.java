package de.japkit.roo.japkit.domain;

import javax.persistence.AttributeOverride;
import javax.persistence.AttributeOverrides;
import javax.persistence.Column;
import javax.persistence.Embeddable;
import javax.persistence.Embedded;
import javax.persistence.Entity;

import de.japkit.roo.japkit.meta.AnnotationTemplates;

@AnnotationTemplates(targetAnnotations = {Column.class, Entity.class, Embeddable.class, Embedded.class, AttributeOverride.class, AttributeOverrides.class})
public class JpaAnnotationTemplates {

	
}
