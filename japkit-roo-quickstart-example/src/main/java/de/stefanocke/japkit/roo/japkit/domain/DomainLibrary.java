package de.stefanocke.japkit.roo.japkit.domain;

import javax.validation.constraints.NotNull;
import javax.validation.constraints.Past;

import de.stefanocke.japkit.metaannotations.Function;
import de.stefanocke.japkit.metaannotations.Library;
import de.stefanocke.japkit.metaannotations.Matcher;
import de.stefanocke.japkit.metaannotations.TypeCategory;
import de.stefanocke.japkit.metaannotations.TypeQuery;

@Library(annotationImports={ValueObject.class, JapkitEntity.class})
public class DomainLibrary {
	@TypeQuery(annotation = JapJpaRepository.class, shadow = true, unique = true, filterAV = "domainType")
	class findRepository{}
	
	@Matcher(singleValueTypeAnnotations = JapkitEntity.class)
	class isEntity{}
	
	@Matcher(singleValueTypeAnnotations = ValueObject.class)
	class isVO{}
	
	
	// Some matchers for categorizing properties
	
	@Matcher(singleValueTypeCategory = TypeCategory.TEMPORAL)
	class isDatetime{}
	
	@Matcher(singleValueType = boolean.class)
	class isBoolean{}
	
	@Matcher(singleValueTypeCategory = TypeCategory.ENUM)
	class isEnum{}
	
	@Matcher(annotations = NotNull.class)
	class isRequired{}
	
	@Matcher(annotations = Past.class)
	class isPast{}
	
	@Function(expr = "#{src.Pattern.regexp}")
	class regexp{}
}
