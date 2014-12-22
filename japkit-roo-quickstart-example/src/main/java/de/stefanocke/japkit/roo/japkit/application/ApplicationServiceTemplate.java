package de.stefanocke.japkit.roo.japkit.application;

import static de.stefanocke.japkit.roo.japkit.domain.AnnotationPackages.JSR303;
import static de.stefanocke.japkit.roo.japkit.domain.AnnotationPackages.SPRING_FORMAT;

import javax.annotation.Resource;
import javax.lang.model.element.Modifier;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import de.stefanocke.japkit.annotations.Order;
import de.stefanocke.japkit.annotations.RuntimeMetadata;
import de.stefanocke.japkit.metaannotations.Annotation;
import de.stefanocke.japkit.metaannotations.Case;
import de.stefanocke.japkit.metaannotations.Clazz;
import de.stefanocke.japkit.metaannotations.CodeFragment;
import de.stefanocke.japkit.metaannotations.Field;
import de.stefanocke.japkit.metaannotations.Function;
import de.stefanocke.japkit.metaannotations.Getter;
import de.stefanocke.japkit.metaannotations.Matcher;
import de.stefanocke.japkit.metaannotations.Method;
import de.stefanocke.japkit.metaannotations.ResultVar;
import de.stefanocke.japkit.metaannotations.Setter;
import de.stefanocke.japkit.metaannotations.Template;
import de.stefanocke.japkit.metaannotations.TemplateCall;
import de.stefanocke.japkit.metaannotations.Var;
import de.stefanocke.japkit.metaannotations.classselectors.BehaviorInnerClassWithGenClassPrefix;
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelector;
import de.stefanocke.japkit.metaannotations.classselectors.SrcType;
import de.stefanocke.japkit.roo.japkit.domain.DomainLibrary;

@RuntimeMetadata
@Service
//TODO: Den Call hier könnte man sich ggf. sparen, wenn (non-static ?) Templates innerhalb von templates immer direkt ausgeführt würden.
@Template(
		templates=@TemplateCall(ApplicationServiceTemplate.ApplicationServiceMethodsForAggregate.class)
) 
public class ApplicationServiceTemplate {
	
	@Template(src="#{aggregateRoots}", srcVar="aggregate", 
		libraries=DomainLibrary.class,	
		vars={
			@Var(name="aggregateName", expr="#{src.asElement.simpleName}"),
			@Var(name="aggregateNameLower", expr="#{aggregateName.toFirstLower}"),
			@Var(name="aggregateUpdateMethods", expr="#{publicVoid.filter(src.asElement.declaredMethods)}"),
			@Var(name="aggregateCreateMethods", expr="#{hasParams.filter(src.asElement.declaredConstructors)}"),
			@Var(name = "repository", expr="#{findRepository()}"),
			@Var(name="repositoryName", expr="#{aggregateNameLower}Repository"),
		
		},
		templates={
			@TemplateCall(ApplicationServiceMethodsForAggregate.UpdateCommands.class),
			@TemplateCall(ApplicationServiceMethodsForAggregate.CreateCommands.class)}
	)
	public static class ApplicationServiceMethodsForAggregate {
		@Matcher(modifiers=Modifier.PUBLIC, type=void.class)
		class publicVoid{}
		
		@Matcher(modifiers=Modifier.PUBLIC, condition="#{!src.parameters.isEmpty()}") 
		class hasParams{}
	
		@Function(expr="#{cmdProperties.findByName(src.simpleName).getter}")
		class findGetter{}

		@CodeFragment( 
					iterator="#{src.parameters}" , 
					separator = ",",  
					cases={
							@Case(matcher=@Matcher(condition="#{src.findGetter==null}"), expr="null"),
							@Case(matcher=@Matcher(condition="#{src.asType().asElement.ValueObject != null}"), 
								expr="new #{src.asType().code}.Builder()#{fluentVOSettersFromDTO()}.build()" )
					},
					code="command.#{src.findGetter.simpleName}()")
		static class paramsFromCommand{}

		@CodeFragment(vars={
				@Var(name="dtoGetter", expr="#{src.findGetter}"),
				@Var(name="dto", expr="#{dtoGetter.returnType.asElement}"),
				}, 
				iterator="#{dto.properties}" ,
				code=".#{src.setter.simpleName}(command.#{dtoGetter.simpleName}().#{src.getter.simpleName}())") //Quick&Dirty
		static class fluentVOSettersFromDTO{}

