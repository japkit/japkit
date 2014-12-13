package de.stefanocke.japkit.roo.japkit.domain;

import de.stefanocke.japkit.metaannotations.Library;
import de.stefanocke.japkit.metaannotations.Matcher;
import de.stefanocke.japkit.metaannotations.TypeQuery;

@Library(annotationImports={ValueObject.class, JapkitEntity.class})
public class DomainLibrary {
	@TypeQuery(annotation = JapJpaRepository.class, shadow = true, unique = true, filterAV = "domainType")
	class findRepository{}
	
	@Matcher(singleValueTypeAnnotations = JapkitEntity.class)
	class isEntity{}
	
	@Matcher(singleValueTypeAnnotations = ValueObject.class)
	class isVO{}
	
}
