package de.japkit.annotationtemplates;

import jakarta.validation.Constraint;
import jakarta.validation.GroupSequence;
import jakarta.validation.OverridesAttribute;
import jakarta.validation.ReportAsSingleViolation;
import jakarta.validation.Valid;
import jakarta.validation.constraints.AssertFalse;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Null;
import jakarta.validation.constraints.Past;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

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
