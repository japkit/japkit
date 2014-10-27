package de.stefanocke.japkit.roo.japkit.application;

import javax.annotation.Resource;
import javax.lang.model.element.Modifier;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import de.stefanocke.japkit.annotations.RuntimeMetadata;
import de.stefanocke.japkit.metaannotations.Annotation;
import de.stefanocke.japkit.metaannotations.Clazz;
import de.stefanocke.japkit.metaannotations.CodeFragment;
import de.stefanocke.japkit.metaannotations.Field;
import de.stefanocke.japkit.metaannotations.Getter;
import de.stefanocke.japkit.metaannotations.InnerClass;
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
import de.stefanocke.japkit.metaannotations.classselectors.GeneratedClass;
import de.stefanocke.japkit.metaannotations.classselectors.SrcType;
import de.stefanocke.japkit.roo.japkit.domain.JapJpaRepository;

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
					@Var(name="nameList", isFunction=true, expr="src.collect{it.simpleName}.join(',')", lang="GroovyScript")
		})
	public static class ApplicationServiceMethodsForAggregate {
		
	
		@ClassSelector
		public static class Repository{}
		
		@ClassSelector
		public static class Aggregate{}
		
		
		/**
		 * #{aggregateCreateMethods.toString()}
		 */
		@Field
		@Resource
		private Repository $repositoryName$;
		
		@Clazz(src="aggregateUpdateMethods", srcVar="method", nameExpr="#{method.simpleName.toFirstUpper}Command")
		@ClassSelector(kind=ClassSelectorKind.FQN, expr="#{genClass.enclosingElement.qualifiedName}.#{src.simpleName.toFirstUpper}Command")
		@Template(fieldDefaults=@Field(getter=@Getter, setter=@Setter), allFieldsAreTemplates=true)
		public class Command{
			long id; //TODO: GUID instead of DB ID !
			
			long version;
			
			@Field(src="#{src.parameters}", annotations = @Annotation(copyAnnotationsFromPackages={"javax.validation.constraints", "org.springframework.format.annotation"}))
			private SrcType $srcElementName$;
		};
		

		@Clazz(src="aggregateCreateMethods", nameExpr="Create#{aggregateName}Command")
		@ClassSelector(kind=ClassSelectorKind.FQN, expr="#{genClass.enclosingElement.qualifiedName}.Create#{aggregateName}Command")
		@Template(fieldDefaults=@Field(getter=@Getter, setter=@Setter), allFieldsAreTemplates=true)
		public class CreateCommand{
			
			@Field(src="#{src.parameters}", annotations = @Annotation(copyAnnotationsFromPackages={"javax.validation.constraints", "org.springframework.format.annotation"}))
			private SrcType $srcElementName$;
		};
		
		
		/**
		 * 
		 *  @japkit.bodyCode <pre>
		 * <code>
		 * #{aggregate.code} #{aggregateNameLower} = find#{aggregateName}(command.getId(), command.getVersion());
		 * #{callAggregateMethod.code()} 
		 * </code>
		 * </pre>
		 * @param command
		 */
		@Method(src="aggregateUpdateMethods", vars={ @Var(name="cmdProperties", propertyFilter=@Properties(sourceClass=Command.class)),
				@Var(name = "matchingProperty", isFunction = true, lang = "GroovyScript", expr="cmdProperties.find{src.simpleName.contentEquals(it.name)}"),
				@Var(name = "callAggregateMethod", code = @CodeFragment(emptyIteratorCode="#{aggregateNameLower}.#{src.simpleName}();",
						beforeIteratorCode="#{aggregateNameLower}.#{src.simpleName}(", afterIteratorCode=");", iterator="#{src.parameters}" , 
						separator = ", ", linebreak=true,  code="\tcommand.#{src.matchingProperty.getter.simpleName}()"))})
		//Das ist etwas wacklig, da für das Auflösen des ClassSelectors die passende src bereitstehen muss.
		//Alternativ könnte man auch alles, was mit dem Command zu tun hat, als dependent rules formulieren, die dann die Command-Klasse als Gen-Element bekommen.
		@Transactional
		@CommandMethod(aggregateRoot=Aggregate.class)
		public void $srcElementName$(Command command){}  
		
		/**
		 * 
		 *  @japkit.bodyCode <pre>
		 * <code>
		 * #{callAggregateConstructor.code()}
		 * #{repositoryName}.save(#{aggregateNameLower});
		 * return #{aggregateNameLower};
		 * </code>
		 * </pre>
		 * @param command
		 */
		@Method(src="aggregateCreateMethods", vars={ @Var(name="cmdProperties", propertyFilter=@Properties(sourceClass=CreateCommand.class)),
				@Var(name = "matchingProperty", isFunction = true, lang = "GroovyScript", expr="cmdProperties.find{src.simpleName.contentEquals(it.name)}"),
				@Var(name = "callAggregateConstructor", code = @CodeFragment(
						beforeIteratorCode="#{aggregate.code} #{aggregateNameLower} = new #{aggregate.code}(", afterIteratorCode=");", iterator="#{src.parameters}" , 
						separator = ", ", linebreak=true,  code="\tcommand.#{src.matchingProperty.getter.simpleName}()"))})
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