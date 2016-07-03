package de.japkit.roo.japkit.application;

import static de.japkit.roo.japkit.domain.AnnotationPackages.JSR303;
import static de.japkit.roo.japkit.domain.AnnotationPackages.SPRING_FORMAT;
import static javax.lang.model.element.Modifier.PUBLIC;

import javax.annotation.Resource;
import javax.lang.model.element.Element;
import javax.lang.model.element.ExecutableElement;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import de.japkit.annotations.Order;
import de.japkit.annotations.RuntimeMetadata;
import de.japkit.metaannotations.Annotation;
import de.japkit.metaannotations.Case;
import de.japkit.metaannotations.Clazz;
import de.japkit.metaannotations.CodeFragment;
import de.japkit.metaannotations.Field;
import de.japkit.metaannotations.Function;
import de.japkit.metaannotations.Getter;
import de.japkit.metaannotations.Matcher;
import de.japkit.metaannotations.Method;
import de.japkit.metaannotations.ResultVar;
import de.japkit.metaannotations.Setter;
import de.japkit.metaannotations.Switch;
import de.japkit.metaannotations.Template;
import de.japkit.metaannotations.TemplateCall;
import de.japkit.metaannotations.Var;
import de.japkit.metaannotations.classselectors.BehaviorInnerClassWithGenClassPrefix;
import de.japkit.metaannotations.classselectors.ClassSelector;
import de.japkit.roo.japkit.CommonLibrary.type;
import de.japkit.roo.japkit.domain.DomainLibrary;
import de.japkit.roo.japkit.domain.DomainLibrary.findIdProperty;
import de.japkit.roo.japkit.domain.DomainLibrary.isEntity;
import de.japkit.roo.japkit.domain.DomainLibrary.isVO;

@RuntimeMetadata
@Service
@Template() 
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
		
		}
	)
	public abstract class ApplicationServiceMethodsForAggregate {
		@Matcher(modifiers=PUBLIC, type=void.class)
		class publicVoid{}
		
		@Matcher(modifiers=PUBLIC, condition="#{!src.parameters.isEmpty()}") 
		class hasParams{}
	
		@Function(expr="#{cmdProperties.findByName(e.simpleName).getter}")
		abstract ExecutableElement findGetter(Iterable<?> cmdProperties, Element e);

		@CodeFragment( 
					iterator="#{src.parameters}" , 
					separator = ",",  
					cases={
							@Case(cond ="#{findGetter(cmdProperties, src)==null}", value="null"),
							@Case(cond ="#{src.asType().asElement.ValueObject != null}", 
								value="new #{src.asType().code}.Builder()#{fluentVOSettersFromDTO()}.build()" ),
							//TODO: Das ist Q&D, da es davon augeht, dass der App-Service alle Aggregate bzw. ihre Repos kennt
							@Case(condFun = DomainLibrary.isEntity.class, value = "#{src.singleValueType.simpleName.toFirstLower}Repository.findOne(command.#{findGetter(cmdProperties, src).simpleName}())"),
					},
					code="command.#{findGetter(cmdProperties, src).simpleName}()")
		class paramsFromCommand{}

		@CodeFragment(vars={
				@Var(name="dtoGetter", expr="#{findGetter(cmdProperties, src)}"),
				@Var(name="dto", expr="#{dtoGetter.returnType.asElement}")
				}, 
				iterator="#{dto.properties}" ,
				code=".#{src.setter.simpleName}(command.#{dtoGetter.simpleName}().#{src.getter.simpleName}())") //Quick&Dirty
		class fluentVOSettersFromDTO{}

		@ClassSelector
		public class Repository{}
		
		@ClassSelector
		public class Aggregate{}
		
		@Order(0)
		@Field
		@Resource
		private Repository $repositoryName$;
		
		/**
		@Var(expr = "#{aggregate.properties}", filterFun = isEntity.class)
		class entityProperties{}
		
		@Template(srcFun=entityProperties.class, srcGroupByFun={SrcSingleValueType.class, findRepository.class} ) 
		abstract class RelatedEntityMembers{
			
			@Var(fun={SrcKey.class, nameFirstLower.class})
			class repositoryFieldName {}
			
			@Field
			@Autowired
			private SrcKey $repositoryFieldName$;
			
		}
		*/
		
		@Order(1)
		@Template(src="aggregateUpdateMethods", srcVar="method")
		class UpdateCommands{
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
		class CreateCommands{
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
			@Method(vars={ @Var(name="cmdProperties", expr="#{command.properties}")})
			@Transactional
			@CommandMethod(aggregateRoot=Aggregate.class)
			public Aggregate create$aggregateName$(CreateCommand command){
				return null;
			}
			
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

	@Template(
			vars={@Var(name="fieldType", expr="#{src.singleValueType}")},
					fieldDefaults=@Field(annotations = @Annotation(copyAnnotationsFromPackages={JSR303, SPRING_FORMAT}), 
							getter=@Getter, setter=@Setter)
	)
	public static class CommandFieldTemplate{
		
		@Order(1)
		@Clazz(condFun=isVO.class,
				src="#{fieldType.asElement}", srcVar="vo", nameExpr="#{vo.simpleName}DTO",
				 templates = {@TemplateCall(value=CommandFieldTemplate.class, src="#{vo.properties}")})
		@ResultVar("dtoClass")
		@DTO
		public class DTOClass{}	
		
		@Switch({
			@Case(condFun=isVO.class, value="#{dtoClass.asType()}"),
			@Case(condFun=isEntity.class, value="#{fieldType}", valueFun={findIdProperty.class, type.class}),
			@Case(cond="#{true}", value = "#{fieldType}" )
		})
		class FieldType{}
		
		
		
		@Order(2)			
		@Field()
		private FieldType $srcElementName$;
		
			
		
	}
}