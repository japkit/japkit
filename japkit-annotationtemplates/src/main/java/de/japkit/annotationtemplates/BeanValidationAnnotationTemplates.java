package de.japkit.annotationtemplates;

import javax.validation.Constraint;
import javax.validation.GroupSequence;
import javax.validation.OverridesAttribute;
import javax.validation.ReportAsSingleViolation;
import javax.validation.Valid;
import javax.validation.constraints.AssertFalse;
import javax.validation.constraints.AssertTrue;
import javax.validation.constraints.DecimalMax;
import javax.validation.constraints.DecimalMin;
import javax.validation.constraints.Digits;
import javax.validation.constraints.Future;
import javax.validation.constraints.Max;
import javax.validation.constraints.Min;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Null;
import javax.validation.constraints.Past;
import javax.validation.constraints.Pattern;
import javax.validation.constraints.Size;

@AnnotationTemplates(targetAnnotations = { 
		Constraint.class,
		GroupSequence.class,
		OverridesAttribute.class,
		ReportAsSingleViolation.class,
		Valid.class,
		AssertFalse.class,
		AssertTrue.class,
		DecimalMax.class,
		DecimalMin.class,
		Digits.class,
		Future.class,
		Max.class,
		Min.class,
		NotNull.class,
		Null.class,
		Past.class,
		Pattern.class,
		Size.class

})
public class BeanValidationAnnotationTemplates {

}
