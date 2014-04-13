package de.stefanocke.japkit.roo.japkit;

import javax.persistence.Column;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.Version;

import de.stefanocke.japkit.metaannotations.AnnotationMapping;
import de.stefanocke.japkit.metaannotations.Properties;

@Properties(sourceClass=IdAndVersion.class, fromFields=true, annotationMappings = @AnnotationMapping(copyAnnotationsFromPackages="*"))
public class IdAndVersion {
	@Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "id")
    private Long id;
    
    @Version
    @Column(name = "version")
    private Integer version;
    
}