		@ClassSelector
		public static class Repository{}
		
		@ClassSelector
		public static class Aggregate{}
		
		@Order(0)
		@Field
		@Resource
		private Repository $repositoryName$;
		
		@Order(1)
		@Template(src="aggregateUpdateMethods", srcVar="method")
		static class UpdateCommands{
			@Order(1)
			@Clazz(nameExpr="#{method.simpleName.toFirstUpper}Command", behaviorClass=BehaviorInnerClassWithGenClassPrefix.class)
			@ClassSelector(expr="#{command.asType()}")
			@ResultVar("command")
			@Template(
				fieldDefaults=@Field(getter=@Getter, setter=@Setter),
				allFieldsAreTemplates=true,
				templates = @TemplateCall(value=CommandFieldTemplate.class, src="#{src.parameters}"))
			public class Command{
				Long id; //TODO: GUID instead of DB ID !
				
				Long version;		
			};
			
			/**
			 * @japkit.bodyCode <pre>
			 * <code>
			 * #{aggregate.code} #{aggregateNameLower} = find#{aggregateName}(command.getId(), command.getVersion());
			 * #{aggregateNameLower}.#{src.simpleName}(#{paramsFromCommand()}); 
			 * </code>
			 * </pre>
			 * @param command
			 */
			@Order(2)
			@Method(vars={ @Var(name="cmdProperties", expr="#{command.properties}")})
			@Transactional
			@CommandMethod(aggregateRoot=Aggregate.class)
			public void $srcElementName$(Command command){} 
		}
		
		@Order(2)
		@Template(src="aggregateCreateMethods", srcVar="method")
		static class CreateCommands{
			@Order(1)
			@Clazz(nameExpr="Create#{aggregateName}Command")
			@ClassSelector(expr="#{command.asType()}")
			@ResultVar("command")
			@Template(fieldDefaults=@Field(getter=@Getter, setter=@Setter), 
					 templates = {@TemplateCall(value=CommandFieldTemplate.class, src="#{src.parameters}"),
				})
			public class CreateCommand{};
			
			/**
			 * 
			 *  @japkit.bodyCode <pre>
			 * <code>
			 * #{aggregate.code} #{aggregateNameLower} = new #{aggregate.code}(#{paramsFromCommand()});
			 * #{repositoryName}.save(#{aggregateNameLower});
			 * return #{aggregateNameLower};
			 * </code>
			 * </pre>
			 * @param command
			 */
			@Order(2)
			@Method(src="aggregateCreateMethods", vars={ @Var(name="cmdProperties", expr="#{command.properties}")})
			@Transactional
			@CommandMethod(aggregateRoot=Aggregate.class)
			public Aggregate create$aggregateName$(CreateCommand command){
				return null;
			}
			
		}
	
		
		@Template(
				vars={@Var(name="srcTypeElement", expr="#{src.asType().asElement}"), @Var(name="fieldType", expr = "#{src.asType()}")},
						fieldDefaults=@Field(annotations = @Annotation(copyAnnotationsFromPackages={JSR303, SPRING_FORMAT}), 
								getter=@Getter, setter=@Setter)
		)
		public static class CommandFieldTemplate{
			
			@Order(1)
			@Clazz(activation=@Matcher(condition="#{srcTypeElement.ValueObject != null}"),
					src="#{srcTypeElement}", srcVar="vo", nameExpr="#{vo.simpleName}DTO",
					 templates = {@TemplateCall(value=CommandFieldTemplate.class, src="#{vo.properties}")})
			@ResultVar("fieldType")
			@DTO
			public class DTOClass{}	
			
			@ClassSelector()
			class FieldType{}
			
			@Order(2)			
			@Field()
			private FieldType $srcElementName$;
			
				
			
		}
		
		
		
		/**
		 *  @japkit.bodyCode <pre>
		 * <code>
		 * #{aggregate.code} #{aggregateNameLower} = #{repositoryName}.findOne(id);
		 * if(#{aggregateNameLower}==null){
		 * 	throw new IllegalArgumentException("#{aggregateName} not found for id:"+id);
		 * }
		 * if(version!=null && !version.equals(#{aggregateNameLower}.getVersion())){
		 * 	throw new IllegalStateException("Wrong version for #{aggregateName} :"+version);
		 * }
		 * return #{aggregateNameLower};
		 * </code>
		 * </pre>
		 */
		public Aggregate find$aggregateName$(long id, Long version){return null;}
	}
}