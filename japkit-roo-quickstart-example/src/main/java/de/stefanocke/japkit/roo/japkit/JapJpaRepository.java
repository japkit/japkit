package de.stefanocke.japkit.roo.japkit;

import javax.lang.model.element.ElementKind;
import javax.lang.model.element.Modifier;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import de.stefanocke.japkit.metaannotations.Annotation;
import de.stefanocke.japkit.metaannotations.Clazz;

@Clazz(nameSuffixToRemove = "RepositoryDef", nameSuffixToAppend = "Repository", modifiers = Modifier.PUBLIC,
		kind = ElementKind.INTERFACE, interface1 = JpaRepository.class, interface1TypeArgs = { DomainType.class, Long.class },
		interface2 = JpaSpecificationExecutor.class, interface2TypeArgs = DomainType.class, annotations = @Annotation(
				targetAnnotation = Repository.class))
public @interface JapJpaRepository {
	boolean shadow() default false;

	Class<?> domainType();
}
