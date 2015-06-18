package de.stefanocke.japkit.roo.japkit.web;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;

import de.stefanocke.japkit.metaannotations.Field;
import de.stefanocke.japkit.metaannotations.Method;
import de.stefanocke.japkit.metaannotations.Template;
import de.stefanocke.japkit.metaannotations.TemplateCall;
import de.stefanocke.japkit.metaannotations.Var;
import de.stefanocke.japkit.roo.base.web.CrudOperations;
import de.stefanocke.japkit.roo.base.web.RepositoryAdapter;
import de.stefanocke.japkit.roo.japkit.domain.DomainLibrary.findRepository;

@Template(
		templates=@TemplateCall(value = ControllerMembersJpaRepository.RelatedEntityRepositoryFields.class)
		)
public abstract class ControllerMembersJpaRepository {
	/**${this.class.superclass.toString()}*/
	@Field(commentLang="GStringTemplateInline")
	@Autowired
	private Repository repository;

	
	@Template(src="#{relatedEntities}",
			vars={
				@Var(name="relatedEntity", expr = "#{src.asType()}" ),
				@Var(name="repository", expr = "#{relatedEntity}", fun=findRepository.class, nullable=true),
				@Var(name="repositoryFieldName", expr = "#{relatedEntity.simpleName.toFirstLower}Repository")
			})
	abstract class RelatedEntityRepositoryFields{
		@Field(cond="#{repository!=null}")
		@Autowired
		private Repository $repositoryFieldName$;
		
		/**
		 * #{src}  #{src.singleValueType} #{repository}
		 */
		@Method(src = "#{entityProperties}",  srcFilter="#{src.singleValueType.isSame(relatedEntity)}" , 			
				bodyCode = "return #{repositoryFieldName}.findAll();")
		protected abstract List<RelatedEntity> get$srcElementName$Choices();
	}

	@Method(imports = RepositoryAdapter.class,
			bodyCode = "return new RepositoryAdapter<#{fbo.code}>(repository);")
	protected abstract CrudOperations<FormBackingObject> crudOperations();

	

}
