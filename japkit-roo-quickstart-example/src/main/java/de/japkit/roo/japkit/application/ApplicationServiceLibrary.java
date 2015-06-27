package de.japkit.roo.japkit.application;

import de.japkit.metaannotations.Function;
import de.japkit.metaannotations.Library;
import de.japkit.metaannotations.Matcher;
import de.japkit.metaannotations.TypeQuery;

@Library(annotationImports=CommandMethod.class)
public class ApplicationServiceLibrary {
	
	@TypeQuery(annotation = ApplicationService.class, shadow = true, unique = true, filterAV = "aggregateRoots")
	public class findApplicationService{}
	
	@Function(expr="#{src.CommandMethod.aggregateRoot}")
	class cmdAggregateRoot{}
	
	@Matcher(annotations=CommandMethod.class, condition="#{src.returnType.isSame(fbo) && src.cmdAggregateRoot.isSame(fbo)}")
	class isCreateCommand{}
	
	@Matcher(annotations=CommandMethod.class, type=void.class , condition="#{src.cmdAggregateRoot.isSame(fbo)}")
	class isUpdateCommand{}
			
	@Function(expr="#{src.declaredMethods}")
	class declaredMethods{}
	/**
	 * src is the AppService.
	 */
	@Function(fun=declaredMethods.class, filterFun=isCreateCommand.class)
	public class findCreateCommandMethods{}
	
	@Function(fun=declaredMethods.class, filterFun=isUpdateCommand.class)
	public class findUpdateCommandMethods{}
	
	/**
	 * src is the command method.
	 */
	@Function(expr="#{src.parameters.get(0).asType()}")
	class command{}
			
}
