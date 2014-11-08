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
import de.stefanocke.japkit.metaannotations.Getter;
import de.stefanocke.japkit.metaannotations.Matcher;
import de.stefanocke.japkit.metaannotations.Method;
import de.stefanocke.japkit.metaannotations.Properties;
import de.stefanocke.japkit.metaannotations.Setter;
import de.stefanocke.japkit.metaannotations.Template;
import de.stefanocke.japkit.metaannotations.TemplateCall;
import de.stefanocke.japkit.metaannotations.TypeQuery;
import de.stefanocke.japkit.metaannotations.Var;
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelector;
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelectorKind;
import de.stefanocke.japkit.metaannotations.classselectors.SrcType;
import de.stefanocke.japkit.roo.japkit.application.ApplicationServiceTemplate.ApplicationServiceMethodsForAggregate.DTOforVO.DTOClass;
import de.stefanocke.japkit.roo.japkit.domain.JapJpaRepository;
import de.stefanocke.japkit.roo.japkit.domain.ValueObject;

@RuntimeMetadata
@Service
//TODO: Den Call hier könnte man sich ggf. sparen, wenn Templates innerhalb von templates immer direkt ausgeführt würden.
@Template(templates=@TemplateCall(ApplicationServiceTemplate.ApplicationServiceMethodsForAggregate.class)) 
public class ApplicationServiceTemplate {
	@Template(src="#{aggregateRoots}", srcVar="aggregate", 
		vars={
			@Var(name="aggregateName", expr="#{src.asElement.simpleName}"),
			@Var(name="aggregateNameLower", expr="#{aggregateName.toFirstLower}"),
			@Var(name="aggregateUpdateMethods", expr="#{src.asElement.declaredMethods}", matcher=@Matcher(modifiers=Modifier.PUBLIC, type=void.class) ),
			@Var(name="aggregateCreateMethods", expr="#{src.asElement.declaredConstructors}", matcher=@Matcher(modifiers=Modifier.PUBLIC, condition="#{!src.parameters.isEmpty()}") ),
			@Var(name = "repository", typeQuery = @TypeQuery(
					annotation = JapJpaRepository.class, shadow = true, unique = true, filterAV = "domainType", inExpr = "#{src}")),
			@Var(name="repositoryName", expr="#{aggregateNameLower}Repository"),
			@Var(name="nameList", isFunction=true, expr="src.collect{it.simpleName}.join(',')", lang="GroovyScript"),
			@Var(name="valueObject", isFunction=true, annotation=ValueObject.class),
			@Var(name = "findGetter", isFunction=true, expr="#{cmdProperties.findByName(src.simpleName).getter}"),
					
			
			
		})
	public static class ApplicationServiceMethodsForAggregate {
		
	
		@ClassSelector
		public static class Repository{}
		
		@ClassSelector
		public static class Aggregate{}
		
		@Order(0)
		@Field
		@Resource
		private Repository $repositoryName$;
		
		@Order(1)
		@Clazz(src="aggregateUpdateMethods", srcVar="method", nameExpr="#{method.simpleName.toFirstUpper}Command")
		@ClassSelector(kind=ClassSelectorKind.FQN, expr="#{genClass.enclosingElement.qualifiedName}.#{src.simpleName.toFirstUpper}Command")
		@Template(fieldDefaults=@Field(getter=@Getter, setter=@Setter), allFieldsAreTemplates=true,
		 templates = @TemplateCall(value=CommandFieldTemplate.class, src="#{src.parameters}"))
		public class Command{
			long id; //TODO: GUID instead of DB ID !
			
			long version;		
		};

