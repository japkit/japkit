package de.japkit.roo.japkit.domain;

import javax.lang.model.element.ElementKind;
import javax.lang.model.element.Modifier;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import de.japkit.metaannotations.Annotation;
import de.japkit.metaannotations.Clazz;
import de.japkit.metaannotations.Trigger;
import de.japkit.roo.japkit.Layers;

@Trigger(layer=Layers.REPOSITORIES)
@Clazz(nameSuffixToRemove = "RepositoryDef", nameSuffixToAppend = "Repository", modifiers = Modifier.PUBLIC,
		kind = ElementKind.INTERFACE, interface1 = JpaRepository.class, interface1Args = { DomainType.class, Long.class },
		interface2 = JpaSpecificationExecutor.class, interface2Args = DomainType.class, annotations = @Annotation(
				targetAnnotation = Repository.class))
public @interface JapJpaRepository {
	boolean shadow() default false;

	Class<?> domainType();
}
