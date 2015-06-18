package de.stefanocke.japkit.roo.japkit.domain;

import java.util.Date;

import javax.validation.constraints.NotNull;
import javax.validation.constraints.Past;
import javax.validation.constraints.Pattern;

import org.springframework.format.annotation.DateTimeFormat;

import de.stefanocke.japkit.metaannotations.Function;
import de.stefanocke.japkit.metaannotations.Library;
import de.stefanocke.japkit.metaannotations.Matcher;
import de.stefanocke.japkit.metaannotations.TypeCategory;
import de.stefanocke.japkit.metaannotations.TypeQuery;

@Library(annotationImports={ValueObject.class, JapkitEntity.class, DateTimeFormat.class, Pattern.class})
public class DomainLibrary {
	@TypeQuery(annotation = JapJpaRepository.class, shadow = true, unique = true, filterAV = "domainType")
	public class findRepository{}
	
	@Matcher(singleValueTypeAnnotations = JapkitEntity.class)
	public class isEntity{}
	
	@Matcher(singleValueTypeAnnotations = ValueObject.class)
	public class isVO{}
	
	
	// Some matchers for categorizing properties
	
	@Matcher(singleValueTypeCategory = TypeCategory.TEMPORAL)
	public class isDatetime{}
	
	@Matcher(type = Date.class)
	public class isDate{}
	
	@Function(expr="#{src.DateTimeFormat.style}")
	public class dateTimeFormatStyle{}
	
	@Matcher(singleValueType = boolean.class)
	public class isBoolean{}
	
	@Matcher(singleValueTypeCategory = TypeCategory.ENUM)
	public class isEnum{}
	
	@Matcher(annotations = NotNull.class)
	public class isRequired{}
	
	@Matcher(annotations = Past.class)
	public class isPast{}
	
	@Function(expr = "#{src.Pattern.regexp}")
	public class regexp{}
	
	@Matcher(typeCategory=TypeCategory.COLLECTION)
	public class isCollection{}
}