		@Order(3)
		@Clazz(src="aggregateCreateMethods", nameExpr="Create#{aggregateName}Command")
		@ClassSelector(kind=ClassSelectorKind.FQN, expr="#{genClass.enclosingElement.qualifiedName}.Create#{aggregateName}Command")
		@Template(fieldDefaults=@Field(getter=@Getter, setter=@Setter), 
				 templates = {@TemplateCall(value=CommandFieldTemplate.class, src="#{src.parameters}"),
			})
		public class CreateCommand{
		};
		
		
		@Template(templates=@TemplateCall( 
						activation=@Matcher(condition="#{src.asType().asElement.valueObject != null}"), 
						value=DTOforVO.class , src="#{src.asType()}"),
						fieldDefaults=@Field(annotations = @Annotation(copyAnnotationsFromPackages={JSR303, SPRING_FORMAT}), 
								getter=@Getter, setter=@Setter)
		)
		public static class CommandFieldTemplate{
			
			
			/**
			 * #{src.asType().asElement.valueObject.toString()}
			 *
			 */			
			@Field( activation=@Matcher(condition="#{src.asType().asElement.valueObject == null}"))
			private SrcType $srcElementName$;
			
			
			@Field( activation=@Matcher(condition="#{src.asType().asElement.valueObject != null}"), nameExpr="#{src.simpleName}")
			private DTOClass dtoForVO;
			
			
		}
		
		
		@Template(src="#{src.asElement}", srcVar="vo")
		public static class DTOforVO{
			@Clazz( nameExpr="#{vo.simpleName}DTO",
					 templates = {@TemplateCall(value=CommandFieldTemplate.class, src="#{vo.properties}")})
			@ClassSelector(kind=ClassSelectorKind.FQN,  expr="#{genClass.enclosingElement.qualifiedName}.#{src.asType().asElement.simpleName}DTO")
			@DTO
			public class DTOClass{				
			}			
//			@ClassSelector(expr="#{vo.asType()}") 
//			class VO{}
//			
//			@SuppressWarnings("unused")
//			private VO $srcElementName$FromDTO(){return null;}
		}
		
		@CodeFragment( 
					iterator="#{src.parameters}" , 
					separator = ",", linebreak=true,  
					cases={
							@Case(matcher=@Matcher(condition="#{src.findGetter==null}"), expr="null"),
							@Case(matcher=@Matcher(condition="#{src.asType().asElement.valueObject != null}"), 
								expr="new #{src.asType().code}.Builder()#{fluentVOSettersFromDTO.code(true)}.build()" )
					},
					code="command.#{src.findGetter.simpleName}()")
		static class ParamsFromCommand{}
		
		@CodeFragment(vars={
				@Var(name="dtoGetter", expr="#{src.findGetter}"),
				@Var(name="dto", expr="#{dtoGetter.returnType.asElement}"),
				}, 
				iterator="#{dto.properties}" ,
				code=".#{src.setter.simpleName}(command.#{dtoGetter.simpleName}().#{src.getter.simpleName}())") //Quick&Dirty
		static class FluentVOSettersFromDTO{}
		
		
		/**
		 * 
		 *  @japkit.bodyCode <pre>
		 * <code>
		 * #{aggregate.code} #{aggregateNameLower} = find#{aggregateName}(command.getId(), command.getVersion());
		 * #{aggregateNameLower}.#{src.simpleName}(#{paramsFromCommand.code(true)}); 
		 * </code>
		 * </pre>
		 * @param command
		 */
		@Order(4)
		@Method(src="aggregateUpdateMethods", vars={ @Var(name="cmdProperties", propertyFilter=@Properties(sourceClass=Command.class))})
		//Das ist etwas wacklig, da für das Auflösen des ClassSelectors die passende src bereitstehen muss.
		//Alternativ könnte man auch alles, was mit dem Command zu tun hat, als dependent rules formulieren, die dann die Command-Klasse als Gen-Element bekommen.
		@Transactional
		@CommandMethod(aggregateRoot=Aggregate.class)
		public void $srcElementName$(Command command){}  
		
		/**
		 * 
		 *  @japkit.bodyCode <pre>
		 * <code>
		 * #{aggregate.code} #{aggregateNameLower} = new #{aggregate.code}(#{paramsFromCommand.code(true)});
		 * #{repositoryName}.save(#{aggregateNameLower});
		 * return #{aggregateNameLower};
		 * </code>
		 * </pre>
		 * @param command
		 */
		@Order(5)
		@Method(src="aggregateCreateMethods", vars={ @Var(name="cmdProperties", propertyFilter=@Properties(sourceClass=CreateCommand.class))})
		//Das ist etwas wacklig, da für das Auflösen des ClassSelectors die passende src bereitstehen muss.
		//Alternativ könnte man auch alles, was mit dem Command zu tun hat, als dependent rules formulieren, die dann die Command-Klasse als Gen-Element bekommen.
		@Transactional
		@CommandMethod(aggregateRoot=Aggregate.class)
		public Aggregate create$aggregateName$(CreateCommand command){
			return null;
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