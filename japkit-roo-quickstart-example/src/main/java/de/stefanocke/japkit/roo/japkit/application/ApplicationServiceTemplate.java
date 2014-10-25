package de.stefanocke.japkit.roo.japkit.application;

import javax.lang.model.element.Modifier;

import de.stefanocke.japkit.annotations.RuntimeMetadata;
import de.stefanocke.japkit.metaannotations.CodeFragment;
import de.stefanocke.japkit.metaannotations.Field;
import de.stefanocke.japkit.metaannotations.Getter;
import de.stefanocke.japkit.metaannotations.InnerClass;
import de.stefanocke.japkit.metaannotations.Matcher;
import de.stefanocke.japkit.metaannotations.Method;
import de.stefanocke.japkit.metaannotations.Properties;
import de.stefanocke.japkit.metaannotations.Setter;
import de.stefanocke.japkit.metaannotations.Template;
import de.stefanocke.japkit.metaannotations.TypeQuery;
import de.stefanocke.japkit.metaannotations.Var;
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelector;
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelectorKind;
import de.stefanocke.japkit.metaannotations.classselectors.GeneratedClass;
import de.stefanocke.japkit.metaannotations.classselectors.SrcType;
import de.stefanocke.japkit.roo.japkit.domain.JapJpaRepository;

@RuntimeMetadata
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
public class ApplicationServiceTemplate {
	

	@ClassSelector
	public static class Repository{}
	
	@ClassSelector
	public static class Aggregate{}
	
	
	/**
	 * #{aggregateCreateMethods.toString()}
	 */
	@Field
	private Repository $repositoryName$;
	
	@InnerClass(src="aggregateUpdateMethods", nameExpr="#{src.simpleName.toFirstUpper}Command")
	@ClassSelector(kind=ClassSelectorKind.INNER_CLASS_NAME, enclosing = GeneratedClass.class, expr="#{src.simpleName.toFirstUpper}Command")
	@Template(fieldDefaults=@Field(getter=@Getter, setter=@Setter), allFieldsAreTemplates=true)
	public static class Command{
		long id; //TODO: GUID instead of DB ID !
		
		long version;
		
		@Field(src="#{src.parameters}")
		private SrcType $srcElementName$;
	};
	
	@InnerClass(src="aggregateCreateMethods", nameExpr="Create#{aggregateName}Command")
	@ClassSelector(kind=ClassSelectorKind.INNER_CLASS_NAME, enclosing = GeneratedClass.class, expr="Create#{aggregateName}Command")
	@Template(fieldDefaults=@Field(getter=@Getter, setter=@Setter), allFieldsAreTemplates=true)
	public static class CreateCommand{
		
		@Field(src="#{src.parameters}")
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
