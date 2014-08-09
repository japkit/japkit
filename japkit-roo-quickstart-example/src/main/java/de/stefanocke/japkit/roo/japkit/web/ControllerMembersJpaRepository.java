package de.stefanocke.japkit.roo.japkit.web;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;

import de.stefanocke.japkit.metaannotations.Field;
import de.stefanocke.japkit.metaannotations.Matcher;
import de.stefanocke.japkit.metaannotations.Method;
import de.stefanocke.japkit.metaannotations.Template;
import de.stefanocke.japkit.metaannotations.Var;
import de.stefanocke.japkit.roo.base.web.CrudOperations;
import de.stefanocke.japkit.roo.base.web.RepositoryAdapter;

@Template(
		vars = {
				@Var(name = "useFboRepository", matcher = @Matcher(condition = "#{repository != null && !entityAnnotation.activeRecord}")),
				@Var(name = "relatedEntitiesWithJpaRepositories",
						expr = "relatedEntities.collectEntries{it->[it, it.findRepository]}.findAll{it.value!=null}", lang = "GroovyScript"),
				@Var(name = "entityPropertiesWithJpaRepositories", expr = "entityProperties.collectEntries{p -> [p, "
						+ "relatedEntitiesWithJpaRepositories[p.singleValueType.asElement()]" + "]}.findAll{it.value!=null}",
						lang = "GroovyScript") })
public abstract class ControllerMembersJpaRepository {

	@Field(activation = @Matcher(condition = "useFboRepository"))
	@Autowired
	private Repository repository;

	@Field(src = "#{relatedEntitiesWithJpaRepositories.keySet()}", nameExpr = "#{src.simpleName.toFirstLower}Repository",
			vars = @Var(name = "relatedEntityRepository", expr = "#{relatedEntitiesWithJpaRepositories[src]}"))
	@Autowired
	private RelatedEntityRepository relatedEntityRepository;

	@Method(activation = @Matcher(condition = "useFboRepository"), imports = RepositoryAdapter.class,
			bodyCode = "return new RepositoryAdapter<#{fbo.code}>(repository);")
	protected abstract CrudOperations<FormBackingObject> crudOperations();

	@Method(src = "#{entityPropertiesWithJpaRepositories.keySet()}", nameExpr = "get#{src.name.toFirstUpper}Choices", vars = {
			@Var(name = "relatedEntity", expr = "#{src.singleValueType}"),
			@Var(name = "relatedEntityRepositoryName", expr = "#{relatedEntity.asElement.simpleName.toFirstLower}Repository") },
			bodyCode = "return #{relatedEntityRepositoryName}.findAll();")
	protected abstract List<RelatedEntity> getEntityChoices();

}
