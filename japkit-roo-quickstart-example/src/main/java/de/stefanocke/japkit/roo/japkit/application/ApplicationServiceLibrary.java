package de.stefanocke.japkit.roo.japkit.application;

import de.stefanocke.japkit.metaannotations.Function;
import de.stefanocke.japkit.metaannotations.Library;
import de.stefanocke.japkit.metaannotations.Matcher;
import de.stefanocke.japkit.metaannotations.TypeQuery;

@Library(annotationImports=CommandMethod.class)
public class ApplicationServiceLibrary {
	
	@TypeQuery(annotation = ApplicationService.class, shadow = true, unique = true, filterAV = "aggregateRoots")
	class findApplicationService{}
	
	
	@Matcher(annotations=CommandMethod.class, condition="#{src.returnType.isSame(fbo) && src.CommandMethod.aggregateRoot.isSame(fbo)}")
	class isCreateCommand{}
	
	@Matcher(annotations=CommandMethod.class, type=void.class , condition="#{src.CommandMethod.aggregateRoot.isSame(fbo)}")
	class isUpdateCommand{}
			
	/**
	 * src is the AppService.
	 */
	@Function(expr="#{isCreateCommand.filter(src.declaredMethods)}")
	class findCreateCommandMethods{}
	
	@Function(expr="#{isUpdateCommand.filter(src.declaredMethods)}")
	class findUpdateCommandMethods{}
	
	/**
	 * src is the command method.
	 */
	@Function(expr="#{src.parameters.get(0).asType()}")
	class command{}
			
}
