package de.japkit.roo.japkit.domain;

import java.util.Date;

import javax.persistence.Id;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Past;
import javax.validation.constraints.Pattern;

import org.springframework.format.annotation.DateTimeFormat;

import de.japkit.metaannotations.Function;
import de.japkit.metaannotations.Library;
import de.japkit.metaannotations.Matcher;
import de.japkit.metaannotations.TypeCategory;
import de.japkit.metaannotations.TypeQuery;

@Library(annotationImports={ValueObject.class, JapkitEntity.class, DateTimeFormat.class, Pattern.class})
public class DomainLibrary {
	@TypeQuery(annotation = JapJpaRepository.class, shadow = true, unique = true, filterAV = "domainType")
	public class findRepository{}
	
	@Matcher(singleValueTypeAnnotations = JapkitEntity.class)
	public class isEntity{}
	
	@Matcher(singleValueTypeAnnotations = ValueObject.class)
	public class isVO{}
	
	@Function(expr="#{src.properties}", filterFun=isId.class, unique=true)
	public class findIdProperty{}
	
	
	//TODO: Use "business-id" instead of technical. (UUID)
	@Matcher(annotations=Id.class)
	public class isId{}
	
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
	
	@Function(expr = "#{src.Pattern.regexp}", nullable=true)
	public class regexp{}
	
	@Matcher(typeCategory=TypeCategory.COLLECTION)
	public class isCollection{}
}
